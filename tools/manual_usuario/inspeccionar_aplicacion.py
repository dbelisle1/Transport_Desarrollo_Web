"""Inventaria enlaces y formularios visibles de TransPort por perfil.

Este script es auxiliar del manual de usuario. No envía formularios ni modifica
datos; navega por las rutas internas accesibles desde la interfaz y guarda un
JSON con los controles que realmente renderiza la aplicación.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import deque
from pathlib import Path
from urllib.parse import urljoin, urlparse, urlunparse

from playwright.sync_api import Page, sync_playwright


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "docs" / "manual_usuario" / "inventario_aplicacion.json"
DEFAULT_BASE_URL = "http://localhost:8080"
CHROME_PATHS = (
    Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe"),
    Path(r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"),
    Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"),
)

USERS = {
    "administrador": ("admin.demo", "TransPortAdmin2026!"),
    "gerente": ("gerente.demo", "TransPortGerente2026!"),
    "empleado": ("empleado.demo", "TransPortEmpleado2026!"),
    "operativo": ("operativo.demo", "TransPortOperativo2026!"),
    "vendedor": ("vendedor.demo", "TransPortVendedor2026!"),
    "cliente": ("cliente.demo", "TransPortCliente2026!"),
    "cliente_una_empresa": ("cliente2.demo", "TransPortCliente22026!"),
    "cliente_varias_empresas": ("cliente3.demo", "TransPortCliente32026!"),
}

SKIP_EXTENSIONS = re.compile(
    r"\.(?:css|js|png|jpe?g|gif|svg|ico|webmanifest|pdf|zip)$", re.IGNORECASE
)


def chrome_path() -> str:
    for candidate in CHROME_PATHS:
        if candidate.exists():
            return str(candidate)
    raise FileNotFoundError("No se encontró Google Chrome ni Microsoft Edge.")


def normalize_url(base_url: str, href: str) -> str | None:
    if not href or href.startswith(("#", "mailto:", "tel:", "javascript:")):
        return None
    absolute = urljoin(base_url, href)
    parsed = urlparse(absolute)
    base = urlparse(base_url)
    if parsed.netloc != base.netloc or SKIP_EXTENSIONS.search(parsed.path):
        return None
    # Los parámetros son importantes para filtros, pero no para inventariar la
    # misma pantalla repetidas veces. Se conservan únicamente las rutas.
    return urlunparse((parsed.scheme, parsed.netloc, parsed.path, "", "", ""))


def login(page: Page, base_url: str, username: str, password: str) -> None:
    page.goto(f"{base_url}/acceso", wait_until="networkidle")
    page.locator("input[name='Usuario'], input[name='NombreUsuario']").first.fill(username)
    page.locator("input[name='Clave'], input[name='Contrasena'], input[name='Password']").first.fill(password)
    page.locator("form").first.locator("button[type='submit'], input[type='submit']").first.click()
    page.wait_for_load_state("networkidle")
    if "/acceso" in page.url.lower():
        raise RuntimeError(f"No fue posible iniciar sesión como {username}.")


def field_data(field) -> dict:
    tag = field.evaluate("element => element.tagName.toLowerCase()")
    data = {
        "tag": tag,
        "type": field.get_attribute("type") or tag,
        "name": field.get_attribute("name"),
        "id": field.get_attribute("id"),
        "placeholder": field.get_attribute("placeholder"),
        "required": field.get_attribute("required") is not None,
        "value": field.get_attribute("value"),
    }
    if tag == "select":
        data["options"] = [
            {"value": option.get_attribute("value"), "text": option.inner_text().strip()}
            for option in field.locator("option").all()
        ]
    return data


def inspect_page(page: Page) -> dict:
    headings = [
        " ".join(item.inner_text().split())
        for item in page.locator("h1, h2").all()
        if item.is_visible()
    ]
    forms = []
    for index, form in enumerate(page.locator("form").all(), start=1):
        fields = [
            field_data(field)
            for field in form.locator("input:not([type='hidden']), select, textarea").all()
        ]
        buttons = [
            " ".join(button.inner_text().split())
            for button in form.locator("button, input[type='submit']").all()
            if button.is_visible()
        ]
        forms.append(
            {
                "numero": index,
                "method": (form.get_attribute("method") or "get").lower(),
                "action": form.get_attribute("action"),
                "fields": fields,
                "buttons": buttons,
            }
        )
    links = []
    for anchor in page.locator("a[href]").all():
        if not anchor.is_visible():
            continue
        links.append(
            {
                "text": " ".join(anchor.inner_text().split()),
                "href": anchor.get_attribute("href"),
            }
        )
    return {
        "url": page.url,
        "title": page.title(),
        "headings": headings,
        "forms": forms,
        "links": links,
    }


def crawl_profile(page: Page, base_url: str, limit: int) -> dict:
    queue = deque([normalize_url(base_url, page.url) or base_url])
    visited: set[str] = set()
    pages: list[dict] = []
    errors: list[dict] = []

    while queue and len(visited) < limit:
        url = queue.popleft()
        if not url or url in visited:
            continue
        visited.add(url)
        try:
            response = page.goto(url, wait_until="networkidle", timeout=30_000)
            status = response.status if response else None
            data = inspect_page(page)
            data["http_status"] = status
            pages.append(data)
            for link in data["links"]:
                target = normalize_url(base_url, link["href"] or "")
                if target and target not in visited:
                    queue.append(target)
        except Exception as exc:  # Continuar es intencional para el inventario.
            errors.append({"url": url, "error": str(exc)})
    return {"pages": pages, "errors": errors}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL)
    parser.add_argument("--limit", type=int, default=160)
    parser.add_argument(
        "--profiles",
        default=",".join(USERS),
        help="Perfiles separados por coma (por defecto: todos).",
    )
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()

    args.output.parent.mkdir(parents=True, exist_ok=True)
    result = {"base_url": args.base_url, "profiles": {}}

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(
            headless=True,
            executable_path=chrome_path(),
            args=["--disable-dev-shm-usage"],
        )
        selected_profiles = [item.strip() for item in args.profiles.split(",") if item.strip()]
        unknown = [item for item in selected_profiles if item not in USERS]
        if unknown:
            raise ValueError(f"Perfiles desconocidos: {', '.join(unknown)}")
        for profile in selected_profiles:
            credentials = USERS[profile]
            print(f"Inspeccionando perfil {profile}...", flush=True)
            context = browser.new_context(viewport={"width": 1440, "height": 1000})
            page = context.new_page()
            try:
                login(page, args.base_url, *credentials)
                result["profiles"][profile] = crawl_profile(page, args.base_url, args.limit)
            except Exception as exc:
                result["profiles"][profile] = {"pages": [], "errors": [{"error": str(exc)}]}
            finally:
                context.close()
        browser.close()

    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Inventario guardado en {args.output}")
    for profile, data in result["profiles"].items():
        print(f"{profile}: {len(data['pages'])} páginas, {len(data['errors'])} errores")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

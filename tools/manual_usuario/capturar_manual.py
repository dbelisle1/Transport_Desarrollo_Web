"""Ejecuta los flujos de aceptación y genera las capturas del manual TransPort.

La automatización usa los usuarios DEMO creados por database/005_datos_demostracion.sql.
Cada paso se aísla: un fallo se registra y la ejecución continúa con el siguiente.
Los registros creados incluyen un identificador MANUAL-<fecha> para reconocerlos.
"""

from __future__ import annotations

import argparse
import json
import re
import traceback
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Any, Callable
from urllib.parse import urlparse

from playwright.sync_api import Browser, Locator, Page, TimeoutError as PlaywrightTimeoutError, sync_playwright

from inspeccionar_aplicacion import CHROME_PATHS, USERS, chrome_path


ROOT = Path(__file__).resolve().parents[2]
OUTPUT_DIR = ROOT / "docs" / "manual_usuario"
CAPTURE_DIR = OUTPUT_DIR / "capturas"
REPORT_PATH = OUTPUT_DIR / "reporte_ejecucion.json"
DEFAULT_BASE_URL = "http://localhost:8080"


@dataclass
class ManualRun:
    base_url: str
    run_id: str
    browser: Browser
    captures: list[dict[str, Any]] = field(default_factory=list)
    checks: list[dict[str, Any]] = field(default_factory=list)
    counter: int = 0
    generated_records: dict[str, Any] = field(default_factory=dict)

    def screenshot_path(self, title: str) -> Path:
        self.counter += 1
        slug = re.sub(r"[^a-z0-9]+", "-", title.lower(), flags=re.IGNORECASE).strip("-")
        slug = slug[:70] or "captura"
        return CAPTURE_DIR / f"{self.counter:03d}_{slug}.png"

    def capture(
        self,
        page: Page,
        chapter: str,
        title: str,
        description: str,
        *,
        target: Locator | None = None,
        outcome: str = "informativo",
    ) -> Path:
        path = self.screenshot_path(title)
        path.parent.mkdir(parents=True, exist_ok=True)
        try:
            if target is not None:
                target.scroll_into_view_if_needed(timeout=5_000)
                target.screenshot(path=str(path), animations="disabled")
            else:
                page.screenshot(path=str(path), full_page=True, animations="disabled")
        except Exception:
            page.screenshot(path=str(path), animations="disabled")
        self.captures.append(
            {
                "chapter": chapter,
                "title": title,
                "description": description,
                "image": str(path.relative_to(OUTPUT_DIR)).replace("\\", "/"),
                "url": page.url,
                "outcome": outcome,
            }
        )
        return path

    def check(
        self,
        name: str,
        chapter: str,
        status: str,
        page: Page | None,
        detail: str = "",
    ) -> None:
        self.checks.append(
            {
                "name": name,
                "chapter": chapter,
                "status": status,
                "url": page.url if page else None,
                "detail": detail,
            }
        )

    def safe(
        self,
        name: str,
        chapter: str,
        page: Page | None,
        action: Callable[[], Any],
    ) -> Any:
        try:
            result = action()
            self.check(name, chapter, "correcto", page)
            return result
        except Exception as exc:  # La continuidad es un requisito de esta prueba.
            detail = f"{type(exc).__name__}: {exc}"
            self.check(name, chapter, "fallo", page, detail)
            if page:
                try:
                    self.capture(
                        page,
                        chapter,
                        f"Fallo - {name}",
                        detail,
                        outcome="fallo",
                    )
                except Exception:
                    pass
            print(f"[FALLO] {name}: {detail}", flush=True)
            return None

    def write_report(self) -> None:
        payload = {
            "generated_at": datetime.now().isoformat(timespec="seconds"),
            "base_url": self.base_url,
            "run_id": self.run_id,
            "summary": {
                "checks": len(self.checks),
                "passed": sum(item["status"] == "correcto" for item in self.checks),
                "failed": sum(item["status"] == "fallo" for item in self.checks),
                "screenshots": len(self.captures),
            },
            "generated_records": self.generated_records,
            "checks": self.checks,
            "captures": self.captures,
        }
        REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
        REPORT_PATH.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def new_page(run: ManualRun) -> tuple[Any, Page]:
    context = run.browser.new_context(
        viewport={"width": 1440, "height": 1000},
        locale="es-GT",
        timezone_id="America/Guatemala",
        color_scheme="light",
    )
    page = context.new_page()
    page.set_default_timeout(12_000)
    page.on("dialog", lambda dialog: dialog.accept())
    return context, page


def go(page: Page, base_url: str, path: str) -> None:
    response = page.goto(f"{base_url}{path}", wait_until="networkidle", timeout=30_000)
    if response and response.status >= 400:
        raise RuntimeError(f"HTTP {response.status} al abrir {path}")


def login(
    run: ManualRun,
    page: Page,
    profile: str,
    *,
    capture_pair: bool = False,
    invalid_first: bool = False,
) -> None:
    username, password = USERS[profile]
    go(page, run.base_url, "/acceso")
    if invalid_first:
        page.locator("[name='NombreUsuario']").fill(username)
        page.locator("[name='Clave']").fill("ClaveIncorrecta2026!")
        run.capture(
            page,
            "Acceso y seguridad",
            "Inicio de sesión con clave incorrecta - datos",
            "El formulario completo antes de intentar el acceso con una clave incorrecta.",
            target=page.locator("form.auth-form"),
        )
        page.locator("form.auth-form button[type='submit']").click()
        page.wait_for_load_state("networkidle")
        run.capture(
            page,
            "Acceso y seguridad",
            "Inicio de sesión con clave incorrecta - resultado",
            "La aplicación conserva el formulario y presenta el mensaje de validación.",
        )
        if "/acceso" not in page.url.lower():
            raise RuntimeError("La aplicación aceptó una clave incorrecta.")

    page.locator("[name='NombreUsuario']").fill(username)
    page.locator("[name='Clave']").fill(password)
    if capture_pair:
        run.capture(
            page,
            "Acceso y seguridad",
            f"Inicio de sesión {profile} - datos",
            f"Credenciales de demostración introducidas para el perfil {profile}.",
            target=page.locator("form.auth-form"),
        )
    page.locator("form.auth-form button[type='submit']").click()
    page.wait_for_load_state("networkidle")
    if "/acceso" in page.url.lower():
        raise RuntimeError(f"No se inició sesión como {profile}.")
    if capture_pair:
        run.capture(
            page,
            "Acceso y seguridad",
            f"Inicio de sesión {profile} - resultado",
            f"Portal inicial mostrado después de autenticar el perfil {profile}.",
        )


def find_form(
    page: Page,
    *,
    action_contains: str | None = None,
    method: str | None = None,
    field: str | None = None,
    button_text: str | None = None,
) -> Locator:
    forms = page.locator("form")
    for index in range(forms.count()):
        form = forms.nth(index)
        action = form.get_attribute("action") or ""
        form_method = (form.get_attribute("method") or "get").lower()
        if action == "/acceso/salir" and action_contains != "/acceso/salir":
            continue
        if action_contains and action_contains.lower() not in action.lower():
            continue
        if method and form_method != method.lower():
            continue
        if field and form.locator(f"[name='{field}']").count() == 0:
            continue
        if button_text and form.get_by_role("button", name=re.compile(button_text, re.IGNORECASE)).count() == 0:
            continue
        return form
    raise LookupError(
        f"Formulario no encontrado (action={action_contains}, method={method}, field={field}, button={button_text})."
    )


def select_option(locator: Locator, desired: Any) -> None:
    if isinstance(desired, dict):
        if desired.get("value") is not None:
            locator.select_option(value=str(desired["value"]))
            return
        if desired.get("label") is not None:
            locator.select_option(label=str(desired["label"]))
            return
        if desired.get("contains") is not None:
            needle = str(desired["contains"]).lower()
            options = locator.locator("option")
            for index in range(options.count()):
                option = options.nth(index)
                if needle in option.inner_text().lower():
                    locator.select_option(value=option.get_attribute("value"))
                    return
            raise LookupError(f"No existe una opción que contenga {desired['contains']!r}.")
    locator.select_option(value=str(desired))


def fill_form(form: Locator, values: dict[str, Any], *, fill_defaults: bool = False) -> None:
    for name, desired in values.items():
        fields = form.locator(f"[name='{name}']")
        if fields.count() == 0:
            continue
        first = fields.first
        tag = first.evaluate("element => element.tagName.toLowerCase()")
        kind = (first.get_attribute("type") or tag).lower()
        if tag == "select":
            select_option(first, desired)
        elif kind in {"checkbox", "radio"}:
            fields = form.locator(
                f"input[name='{name}'][type='checkbox'], input[name='{name}'][type='radio']"
            )
            desired_values = {str(value) for value in desired} if isinstance(desired, list) else None
            for index in range(fields.count()):
                field = fields.nth(index)
                should_check = bool(desired) if desired_values is None else (field.get_attribute("value") or "") in desired_values
                field.set_checked(should_check)
        else:
            first.fill(str(desired))

    if not fill_defaults:
        return
    for field in form.locator("input:not([type='hidden']):not([type='submit']), textarea, select").all():
        if field.get_attribute("name") in values or field.is_disabled():
            continue
        tag = field.evaluate("element => element.tagName.toLowerCase()")
        kind = (field.get_attribute("type") or tag).lower()
        if tag == "select":
            options = field.locator("option")
            for index in range(options.count()):
                option = options.nth(index)
                value = option.get_attribute("value")
                if value not in {None, "", "0"} and not option.is_disabled():
                    field.select_option(value=value)
                    break
        elif kind == "checkbox":
            if field.get_attribute("required") is not None:
                field.check()
        elif kind == "date":
            field.fill((date.today() + timedelta(days=30)).isoformat())
        elif kind == "datetime-local":
            field.fill((datetime.now() + timedelta(days=2)).strftime("%Y-%m-%dT%H:%M"))
        elif kind in {"number", "range"}:
            field.fill("1")
        elif kind not in {"file", "password"} and not field.input_value():
            field.fill("Dato de prueba del manual")


def visible_messages(page: Page) -> str:
    selectors = ".validation, .alert, .notice, .flash, [role='alert'], .field-validation-error"
    messages: list[str] = []
    for item in page.locator(selectors).all():
        if item.is_visible():
            text = " ".join(item.inner_text().split())
            if text and text not in messages:
                messages.append(text)
    return " | ".join(messages)[:1200]


def submit_form(
    run: ManualRun,
    page: Page,
    chapter: str,
    title: str,
    description: str,
    values: dict[str, Any],
    *,
    action_contains: str | None = None,
    method: str | None = None,
    field: str | None = None,
    button_text: str | None = None,
    fill_defaults: bool = False,
) -> str:
    form = find_form(
        page,
        action_contains=action_contains,
        method=method,
        field=field,
        button_text=button_text,
    )
    fill_form(form, values, fill_defaults=fill_defaults)
    run.capture(
        page,
        chapter,
        f"{title} - datos",
        f"{description} Esta captura muestra los datos antes de enviarlos.",
        target=form,
    )
    button = (
        form.get_by_role("button", name=re.compile(button_text, re.IGNORECASE)).first
        if button_text
        else form.locator("button:not([type='button']), input[type='submit']").first
    )
    button.click()
    try:
        page.wait_for_load_state("networkidle", timeout=20_000)
    except PlaywrightTimeoutError:
        page.wait_for_timeout(1_000)
    messages = visible_messages(page)
    try:
        body_text = page.locator("body").inner_text(timeout=2_000)
    except Exception:
        body_text = ""
    failure_words = ("no fue posible", "error no controlado", "exception", "revise los datos")
    body_failure_words = ("an unhandled exception", "http error", "error no controlado")
    browser_error = page.url.startswith("chrome-error://") or "HTTP ERROR" in body_text.upper()
    outcome = (
        "fallo"
        if browser_error
        or any(word in messages.lower() for word in failure_words)
        or any(word in body_text.lower() for word in body_failure_words)
        else "correcto"
    )
    if browser_error and not messages:
        messages = "El navegador recibió HTTP 400 al enviar el formulario."
    run.capture(
        page,
        chapter,
        f"{title} - resultado",
        f"Resultado devuelto por la aplicación. {messages or 'La pantalla se actualizó sin un mensaje de error visible.'}",
        outcome=outcome,
    )
    if outcome == "fallo":
        raise RuntimeError(messages or "La aplicación mostró un error.")
    return page.url


def capture_route(
    run: ManualRun,
    page: Page,
    chapter: str,
    title: str,
    path: str,
    description: str,
) -> None:
    go(page, run.base_url, path)
    if "/acceso" in page.url.lower() and path != "/acceso":
        raise RuntimeError("La ruta redirigió al acceso.")
    run.capture(page, chapter, title, description)


def test_public_and_roles(run: ManualRun) -> None:
    context, page = new_page(run)
    try:
        run.safe(
            "Portada pública",
            "Sitio público",
            page,
            lambda: capture_route(
                run,
                page,
                "Sitio público",
                "Portada pública",
                "/",
                "Página de bienvenida y acceso a los servicios públicos de TransPort.",
            ),
        )
        run.safe(
            "Catálogo público",
            "Sitio público",
            page,
            lambda: capture_route(
                run,
                page,
                "Sitio público",
                "Catálogo público de productos y servicios",
                "/catalogo",
                "Ofertas comerciales visibles sin autenticación.",
            ),
        )
        run.safe(
            "Filtro del catálogo público",
            "Sitio público",
            page,
            lambda: submit_form(
                run,
                page,
                "Sitio público",
                "Filtrar catálogo público",
                "Selección de un giro para reducir las ofertas visibles.",
                {"giroId": {"value": "1"}},
                method="get",
                field="giroId",
            ),
        )
        run.safe(
            "Inicio de sesión",
            "Acceso y seguridad",
            page,
            lambda: login(run, page, "administrador", capture_pair=True, invalid_first=True),
        )
        run.safe(
            "Cierre de sesión",
            "Acceso y seguridad",
            page,
            lambda: submit_form(
                run,
                page,
                "Acceso y seguridad",
                "Cerrar sesión",
                "El botón termina la sesión y regresa al sitio público.",
                {},
                action_contains="/acceso/salir",
                button_text="Cerrar sesión",
            ),
        )
    finally:
        context.close()

    for profile in USERS:
        context, page = new_page(run)
        try:
            def role_flow(profile: str = profile) -> None:
                login(run, page, profile)
                chapter = "Perfiles y portales"
                run.capture(
                    page,
                    chapter,
                    f"Portal del perfil {profile}",
                    "Menú y página inicial disponibles de acuerdo con los permisos de este usuario.",
                )

            run.safe(f"Portal de {profile}", "Perfiles y portales", page, role_flow)
        finally:
            context.close()


def test_administration(run: ManualRun, page: Page) -> None:
    chapter = "Administración"
    routes = [
        ("Panel de administración", "/admin"),
        ("Listado de usuarios", "/admin/usuarios"),
        ("Listado de clientes", "/admin/clientes"),
        ("Catálogo de roles", "/admin/catalogos/roles"),
        ("Catálogo de giros", "/admin/catalogos/giros"),
        ("Catálogo de sedes", "/admin/catalogos/sedes"),
        ("Auditoría", "/admin/auditoria"),
    ]
    for title, path in routes:
        run.safe(
            title,
            chapter,
            page,
            lambda title=title, path=path: capture_route(
                run, page, chapter, title, path, f"Pantalla {title.lower()} disponible para administración."
            ),
        )

    for title, path, field, values in [
        ("Filtrar usuarios", "/admin/usuarios", "busqueda", {"busqueda": "demo", "esActivo": "true"}),
        ("Filtrar clientes", "/admin/clientes", "busqueda", {"busqueda": "DEMO", "esActivo": "true"}),
        ("Filtrar auditoría", "/admin/auditoria", "TipoOperacion", {"TipoOperacion": "Crear"}),
    ]:
        def filter_flow(title=title, path=path, field=field, values=values):
            go(page, run.base_url, path)
            submit_form(run, page, chapter, title, "Uso de los criterios de búsqueda de la pantalla.", values, method="get", field=field)

        run.safe(title, chapter, page, filter_flow)

    marker = run.run_id
    catalog_definitions = [
        ("roles", {"Nombre": f"{marker}-ROL", "Descripcion": "Rol temporal creado durante la prueba del manual.", "EsActivo": True}),
        ("giros", {"Nombre": f"{marker}-GIRO", "Descripcion": "Giro temporal creado durante la prueba del manual.", "EsActivo": True}),
        (
            "sedes",
            {
                "Nombre": f"{marker}-SEDE",
                "Direccion": "Zona 1, Ciudad de Guatemala",
                "GiroNegocioId": {"value": "1"},
                "EsActivo": True,
            },
        ),
    ]
    for catalog_type, values in catalog_definitions:
        def catalog_flow(catalog_type=catalog_type, values=values):
            go(page, run.base_url, f"/admin/catalogos/{catalog_type}/crear")
            submit_form(
                run,
                page,
                chapter,
                f"Crear catálogo de {catalog_type}",
                f"Alta de un registro temporal en el catálogo de {catalog_type}.",
                values,
                method="post",
                field="Nombre",
                fill_defaults=True,
            )

        run.safe(f"Crear {catalog_type}", chapter, page, catalog_flow)

    def user_flow() -> None:
        go(page, run.base_url, "/admin/usuarios/crear")
        submit_form(
            run,
            page,
            chapter,
            "Crear usuario",
            "Alta de un usuario temporal con rol, giro y sede.",
            {
                "NombreUsuario": f"{marker.lower()}.usuario",
                "Correo": f"{marker.lower()}@example.test",
                "Nombre": "Usuario",
                "Apellido": "Manual",
                "Clave": "ManualTest2026!",
                "EsActivo": True,
                "RolesSeleccionados": ["3"],
                "GirosSeleccionados": ["1"],
                "SedesSeleccionadas": ["2"],
            },
            method="post",
            field="NombreUsuario",
        )

    run.safe("Crear usuario", chapter, page, user_flow)

    def client_flow() -> None:
        go(page, run.base_url, "/admin/clientes/crear")
        submit_form(
            run,
            page,
            chapter,
            "Crear cliente",
            "Alta de una empresa cliente temporal y asignación de alcance.",
            {
                "Nombre": f"{marker} Cliente",
                "Nit": f"{datetime.now():%y%m%d%H%M}",
                "CorreoContacto": f"cliente.{marker.lower()}@example.test",
                "EsActivo": True,
                "UsuariosSeleccionados": ["3"],
                "GirosSeleccionados": ["1"],
            },
            method="post",
            field="Nit",
        )

    run.safe("Crear cliente", chapter, page, client_flow)


def filter_and_capture(run: ManualRun, page: Page, chapter: str, title: str, path: str, field: str, values: dict[str, Any]) -> None:
    go(page, run.base_url, path)
    submit_form(run, page, chapter, f"Filtrar {title}", f"Aplicación de filtros en {title.lower()}.", values, method="get", field=field)


def test_management_pages(run: ManualRun, page: Page) -> None:
    chapter = "Gestión operativa"
    pages = [
        ("Panel de gestión", "/gestion"),
        ("Pedidos comerciales", "/gestion/pedidos"),
        ("Inventarios y bodegas", "/gestion/inventarios"),
        ("Catálogo comercial", "/gestion/catalogo"),
        ("Abastecimiento", "/gestion/abastecimientos"),
        ("Extracción minera", "/gestion/extracciones"),
        ("Producción", "/gestion/producciones"),
        ("Maquinaria", "/gestion/maquinarias"),
        ("Transporte", "/gestion/transportes"),
        ("GPS", "/gestion/gps"),
        ("Construcción", "/gestion/construcciones"),
        ("Finanzas", "/gestion/finanzas"),
        ("Ingresos", "/gestion/finanzas/ingresos"),
        ("Alertas", "/gestion/alertas"),
        ("Comunicaciones", "/gestion/comunicaciones"),
        ("Integraciones", "/gestion/integraciones"),
        ("Reportes", "/gestion/reportes"),
    ]
    for title, path in pages:
        run.safe(
            title,
            chapter,
            page,
            lambda title=title, path=path: capture_route(
                run, page, chapter, title, path, f"Vista general del módulo {title.lower()}."
            ),
        )

    filters = [
        ("Pedidos", "/gestion/pedidos", "busqueda", {"busqueda": "DEMO"}),
        ("Inventarios", "/gestion/inventarios", "busqueda", {"busqueda": "DEMO"}),
        ("Catálogo", "/gestion/catalogo", "busqueda", {"busqueda": "DEMO"}),
        ("Abastecimiento", "/gestion/abastecimientos", "busqueda", {"busqueda": "DEMO"}),
        ("Extracciones", "/gestion/extracciones", "estado", {"estado": {"value": "Registrada"}}),
        ("Producciones", "/gestion/producciones", "estado", {"estado": {"value": "Planificada"}}),
        ("Maquinaria", "/gestion/maquinarias", "busqueda", {"busqueda": "DEMO"}),
        ("Transportes", "/gestion/transportes", "estado", {"estado": {"value": "Programado"}}),
        ("Construcciones", "/gestion/construcciones", "busqueda", {"busqueda": "DEMO"}),
        ("Finanzas", "/gestion/finanzas", "anio", {"anio": "2026", "mes": "10"}),
        ("Alertas", "/gestion/alertas", "estado", {"estado": {"value": "Activa"}}),
        ("Comunicaciones", "/gestion/comunicaciones", "busqueda", {"busqueda": "DEMO"}),
        ("Integraciones", "/gestion/integraciones", "busqueda", {"busqueda": "DEMO"}),
        ("Reportes", "/gestion/reportes", "desde", {"desde": "2026-01-01", "hasta": "2026-12-31"}),
    ]
    for title, path, field, values in filters:
        run.safe(
            f"Filtrar {title}",
            chapter,
            page,
            lambda title=title, path=path, field=field, values=values: filter_and_capture(
                run, page, chapter, title, path, field, values
            ),
        )


def create_and_follow(
    run: ManualRun,
    page: Page,
    chapter: str,
    title: str,
    path: str,
    field: str,
    values: dict[str, Any],
    *,
    action_contains: str,
    button_text: str | None = None,
) -> str:
    go(page, run.base_url, path)
    result = submit_form(
        run,
        page,
        chapter,
        title,
        f"Registro de {title.lower()} con datos ficticios identificados por {run.run_id}.",
        values,
        action_contains=action_contains,
        field=field,
        button_text=button_text,
    )
    return urlparse(result).path


def test_inventory(run: ManualRun, page: Page) -> None:
    chapter = "Inventarios y bodegas"
    marker = run.run_id
    run.safe(
        "Crear artículo de inventario",
        chapter,
        page,
        lambda: create_and_follow(
            run,
            page,
            chapter,
            "Crear artículo de inventario",
            "/gestion/inventarios",
            "Codigo",
            {
                "GiroNegocioId": "1",
                "Codigo": f"{marker}-ART",
                "Nombre": f"Árido de prueba {marker}",
                "Categoria": "Materia prima",
                "UnidadMedida": "t",
                "StockMinimo": "5",
            },
            action_contains="/articulos",
        ),
    )

    def inventory_movement() -> None:
        go(page, run.base_url, "/gestion/inventarios")
        submit_form(
            run,
            page,
            chapter,
            "Registrar entrada de inventario",
            "Entrada de existencias sobre un artículo de demostración existente.",
            {
                "InventarioArticuloId": "22",
                "Tipo": {"label": "Entrada"},
                "SedeDestinoId": "2",
                "Cantidad": "25",
                "Referencia": marker,
                "Observacion": "Entrada creada durante la elaboración del manual.",
            },
            action_contains="/movimientos",
            field="Cantidad",
        )
    run.safe("Registrar movimiento de inventario", chapter, page, inventory_movement)


def test_simple_creations(run: ManualRun, page: Page) -> dict[str, str]:
    marker = run.run_id
    tomorrow = (date.today() + timedelta(days=15)).isoformat()
    timestamp_number = int(datetime.now().strftime("%H%M%S"))
    budget_year = 2030 + timestamp_number % 70
    budget_month = (timestamp_number // 70) % 12 + 1
    paths: dict[str, str] = {}
    definitions = [
        (
            "abastecimiento",
            "Abastecimiento",
            "/gestion/abastecimientos",
            "/crear",
            "Motivo",
            {
                "GiroSolicitanteId": "2",
                "SedeSolicitanteId": "7",
                "GiroProveedorId": "1",
                "SedeProveedorId": "2",
                "FechaNecesaria": tomorrow,
                "Motivo": f"{marker} reposición de materia prima",
                "ArticuloProveedorId": "22",
                "ArticuloDestinoId": "23",
                "Cantidad": "4",
            },
        ),
        (
            "extraccion",
            "Extracción minera",
            "/gestion/extracciones",
            "/crear",
            "FrenteExtraccion",
            {
                "SedeId": "2",
                "InventarioArticuloId": "22",
                "FechaOperacion": date.today().isoformat(),
                "Turno": "Diurno",
                "FrenteExtraccion": f"{marker}-FRENTE",
                "CantidadExtraida": "12",
                "CantidadRechazada": "1",
                "DestinoTipo": {"label": "Inventario"},
                "DestinoDescripcion": "Bodega Cobán",
                "Observacion": f"Jornada {marker}",
            },
        ),
        (
            "produccion",
            "Orden de producción",
            "/gestion/producciones",
            "/crear",
            "CantidadEntrada",
            {
                "SedeId": "6",
                "ArticuloEntradaId": "23",
                "ArticuloSalidaId": "24",
                "FechaPlanificada": tomorrow,
                "CantidadEntrada": "10",
                "CantidadSalidaPlanificada": "8",
                "Observacion": f"Orden {marker}",
            },
        ),
        (
            "maquinaria",
            "Equipo de maquinaria",
            "/gestion/maquinarias",
            "/crear",
            "Codigo",
            {
                "SedeId": "9",
                "Codigo": f"{marker}-MAQ",
                "Tipo": "Excavadora",
                "Marca": "Caterpillar",
                "Modelo": "320 prueba",
                "Anio": "2026",
                "PrecioVenta": "800000",
                "TarifaDiaria": "3200",
                "HorasUso": "25",
            },
        ),
        (
            "construccion",
            "Proyecto de construcción",
            "/gestion/construcciones",
            "/crear",
            "Nombre",
            {
                "SedeId": "1",
                "ClienteId": "8",
                "Nombre": f"{marker} Puente demostrativo",
                "TipoObra": {"label": "Puente"},
                "Ubicacion": "Ciudad de Guatemala",
                "FechaInicio": date.today().isoformat(),
                "FechaFin": (date.today() + timedelta(days=90)).isoformat(),
                "Presupuesto": "450000",
                "ResponsableId": "1",
            },
        ),
        (
            "finanzas",
            "Presupuesto",
            "/gestion/finanzas",
            "/crear",
            "Nombre",
            {
                "GiroId": "1",
                "SedeId": "2",
                "Anio": str(budget_year),
                "Mes": str(budget_month),
                "Nombre": f"{marker} Presupuesto operativo",
                "Monto": "75000",
                "Observacion": "Presupuesto creado durante la prueba del manual.",
            },
        ),
        (
            "alerta",
            "Alerta",
            "/gestion/alertas",
            "/crear",
            "Titulo",
            {
                "Tipo": {"label": "Alerta"},
                "Severidad": {"label": "Advertencia"},
                "Titulo": f"{marker} Revisión operativa",
                "Mensaje": "Revisar existencias y actividades pendientes.",
                "RolId": "4",
                "GiroId": "1",
                "SedeId": "2",
                "FechaProgramadaUtc": (datetime.now() + timedelta(hours=1)).strftime("%Y-%m-%dT%H:%M"),
                "FechaVencimientoUtc": (datetime.now() + timedelta(days=2)).strftime("%Y-%m-%dT%H:%M"),
                "ModuloOrigen": "ManualUsuario",
                "RegistroOrigenId": "1",
            },
        ),
        (
            "comunicacion",
            "Comunicación interna",
            "/gestion/comunicaciones",
            "/crear",
            "Asunto",
            {
                "Tipo": {"label": "Interna"},
                "GiroNegocioId": "1",
                "Asunto": f"{marker} Coordinación operativa",
                "ModuloOrigen": "ManualUsuario",
                "RegistroOrigenId": "1",
                "MensajeInicial": "Mensaje inicial generado durante la prueba del manual.",
            },
        ),
    ]
    for key, title, route, action, field_name, values in definitions:
        chapter = title
        result = run.safe(
            f"Crear {title}",
            chapter,
            page,
            lambda title=title, route=route, action=action, field_name=field_name, values=values, chapter=chapter: create_and_follow(
                run,
                page,
                chapter,
                f"Crear {title.lower()}",
                route,
                field_name,
                values,
                action_contains=action,
            ),
        )
        if result:
            paths[key] = result
            run.generated_records[key] = result
    return paths


def test_detail_actions(run: ManualRun, page: Page, paths: dict[str, str]) -> None:
    marker = run.run_id
    action_definitions = {
        "abastecimiento": [
            ("Aprobar solicitud", "/estado", "estado", {"estado": {"label": "Aprobado"}, "comentario": f"Aprobado {marker}"}),
            ("Comentar solicitud", "/comentar", "comentario", {"comentario": f"Seguimiento {marker}"}),
        ],
        "extraccion": [
            ("Confirmar extracción", "/estado", "estado", {"estado": {"label": "Confirmada"}, "comentario": f"Confirmada {marker}"}),
        ],
        "produccion": [
            ("Iniciar producción", "/estado", "estado", {"estado": {"label": "EnProceso"}, "comentario": f"Inicio {marker}"}),
        ],
        "finanzas": [
            (
                "Registrar gasto",
                "/gastos",
                "Concepto",
                {
                    "Fecha": date.today().isoformat(),
                    "Categoria": {"value": "Material"},
                    "Concepto": f"{marker} Combustible",
                    "Monto": "1250",
                    "Referencia": marker,
                },
            ),
        ],
        "alerta": [
            ("Agregar seguimiento", "/seguimientos", "comentario", {"comentario": f"Atención documentada {marker}"}),
        ],
        "comunicacion": [
            ("Responder comunicación", "/mensajes", "mensaje", {"mensaje": f"Respuesta de seguimiento {marker}", "esInterno": True}),
        ],
    }
    for key, actions in action_definitions.items():
        if key not in paths:
            continue
        chapter = key.capitalize()
        for title, action, field_name, values in actions:
            def detail_flow(key=key, title=title, action=action, field_name=field_name, values=values, chapter=chapter):
                go(page, run.base_url, paths[key])
                submit_form(
                    run,
                    page,
                    chapter,
                    title,
                    "Actualización del registro creado en el paso anterior.",
                    values,
                    action_contains=action,
                    field=field_name,
                )

            run.safe(title, chapter, page, detail_flow)

    if "maquinaria" in paths:
        chapter = "Maquinaria"
        def machinery_contract() -> None:
            go(page, run.base_url, paths["maquinaria"])
            submit_form(
                run,
                page,
                chapter,
                "Reservar maquinaria",
                "Creación de un contrato de alquiler para el equipo registrado.",
                {
                    "ClienteId": "8",
                    "FechaInicio": (date.today() + timedelta(days=2)).isoformat(),
                    "FechaFin": (date.today() + timedelta(days=5)).isoformat(),
                    "MontoTotal": "9600",
                    "Deposito": "5000",
                    "Observacion": marker,
                },
                action_contains="/contratos",
                field="FechaInicio",
                fill_defaults=True,
            )
        def machinery_maintenance() -> None:
            go(page, run.base_url, paths["maquinaria"])
            submit_form(
                run,
                page,
                chapter,
                "Programar mantenimiento",
                "Programación de mantenimiento preventivo del equipo.",
                {
                    "Tipo": "Preventivo",
                    "FechaProgramada": (date.today() + timedelta(days=10)).isoformat(),
                    "Costo": "1800",
                },
                action_contains="/mantenimientos",
                field="Tipo",
                fill_defaults=True,
            )
        run.safe("Programar mantenimiento", chapter, page, machinery_maintenance)
        run.safe("Reservar maquinaria", chapter, page, machinery_contract)

    if "construccion" in paths:
        chapter = "Construcción"
        construction_actions = [
            ("Iniciar proyecto", "/estado", "estado", {"estado": {"label": "EnEjecucion"}, "observacion": marker}),
            (
                "Registrar actividad de obra",
                "/actividades",
                "Nombre",
                {
                    "Nombre": f"{marker} Cimentación",
                    "Descripcion": "Preparación y fundición de cimentación.",
                    "FechaInicio": date.today().isoformat(),
                    "FechaFin": (date.today() + timedelta(days=7)).isoformat(),
                    "PorcentajeAvance": "20",
                },
            ),
            (
                "Asignar recurso de obra",
                "/recursos",
                "Descripcion",
                {"Tipo": "Material", "Descripcion": f"{marker} Cemento", "Cantidad": "50", "Unidad": "sacos", "Costo": "4500"},
            ),
            (
                "Registrar avance de obra",
                "/avance",
                "porcentaje",
                {"porcentaje": "15", "comentario": f"Avance verificado {marker}", "evidenciaUrl": "https://example.test/evidencia"},
            ),
        ]
        for title, action, field_name, values in construction_actions:
            def construction_flow(title=title, action=action, field_name=field_name, values=values):
                go(page, run.base_url, paths["construccion"])
                submit_form(run, page, chapter, title, "Operación sobre el proyecto de construcción.", values, action_contains=action, field=field_name, fill_defaults=True)
            run.safe(title, chapter, page, construction_flow)


def first_detail_path(page: Page, module: str) -> str:
    pattern = re.compile(rf"^/gestion/{re.escape(module)}/\d+$")
    links = page.locator(f"a[href^='/gestion/{module}/']")
    for index in range(links.count()):
        href = links.nth(index).get_attribute("href") or ""
        if pattern.match(href):
            return href
    raise LookupError(f"No se encontró un registro de demostración para {module}.")


def test_seeded_detail_actions(run: ManualRun, page: Page, created_paths: dict[str, str]) -> None:
    """Prueba acciones de detalle aun cuando el alta del registro haya fallado."""

    marker = run.run_id
    scenarios = [
        (
            "Abastecimiento",
            "abastecimientos",
            "abastecimiento",
            "Actualizar abastecimiento existente",
            "/estado",
            "estado",
            {"estado": {"label": "Aprobado"}, "comentario": marker},
        ),
        (
            "Extracción minera",
            "extracciones",
            "extraccion",
            "Actualizar extracción existente",
            "/estado",
            "estado",
            {"estado": {"label": "Confirmada"}, "comentario": marker},
        ),
        (
            "Producción",
            "producciones",
            "produccion",
            "Actualizar producción existente",
            "/estado",
            "estado",
            {"estado": {"label": "EnProceso"}, "comentario": marker},
        ),
        (
            "Finanzas",
            "finanzas",
            "finanzas",
            "Registrar gasto en presupuesto existente",
            "/gastos",
            "Concepto",
            {
                "Fecha": date.today().isoformat(),
                "Categoria": {"value": "Material"},
                "Concepto": f"Gasto {marker}",
                "Monto": "100",
                "OrigenModulo": {"value": "Manual"},
                "Referencia": marker,
            },
        ),
        (
            "Alertas",
            "alertas",
            "alerta",
            "Agregar seguimiento a alerta existente",
            "/seguimientos",
            "comentario",
            {"comentario": f"Seguimiento {marker}"},
        ),
    ]
    for chapter, module, created_key, title, action, field_name, values in scenarios:
        if created_key in created_paths:
            continue
        def seeded_flow(
            chapter=chapter,
            module=module,
            title=title,
            action=action,
            field_name=field_name,
            values=values,
        ) -> None:
            go(page, run.base_url, f"/gestion/{module}")
            path = first_detail_path(page, module)
            go(page, run.base_url, path)
            submit_form(
                run,
                page,
                chapter,
                title,
                "Operación sobre un registro ficticio preexistente.",
                values,
                action_contains=action,
                field=field_name,
            )

        run.safe(title, chapter, page, seeded_flow)

def test_transport_and_gps(run: ManualRun, page: Page) -> None:
    marker = run.run_id
    chapter = "Transporte y GPS"
    plate = f"MNL-{datetime.now():%H%M%S}"

    def vehicle() -> bool:
        go(page, run.base_url, "/gestion/transportes")
        submit_form(
            run,
            page,
            chapter,
            "Registrar vehículo",
            "Alta del vehículo que se usará en el viaje de prueba.",
            {
                "SedeId": "1",
                "Placa": plate,
                "Tipo": "Camión",
                "Marca": "Hino",
                "Modelo": marker,
                "Capacidad": "12",
                "UnidadCapacidad": "t",
                "EsInternacional": True,
            },
            action_contains="/vehiculos",
            field="Placa",
        )
        return True
    vehicle_ok = run.safe("Registrar vehículo", chapter, page, vehicle)

    def driver() -> bool:
        go(page, run.base_url, "/gestion/transportes")
        submit_form(
            run,
            page,
            chapter,
            "Registrar conductor",
            "Alta del conductor que se usará en el viaje de prueba.",
            {
                "Nombre": f"Conductor {marker}",
                "Licencia": f"L-{datetime.now():%H%M%S}",
                "Categoria": "A",
                "FechaVencimiento": (date.today() + timedelta(days=365)).isoformat(),
                "Telefono": "5555-2026",
            },
            action_contains="/conductores",
            field="Licencia",
        )
        return True
    driver_ok = run.safe("Registrar conductor", chapter, page, driver)

    trip_path = None
    def trip() -> str:
        go(page, run.base_url, "/gestion/transportes")
        form = find_form(page, action_contains="/viajes", field="Origen")
        vehicle_select = form.locator("[name='VehiculoId']")
        driver_select = form.locator("[name='ConductorId']")
        vehicle_value = vehicle_select.locator("option").filter(has_text=plate).first.get_attribute("value")
        driver_value = driver_select.locator("option").filter(has_text=marker).first.get_attribute("value")
        return urlparse(
            submit_form(
                run,
                page,
                chapter,
                "Programar viaje",
                "Programación de un traslado nacional con los recursos creados.",
                {
                    "SedeId": "1",
                    "VehiculoId": vehicle_value,
                    "ConductorId": driver_value,
                    "ClienteId": "8",
                    "Tipo": {"label": "Nacional"},
                    "Origen": "Ciudad de Guatemala",
                    "Destino": "Antigua Guatemala",
                    "DescripcionCarga": f"Carga {marker}",
                    "PesoCarga": "8",
                    "FechaSalidaPlanificada": (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%dT%H:%M"),
                },
                action_contains="/viajes",
                field="Origen",
            )
        ).path
    trip_path = run.safe("Programar viaje", chapter, page, trip) if vehicle_ok is not None and driver_ok is not None else None
    if trip_path:
        run.generated_records["viaje"] = trip_path
        def start_trip() -> None:
            go(page, run.base_url, trip_path)
            submit_form(run, page, chapter, "Iniciar viaje", "Cambio del viaje programado al estado en ruta.", {"estado": {"label": "EnRuta"}, "observacion": marker}, action_contains="/estado", field="estado")
        run.safe("Iniciar viaje", chapter, page, start_trip)

        def incident() -> None:
            go(page, run.base_url, trip_path)
            submit_form(run, page, chapter, "Registrar incidencia", "Registro de una novedad durante el traslado.", {"tipo": "Tráfico", "severidad": {"label": "Media"}, "descripcion": f"Congestión reportada {marker}"}, action_contains="/incidencias", field="descripcion")
        run.safe("Registrar incidencia", chapter, page, incident)

    gps_path = None
    def gps_device() -> bool:
        go(page, run.base_url, "/gestion/gps")
        submit_form(
            run,
            page,
            chapter,
            "Registrar dispositivo GPS",
            "Alta de un dispositivo externo sin asociación obligatoria.",
            {"IdentificadorExterno": f"{marker}-GPS", "NombreActivo": f"Unidad {marker}", "Proveedor": "Simulador manual", "VelocidadMaxima": "80"},
            action_contains="/dispositivos",
            field="IdentificadorExterno",
        )
        return True
    gps_ok = run.safe("Registrar GPS", chapter, page, gps_device)

    def gps_simulation() -> None:
        go(page, run.base_url, "/gestion/gps")
        submit_form(
            run,
            page,
            chapter,
            "Simular dato GPS externo",
            "Recepción simulada de latitud y longitud de Ciudad de Guatemala.",
            {
                "dispositivoId": {"contains": marker},
                "datosFuente": json.dumps({"latitud": 14.634915, "longitud": -90.506882, "velocidad": 45, "rumbo": 180, "evento": "NORMAL"}),
            },
            action_contains="/simular",
            field="datosFuente",
        )
    if gps_ok is not None:
        run.safe("Simular GPS", chapter, page, gps_simulation)


def test_integrations_and_income(run: ManualRun, page: Page) -> None:
    marker = run.run_id
    chapter = "Integraciones y finanzas"
    for channel in ("Webhook", "REST", "CSV"):
        def integration(channel=channel):
            go(page, run.base_url, "/gestion/integraciones")
            submit_form(
                run,
                page,
                chapter,
                f"Simular integración {channel}",
                f"Ingreso de un dato externo por el canal {channel}.",
                {
                    "Canal": {"label": channel},
                    "Direccion": {"label": "Entrada"},
                    "SocioTipo": {"label": "Proveedor"},
                    "SocioNombre": f"Proveedor {marker}",
                    "Operacion": {"label": "RecepcionMateriaPrima"},
                    "ClaveIdempotencia": f"{marker}-{channel}",
                    "DocumentoExterno": f"DOC-{marker}-{channel}",
                    "InventarioArticuloId": "21",
                    "SedeId": "2",
                    "Cantidad": "2",
                    "Contenido": json.dumps({"origen": channel, "descripcion": "Dato ficticio del manual", "latitud": 14.634915, "longitud": -90.506882}),
                },
                action_contains="/simular",
                field="Contenido",
            )
        run.safe(f"Integración {channel}", chapter, page, integration)

    def income() -> None:
        go(page, run.base_url, "/gestion/finanzas/ingresos")
        submit_form(
            run,
            page,
            chapter,
            "Registrar ingreso",
            "Registro manual de un ingreso financiero ficticio.",
            {
                "GiroId": "1",
                "SedeId": "2",
                "ClienteId": "",
                "Fecha": date.today().isoformat(),
                "Categoria": {"value": "VentaProducto"},
                "Concepto": f"{marker} Venta de material",
                "Monto": "8250",
                "OrigenModulo": {"value": "Manual"},
                "OrigenRegistroId": "",
                "Referencia": marker,
            },
            action_contains="/crear",
            field="Concepto",
        )
    run.safe("Registrar ingreso", chapter, page, income)


def test_client(run: ManualRun) -> None:
    chapter = "Portal del cliente"
    context, page = new_page(run)
    try:
        run.safe("Acceso cliente", chapter, page, lambda: login(run, page, "cliente_varias_empresas", capture_pair=True))
        routes = [
            ("Inicio del cliente", "/cliente"),
            ("Pedidos del cliente", "/cliente/pedidos"),
            ("Seguimiento operativo", "/cliente/operaciones"),
            ("Reportes del cliente", "/cliente/reportes"),
            ("Comunicaciones del cliente", "/cliente/comunicaciones"),
        ]
        for title, path in routes:
            run.safe(title, chapter, page, lambda title=title, path=path: capture_route(run, page, chapter, title, path, f"Pantalla {title.lower()} con alcance de varias empresas."))

        def order() -> str:
            go(page, run.base_url, "/cliente/pedidos/crear")
            return urlparse(
                submit_form(
                    run,
                    page,
                    chapter,
                    "Crear solicitud comercial",
                    "Solicitud de pedido con dos líneas del catálogo.",
                    {
                        "ClienteId": "9",
                        "GiroNegocioId": "2",
                        "TipoSolicitud": {"label": "Pedido"},
                        "FechaRequerida": (date.today() + timedelta(days=20)).isoformat(),
                        "Titulo": f"{run.run_id} Pedido de piso",
                        "Descripcion": "Pedido ficticio creado para documentar el flujo del cliente.",
                        "Lineas[0].CatalogoOfertaId": "2",
                        "Lineas[0].Cantidad": "4",
                        "Lineas[1].CatalogoOfertaId": "10",
                        "Lineas[1].Cantidad": "25",
                    },
                    method="post",
                    field="Titulo",
                )
            ).path
        order_path = run.safe("Crear solicitud", chapter, page, order)
        if order_path:
            run.generated_records["pedido_cliente"] = order_path
            def comment_order() -> None:
                go(page, run.base_url, order_path)
                submit_form(run, page, chapter, "Comentar solicitud", "Mensaje adicional del cliente sobre su pedido.", {"comentario": f"Confirmar disponibilidad {run.run_id}"}, action_contains="/comentar", field="comentario")
            run.safe("Comentar solicitud", chapter, page, comment_order)

        def client_comm() -> str:
            go(page, run.base_url, "/cliente/comunicaciones")
            return urlparse(
                submit_form(
                    run,
                    page,
                    chapter,
                    "Iniciar comunicación con TransPort",
                    "Consulta nueva enviada desde el portal del cliente.",
                    {
                        "ClienteId": "8",
                        "GiroNegocioId": "6",
                        "Asunto": f"{run.run_id} Consulta de obra",
                        "MensajeInicial": "Necesitamos confirmar la fecha de la visita técnica.",
                    },
                    action_contains="/crear",
                    field="Asunto",
                )
            ).path
        comm_path = run.safe("Crear comunicación cliente", chapter, page, client_comm)
        if comm_path:
            def client_reply() -> None:
                go(page, run.base_url, comm_path)
                submit_form(run, page, chapter, "Responder comunicación", "Respuesta adicional dentro de la conversación.", {"mensaje": f"Información adicional {run.run_id}"}, action_contains="/mensajes", field="mensaje")
            run.safe("Responder comunicación cliente", chapter, page, client_reply)

        for title, path, field, values in [
            ("Filtrar pedidos del cliente", "/cliente/pedidos", "busqueda", {"busqueda": "DEMO"}),
            ("Filtrar operaciones por empresa", "/cliente/operaciones", "clienteId", {"clienteId": "8"}),
            ("Generar reporte del cliente", "/cliente/reportes", "desde", {"desde": "2026-01-01", "hasta": "2026-12-31", "clienteId": "8"}),
            ("Filtrar comunicaciones del cliente", "/cliente/comunicaciones", "busqueda", {"busqueda": "DEMO"}),
        ]:
            def client_filter(title=title, path=path, field=field, values=values):
                go(page, run.base_url, path)
                submit_form(run, page, chapter, title, "Aplicación de criterios dentro del portal del cliente.", values, method="get", field=field)
            run.safe(title, chapter, page, client_filter)
    finally:
        context.close()


def test_internal(run: ManualRun) -> None:
    context, page = new_page(run)
    try:
        run.safe("Acceso administrador para pruebas", "Administración", page, lambda: login(run, page, "administrador"))
        test_administration(run, page)
        test_management_pages(run, page)
        run.safe("Flujo de inventario", "Inventarios y bodegas", page, lambda: test_inventory(run, page))
        paths = test_simple_creations(run, page)
        test_detail_actions(run, page, paths)
        test_seeded_detail_actions(run, page, paths)
        test_transport_and_gps(run, page)
        test_integrations_and_income(run, page)
    finally:
        context.close()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL)
    parser.add_argument("--headed", action="store_true")
    args = parser.parse_args()

    CAPTURE_DIR.mkdir(parents=True, exist_ok=True)
    for previous in CAPTURE_DIR.glob("*.png"):
        previous.unlink()
    run_id = f"MANUAL-{datetime.now():%Y%m%d-%H%M%S}"

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(
            headless=not args.headed,
            executable_path=chrome_path(),
            args=["--disable-dev-shm-usage"],
        )
        run = ManualRun(args.base_url, run_id, browser)
        try:
            test_public_and_roles(run)
            test_client(run)
            test_internal(run)
        except KeyboardInterrupt:
            run.check("Ejecución interrumpida", "General", "fallo", None, "Interrumpida por el usuario.")
        except Exception as exc:
            run.check("Error general", "General", "fallo", None, f"{exc}\n{traceback.format_exc()}")
        finally:
            run.write_report()
            browser.close()

    summary = json.loads(REPORT_PATH.read_text(encoding="utf-8"))["summary"]
    print(f"Reporte: {REPORT_PATH}")
    print(f"Comprobaciones: {summary['checks']} | Correctas: {summary['passed']} | Fallos: {summary['failed']}")
    print(f"Capturas: {summary['screenshots']}")
    return 0 if summary["failed"] == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())

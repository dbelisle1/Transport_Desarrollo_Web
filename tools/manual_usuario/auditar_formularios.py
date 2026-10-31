"""Detecta formularios POST Razor que no generan token antifalsificación."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUTPUT = ROOT / "docs" / "manual_usuario" / "auditoria_formularios.json"
FORM_RE = re.compile(r"<form\b(?P<attrs>[^>]*)>", re.IGNORECASE | re.DOTALL)


def audit_file(path: Path) -> list[dict]:
    source = path.read_text(encoding="utf-8")
    findings = []
    for match in FORM_RE.finditer(source):
        attrs = match.group("attrs")
        if not re.search(r"\bmethod\s*=\s*['\"]post['\"]", attrs, re.IGNORECASE):
            continue
        closing = source.find("</form>", match.end())
        body = source[match.end() : closing if closing >= 0 else match.end() + 500]
        # Un formulario que usa atributos asp-* es procesado por FormTagHelper.
        # Los formularios con action HTML plano necesitan el token explícito.
        tag_helper = re.search(r"\basp-(?:action|controller|route|page)\s*=", attrs, re.IGNORECASE)
        explicit_token = "AntiForgeryToken" in body
        if tag_helper or explicit_token:
            continue
        line = source.count("\n", 0, match.start()) + 1
        action_match = re.search(r"\baction\s*=\s*['\"]([^'\"]+)['\"]", attrs, re.IGNORECASE)
        action_match = re.search(r"\baction\s*=\s*['\"]([^'\"]+)['\"]", attrs, re.IGNORECASE)
        # Los formularios sin action son procesados por FormTagHelper (como el
        # acceso y los formularios CRUD de administración). El caso defectuoso
        # comprobado es action HTML explícito sin token manual.
        if not action_match:
            continue
        findings.append(
            {
                "file": str(path.relative_to(ROOT)).replace("\\", "/"),
                "line": line,
                "action": action_match.group(1),
                "opening_tag": " ".join(match.group(0).split()),
            }
        )
    return findings


def fix_file(path: Path) -> int:
    """Inserta el token en formularios POST con action HTML explícito."""
    source = path.read_text(encoding="utf-8")
    positions: list[int] = []
    for match in FORM_RE.finditer(source):
        attrs = match.group("attrs")
        if not re.search(r"\bmethod\s*=\s*['\"]post['\"]", attrs, re.IGNORECASE):
            continue
        action_match = re.search(r"\baction\s*=\s*['\"]([^'\"]+)['\"]", attrs, re.IGNORECASE)
        if not action_match:
            continue
        closing = source.find("</form>", match.end())
        body = source[match.end() : closing if closing >= 0 else match.end() + 500]
        tag_helper = re.search(r"\basp-(?:action|controller|route|page)\s*=", attrs, re.IGNORECASE)
        if tag_helper or "AntiForgeryToken" in body:
            continue
        positions.append(match.end())
    for position in reversed(positions):
        source = source[:position] + "@Html.AntiForgeryToken()" + source[position:]
    if positions:
        path.write_text(source, encoding="utf-8")
    return len(positions)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--fix", action="store_true", help="Inserta los tokens faltantes antes de auditar.")
    args = parser.parse_args()
    if args.fix:
        fixed = 0
        for view in sorted((ROOT / "TransPort.Web").rglob("*.cshtml")):
            fixed += fix_file(view)
        print(f"Tokens insertados: {fixed}")
    findings = []
    for view in sorted((ROOT / "TransPort.Web").rglob("*.cshtml")):
        findings.extend(audit_file(view))
    payload = {
        "summary": {
            "forms_without_antiforgery": len(findings),
            "files_affected": len({item["file"] for item in findings}),
        },
        "findings": findings,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print(
        f"{payload['summary']['forms_without_antiforgery']} formularios potencialmente afectados "
        f"en {payload['summary']['files_affected']} archivos."
    )
    print(f"Reporte: {args.output}")
    return 1 if findings else 0


if __name__ == "__main__":
    raise SystemExit(main())

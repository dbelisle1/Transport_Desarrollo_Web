# Reporte de pruebas del manual de usuario

- Ejecución: `MANUAL-20261031-025056`
- Fecha: 2026-10-31T02:53:11
- URL: `http://localhost:8080`
- Comprobaciones: **109**
- Correctas: **109**
- Fallidas: **0**
- Capturas: **177**

## Resultado final

Todos los flujos automatizados finalizaron correctamente. La auditoría estática tampoco encontró formularios POST sin token antifalsificación.

## Evidencia reproducible

- `manual_usuario/reporte_ejecucion.json`: cada comprobación y captura.
- `manual_usuario/auditoria_formularios.json`: hallazgos estáticos.
- `manual_usuario/capturas/`: imágenes antes y después de cada envío.
- `../tools/manual_usuario/capturar_manual.py`: ejecución Playwright.

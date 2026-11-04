using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Areas.Gestion.Controllers;

[Area("Gestion")]
[Authorize(Roles = "AdministradorGeneral,Gerente,Vendedor,Empleado,Operativo")]
[Route("gestion/comunicaciones")]
public sealed class ComunicacionesController(ITransportApiClient api) : Controller
{
    [HttpGet("")]
    public async Task<IActionResult> Index(string? estado, string? tipo, string? busqueda, CancellationToken ct)
    {
        var options = await api.ComunicacionOpcionesAsync(ct);
        return View(new ComunicacionPaginaViewModel
        {
            Estado = estado,
            Tipo = tipo,
            Busqueda = busqueda,
            Comunicaciones = await api.ComunicacionesAsync(estado, tipo, busqueda, ct),
            Opciones = options,
            Nueva = new ComunicacionCrearViewModel { Tipo = "Interna" }
        });
    }

    [HttpPost("crear")]
    public async Task<IActionResult> Crear(ComunicacionCrearViewModel model, CancellationToken ct)
    {
        if (!ModelState.IsValid)
        {
            TempData["Error"] = "Revise los datos de la comunicación.";
            return RedirectToAction(nameof(Index));
        }
        var id = await api.CrearComunicacionAsync(model, ct);
        TempData["Exito"] = "Comunicación iniciada.";
        return RedirectToAction(nameof(Detalle), new { id });
    }

    [HttpGet("{id:long}")]
    public async Task<IActionResult> Detalle(long id, CancellationToken ct)
    {
        var detail = await api.ComunicacionAsync(id, ct);
        return detail is null ? NotFound() : View(new ComunicacionDetalleViewModel
        {
            Comunicacion = detail,
            Opciones = await api.ComunicacionOpcionesAsync(ct)
        });
    }

    [HttpPost("{id:long}/mensajes")]
    public async Task<IActionResult> Mensaje(long id, string mensaje, bool esInterno, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(mensaje)) TempData["Error"] = "Ingrese un mensaje.";
        else
        {
            await api.AgregarMensajeComunicacionAsync(id, mensaje, esInterno, ct);
            TempData["Exito"] = esInterno ? "Nota interna agregada." : "Mensaje enviado.";
        }
        return RedirectToAction(nameof(Detalle), new { id });
    }

    [HttpPost("{id:long}/gestion")]
    [Authorize(Roles = "AdministradorGeneral,Gerente,Vendedor")]
    public async Task<IActionResult> Gestionar(long id, string estado, int? responsableUsuarioId, CancellationToken ct)
    {
        await api.GestionarComunicacionAsync(id, estado, responsableUsuarioId, ct);
        TempData["Exito"] = "Responsable y estado actualizados.";
        return RedirectToAction(nameof(Detalle), new { id });
    }

    [HttpPost("{id:long}/eliminar")]
    [Authorize(Roles = "AdministradorGeneral")]
    public async Task<IActionResult> Eliminar(long id, CancellationToken ct)
    {
        await api.EliminarComunicacionAsync(id, ct);
        TempData["Exito"] = "Comunicación eliminada lógicamente.";
        return RedirectToAction(nameof(Index));
    }
}

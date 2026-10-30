using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Areas.Cliente.Controllers;

[Area("Cliente")]
[Authorize(Policy = "Cliente")]
[Route("cliente/comunicaciones")]
public sealed class ComunicacionesController(ITransportApiClient api) : Controller
{
    [HttpGet("")]
    public async Task<IActionResult> Index(string? estado, string? busqueda, CancellationToken ct)
    {
        var options = await api.ComunicacionOpcionesAsync(ct);
        var create = new ComunicacionCrearViewModel { Tipo = "Cliente" };
        if (options.Clientes.Count == 1) create.ClienteId = options.Clientes[0].Id;
        if (options.Giros.Count == 1) create.GiroNegocioId = options.Giros[0].Id;
        return View(new ComunicacionPaginaViewModel
        {
            Estado = estado,
            Busqueda = busqueda,
            Comunicaciones = await api.ComunicacionesAsync(estado, "Cliente", busqueda, ct),
            Opciones = options,
            Nueva = create
        });
    }

    [HttpPost("crear")]
    public async Task<IActionResult> Crear(ComunicacionCrearViewModel model, CancellationToken ct)
    {
        model.Tipo = "Cliente";
        if (!ModelState.IsValid)
        {
            TempData["Error"] = "Revise el asunto y mensaje de la comunicación.";
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
        return detail is null ? NotFound() : View(new ComunicacionDetalleViewModel { Comunicacion = detail });
    }

    [HttpPost("{id:long}/mensajes")]
    public async Task<IActionResult> Mensaje(long id, string mensaje, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(mensaje)) TempData["Error"] = "Ingrese un mensaje.";
        else
        {
            await api.AgregarMensajeComunicacionAsync(id, mensaje, false, ct);
            TempData["Exito"] = "Mensaje enviado.";
        }
        return RedirectToAction(nameof(Detalle), new { id });
    }
}

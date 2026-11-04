using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Areas.Cliente.Controllers;

[Area("Cliente")]
[Authorize(Policy = "Cliente")]
[Route("cliente")]
public sealed class InicioController(ITransportApiClient api, ILogger<InicioController> logger) : Controller
{
    [HttpGet("")]
    public async Task<IActionResult> Index(CancellationToken ct)
    {
        try
        {
            var resumen = await api.PortalClienteResumenAsync(ct);
            var operaciones = await api.PortalClienteOperacionesAsync(null, ct);
            return View(resumen with { Operaciones = operaciones });
        }
        catch (Exception ex) when (ex is HttpRequestException or TransportApiException)
        {
            logger.LogError(ex, "No fue posible cargar el resumen del portal del cliente.");
            TempData["Error"] = "No fue posible cargar el resumen operativo.";
            return View(PortalClienteResumenModel.Vacio);
        }
    }
}

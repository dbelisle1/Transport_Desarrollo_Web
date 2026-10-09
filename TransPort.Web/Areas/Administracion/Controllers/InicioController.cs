using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Services;

namespace TransPort.Web.Areas.Administracion.Controllers;

[Area("Administracion")]
[Authorize(Policy = "Administracion")]
[Route("admin")]
public sealed class InicioController(ITransportApiClient api, ILogger<InicioController> logger) : Controller
{
    [HttpGet("")]
    public async Task<IActionResult> Index(CancellationToken ct)
    {
        try { return View(await api.ResumenAsync(ct)); }
        catch (Exception ex) when (ex is HttpRequestException or TransportApiException)
        {
            logger.LogError(ex, "No fue posible cargar el resumen administrativo.");
            ViewBag.Error = "No fue posible consultar el resumen en este momento.";
            return View(new Models.DashboardModel(0, 0, 0));
        }
    }
}

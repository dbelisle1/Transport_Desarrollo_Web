using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Areas.Administracion.Controllers;

[Area("Administracion")]
[Authorize(Policy = "Administracion")]
[Route("admin/auditoria")]
public sealed class AuditoriaController(ITransportApiClient api, ILogger<AuditoriaController> logger) : Controller
{
    [HttpGet("")]
    public async Task<IActionResult> Index(AuditoriaFiltroViewModel model, CancellationToken ct)
    {
        model.Pagina = Math.Max(model.Pagina, 1);
        if (model.TamanoPagina is not (10 or 25 or 50 or 100)) model.TamanoPagina = 25;
        if (model.FechaDesde.HasValue && model.FechaHasta.HasValue && model.FechaHasta < model.FechaDesde)
            ModelState.AddModelError(nameof(model.FechaHasta), "La fecha hasta debe ser igual o posterior a la fecha desde.");

        if (!ModelState.IsValid) return View(model);

        try
        {
            model.Resultados = await api.AuditoriaAsync(model, ct);
        }
        catch (Exception ex) when (ex is HttpRequestException or TransportApiException)
        {
            logger.LogError(ex, "No fue posible consultar la auditoría.");
            TempData["Error"] = "No fue posible consultar los eventos de auditoría.";
        }
        return View(model);
    }
}

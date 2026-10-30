using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Controllers;

[AllowAnonymous]
[Route("catalogo")]
public sealed class CatalogoController(ITransportApiClient api) : Controller
{
    [HttpGet("")]
    public async Task<IActionResult> Index(int? giroId, string? tipo, CancellationToken ct)
    {
        var ofertas = await api.CatalogoPublicoAsync(null, null, ct);
        ViewData["GiroId"] = giroId;
        ViewData["Tipo"] = tipo;
        ViewData["Giros"] = ofertas
            .GroupBy(x => new { x.GiroNegocioId, x.Giro })
            .Select(x => new CatalogoModel(x.Key.GiroNegocioId, x.Key.Giro))
            .OrderBy(x => x.Nombre)
            .ToArray();
        return View(ofertas
            .Where(x => !giroId.HasValue || x.GiroNegocioId == giroId.Value)
            .Where(x => string.IsNullOrWhiteSpace(tipo) || x.Tipo.Equals(tipo, StringComparison.OrdinalIgnoreCase))
            .ToArray());
    }
}

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Areas.Cliente.Controllers;

[Area("Cliente")]
[Authorize(Policy = "Cliente")]
[Route("cliente/operaciones")]
public sealed class OperacionesController(ITransportApiClient api) : Controller
{
    [HttpGet("")]
    public async Task<IActionResult> Index(int? clienteId, CancellationToken ct)
    {
        var resumen = await api.PortalClienteResumenAsync(ct);
        return View(new PortalClienteOperacionesPaginaViewModel
        {
            ClienteId = clienteId,
            Empresas = resumen.Empresas,
            Operaciones = await api.PortalClienteOperacionesAsync(clienteId, ct)
        });
    }
}

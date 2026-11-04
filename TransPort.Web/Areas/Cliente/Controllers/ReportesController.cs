using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Areas.Cliente.Controllers;

[Area("Cliente"),Authorize(Policy="Cliente"),Route("cliente/reportes")]
public sealed class ReportesController(ITransportApiClient api):Controller
{
    [HttpGet("")]
    public async Task<IActionResult> Index(DateTime? desde,DateTime? hasta,int? clienteId,CancellationToken ct)
    {
        var empresas=await api.PortalClienteResumenAsync(ct);var reporte=await api.ReporteClienteAsync(desde,hasta,clienteId,ct);
        return View(new ReporteClientePaginaViewModel{Desde=reporte.Resumen.Desde,Hasta=reporte.Resumen.Hasta,ClienteId=clienteId,Empresas=empresas.Empresas,Reporte=reporte});
    }
}

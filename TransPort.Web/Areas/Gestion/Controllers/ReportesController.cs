using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Areas.Gestion.Controllers;

[Area("Gestion"),Authorize(Roles="AdministradorGeneral,Gerente,Empleado,Operativo"),Route("gestion/reportes")]
public sealed class ReportesController(ITransportApiClient api):Controller
{
    [HttpGet("")]
    public async Task<IActionResult> Index(DateTime? desde,DateTime? hasta,int? giroId,int? sedeId,CancellationToken ct)
    {
        var reporte=await api.ReporteInternoAsync(desde,hasta,giroId,sedeId,ct);
        return View(new ReporteInternoPaginaViewModel{Desde=reporte.Resumen.Desde,Hasta=reporte.Resumen.Hasta,GiroId=giroId,SedeId=sedeId,Opciones=await api.ReporteOpcionesAsync(ct),Reporte=reporte});
    }
}

using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Modules.Reportes.DTOs;
using TransPort.Api.Modules.Reportes.Repositories;

namespace TransPort.Api.Controllers;

[ApiController,Route("api/reportes"),Authorize]
public sealed class ReportesController(IReporteRepository reportes):ControllerBase
{
    [HttpGet("opciones"),Authorize(Roles="AdministradorGeneral,Gerente,Empleado,Operativo")]
    public Task<ReporteOpcionesDto> Opciones(CancellationToken ct)=>reportes.OpcionesAsync(Alcance(),ct);
    [HttpGet("interno"),Authorize(Roles="AdministradorGeneral,Gerente,Empleado,Operativo")]
    public Task<ReporteInternoDto> Interno(DateTime? desde,DateTime? hasta,int? giroId,int? sedeId,CancellationToken ct)=>reportes.InternoAsync(desde,hasta,giroId,sedeId,Alcance(),ct);
    [HttpGet("cliente"),Authorize(Roles="Cliente,AdministradorGeneral")]
    public Task<ReporteClienteDto> Cliente(DateTime? desde,DateTime? hasta,int? clienteId,CancellationToken ct)=>reportes.ClienteAsync(desde,hasta,clienteId,Alcance(),ct);
    private AlcanceReporte Alcance()=>new(int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!),User.IsInRole("AdministradorGeneral"));
}

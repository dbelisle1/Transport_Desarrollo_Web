using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Modules.Alertas.DTOs;
using TransPort.Api.Modules.Alertas.Repositories;

namespace TransPort.Api.Controllers;

[ApiController,Route("api/alertas"),Authorize(Roles="AdministradorGeneral,Gerente,Vendedor,Empleado,Operativo")]
public sealed class AlertasController(IAlertaRepository alertas):ControllerBase
{
    [HttpGet] public Task<IReadOnlyList<AlertaListadoDto>> Listar(string? estado,bool soloPendientes,CancellationToken ct)=>alertas.ListarAsync(estado,soloPendientes,Alcance(),ct);
    [HttpGet("opciones")] public Task<AlertaOpcionesDto> Opciones(CancellationToken ct)=>alertas.OpcionesAsync(Alcance(),ct);
    [HttpGet("{id:long}")] public async Task<IActionResult> Obtener(long id,CancellationToken ct){var x=await alertas.ObtenerAsync(id,Alcance(),ct);return x is null?NotFound():Ok(x);}
    [HttpPost,Authorize(Roles="AdministradorGeneral,Gerente")] public async Task<IActionResult> Crear(CrearAlertaRequest request,CancellationToken ct)=>Ok(new ResultadoAlertaDto(await alertas.CrearAsync(request,Alcance(),ct)));
    [HttpPut("{id:long}/leer")] public async Task<IActionResult> Leer(long id,CancellationToken ct)=>await alertas.MarcarLeidaAsync(id,Alcance(),ct)?NoContent():NotFound();
    [HttpPost("{id:long}/seguimientos")] public async Task<IActionResult> Seguimiento(long id,SeguimientoAlertaRequest request,CancellationToken ct)=>Ok(new ResultadoAlertaDto(await alertas.SeguimientoAsync(id,request.Comentario,Alcance(),ct)));
    [HttpPut("{id:long}/estado"),Authorize(Roles="AdministradorGeneral,Gerente")] public async Task<IActionResult> Estado(long id,EstadoAlertaRequest request,CancellationToken ct)=>await alertas.EstadoAsync(id,request.Estado,Alcance(),ct)?NoContent():NotFound();
    [HttpDelete("{id:long}"),Authorize(Roles="AdministradorGeneral")] public async Task<IActionResult> Eliminar(long id,CancellationToken ct)=>await alertas.EliminarAsync(id,Alcance().UsuarioId,ct)?NoContent():NotFound();
    private AlcanceAlerta Alcance()=>new(int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!),User.IsInRole("AdministradorGeneral"));
}

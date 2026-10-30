using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Modules.Integraciones.DTOs;
using TransPort.Api.Modules.Integraciones.Repositories;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Controllers;

[ApiController]
[Route("api/integraciones")]
[Authorize(Roles="AdministradorGeneral,Gerente,Empleado,Operativo")]
public sealed class IntegracionesController(IIntegracionRepository integraciones):ControllerBase
{
    [HttpGet]public Task<IReadOnlyList<IntegracionListadoDto>> Listar(string?estado,string?canal,string?busqueda,CancellationToken ct)=>integraciones.ListarAsync(estado,canal,busqueda,Alcance(),ct);
    [HttpGet("opciones")]public Task<IntegracionOpcionesDto> Opciones(CancellationToken ct)=>integraciones.OpcionesAsync(Alcance(),ct);
    [HttpGet("{id:long}")]public async Task<IActionResult> Obtener(long id,CancellationToken ct){var x=await integraciones.ObtenerAsync(id,Alcance(),ct);return x is null?NotFound():Ok(x);}
    [HttpPost("simular")]public async Task<IActionResult> Simular(SimularIntegracionRequest request,CancellationToken ct){var id=await integraciones.SimularAsync(request,Alcance(),ct);return CreatedAtAction(nameof(Obtener),new{id},new ResultadoIdDto(checked((int)id)));}
    [HttpPost("{id:long}/reintentar")]public async Task<IActionResult> Reintentar(long id,CancellationToken ct)=>Ok(new ResultadoIdDto(checked((int)await integraciones.ReintentarAsync(id,Alcance(),ct))));
    [HttpDelete("{id:long}")][Authorize(Roles="AdministradorGeneral")]public async Task<IActionResult> Eliminar(long id,CancellationToken ct)=>await integraciones.EliminarAsync(id,UsuarioId(),ct)?NoContent():NotFound();
    private AlcanceIntegracion Alcance()=>new(UsuarioId(),User.IsInRole("AdministradorGeneral"));
    private int UsuarioId()=>int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}

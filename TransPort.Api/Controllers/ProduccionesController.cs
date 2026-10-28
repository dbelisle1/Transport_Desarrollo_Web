using System.Security.Claims;using Microsoft.AspNetCore.Authorization;using Microsoft.AspNetCore.Mvc;using TransPort.Api.Modules.Produccion.DTOs;using TransPort.Api.Modules.Produccion.Repositories;
namespace TransPort.Api.Controllers;
[ApiController,Route("api/producciones"),Authorize(Roles="AdministradorGeneral,Gerente,Empleado,Operativo")]
public sealed class ProduccionesController(IProduccionRepository repo):ControllerBase
{
 [HttpGet]public Task<IReadOnlyList<ProduccionListadoDto>>Listar([FromQuery]string?estado,[FromQuery]int?sedeId,[FromQuery]DateTime?fechaDesde,[FromQuery]DateTime?fechaHasta,CancellationToken ct)=>repo.ListarAsync(estado,sedeId,fechaDesde,fechaHasta,A(),ct);
 [HttpGet("opciones")]public Task<ProduccionOpcionesDto>Opciones(CancellationToken ct)=>repo.OpcionesAsync(A(),ct);
 [HttpGet("{id:long}")]public async Task<IActionResult>Obtener(long id,CancellationToken ct){var x=await repo.ObtenerAsync(id,A(),ct);return x is null?NotFound():Ok(x);}
 [HttpPost]public async Task<IActionResult>Crear(CrearProduccionRequest x,CancellationToken ct){var id=await repo.CrearAsync(x,A(),ct);return Ok(new ResultadoProduccionDto(id));}
 [HttpPut("{id:long}/estado")]public async Task<IActionResult>Estado(long id,CambiarEstadoProduccionRequest x,CancellationToken ct)=>await repo.CambiarEstadoAsync(id,x,A(),ct)?NoContent():NotFound();
 [HttpPut("{id:long}/etapas/{etapaId:long}/completar")]public async Task<IActionResult>CompletarEtapa(long id,long etapaId,CompletarEtapaProduccionRequest x,CancellationToken ct)=>await repo.CompletarEtapaAsync(id,etapaId,x.Observacion,A(),ct)?NoContent():NotFound();
 [HttpDelete("{id:long}"),Authorize(Roles="AdministradorGeneral")]public async Task<IActionResult>Eliminar(long id,CancellationToken ct)=>await repo.EliminarAsync(id,A().UsuarioId,ct)?NoContent():NotFound();
 private AlcanceProduccion A()=>new(int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!),User.IsInRole("AdministradorGeneral"));
}

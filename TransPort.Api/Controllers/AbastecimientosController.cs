using System.Security.Claims;using Microsoft.AspNetCore.Authorization;using Microsoft.AspNetCore.Mvc;using TransPort.Api.Modules.Abastecimiento.DTOs;using TransPort.Api.Modules.Abastecimiento.Repositories;
namespace TransPort.Api.Controllers;
[ApiController,Route("api/abastecimientos"),Authorize(Roles="AdministradorGeneral,Gerente,Empleado,Operativo")]
public sealed class AbastecimientosController(IAbastecimientoRepository repo):ControllerBase
{
 [HttpGet]public Task<IReadOnlyList<AbastecimientoListadoDto>>Listar([FromQuery]string?estado,[FromQuery]string?busqueda,CancellationToken ct)=>repo.ListarAsync(estado,busqueda,A(),ct);
 [HttpGet("opciones")]public Task<AbastecimientoOpcionesDto>Opciones(CancellationToken ct)=>repo.OpcionesAsync(A(),ct);
 [HttpGet("{id:long}")]public async Task<IActionResult>Obtener(long id,CancellationToken ct){var x=await repo.ObtenerAsync(id,A(),ct);return x is null?NotFound():Ok(x);}
 [HttpPost]public async Task<IActionResult>Crear(CrearAbastecimientoRequest x,CancellationToken ct){var id=await repo.CrearAsync(x,A(),ct);return Ok(new ResultadoAbastecimientoDto(id));}
 [HttpPut("{id:long}/estado")]public async Task<IActionResult>Estado(long id,CambiarEstadoAbastecimientoRequest x,CancellationToken ct)=>await repo.CambiarEstadoAsync(id,x,A(),ct)?NoContent():NotFound();
 [HttpPost("{id:long}/comentarios")]public async Task<IActionResult>Comentar(long id,ComentarAbastecimientoRequest x,CancellationToken ct){await repo.ComentarAsync(id,x.Comentario,A(),ct);return NoContent();}
 [HttpDelete("{id:long}"),Authorize(Roles="AdministradorGeneral")]public async Task<IActionResult>Eliminar(long id,CancellationToken ct)=>await repo.EliminarAsync(id,A().UsuarioId,ct)?NoContent():NotFound();
 private AlcanceAbastecimiento A()=>new(int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!),User.IsInRole("AdministradorGeneral"));
}

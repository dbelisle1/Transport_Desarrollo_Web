using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Modules.Extraccion.DTOs;
using TransPort.Api.Modules.Extraccion.Repositories;

namespace TransPort.Api.Controllers;

[ApiController, Route("api/extracciones"), Authorize(Roles = "AdministradorGeneral,Gerente,Empleado,Operativo")]
public sealed class ExtraccionesController(IExtraccionRepository repository) : ControllerBase
{
    [HttpGet] public Task<IReadOnlyList<ExtraccionListadoDto>> Listar([FromQuery] string? estado, [FromQuery] int? sedeId, [FromQuery] DateTime? fechaDesde, [FromQuery] DateTime? fechaHasta, CancellationToken ct) => repository.ListarAsync(estado, sedeId, fechaDesde, fechaHasta, Alcance(), ct);
    [HttpGet("opciones")] public Task<ExtraccionOpcionesDto> Opciones(CancellationToken ct) => repository.OpcionesAsync(Alcance(), ct);
    [HttpGet("{id:long}")] public async Task<IActionResult> Obtener(long id, CancellationToken ct) { var item = await repository.ObtenerAsync(id, Alcance(), ct); return item is null ? NotFound() : Ok(item); }
    [HttpPost] public async Task<IActionResult> Crear(CrearExtraccionRequest request, CancellationToken ct) { var id = await repository.CrearAsync(request, Alcance(), ct); return Ok(new ResultadoExtraccionDto(id)); }
    [HttpPut("{id:long}/estado")] public async Task<IActionResult> Estado(long id, CambiarEstadoExtraccionRequest request, CancellationToken ct) => await repository.CambiarEstadoAsync(id, request, Alcance(), ct) ? NoContent() : NotFound();
    [HttpDelete("{id:long}"), Authorize(Roles = "AdministradorGeneral")] public async Task<IActionResult> Eliminar(long id, CancellationToken ct) => await repository.EliminarAsync(id, Alcance().UsuarioId, ct) ? NoContent() : NotFound();
    private AlcanceExtraccion Alcance() => new(int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!), User.IsInRole("AdministradorGeneral"));
}

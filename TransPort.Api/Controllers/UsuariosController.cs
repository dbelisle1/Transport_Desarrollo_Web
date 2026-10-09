using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using TransPort.Api.Modules.Seguridad.DTOs;
using TransPort.Api.Modules.Seguridad.Repositories;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Controllers;

[ApiController]
[Route("api/usuarios")]
[Authorize(Roles = "AdministradorGeneral")]
public sealed class UsuariosController(IUsuarioRepository usuarios) : ControllerBase
{
    [HttpGet]
    public Task<IReadOnlyList<UsuarioListadoDto>> Listar(
        [FromQuery] string? busqueda, [FromQuery] bool? esActivo, [FromQuery] int? rolId, CancellationToken ct) =>
        usuarios.ListarAsync(busqueda, esActivo, rolId, ct);

    [HttpGet("{id:int}")]
    public async Task<IActionResult> Obtener(int id, CancellationToken ct)
    {
        var usuario = await usuarios.ObtenerAsync(id, ct);
        return usuario is null ? NotFound() : Ok(usuario);
    }

    [HttpPost]
    public async Task<IActionResult> Crear(CrearUsuarioRequest request, CancellationToken ct)
    {
        var id = await usuarios.CrearAsync(request, ResponsableId(), ct);
        return CreatedAtAction(nameof(Obtener), new { id }, new ResultadoIdDto(id));
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Actualizar(int id, ActualizarUsuarioRequest request, CancellationToken ct) =>
        await usuarios.ActualizarAsync(id, request, ResponsableId(), ct) ? NoContent() : NotFound();

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Eliminar(int id, CancellationToken ct)
    {
        if (id == ResponsableId()) return BadRequest(new MensajeDto("No puede eliminar su propia cuenta."));
        return await usuarios.EliminarAsync(id, ResponsableId(), ct) ? NoContent() : NotFound();
    }

    [HttpPut("{id:int}/asignaciones")]
    public async Task<IActionResult> Asignaciones(int id, AsignacionesUsuarioRequest request, CancellationToken ct)
    {
        if (await usuarios.ObtenerAsync(id, ct) is null) return NotFound();
        if (id == ResponsableId() && !request.Roles.Any())
            return BadRequest(new MensajeDto("No puede retirar todos sus propios roles."));
        await usuarios.ActualizarAsignacionesAsync(id, request, ResponsableId(), ct);
        return NoContent();
    }

    private int ResponsableId() => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using TransPort.Api.Modules.Organizacion.DTOs;
using TransPort.Api.Modules.Organizacion.Repositories;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Controllers;

[ApiController]
[Route("api/clientes")]
[Authorize(Roles = "AdministradorGeneral")]
public sealed class ClientesController(IClienteRepository clientes) : ControllerBase
{
    [HttpGet]
    public Task<IReadOnlyList<ClienteListadoDto>> Listar([FromQuery] string? busqueda, [FromQuery] bool? esActivo, CancellationToken ct) => 
        clientes.ListarAsync(busqueda, esActivo, ct);

    [HttpGet("{id:int}")]
    public async Task<IActionResult> Obtener(int id, CancellationToken ct)
    {
        var c = await clientes.ObtenerAsync(id, ct);
        return c is null ? NotFound() : Ok(c);
    }

    [HttpPost]
    public async Task<IActionResult> Crear(CrearClienteRequest request, CancellationToken ct)
    {
        var id = await clientes.CrearAsync(request, ResponsableId(), ct);
        return CreatedAtAction(nameof(Obtener), new { id }, new ResultadoIdDto(id));
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Actualizar(int id, ActualizarClienteRequest request, CancellationToken ct) =>
        await clientes.ActualizarAsync(id, request, ResponsableId(), ct) ? NoContent() : NotFound();

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Eliminar(int id, CancellationToken ct) =>
        await clientes.EliminarAsync(id, ResponsableId(), ct) ? NoContent() : NotFound();

    [HttpPut("{id:int}/asociaciones")]
    public async Task<IActionResult> Asociaciones(int id, AsociacionesClienteRequest request, CancellationToken ct)
    {
        if (await clientes.ObtenerAsync(id, ct) is null) return NotFound();
        await clientes.ActualizarAsociacionesAsync(id, request, ResponsableId(), ct);
        return NoContent();
    }

    private int ResponsableId() => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}
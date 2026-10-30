using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Modules.Comercial.DTOs;
using TransPort.Api.Modules.Comercial.Repositories;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Controllers;

[ApiController]
[Route("api/comunicaciones")]
[Authorize(Roles = "AdministradorGeneral,Gerente,Vendedor,Empleado,Operativo,Cliente")]
public sealed class ComunicacionesController(IComunicacionRepository comunicaciones) : ControllerBase
{
    [HttpGet]
    public Task<IReadOnlyList<ComunicacionListadoDto>> Listar(
        string? estado, string? tipo, string? busqueda, CancellationToken ct) =>
        comunicaciones.ListarAsync(estado, tipo, busqueda, Alcance(), ct);

    [HttpGet("opciones")]
    public Task<ComunicacionOpcionesDto> Opciones(CancellationToken ct) =>
        comunicaciones.OpcionesAsync(Alcance(), ct);

    [HttpGet("{id:long}")]
    public async Task<IActionResult> Obtener(long id, CancellationToken ct)
    {
        var detail = await comunicaciones.ObtenerAsync(id, Alcance(), ct);
        return detail is null ? NotFound() : Ok(detail);
    }

    [HttpPost]
    public async Task<IActionResult> Crear(CrearComunicacionRequest request, CancellationToken ct)
    {
        if (EsCliente()) request.Tipo = "Cliente";
        var id = await comunicaciones.CrearAsync(request, Alcance(), ct);
        return CreatedAtAction(nameof(Obtener), new { id }, new ResultadoIdDto(checked((int)id)));
    }

    [HttpPost("{id:long}/mensajes")]
    public async Task<IActionResult> Mensaje(long id, CrearMensajeComunicacionRequest request, CancellationToken ct)
    {
        if (EsCliente()) request.EsInterno = false;
        return Ok(new ResultadoIdDto(checked((int)await comunicaciones.AgregarMensajeAsync(id, request, Alcance(), ct))));
    }

    [HttpPut("{id:long}/gestion")]
    [Authorize(Roles = "AdministradorGeneral,Gerente,Vendedor")]
    public async Task<IActionResult> Gestionar(long id, GestionComunicacionRequest request, CancellationToken ct) =>
        await comunicaciones.GestionarAsync(id, request, Alcance(), ct) ? NoContent() : NotFound();

    [HttpDelete("{id:long}")]
    [Authorize(Roles = "AdministradorGeneral")]
    public async Task<IActionResult> Eliminar(long id, CancellationToken ct) =>
        await comunicaciones.EliminarAsync(id, UsuarioId(), ct) ? NoContent() : NotFound();

    private AlcanceComunicacion Alcance() => new(UsuarioId(), EsAdministrador(), EsCliente());
    private int UsuarioId() => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    private bool EsAdministrador() => User.IsInRole("AdministradorGeneral");
    private bool EsCliente() => User.IsInRole("Cliente") && !EsAdministrador();
}

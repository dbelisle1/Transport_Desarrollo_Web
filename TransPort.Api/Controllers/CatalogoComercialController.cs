using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Modules.Comercial.DTOs;
using TransPort.Api.Modules.Comercial.Repositories;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Controllers;

[ApiController]
[Route("api/catalogo-comercial")]
public sealed class CatalogoComercialController(ICatalogoComercialRepository catalogo) : ControllerBase
{
    private static readonly HashSet<string> Tipos = new(StringComparer.OrdinalIgnoreCase)
        { "Producto", "Servicio" };

    [AllowAnonymous]
    [HttpGet("publico")]
    public Task<IReadOnlyList<OfertaCatalogoDto>> Publico(
        [FromQuery] int? giroId, [FromQuery] string? tipo, CancellationToken ct) =>
        catalogo.ListarPublicoAsync(giroId, tipo, ct);

    [Authorize(Roles = "AdministradorGeneral,Gerente")]
    [HttpGet]
    public Task<IReadOnlyList<OfertaCatalogoDto>> Listar(
        [FromQuery] string? busqueda, [FromQuery] int? giroId, [FromQuery] string? tipo,
        [FromQuery] bool? esActivo, CancellationToken ct) =>
        catalogo.ListarAsync(busqueda, giroId, tipo, esActivo, Alcance(), ct);

    [Authorize(Roles = "AdministradorGeneral,Gerente")]
    [HttpGet("opciones")]
    public Task<CatalogoComercialOpcionesDto> Opciones(CancellationToken ct) =>
        catalogo.OpcionesAsync(Alcance(), ct);

    [Authorize(Roles = "AdministradorGeneral,Gerente")]
    [HttpPost]
    public async Task<IActionResult> Crear(GuardarOfertaCatalogoRequest request, CancellationToken ct)
    {
        if (!TipoValido(request.Tipo)) return TipoInvalido();
        var id = await catalogo.CrearAsync(request, Alcance(), ct);
        return CreatedAtAction(nameof(Listar), new { id }, new ResultadoIdDto(id));
    }

    [Authorize(Roles = "AdministradorGeneral,Gerente")]
    [HttpPut("{id:int}")]
    public async Task<IActionResult> Actualizar(int id, GuardarOfertaCatalogoRequest request, CancellationToken ct)
    {
        if (!TipoValido(request.Tipo)) return TipoInvalido();
        return await catalogo.ActualizarAsync(id, request, Alcance(), ct) ? NoContent() : NotFound();
    }

    [Authorize(Roles = "AdministradorGeneral,Gerente")]
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Eliminar(int id, CancellationToken ct) =>
        await catalogo.EliminarAsync(id, Alcance(), ct) ? NoContent() : NotFound();

    private bool TipoValido(string tipo) => Tipos.Contains(tipo);
    private IActionResult TipoInvalido()
    {
        ModelState.AddModelError("Tipo", "Tipo de oferta inválido.");
        return ValidationProblem();
    }

    private AlcanceCatalogoComercial Alcance() => new(
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!),
        User.IsInRole("AdministradorGeneral"));
}

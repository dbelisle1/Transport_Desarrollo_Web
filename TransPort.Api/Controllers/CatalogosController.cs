using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using TransPort.Api.Modules.Organizacion.Repositories;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Controllers;

[ApiController]
[Route("api/catalogos/{tipo}")]
[Authorize(Roles = "AdministradorGeneral")]
public sealed class CatalogosController(ICatalogoRepository catalogos) : ControllerBase
{
    private const string RolAdministrador = "AdministradorGeneral";

    private static bool Valido(string tipo) =>
        tipo.Equals("roles", StringComparison.OrdinalIgnoreCase) ||
        tipo.Equals("giros", StringComparison.OrdinalIgnoreCase) ||
        tipo.Equals("sedes", StringComparison.OrdinalIgnoreCase);

    [HttpGet]
    public async Task<IActionResult> Listar(string tipo, CancellationToken ct) =>
        Valido(tipo) ? Ok(await catalogos.ListarAsync(tipo, ct)) : NotFound();

    [HttpGet("{id:int}")]
    public async Task<IActionResult> Obtener(string tipo, int id, CancellationToken ct)
    {
        if (!Valido(tipo)) return NotFound();
        var item = await catalogos.ObtenerAsync(tipo, id, ct);
        return item is null ? NotFound() : Ok(item);
    }

    [HttpPost]
    public async Task<IActionResult> Crear(string tipo, GuardarCatalogoRequest request, CancellationToken ct)
    {
        if (!Valido(tipo)) return NotFound();
        var id = await catalogos.CrearAsync(tipo, request, ResponsableId(), ct);
        return CreatedAtAction(nameof(Obtener), new { tipo, id }, new ResultadoIdDto(id));
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Actualizar(string tipo, int id, GuardarCatalogoRequest request, CancellationToken ct)
    {
        if (!Valido(tipo)) return NotFound();
        if (tipo.Equals("roles", StringComparison.OrdinalIgnoreCase))
        {
            var actual = await catalogos.ObtenerAsync(tipo, id, ct);
            if (actual is null) return NotFound();
            if (EsRolAdministrador(actual.Nombre) &&
                (!request.EsActivo || !EsRolAdministrador(request.Nombre.Trim())))
                return BadRequest(new MensajeDto("El rol AdministradorGeneral debe conservar su nombre y permanecer activo."));
        }
        return await catalogos.ActualizarAsync(tipo, id, request, ResponsableId(), ct) ? NoContent() : NotFound();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Eliminar(string tipo, int id, CancellationToken ct)
    {
        if (!Valido(tipo)) return NotFound();
        if (tipo.Equals("roles", StringComparison.OrdinalIgnoreCase))
        {
            var actual = await catalogos.ObtenerAsync(tipo, id, ct);
            if (actual is null) return NotFound();
            if (EsRolAdministrador(actual.Nombre))
                return BadRequest(new MensajeDto("El rol AdministradorGeneral no puede eliminarse."));
        }
        return await catalogos.EliminarAsync(tipo, id, ResponsableId(), ct) ? NoContent() : NotFound();
    }

    private static bool EsRolAdministrador(string nombre) =>
        nombre.Equals(RolAdministrador, StringComparison.OrdinalIgnoreCase);

    private int ResponsableId() => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}

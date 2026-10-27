using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Modules.Comercial.DTOs;
using TransPort.Api.Modules.Comercial.Repositories;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Controllers;

[ApiController]
[Route("api/pedidos")]
[Authorize(Roles = "AdministradorGeneral,Gerente,Vendedor,Cliente")]
public sealed class PedidosController(IPedidoRepository pedidos) : ControllerBase
{
    private static readonly HashSet<string> Tipos = new(StringComparer.OrdinalIgnoreCase) { "Pedido", "Cotizacion", "Reunion" };
    private static readonly HashSet<string> Estados = new(StringComparer.OrdinalIgnoreCase)
        { "Solicitado", "EnRevision", "Cotizado", "Aprobado", "EnProceso", "Completado", "Rechazado", "Cancelado" };

    [HttpGet]
    public Task<IReadOnlyList<PedidoListadoDto>> Listar(
        [FromQuery] string? busqueda, [FromQuery] string? estado, [FromQuery] int? clienteId,
        [FromQuery] int? giroId, CancellationToken ct) =>
        pedidos.ListarAsync(busqueda, estado, clienteId, giroId, Alcance(), ct);

    [HttpGet("opciones")]
    public Task<PedidoOpcionesDto> Opciones(CancellationToken ct) => pedidos.OpcionesAsync(Alcance(), ct);

    [HttpGet("{id:long}")]
    public async Task<IActionResult> Obtener(long id, CancellationToken ct)
    {
        var pedido = await pedidos.ObtenerAsync(id, Alcance(), ct);
        return pedido is null ? NotFound() : Ok(pedido);
    }

    [HttpPost]
    public async Task<IActionResult> Crear(CrearPedidoRequest request, CancellationToken ct)
    {
        if (!Tipos.Contains(request.TipoSolicitud))
        {
            ModelState.AddModelError(nameof(request.TipoSolicitud), "Tipo de solicitud inválido.");
            return ValidationProblem();
        }
        var id = await pedidos.CrearAsync(request, Alcance(), ct);
        return CreatedAtAction(nameof(Obtener), new { id }, new ResultadoIdDto(checked((int)id)));
    }

    [HttpPut("{id:long}/gestion")]
    [Authorize(Roles = "AdministradorGeneral,Gerente,Vendedor")]
    public async Task<IActionResult> Gestionar(long id, GestionPedidoRequest request, CancellationToken ct)
    {
        if (!Estados.Contains(request.Estado))
        {
            ModelState.AddModelError(nameof(request.Estado), "Estado inválido.");
            return ValidationProblem();
        }
        return await pedidos.GestionarAsync(id, request, Alcance(), ct) ? NoContent() : NotFound();
    }

    [HttpPost("{id:long}/comentarios")]
    public async Task<IActionResult> Comentar(long id, AgregarComentarioPedidoRequest request, CancellationToken ct)
    {
        await pedidos.ComentarAsync(id, request, Alcance(), ct);
        return NoContent();
    }

    [HttpPost("{id:long}/documentos")]
    public async Task<IActionResult> Documento(long id, AgregarDocumentoPedidoRequest request, CancellationToken ct)
    {
        var documentoId = await pedidos.AgregarDocumentoAsync(id, request, Alcance(), ct);
        return Ok(new ResultadoIdDto(checked((int)documentoId)));
    }

    [HttpDelete("{id:long}")]
    [Authorize(Roles = "AdministradorGeneral")]
    public async Task<IActionResult> Eliminar(long id, CancellationToken ct) =>
        await pedidos.EliminarAsync(id, UsuarioId(), ct) ? NoContent() : NotFound();

    private AlcancePedido Alcance() => new(
        UsuarioId(), User.IsInRole("AdministradorGeneral"), User.IsInRole("Cliente"));
    private int UsuarioId() => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}

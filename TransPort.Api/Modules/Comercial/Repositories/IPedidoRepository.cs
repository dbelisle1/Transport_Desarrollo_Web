using TransPort.Api.Modules.Comercial.DTOs;

namespace TransPort.Api.Modules.Comercial.Repositories;

public interface IPedidoRepository
{
    Task<IReadOnlyList<PedidoListadoDto>> ListarAsync(string? busqueda, string? estado, int? clienteId, int? giroId, AlcancePedido alcance, CancellationToken ct);
    Task<PedidoDetalleDto?> ObtenerAsync(long id, AlcancePedido alcance, CancellationToken ct);
    Task<PedidoOpcionesDto> OpcionesAsync(AlcancePedido alcance, CancellationToken ct);
    Task<long> CrearAsync(CrearPedidoRequest request, AlcancePedido alcance, CancellationToken ct);
    Task<bool> GestionarAsync(long id, GestionPedidoRequest request, AlcancePedido alcance, CancellationToken ct);
    Task ComentarAsync(long id, AgregarComentarioPedidoRequest request, AlcancePedido alcance, CancellationToken ct);
    Task<long> AgregarDocumentoAsync(long id, AgregarDocumentoPedidoRequest request, AlcancePedido alcance, CancellationToken ct);
    Task<bool> EliminarAsync(long id, int usuarioId, CancellationToken ct);
}

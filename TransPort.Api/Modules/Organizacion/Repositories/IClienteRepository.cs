using TransPort.Api.Modules.Organizacion.DTOs;

namespace TransPort.Api.Modules.Organizacion.Repositories;

public interface IClienteRepository
{
    Task<IReadOnlyList<ClienteListadoDto>> ListarAsync(string? busqueda, bool? esActivo, CancellationToken ct);
    Task<ClienteDetalleDto?> ObtenerAsync(int id, CancellationToken ct);
    Task<int> CrearAsync(CrearClienteRequest request, int responsableId, CancellationToken ct);
    Task<bool> ActualizarAsync(int id, ActualizarClienteRequest request, int responsableId, CancellationToken ct);
    Task<bool> EliminarAsync(int id, int responsableId, CancellationToken ct);
    Task ActualizarAsociacionesAsync(int clienteId, AsociacionesClienteRequest request, int responsableId, CancellationToken ct);
}
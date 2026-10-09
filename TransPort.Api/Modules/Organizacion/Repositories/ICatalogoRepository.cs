using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Modules.Organizacion.Repositories;

public interface ICatalogoRepository
{
    Task<IReadOnlyList<EntidadCatalogoDto>> ListarAsync(string tipo, CancellationToken ct);
    Task<EntidadCatalogoDto?> ObtenerAsync(string tipo, int id, CancellationToken ct);
    Task<int> CrearAsync(string tipo, GuardarCatalogoRequest request, int responsableId, CancellationToken ct);
    Task<bool> ActualizarAsync(string tipo, int id, GuardarCatalogoRequest request, int responsableId, CancellationToken ct);
    Task<bool> EliminarAsync(string tipo, int id, int responsableId, CancellationToken ct);
}

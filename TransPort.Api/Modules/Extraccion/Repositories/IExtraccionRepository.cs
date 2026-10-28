using TransPort.Api.Modules.Extraccion.DTOs;

namespace TransPort.Api.Modules.Extraccion.Repositories;

public interface IExtraccionRepository
{
    Task<IReadOnlyList<ExtraccionListadoDto>> ListarAsync(string? estado, int? sedeId, DateTime? fechaDesde, DateTime? fechaHasta, AlcanceExtraccion alcance, CancellationToken ct);
    Task<ExtraccionDetalleDto?> ObtenerAsync(long id, AlcanceExtraccion alcance, CancellationToken ct);
    Task<ExtraccionOpcionesDto> OpcionesAsync(AlcanceExtraccion alcance, CancellationToken ct);
    Task<long> CrearAsync(CrearExtraccionRequest request, AlcanceExtraccion alcance, CancellationToken ct);
    Task<bool> CambiarEstadoAsync(long id, CambiarEstadoExtraccionRequest request, AlcanceExtraccion alcance, CancellationToken ct);
    Task<bool> EliminarAsync(long id, int usuarioId, CancellationToken ct);
}

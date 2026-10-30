using TransPort.Api.Modules.Comercial.DTOs;

namespace TransPort.Api.Modules.Comercial.Repositories;

public interface ICatalogoComercialRepository
{
    Task<IReadOnlyList<OfertaCatalogoDto>> ListarPublicoAsync(int? giroId, string? tipo, CancellationToken ct);
    Task<IReadOnlyList<OfertaCatalogoDto>> ListarAsync(string? busqueda, int? giroId, string? tipo, bool? esActivo, AlcanceCatalogoComercial alcance, CancellationToken ct);
    Task<CatalogoComercialOpcionesDto> OpcionesAsync(AlcanceCatalogoComercial alcance, CancellationToken ct);
    Task<int> CrearAsync(GuardarOfertaCatalogoRequest request, AlcanceCatalogoComercial alcance, CancellationToken ct);
    Task<bool> ActualizarAsync(int id, GuardarOfertaCatalogoRequest request, AlcanceCatalogoComercial alcance, CancellationToken ct);
    Task<bool> EliminarAsync(int id, AlcanceCatalogoComercial alcance, CancellationToken ct);
}

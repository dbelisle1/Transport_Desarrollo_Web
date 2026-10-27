using TransPort.Api.Modules.Inventarios.DTOs;

namespace TransPort.Api.Modules.Inventarios.Repositories;

public interface IInventarioRepository
{
    Task<IReadOnlyList<InventarioExistenciaDto>> ListarAsync(string? busqueda,int? giroId,int? sedeId,bool soloBajoMinimo,AlcanceInventario alcance,CancellationToken ct);
    Task<IReadOnlyList<InventarioMovimientoDto>> MovimientosAsync(int? articuloId,int limite,AlcanceInventario alcance,CancellationToken ct);
    Task<InventarioOpcionesDto> OpcionesAsync(AlcanceInventario alcance,CancellationToken ct);
    Task<int> CrearArticuloAsync(CrearInventarioArticuloRequest request,AlcanceInventario alcance,CancellationToken ct);
    Task<long> RegistrarMovimientoAsync(RegistrarInventarioMovimientoRequest request,AlcanceInventario alcance,CancellationToken ct);
    Task<bool> EliminarArticuloAsync(int id,int usuarioId,CancellationToken ct);
}

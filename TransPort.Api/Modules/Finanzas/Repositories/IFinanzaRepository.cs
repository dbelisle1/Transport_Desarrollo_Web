using TransPort.Api.Modules.Finanzas.DTOs;

namespace TransPort.Api.Modules.Finanzas.Repositories;

public interface IFinanzaRepository
{
    Task<IReadOnlyList<PresupuestoListadoDto>> ListarAsync(short? anio,byte? mes,int? giroId,int? sedeId,AlcanceFinanza alcance,CancellationToken ct);
    Task<PresupuestoDetalleDto?> ObtenerAsync(long id,AlcanceFinanza alcance,CancellationToken ct);
    Task<FinanzaOpcionesDto> OpcionesAsync(AlcanceFinanza alcance,CancellationToken ct);
    Task<long> CrearAsync(CrearPresupuestoRequest request,AlcanceFinanza alcance,CancellationToken ct);
    Task<long> RegistrarGastoAsync(long id,RegistrarGastoRequest request,AlcanceFinanza alcance,CancellationToken ct);
    Task<bool> ActualizarEstadoAsync(long id,string estado,AlcanceFinanza alcance,CancellationToken ct);
    Task<bool> EliminarAsync(long id,int usuarioId,CancellationToken ct);
    Task<IReadOnlyList<IngresoDto>> ListarIngresosAsync(short? anio,byte? mes,int? giroId,int? sedeId,AlcanceFinanza alcance,CancellationToken ct);
    Task<IngresoDto?> ObtenerIngresoAsync(long id,AlcanceFinanza alcance,CancellationToken ct);
    Task<IngresoOpcionesDto> OpcionesIngresoAsync(AlcanceFinanza alcance,CancellationToken ct);
    Task<long> CrearIngresoAsync(CrearIngresoRequest request,AlcanceFinanza alcance,CancellationToken ct);
    Task<bool> EliminarIngresoAsync(long id,int usuarioId,CancellationToken ct);
}

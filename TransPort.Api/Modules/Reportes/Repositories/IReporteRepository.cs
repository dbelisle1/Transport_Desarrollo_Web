using TransPort.Api.Modules.Reportes.DTOs;

namespace TransPort.Api.Modules.Reportes.Repositories;

public interface IReporteRepository
{
    Task<ReporteOpcionesDto> OpcionesAsync(AlcanceReporte alcance,CancellationToken ct);
    Task<ReporteInternoDto> InternoAsync(DateTime? desde,DateTime? hasta,int? giroId,int? sedeId,AlcanceReporte alcance,CancellationToken ct);
    Task<ReporteClienteDto> ClienteAsync(DateTime? desde,DateTime? hasta,int? clienteId,AlcanceReporte alcance,CancellationToken ct);
}

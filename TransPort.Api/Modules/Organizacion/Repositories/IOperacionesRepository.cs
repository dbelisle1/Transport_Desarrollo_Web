using TransPort.Api.Modules.Organizacion.DTOs;

namespace TransPort.Api.Modules.Organizacion.Repositories;

public interface IOperacionesRepository
{
    Task<DashboardDto> ObtenerResumenAsync(CancellationToken ct);
    Task CrearAuditoriaAsync(CrearAuditoriaDto evento, CancellationToken ct);
    Task<AuditoriaPaginaDto> ListarAuditoriaAsync(AuditoriaConsultaDto consulta, CancellationToken ct);
}

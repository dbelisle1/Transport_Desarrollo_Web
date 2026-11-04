using TransPort.Api.Modules.PortalCliente.DTOs;

namespace TransPort.Api.Modules.PortalCliente.Repositories;

public interface IPortalClienteRepository
{
    Task<PortalClienteResumenDto> ResumenAsync(int usuarioId, bool esAdministrador, CancellationToken ct);
    Task<PortalClienteOperacionesDto> OperacionesAsync(
        int usuarioId, bool esAdministrador, int? clienteId, CancellationToken ct);
}

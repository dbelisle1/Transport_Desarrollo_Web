using TransPort.Api.Modules.Comercial.DTOs;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Modules.PortalCliente.DTOs;

public sealed record EmpresaPortalClienteDto(
    int ClienteId, string Nombre, string? Nit, string? CorreoContacto,
    IReadOnlyList<CatalogoDto> ServiciosContratados);

public sealed record PortalClienteResumenDto(
    IReadOnlyList<EmpresaPortalClienteDto> Empresas,
    long TotalSolicitudes, long Solicitadas, long EnGestion,
    long Completadas, long Documentos,
    IReadOnlyList<PedidoListadoDto> SolicitudesRecientes);

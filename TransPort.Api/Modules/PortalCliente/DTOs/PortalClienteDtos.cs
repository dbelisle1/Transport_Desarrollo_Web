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

public sealed record PortalClienteViajeDto(
    long TransporteViajeId, int ClienteId, string Cliente, string Tipo,
    string Origen, string Destino, string DescripcionCarga,
    DateTime FechaSalidaPlanificada, DateTime? FechaSalidaReal,
    DateTime? FechaEntrega, string Estado, string Placa,
    string Conductor, int IncidenciasAbiertas);

public sealed record PortalClienteContratoDto(
    long MaquinariaContratoId, int ClienteId, string Cliente,
    int MaquinariaEquipoId, string Codigo, string Equipo, string Tipo,
    DateTime FechaInicio, DateTime? FechaFin, decimal MontoTotal,
    string Estado, decimal? HorasEntrega, decimal? HorasDevolucion);

public sealed record PortalClienteProyectoDto(
    long ConstruccionProyectoId, int ClienteId, string Cliente, string Nombre,
    string TipoObra, string Ubicacion, DateTime FechaInicioPlanificada,
    DateTime FechaFinPlanificada, decimal Presupuesto, string Estado,
    decimal PorcentajeAvance, decimal CostoReal);

public sealed record PortalClienteOperacionesDto(
    long ViajesActivos, long ContratosActivos, long ProyectosActivos,
    IReadOnlyList<PortalClienteViajeDto> Viajes,
    IReadOnlyList<PortalClienteContratoDto> Contratos,
    IReadOnlyList<PortalClienteProyectoDto> Proyectos);

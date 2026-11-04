using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Modules.Reportes.DTOs;

public readonly record struct AlcanceReporte(int UsuarioId,bool EsAdministrador);
public sealed record ReporteOpcionesDto(IReadOnlyList<CatalogoDto> Giros,IReadOnlyList<CatalogoDto> Sedes);
public sealed record ReporteInternoResumenDto(DateTime Desde,DateTime Hasta,int Giros,int Sedes,long Operaciones,long Completadas,decimal Presupuesto,decimal Gastos,decimal Ingresos,decimal Resultado);
public sealed record ReporteGiroDto(int GiroNegocioId,string Giro,long Operaciones,long Completadas,string Indicador,decimal ValorIndicador,string UnidadIndicador,decimal Presupuesto,decimal Gastos,decimal Ingresos,decimal Resultado);
public sealed record ReportePeriodoDto(short Anio,byte Mes,string Periodo,decimal Presupuesto,decimal Gastos,decimal Ingresos,decimal Resultado);
public sealed record ReporteInternoDto(ReporteInternoResumenDto Resumen,IReadOnlyList<ReporteGiroDto> Giros,IReadOnlyList<ReportePeriodoDto> Periodos);
public sealed record ReporteClienteResumenDto(DateTime Desde,DateTime Hasta,int Empresas,long Pedidos,long Completados,decimal MontoCotizado,long Viajes,long Entregados,decimal PesoTransportado,long Contratos,decimal MontoContratos,long Proyectos,decimal PresupuestoObras,decimal AvancePromedio,decimal IngresosRegistrados);
public sealed record ReporteClienteEmpresaDto(int ClienteId,string Cliente,long Pedidos,long Completados,decimal MontoCotizado,long Viajes,long Entregados,decimal PesoTransportado,long Contratos,decimal MontoContratos,long Proyectos,decimal PresupuestoObras,decimal AvancePromedio,decimal IngresosRegistrados);
public sealed record ReporteClientePeriodoDto(short Anio,byte Mes,string Periodo,long Pedidos,long Operaciones,decimal IngresosRegistrados);
public sealed record ReporteClienteDto(ReporteClienteResumenDto Resumen,IReadOnlyList<ReporteClienteEmpresaDto> Empresas,IReadOnlyList<ReporteClientePeriodoDto> Periodos);

using System.ComponentModel.DataAnnotations;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Modules.Produccion.DTOs;

public sealed record ProduccionListadoDto(long ProduccionOrdenId,int SedeId,string Sede,int ArticuloEntradaId,string CodigoEntrada,string ArticuloEntrada,string UnidadEntrada,int ArticuloSalidaId,string CodigoSalida,string ArticuloSalida,string UnidadSalida,DateTime FechaPlanificada,decimal CantidadEntrada,decimal CantidadSalidaPlanificada,decimal? CantidadSalidaReal,decimal? CantidadMerma,decimal? CostoUnitario,string Estado,string Responsable,DateTime FechaCreacion,string? EtapaActual);
public sealed record ProduccionEtapaDto(long ProduccionEtapaId,int Secuencia,string Nombre,string Estado,DateTime? FechaInicio,DateTime? FechaFin,string? Observacion);
public sealed record ProduccionHistorialDto(long ProduccionHistorialId,int UsuarioId,string NombreUsuario,string? EstadoAnterior,string EstadoNuevo,string? Comentario,DateTime Fecha);
public sealed record ProduccionDetalleDto(long ProduccionOrdenId,int SedeId,string Sede,int ArticuloEntradaId,string CodigoEntrada,string ArticuloEntrada,string UnidadEntrada,int ArticuloSalidaId,string CodigoSalida,string ArticuloSalida,string UnidadSalida,DateTime FechaPlanificada,decimal CantidadEntrada,decimal CantidadSalidaPlanificada,decimal? CantidadSalidaReal,decimal? CantidadMerma,decimal? CostoUnitario,string Estado,int ResponsableUsuarioId,string Responsable,string? Observacion,DateTime FechaCreacion,DateTime? FechaModificacion,IReadOnlyList<ProduccionEtapaDto> Etapas,IReadOnlyList<ProduccionHistorialDto> Historial);
public sealed record ProduccionOpcionesDto(IReadOnlyList<CatalogoDto> Sedes,IReadOnlyList<CatalogoDto> Articulos);
public sealed class CrearProduccionRequest{[Range(1,int.MaxValue)]public int SedeId{get;set;}[Range(1,int.MaxValue)]public int ArticuloEntradaId{get;set;}[Range(1,int.MaxValue)]public int ArticuloSalidaId{get;set;}[DataType(DataType.Date)]public DateTime FechaPlanificada{get;set;}[Range(0.001,999999999999999.999)]public decimal CantidadEntrada{get;set;}[Range(0.001,999999999999999.999)]public decimal CantidadSalidaPlanificada{get;set;}[StringLength(500)]public string? Observacion{get;set;}}
public sealed class CambiarEstadoProduccionRequest{[Required,StringLength(30)]public string Estado{get;set;}=string.Empty;[Range(0.001,999999999999999.999)]public decimal? CantidadSalidaReal{get;set;}[Range(0,999999999999999.999)]public decimal? CantidadMerma{get;set;}[Range(0,999999999999999.99)]public decimal? CostoUnitario{get;set;}[StringLength(500)]public string? Comentario{get;set;}}
public sealed class CompletarEtapaProduccionRequest{[StringLength(500)]public string? Observacion{get;set;}}
public sealed record ResultadoProduccionDto(long Id);
public readonly record struct AlcanceProduccion(int UsuarioId,bool EsAdministrador);

using System.ComponentModel.DataAnnotations;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Modules.Finanzas.DTOs;

public sealed record PresupuestoListadoDto(long FinanzaPresupuestoId,int GiroNegocioId,string Giro,int SedeId,string Sede,short Anio,byte Mes,string Nombre,decimal Monto,string Estado,decimal GastoReal,decimal Disponible,decimal PorcentajeEjecutado,DateTime FechaCreacion);
public sealed record GastoDto(long FinanzaGastoId,DateTime Fecha,string Categoria,string Concepto,decimal Monto,string OrigenModulo,long? OrigenRegistroId,string? Referencia,string NombreUsuario,DateTime FechaCreacion);
public sealed record PresupuestoDetalleDto(long FinanzaPresupuestoId,int GiroNegocioId,string Giro,int SedeId,string Sede,short Anio,byte Mes,string Nombre,decimal Monto,string Estado,string? Observacion,decimal GastoReal,decimal Disponible,decimal PorcentajeEjecutado,DateTime FechaCreacion,IReadOnlyList<GastoDto> Gastos);
public sealed record FinanzaOpcionesDto(IReadOnlyList<CatalogoDto> Giros,IReadOnlyList<CatalogoDto> Sedes);
public sealed record IngresoDto(long FinanzaIngresoId,int GiroNegocioId,string Giro,int SedeId,string Sede,int? ClienteId,string? Cliente,DateTime Fecha,string Categoria,string Concepto,decimal Monto,string OrigenModulo,long? OrigenRegistroId,string? Referencia,string NombreUsuario,DateTime FechaCreacion);
public sealed record IngresoOpcionesDto(IReadOnlyList<CatalogoDto> Giros,IReadOnlyList<CatalogoDto> Sedes,IReadOnlyList<CatalogoDto> Clientes);
public sealed class CrearPresupuestoRequest
{
    [Range(1,int.MaxValue)] public int GiroId { get; set; }
    [Range(1,int.MaxValue)] public int SedeId { get; set; }
    [Range(2000,2100)] public short Anio { get; set; }
    [Range(1,12)] public byte Mes { get; set; }
    [Required,StringLength(180)] public string Nombre { get; set; }=string.Empty;
    [Range(.01,999999999999999.99)] public decimal Monto { get; set; }
    [StringLength(500)] public string? Observacion { get; set; }
}
public sealed class RegistrarGastoRequest
{
    public DateTime Fecha { get; set; }
    [Required,StringLength(30)] public string Categoria { get; set; }=string.Empty;
    [Required,StringLength(250)] public string Concepto { get; set; }=string.Empty;
    [Range(.01,999999999999999.99)] public decimal Monto { get; set; }
    [Required,StringLength(30)] public string OrigenModulo { get; set; }="Manual";
    public long? OrigenRegistroId { get; set; }
    [StringLength(120)] public string? Referencia { get; set; }
}
public sealed class EstadoPresupuestoRequest { [Required,StringLength(20)] public string Estado { get; set; }=string.Empty; }
public sealed class CrearIngresoRequest
{
    [Range(1,int.MaxValue)] public int GiroId { get; set; }
    [Range(1,int.MaxValue)] public int SedeId { get; set; }
    public int? ClienteId { get; set; }
    public DateTime Fecha { get; set; }
    [Required,StringLength(30)] public string Categoria { get; set; }=string.Empty;
    [Required,StringLength(250)] public string Concepto { get; set; }=string.Empty;
    [Range(.01,999999999999999.99)] public decimal Monto { get; set; }
    [Required,StringLength(30)] public string OrigenModulo { get; set; }="Manual";
    public long? OrigenRegistroId { get; set; }
    [StringLength(120)] public string? Referencia { get; set; }
}
public sealed record ResultadoFinanzaDto(long Id);
public readonly record struct AlcanceFinanza(int UsuarioId,bool EsAdministrador);

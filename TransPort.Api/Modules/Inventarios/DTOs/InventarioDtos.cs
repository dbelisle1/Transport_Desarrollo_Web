using System.ComponentModel.DataAnnotations;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Modules.Inventarios.DTOs;

public sealed record InventarioExistenciaDto(
    int InventarioArticuloId,string Codigo,string Nombre,string Categoria,string UnidadMedida,
    int GiroNegocioId,string Giro,decimal StockMinimo,int? SedeId,string? Sede,
    decimal Cantidad,decimal CantidadReservada,decimal CantidadDisponible,bool BajoMinimo);

public sealed record InventarioMovimientoDto(
    long InventarioMovimientoId,int InventarioArticuloId,string Codigo,string Articulo,
    string Tipo,int? SedeOrigenId,string? SedeOrigen,int? SedeDestinoId,string? SedeDestino,
    decimal Cantidad,string UnidadMedida,string? Referencia,string? Observacion,
    int UsuarioId,string NombreUsuario,DateTime Fecha);

public sealed record InventarioOpcionesDto(
    IReadOnlyList<CatalogoDto> Giros,IReadOnlyList<CatalogoDto> Sedes,IReadOnlyList<CatalogoDto> Articulos);

public sealed class CrearInventarioArticuloRequest
{
    [Range(1,int.MaxValue)] public int GiroNegocioId { get; set; }
    [Required,StringLength(50,MinimumLength=2)] public string Codigo { get; set; }=string.Empty;
    [Required,StringLength(180,MinimumLength=2)] public string Nombre { get; set; }=string.Empty;
    [Required,StringLength(80,MinimumLength=2)] public string Categoria { get; set; }=string.Empty;
    [Required,StringLength(30,MinimumLength=1)] public string UnidadMedida { get; set; }=string.Empty;
    [Range(0,999999999999999.999)] public decimal StockMinimo { get; set; }
}

public sealed class RegistrarInventarioMovimientoRequest
{
    [Range(1,int.MaxValue)] public int InventarioArticuloId { get; set; }
    [Required,StringLength(30)] public string Tipo { get; set; }=string.Empty;
    public int? SedeOrigenId { get; set; }
    public int? SedeDestinoId { get; set; }
    [Range(0.001,999999999999999.999)] public decimal Cantidad { get; set; }
    [StringLength(120)] public string? Referencia { get; set; }
    [StringLength(500)] public string? Observacion { get; set; }
}

public sealed record ResultadoMovimientoInventarioDto(long Id);
public readonly record struct AlcanceInventario(int UsuarioId,bool EsAdministrador);

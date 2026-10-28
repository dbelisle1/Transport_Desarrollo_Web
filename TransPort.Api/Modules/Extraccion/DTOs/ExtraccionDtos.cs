using System.ComponentModel.DataAnnotations;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Modules.Extraccion.DTOs;

public sealed record ExtraccionListadoDto(long ExtraccionJornadaId, int SedeId, string Sede, int InventarioArticuloId, string Codigo, string Articulo, string UnidadMedida, DateTime FechaOperacion, string Turno, string FrenteExtraccion, decimal CantidadExtraida, decimal CantidadRechazada, decimal CantidadAprovechable, string DestinoTipo, string? DestinoDescripcion, string Estado, string Responsable, DateTime FechaCreacion);
public sealed record ExtraccionHistorialDto(long ExtraccionHistorialId, int UsuarioId, string NombreUsuario, string? EstadoAnterior, string EstadoNuevo, string? Comentario, DateTime Fecha);
public sealed record ExtraccionDetalleDto(long ExtraccionJornadaId, int SedeId, string Sede, int InventarioArticuloId, string Codigo, string Articulo, string UnidadMedida, DateTime FechaOperacion, string Turno, string FrenteExtraccion, decimal CantidadExtraida, decimal CantidadRechazada, decimal CantidadAprovechable, string DestinoTipo, string? DestinoDescripcion, string Estado, int ResponsableUsuarioId, string Responsable, string? Observacion, DateTime FechaCreacion, DateTime? FechaModificacion, IReadOnlyList<ExtraccionHistorialDto> Historial);
public sealed record ExtraccionOpcionesDto(IReadOnlyList<CatalogoDto> Sedes, IReadOnlyList<CatalogoDto> Articulos);
public sealed class CrearExtraccionRequest
{
    [Range(1, int.MaxValue)] public int SedeId { get; set; }
    [Range(1, int.MaxValue)] public int InventarioArticuloId { get; set; }
    [DataType(DataType.Date)] public DateTime FechaOperacion { get; set; }
    [Required, StringLength(30, MinimumLength = 2)] public string Turno { get; set; } = string.Empty;
    [Required, StringLength(120, MinimumLength = 2)] public string FrenteExtraccion { get; set; } = string.Empty;
    [Range(0.001, 999999999999999.999)] public decimal CantidadExtraida { get; set; }
    [Range(0, 999999999999999.999)] public decimal CantidadRechazada { get; set; }
    [Required, StringLength(30)] public string DestinoTipo { get; set; } = string.Empty;
    [StringLength(200)] public string? DestinoDescripcion { get; set; }
    [StringLength(500)] public string? Observacion { get; set; }
}
public sealed class CambiarEstadoExtraccionRequest
{
    [Required, StringLength(30)] public string Estado { get; set; } = string.Empty;
    [StringLength(500)] public string? Comentario { get; set; }
}
public sealed record ResultadoExtraccionDto(long Id);
public readonly record struct AlcanceExtraccion(int UsuarioId, bool EsAdministrador);

using System.ComponentModel.DataAnnotations;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Modules.Comercial.DTOs;

public sealed record OfertaCatalogoDto(
    int CatalogoOfertaId,
    int GiroNegocioId,
    string Giro,
    string Codigo,
    string Tipo,
    string Nombre,
    string Descripcion,
    string UnidadMedida,
    decimal PrecioBase,
    bool EsPublico,
    bool EsActivo,
    DateTime FechaCreacion,
    DateTime? FechaModificacion);

public sealed record CatalogoComercialOpcionesDto(IReadOnlyList<CatalogoDto> Giros);

public sealed class GuardarOfertaCatalogoRequest
{
    [Range(1, int.MaxValue)] public int GiroNegocioId { get; set; }
    [Required, StringLength(50, MinimumLength = 2)] public string Codigo { get; set; } = string.Empty;
    [Required, StringLength(20)] public string Tipo { get; set; } = "Producto";
    [Required, StringLength(180, MinimumLength = 3)] public string Nombre { get; set; } = string.Empty;
    [Required, StringLength(1000, MinimumLength = 5)] public string Descripcion { get; set; } = string.Empty;
    [Required, StringLength(40, MinimumLength = 1)] public string UnidadMedida { get; set; } = string.Empty;
    [Range(0, 9999999999999999.99)] public decimal PrecioBase { get; set; }
    public bool EsPublico { get; set; } = true;
    public bool EsActivo { get; set; } = true;
}

public readonly record struct AlcanceCatalogoComercial(int UsuarioId, bool EsAdministrador);

using System.ComponentModel.DataAnnotations;

namespace TransPort.Api.Modules.Shared.DTOs;

public sealed record CatalogoDto(int Id, string Nombre);

public sealed record EntidadCatalogoDto(
    int Id,
    string Nombre,
    string? Descripcion,
    bool EsActivo,
    DateTime FechaCreacion);

public sealed class GuardarCatalogoRequest
{
    [Required, StringLength(120, MinimumLength = 2)]
    public string Nombre { get; set; } = string.Empty;

    [StringLength(500)]
    public string? Descripcion { get; set; }

    public bool EsActivo { get; set; } = true;
}

public sealed record ResultadoIdDto(int Id);
public sealed record MensajeDto(string Mensaje);

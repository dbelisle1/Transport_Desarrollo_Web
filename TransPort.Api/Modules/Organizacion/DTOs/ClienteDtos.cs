using System.ComponentModel.DataAnnotations;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Modules.Organizacion.DTOs;

public sealed record ClienteListadoDto(
    int ClienteId, string Nombre, string? Nit, string? CorreoContacto, bool EsActivo, DateTime? FechaModificacion);

public sealed record ClienteDetalleDto(
    int ClienteId, string Nombre, string? Nit, string? CorreoContacto, bool EsActivo, DateTime? FechaModificacion,
    IReadOnlyList<CatalogoDto> Usuarios, IReadOnlyList<CatalogoDto> Giros);

public sealed class CrearClienteRequest
{
    [Required, StringLength(200, MinimumLength = 2)] public string Nombre { get; set; } = string.Empty;
    [StringLength(50)] public string? Nit { get; set; }
    [EmailAddress, StringLength(150)] public string? CorreoContacto { get; set; }
    public bool EsActivo { get; set; } = true;
}

public sealed class ActualizarClienteRequest
{
    [Required, StringLength(200, MinimumLength = 2)] public string Nombre { get; set; } = string.Empty;
    [StringLength(50)] public string? Nit { get; set; }
    [EmailAddress, StringLength(150)] public string? CorreoContacto { get; set; }
    public bool EsActivo { get; set; }
}

public sealed class AsociacionesClienteRequest
{
    public IReadOnlyList<int> Usuarios { get; set; } = [];
    public IReadOnlyList<int> Giros { get; set; } = [];
}
using System.ComponentModel.DataAnnotations;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Modules.Seguridad.DTOs;

public sealed record UsuarioListadoDto(
    int UsuarioId,
    string NombreUsuario,
    string Nombre,
    string Apellido,
    string Correo,
    bool EsActivo,
    DateTime FechaCreacion,
    string Roles);

public sealed record UsuarioDetalleDto(
    int UsuarioId,
    string NombreUsuario,
    string Nombre,
    string Apellido,
    string Correo,
    bool EsActivo,
    DateTime FechaCreacion,
    DateTime? FechaModificacion,
    IReadOnlyList<CatalogoDto> Roles,
    IReadOnlyList<CatalogoDto> Giros,
    IReadOnlyList<CatalogoDto> Sedes);

public sealed class CrearUsuarioRequest
{
    [Required, StringLength(80, MinimumLength = 3)]
    public string NombreUsuario { get; set; } = string.Empty;
    [Required, StringLength(100)] public string Nombre { get; set; } = string.Empty;
    [Required, StringLength(100)] public string Apellido { get; set; } = string.Empty;
    [Required, EmailAddress, StringLength(200)] public string Correo { get; set; } = string.Empty;
    [Required, StringLength(200, MinimumLength = 6)] public string Clave { get; set; } = string.Empty;
    public bool EsActivo { get; set; } = true;
}

public sealed class ActualizarUsuarioRequest
{
    [Required, StringLength(80, MinimumLength = 3)] public string NombreUsuario { get; set; } = string.Empty;
    [Required, StringLength(100)] public string Nombre { get; set; } = string.Empty;
    [Required, StringLength(100)] public string Apellido { get; set; } = string.Empty;
    [Required, EmailAddress, StringLength(200)] public string Correo { get; set; } = string.Empty;
    public bool EsActivo { get; set; }
}

public sealed class AsignacionesUsuarioRequest
{
    public IReadOnlyList<int> Roles { get; set; } = [];
    public IReadOnlyList<int> Giros { get; set; } = [];
    public IReadOnlyList<int> Sedes { get; set; } = [];
}

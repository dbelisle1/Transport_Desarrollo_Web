using System.ComponentModel.DataAnnotations;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Modules.Seguridad.DTOs;

public sealed class LoginRequest
{
    [Required, StringLength(80)]
    public string NombreUsuario { get; set; } = string.Empty;

    [Required, StringLength(200)]
    public string Clave { get; set; } = string.Empty;
}

public sealed record UsuarioSesionDto(
    int UsuarioId,
    string NombreUsuario,
    string NombreCompleto,
    string Correo,
    IReadOnlyList<string> Roles,
    IReadOnlyList<CatalogoDto> Giros,
    IReadOnlyList<CatalogoDto> Sedes,
    IReadOnlyList<CatalogoDto> Clientes);

public sealed record LoginResponse(string Token, DateTime ExpiraUtc, UsuarioSesionDto Usuario);

public sealed record CredencialUsuarioDto(
    int UsuarioId,
    string NombreUsuario,
    string Nombre,
    string Apellido,
    string Correo,
    bool EsActivo);

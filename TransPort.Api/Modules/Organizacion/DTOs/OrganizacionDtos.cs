namespace TransPort.Api.Modules.Organizacion.DTOs;

public sealed record DashboardDto(int Usuarios, int Giros, int Sedes);

public sealed record AuditoriaDto(
    long AuditoriaId, int? UsuarioId, string? NombreUsuario, DateTime Fecha,
    string Modulo, string TipoOperacion, string? IdentificadorRegistro,
    string Resultado, string? Detalle);

public sealed record CrearAuditoriaDto(
    int? UsuarioId, string Modulo, string TipoOperacion,
    string? IdentificadorRegistro, string Resultado, string? Detalle);

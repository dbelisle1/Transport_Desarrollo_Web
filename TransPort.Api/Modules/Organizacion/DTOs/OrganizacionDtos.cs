using System.ComponentModel.DataAnnotations;

namespace TransPort.Api.Modules.Organizacion.DTOs;

public sealed record DashboardDto(int Usuarios, int Clientes, int Giros, int Sedes);

public sealed record AuditoriaDto(
    long AuditoriaId, int? UsuarioId, string? NombreUsuario, DateTime Fecha,
    string Modulo, string TipoOperacion, string? IdentificadorRegistro,
    string Resultado, string? Detalle);

public sealed record CrearAuditoriaDto(
    int? UsuarioId, string Modulo, string TipoOperacion,
    string? IdentificadorRegistro, string Resultado, string? Detalle);

public sealed class AuditoriaConsultaDto
{
    [StringLength(200)]
    public string? Busqueda { get; set; }

    public DateTime? FechaDesdeUtc { get; set; }
    public DateTime? FechaHastaUtc { get; set; }

    [StringLength(80)]
    public string? Modulo { get; set; }

    [StringLength(80)]
    public string? TipoOperacion { get; set; }

    [StringLength(80)]
    public string? NombreUsuario { get; set; }

    [StringLength(40)]
    public string? Resultado { get; set; }

    [Range(1, int.MaxValue)]
    public int Pagina { get; set; } = 1;

    [Range(10, 100)]
    public int TamanoPagina { get; set; } = 25;
}

public sealed record AuditoriaPaginaDto(
    IReadOnlyList<AuditoriaDto> Elementos,
    long TotalRegistros,
    int Pagina,
    int TamanoPagina)
{
    public int TotalPaginas => TotalRegistros == 0
        ? 0
        : (int)Math.Ceiling(TotalRegistros / (double)TamanoPagina);
}

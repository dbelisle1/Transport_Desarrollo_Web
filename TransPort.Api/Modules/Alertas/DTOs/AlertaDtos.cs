using System.ComponentModel.DataAnnotations;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Modules.Alertas.DTOs;

public sealed record AlertaListadoDto(long AlertaNotificacionId,string Tipo,string Titulo,string Mensaje,string Severidad,string Estado,DateTime FechaProgramadaUtc,DateTime? FechaVencimientoUtc,string? Rol,string? Giro,string? Sede,string? UsuarioDestino,string? ModuloOrigen,long? RegistroOrigenId,bool Leida,int Seguimientos);
public sealed record AlertaSeguimientoDto(long AlertaSeguimientoId,string Comentario,string NombreUsuario,DateTime Fecha);
public sealed record AlertaDetalleDto(long AlertaNotificacionId,string Tipo,string Titulo,string Mensaje,string Severidad,string Estado,DateTime FechaProgramadaUtc,DateTime? FechaVencimientoUtc,int? RolId,string? Rol,int? GiroNegocioId,string? Giro,int? SedeId,string? Sede,int? UsuarioDestinoId,string? UsuarioDestino,string? ModuloOrigen,long? RegistroOrigenId,string CreadoPor,DateTime FechaCreacion,bool Leida,DateTime? FechaLectura,IReadOnlyList<AlertaSeguimientoDto> Seguimientos);
public sealed record AlertaOpcionesDto(IReadOnlyList<CatalogoDto> Roles,IReadOnlyList<CatalogoDto> Giros,IReadOnlyList<CatalogoDto> Sedes,IReadOnlyList<CatalogoDto> Usuarios);
public sealed class CrearAlertaRequest
{
    [Required,StringLength(20)] public string Tipo { get; set; }="Alerta";
    [Required,StringLength(180)] public string Titulo { get; set; }=string.Empty;
    [Required,StringLength(1500)] public string Mensaje { get; set; }=string.Empty;
    [Required,StringLength(20)] public string Severidad { get; set; }="Informativa";
    public int? RolId { get; set; } public int? GiroId { get; set; } public int? SedeId { get; set; } public int? UsuarioDestinoId { get; set; }
    public DateTime FechaProgramadaUtc { get; set; } public DateTime? FechaVencimientoUtc { get; set; }
    [StringLength(50)] public string? ModuloOrigen { get; set; } public long? RegistroOrigenId { get; set; }
}
public sealed class SeguimientoAlertaRequest { [Required,StringLength(1000)] public string Comentario { get; set; }=string.Empty; }
public sealed class EstadoAlertaRequest { [Required,StringLength(20)] public string Estado { get; set; }=string.Empty; }
public sealed record ResultadoAlertaDto(long Id);
public readonly record struct AlcanceAlerta(int UsuarioId,bool EsAdministrador);

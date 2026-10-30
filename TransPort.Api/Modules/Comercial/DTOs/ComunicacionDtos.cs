using System.ComponentModel.DataAnnotations;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Modules.Comercial.DTOs;

public sealed record ComunicacionListadoDto(
    long ComunicacionHiloId, string Tipo, string Asunto, string Estado,
    int? ClienteId, string? Cliente, int? GiroNegocioId, string? Giro, long? PedidoId,
    int? ResponsableUsuarioId, string? Responsable, string? ModuloOrigen,
    long? RegistroOrigenId, DateTime UltimaActividad, DateTime FechaCreacion, int Mensajes);

public sealed record ComunicacionMensajeDto(
    long ComunicacionMensajeId, int UsuarioId, string NombreUsuario,
    string Mensaje, bool EsInterno, DateTime Fecha);

public sealed record ComunicacionDetalleDto(
    long ComunicacionHiloId, string Tipo, string Asunto, string Estado,
    int? ClienteId, string? Cliente, int? GiroNegocioId, string? Giro, long? PedidoId,
    int? ResponsableUsuarioId, string? Responsable, string? ModuloOrigen,
    long? RegistroOrigenId, string CreadoPor, DateTime UltimaActividad,
    DateTime FechaCreacion, DateTime? FechaModificacion,
    IReadOnlyList<ComunicacionMensajeDto> Mensajes);

public sealed record ComunicacionPedidoOpcionDto(long Id, string Nombre);
public sealed record ComunicacionOpcionesDto(
    IReadOnlyList<CatalogoDto> Clientes,
    IReadOnlyList<CatalogoDto> Giros,
    IReadOnlyList<ComunicacionPedidoOpcionDto> Pedidos,
    IReadOnlyList<CatalogoDto> Responsables);

public sealed class CrearComunicacionRequest
{
    [Required, StringLength(20)] public string Tipo { get; set; } = "Cliente";
    public int? ClienteId { get; set; }
    public int? GiroNegocioId { get; set; }
    public long? PedidoId { get; set; }
    [Required, StringLength(180, MinimumLength = 3)] public string Asunto { get; set; } = string.Empty;
    [Required, StringLength(2000, MinimumLength = 2)] public string MensajeInicial { get; set; } = string.Empty;
    [StringLength(50)] public string? ModuloOrigen { get; set; }
    public long? RegistroOrigenId { get; set; }
}

public sealed class CrearMensajeComunicacionRequest
{
    [Required, StringLength(2000, MinimumLength = 1)] public string Mensaje { get; set; } = string.Empty;
    public bool EsInterno { get; set; }
}

public sealed class GestionComunicacionRequest
{
    [Required, StringLength(20)] public string Estado { get; set; } = "Abierta";
    public int? ResponsableUsuarioId { get; set; }
}

public readonly record struct AlcanceComunicacion(int UsuarioId, bool EsAdministrador, bool EsCliente);

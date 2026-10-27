using System.ComponentModel.DataAnnotations;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Modules.Comercial.DTOs;

public sealed record PedidoListadoDto(
    long PedidoId, int ClienteId, string Cliente, int GiroNegocioId, string Giro,
    string TipoSolicitud, string Titulo, string Estado, DateTime? FechaRequerida,
    decimal? MontoCotizado, int? VendedorUsuarioId, string? Vendedor,
    DateTime FechaCreacion, DateTime? FechaModificacion);

public sealed record PedidoHistorialDto(
    long PedidoHistorialId, int UsuarioId, string NombreUsuario,
    string? EstadoAnterior, string EstadoNuevo, string? Comentario, DateTime Fecha);

public sealed record PedidoDocumentoDto(
    long PedidoDocumentoId, int UsuarioId, string NombreUsuario,
    string Nombre, string TipoDocumento, string Url, DateTime FechaCreacion);

public sealed record PedidoDetalleDto(
    long PedidoId, int ClienteId, string Cliente, int GiroNegocioId, string Giro,
    int SolicitanteUsuarioId, string Solicitante, int? VendedorUsuarioId, string? Vendedor,
    string TipoSolicitud, string Titulo, string Descripcion, string Estado,
    DateTime? FechaRequerida, decimal? MontoCotizado, DateTime? FechaReunionUtc,
    string? EnlaceReunion, DateTime FechaCreacion, DateTime? FechaModificacion,
    IReadOnlyList<PedidoHistorialDto> Historial, IReadOnlyList<PedidoDocumentoDto> Documentos);

public sealed record PedidoOpcionesDto(
    IReadOnlyList<CatalogoDto> Clientes,
    IReadOnlyList<CatalogoDto> Giros,
    IReadOnlyList<CatalogoDto> Vendedores);

public sealed class CrearPedidoRequest
{
    [Range(1, int.MaxValue)] public int ClienteId { get; set; }
    [Range(1, int.MaxValue)] public int GiroNegocioId { get; set; }
    [Required, StringLength(30)] public string TipoSolicitud { get; set; } = string.Empty;
    [Required, StringLength(180, MinimumLength = 3)] public string Titulo { get; set; } = string.Empty;
    [Required, StringLength(2000, MinimumLength = 5)] public string Descripcion { get; set; } = string.Empty;
    [DataType(DataType.Date)] public DateTime? FechaRequerida { get; set; }
    public DateTime? FechaReunionUtc { get; set; }
}

public sealed class GestionPedidoRequest
{
    [Required, StringLength(30)] public string Estado { get; set; } = string.Empty;
    public int? VendedorUsuarioId { get; set; }
    [Range(0, 9999999999999999.99)] public decimal? MontoCotizado { get; set; }
    public DateTime? FechaReunionUtc { get; set; }
    [Url, StringLength(500)] public string? EnlaceReunion { get; set; }
    [StringLength(1000)] public string? Comentario { get; set; }
}

public sealed class AgregarComentarioPedidoRequest
{
    [Required, StringLength(1000, MinimumLength = 2)] public string Comentario { get; set; } = string.Empty;
}

public sealed class AgregarDocumentoPedidoRequest
{
    [Required, StringLength(200, MinimumLength = 2)] public string Nombre { get; set; } = string.Empty;
    [Required, StringLength(60, MinimumLength = 2)] public string TipoDocumento { get; set; } = string.Empty;
    [Required, Url, StringLength(1000)] public string Url { get; set; } = string.Empty;
}

public readonly record struct AlcancePedido(int UsuarioId, bool EsAdministrador, bool EsCliente);

using System.ComponentModel.DataAnnotations;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Modules.Integraciones.DTOs;

public sealed record IntegracionListadoDto(
    long IntegracionEventoId,string Canal,string Direccion,string SocioTipo,string SocioNombre,
    string Operacion,string ClaveIdempotencia,string?DocumentoExterno,string Estado,int Intentos,
    string?Error,int?InventarioArticuloId,string?ArticuloCodigo,string?Articulo,int?SedeId,string?Sede,
    decimal?Cantidad,long?InventarioMovimientoId,string NombreUsuario,DateTime?FechaProcesamiento,DateTime FechaCreacion);

public sealed record IntegracionDetalleDto(
    long IntegracionEventoId,string Canal,string Direccion,string SocioTipo,string SocioNombre,
    string Operacion,string ClaveIdempotencia,string?DocumentoExterno,string Contenido,string Estado,
    int Intentos,string?Error,int?InventarioArticuloId,string?ArticuloCodigo,string?Articulo,string?UnidadMedida,
    int?SedeId,string?Sede,decimal?Cantidad,long?InventarioMovimientoId,string NombreUsuario,
    DateTime?FechaProcesamiento,DateTime FechaCreacion,DateTime?FechaModificacion);

public sealed record IntegracionOpcionesDto(
    IReadOnlyList<CatalogoDto> Articulos,IReadOnlyList<CatalogoDto> Sedes);

public sealed class SimularIntegracionRequest
{
    [Required,RegularExpression("REST|Webhook|CSV")]public string Canal{get;set;}="Webhook";
    [Required,RegularExpression("Entrada|Salida")]public string Direccion{get;set;}="Entrada";
    [Required,RegularExpression("Cliente|Proveedor|Socio")]public string SocioTipo{get;set;}="Proveedor";
    [Required,StringLength(180,MinimumLength=2)]public string SocioNombre{get;set;}=string.Empty;
    [Required,RegularExpression("RecepcionMateriaPrima|EstadoPedido|Notificacion|IntercambioDatos")]public string Operacion{get;set;}="RecepcionMateriaPrima";
    [Required,StringLength(120,MinimumLength=3)]public string ClaveIdempotencia{get;set;}=string.Empty;
    [StringLength(120)]public string?DocumentoExterno{get;set;}
    [Required,StringLength(4000,MinimumLength=2)]public string Contenido{get;set;}=string.Empty;
    public int?InventarioArticuloId{get;set;}
    public int?SedeId{get;set;}
    [Range(0.001,999999999999999.999)]public decimal?Cantidad{get;set;}
}

public readonly record struct AlcanceIntegracion(int UsuarioId,bool EsAdministrador);

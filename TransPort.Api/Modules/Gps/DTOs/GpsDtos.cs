using System.ComponentModel.DataAnnotations;using TransPort.Api.Modules.Shared.DTOs;
namespace TransPort.Api.Modules.Gps.DTOs;
public sealed record GpsDispositivoResumenDto(int GpsDispositivoId,string IdentificadorExterno,string NombreActivo,int?TransporteVehiculoId,string?Placa,int?MaquinariaEquipoId,string?MaquinariaCodigo,string Proveedor,decimal VelocidadMaxima,bool EsActivo,DateTime?UltimaSincronizacion,DateTime?FechaEvento,decimal?Latitud,decimal?Longitud,decimal?Velocidad,decimal?HorasUso,decimal?Kilometraje,string?Evento,int AlertasAbiertas);
public sealed record GpsAlertaDto(long GpsAlertaId,int GpsDispositivoId,string NombreActivo,string Tipo,string Severidad,string Mensaje,bool Atendida,DateTime Fecha,DateTime?FechaAtencion,string?AtendidaPor);
public sealed record GpsPosicionDto(long GpsPosicionId,int GpsDispositivoId,DateTime FechaEvento,decimal Latitud,decimal Longitud,decimal Velocidad,decimal?HorasUso,decimal?Kilometraje,string?Evento,string OrigenDato,string?DatosFuente,DateTime Recibido);
public sealed record GpsResumenDto(IReadOnlyList<GpsDispositivoResumenDto>Dispositivos,IReadOnlyList<GpsAlertaDto>Alertas);
public sealed record GpsOpcionesDto(IReadOnlyList<CatalogoDto>Vehiculos,IReadOnlyList<CatalogoDto>Maquinarias);
public sealed class CrearGpsDispositivoRequest{[Required,StringLength(100,MinimumLength=2)]public string IdentificadorExterno{get;set;}="";[Required,StringLength(160,MinimumLength=2)]public string NombreActivo{get;set;}="";public int?VehiculoId{get;set;}public int?MaquinariaId{get;set;}[Required,StringLength(80)]public string Proveedor{get;set;}="GPS-Inversiones";[Range(1,300)]public decimal VelocidadMaxima{get;set;}=80;}
public sealed class SimularGpsRequest
{
 [Range(1,int.MaxValue)]public int DispositivoId{get;set;}
 [Required,StringLength(2000)]public string DatosFuente{get;set;}="{\"latitud\":14.634915,\"longitud\":-90.506882,\"velocidad\":35.5,\"horasUso\":125.4,\"kilometraje\":48210.7,\"evento\":\"Posicion Ciudad de Guatemala\"}";
}
public sealed class GpsEventoFuenteDto{public DateTime?FechaEvento{get;set;}public decimal Latitud{get;set;}public decimal Longitud{get;set;}public decimal Velocidad{get;set;}public decimal?HorasUso{get;set;}public decimal?Kilometraje{get;set;}public string?Evento{get;set;}}
public sealed record ResultadoGpsDto(long Id);public readonly record struct AlcanceGps(int UsuarioId,bool EsAdministrador);

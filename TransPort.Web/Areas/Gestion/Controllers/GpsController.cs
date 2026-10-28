using Microsoft.AspNetCore.Authorization;using Microsoft.AspNetCore.Mvc;using TransPort.Web.Models;using TransPort.Web.Services;
namespace TransPort.Web.Areas.Gestion.Controllers;
[Area("Gestion"),Authorize(Roles="AdministradorGeneral,Gerente,Empleado,Operativo"),Route("gestion/gps")]
public sealed class GpsController(ITransportApiClient api,ILogger<GpsController> log):Controller
{
 [HttpGet("")]public async Task<IActionResult>Index(CancellationToken ct)=>View(new GpsPaginaViewModel{Resumen=await api.GpsResumenAsync(ct),Opciones=await api.GpsOpcionesAsync(ct)});
 [HttpPost("dispositivos"),Authorize(Roles="AdministradorGeneral,Gerente")]public async Task<IActionResult>Crear(GpsDispositivoCrearViewModel m,CancellationToken ct){try{await api.CrearGpsDispositivoAsync(m,ct);TempData["Exito"]="Dispositivo registrado.";}catch(TransportApiException e){log.LogWarning(e,"No se creó GPS");TempData["Error"]="No fue posible registrar el dispositivo.";}return RedirectToAction(nameof(Index));}
 [HttpPost("simular")]public async Task<IActionResult>Simular(int dispositivoId,string datosFuente,CancellationToken ct){try{await api.SimularGpsAsync(dispositivoId,datosFuente,ct);TempData["Exito"]="Dato externo simulado correctamente.";}catch(TransportApiException e){log.LogWarning(e,"No se simuló GPS");TempData["Error"]="El texto debe ser JSON válido con coordenadas y velocidad.";}return RedirectToAction(nameof(Index));}
 [HttpGet("dispositivos/{id:int}")]public async Task<IActionResult>Recorrido(int id,DateTime?desde,DateTime?hasta,CancellationToken ct){ViewBag.DispositivoId=id;return View(await api.GpsRecorridoAsync(id,desde,hasta,ct));}
 [HttpPost("alertas/{id:long}")]public async Task<IActionResult>Atender(long id,CancellationToken ct){await api.AtenderGpsAlertaAsync(id,ct);return RedirectToAction(nameof(Index));}
 [HttpPost("dispositivos/{id:int}/eliminar"),Authorize(Roles="AdministradorGeneral")]public async Task<IActionResult>Eliminar(int id,CancellationToken ct){await api.EliminarGpsDispositivoAsync(id,ct);return RedirectToAction(nameof(Index));}
}

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Areas.Gestion.Controllers;

[Area("Gestion"),Authorize(Roles="AdministradorGeneral,Gerente,Empleado,Operativo"),Route("gestion/extracciones")]
public sealed class ExtraccionesController(ITransportApiClient api,ILogger<ExtraccionesController> log):Controller
{
 [HttpGet("")]public async Task<IActionResult>Index(string?estado,int?sedeId,DateTime?fechaDesde,DateTime?fechaHasta,CancellationToken ct){try{return View(new ExtraccionPaginaViewModel{Estado=estado,SedeId=sedeId,FechaDesde=fechaDesde,FechaHasta=fechaHasta,Jornadas=await api.ExtraccionesAsync(estado,sedeId,fechaDesde,fechaHasta,ct),Opciones=await api.ExtraccionOpcionesAsync(ct)});}catch(Exception e)when(e is HttpRequestException or TransportApiException){log.LogError(e,"No se cargó extracción");TempData["Error"]="No fue posible consultar las jornadas.";return View(new ExtraccionPaginaViewModel());}}
 [HttpPost("crear")]public async Task<IActionResult>Crear(ExtraccionCrearViewModel m,CancellationToken ct){if(!ModelState.IsValid||m.CantidadRechazada>=m.CantidadExtraida){TempData["Error"]="Revise los datos y las cantidades de la jornada.";return RedirectToAction(nameof(Index));}try{var id=await api.CrearExtraccionAsync(m,ct);TempData["Exito"]="Jornada registrada.";return RedirectToAction(nameof(Detalle),new{id});}catch(TransportApiException e){log.LogWarning(e,"No se creó jornada");TempData["Error"]="No fue posible registrar la jornada; revise planta, artículo y permisos.";return RedirectToAction(nameof(Index));}}
 [HttpGet("{id:long}")]public async Task<IActionResult>Detalle(long id,CancellationToken ct){var x=await api.ExtraccionAsync(id,ct);return x is null?NotFound():View(x);}
 [HttpPost("{id:long}/estado")]public async Task<IActionResult>Estado(long id,string estado,string?comentario,CancellationToken ct){try{await api.CambiarEstadoExtraccionAsync(id,estado,comentario,ct);TempData["Exito"]="Estado actualizado.";}catch(TransportApiException e){log.LogWarning(e,"No cambió estado de extracción");TempData["Error"]="No fue posible cambiar el estado; revise la transición, permisos e inventario.";}return RedirectToAction(nameof(Detalle),new{id});}
 [HttpPost("{id:long}/eliminar"),Authorize(Roles="AdministradorGeneral")]public async Task<IActionResult>Eliminar(long id,CancellationToken ct){await api.EliminarExtraccionAsync(id,ct);return RedirectToAction(nameof(Index));}
}

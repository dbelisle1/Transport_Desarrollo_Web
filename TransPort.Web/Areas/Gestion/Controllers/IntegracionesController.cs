using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Areas.Gestion.Controllers;

[Area("Gestion")]
[Authorize(Roles="AdministradorGeneral,Gerente,Empleado,Operativo")]
[Route("gestion/integraciones")]
public sealed class IntegracionesController(ITransportApiClient api):Controller
{
    [HttpGet("")]
    public async Task<IActionResult> Index(string?estado,string?canal,string?busqueda,CancellationToken ct)
    {
        var options=await api.IntegracionOpcionesAsync(ct);var now=DateTime.UtcNow;
        var create=new IntegracionSimularViewModel{ClaveIdempotencia=$"DEMO-{now:yyyyMMddHHmmssfff}",DocumentoExterno=$"REC-{now:yyyyMMddHHmmss}",InventarioArticuloId=options.Articulos.FirstOrDefault()?.Id,SedeId=options.Sedes.FirstOrDefault()?.Id};
        return View(new IntegracionPaginaViewModel{Estado=estado,Canal=canal,Busqueda=busqueda,Eventos=await api.IntegracionesAsync(estado,canal,busqueda,ct),Opciones=options,Nueva=create});
    }
    [HttpPost("simular")]
    public async Task<IActionResult> Simular(IntegracionSimularViewModel model,CancellationToken ct)
    {
        if(!ModelState.IsValid){TempData["Error"]="Revise los datos de la simulación externa.";return RedirectToAction(nameof(Index));}
        try{var id=await api.SimularIntegracionAsync(model,ct);TempData["Exito"]="Dato externo simulado y procesado.";return RedirectToAction(nameof(Detalle),new{id});}
        catch(TransportApiException ex){TempData["Error"]=$"La simulación se registró con error: {ex.Message}";return RedirectToAction(nameof(Index));}
    }
    [HttpGet("{id:long}")]
    public async Task<IActionResult> Detalle(long id,CancellationToken ct){var x=await api.IntegracionAsync(id,ct);return x is null?NotFound():View(x);}
    [HttpPost("{id:long}/reintentar")]
    public async Task<IActionResult> Reintentar(long id,CancellationToken ct){try{await api.ReintentarIntegracionAsync(id,ct);TempData["Exito"]="Evento reprocesado.";}catch(TransportApiException ex){TempData["Error"]=$"El reintento continúa con error: {ex.Message}";}return RedirectToAction(nameof(Detalle),new{id});}
    [HttpPost("{id:long}/eliminar")][Authorize(Roles="AdministradorGeneral")]
    public async Task<IActionResult> Eliminar(long id,CancellationToken ct){await api.EliminarIntegracionAsync(id,ct);TempData["Exito"]="Evento eliminado lógicamente.";return RedirectToAction(nameof(Index));}
}

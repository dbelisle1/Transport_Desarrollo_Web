using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Areas.Gestion.Controllers;
[Area("Gestion"),Authorize(Roles="AdministradorGeneral,Gerente,Empleado,Operativo"),Route("gestion/inventarios")]
public sealed class InventariosController(ITransportApiClient api,ILogger<InventariosController> logger):Controller
{
    [HttpGet("")]public async Task<IActionResult> Index(string? busqueda,int? giroId,int? sedeId,bool soloBajoMinimo,CancellationToken ct)
    {
        try{return View(new InventarioPaginaViewModel{Busqueda=busqueda,GiroId=giroId,SedeId=sedeId,SoloBajoMinimo=soloBajoMinimo,Existencias=await api.InventarioAsync(busqueda,giroId,sedeId,soloBajoMinimo,ct),Movimientos=await api.InventarioMovimientosAsync(null,50,ct),Opciones=await api.InventarioOpcionesAsync(ct)});}
        catch(Exception ex)when(ex is HttpRequestException or TransportApiException){logger.LogError(ex,"No fue posible cargar inventario.");TempData["Error"]="No fue posible consultar el inventario.";return View(new InventarioPaginaViewModel());}
    }
    [HttpPost("articulos"),Authorize(Roles="AdministradorGeneral,Gerente")]
    public async Task<IActionResult> CrearArticulo(InventarioArticuloFormModel model,CancellationToken ct){if(!ModelState.IsValid){TempData["Error"]="Revise los datos del artículo.";return RedirectToAction(nameof(Index));}try{await api.CrearInventarioArticuloAsync(model,ct);TempData["Exito"]="Artículo creado.";}catch(TransportApiException ex){logger.LogWarning(ex,"No se creó artículo.");TempData["Error"]="No fue posible crear el artículo; verifique el código y el giro.";}return RedirectToAction(nameof(Index));}
    [HttpPost("movimientos")]
    public async Task<IActionResult> Movimiento(InventarioMovimientoFormModel model,CancellationToken ct){if(!ModelState.IsValid){TempData["Error"]="Revise los datos del movimiento.";return RedirectToAction(nameof(Index));}try{await api.RegistrarInventarioMovimientoAsync(model,ct);TempData["Exito"]="Movimiento registrado.";}catch(TransportApiException ex){logger.LogWarning(ex,"No se registró movimiento.");TempData["Error"]="No fue posible registrar el movimiento; revise sedes y disponibilidad.";}return RedirectToAction(nameof(Index));}
}

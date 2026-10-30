using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Areas.Gestion.Controllers;

[Area("Gestion"),Authorize(Roles="AdministradorGeneral,Gerente,Empleado,Operativo"),Route("gestion/finanzas")]
public sealed class FinanzasController(ITransportApiClient api):Controller
{
    [HttpGet("")] public async Task<IActionResult> Index(short? anio,byte? mes,int? giroId,int? sedeId,CancellationToken ct)=>View(new FinanzaPaginaViewModel{Anio=anio,Mes=mes,GiroId=giroId,SedeId=sedeId,Presupuestos=await api.PresupuestosAsync(anio,mes,giroId,sedeId,ct),Opciones=await api.FinanzaOpcionesAsync(ct)});
    [HttpPost("crear"),Authorize(Roles="AdministradorGeneral,Gerente")] public async Task<IActionResult> Crear(PresupuestoCrearViewModel model,CancellationToken ct){var id=await api.CrearPresupuestoAsync(model,ct);return RedirectToAction(nameof(Detalle),new{id});}
    [HttpGet("{id:long}")] public async Task<IActionResult> Detalle(long id,CancellationToken ct){var x=await api.PresupuestoAsync(id,ct);return x is null?NotFound():View(x);}
    [HttpPost("{id:long}/gastos")] public async Task<IActionResult> Gasto(long id,GastoCrearViewModel model,CancellationToken ct){await api.RegistrarGastoAsync(id,model,ct);return RedirectToAction(nameof(Detalle),new{id});}
    [HttpPost("{id:long}/estado"),Authorize(Roles="AdministradorGeneral,Gerente")] public async Task<IActionResult> Estado(long id,string estado,CancellationToken ct){await api.EstadoPresupuestoAsync(id,estado,ct);return RedirectToAction(nameof(Detalle),new{id});}
    [HttpPost("{id:long}/eliminar"),Authorize(Roles="AdministradorGeneral")] public async Task<IActionResult> Eliminar(long id,CancellationToken ct){await api.EliminarPresupuestoAsync(id,ct);return RedirectToAction(nameof(Index));}
    [HttpGet("ingresos")] public async Task<IActionResult> Ingresos(short? anio,byte? mes,int? giroId,int? sedeId,CancellationToken ct)=>View(new IngresoPaginaViewModel{Anio=anio,Mes=mes,GiroId=giroId,SedeId=sedeId,Ingresos=await api.IngresosAsync(anio,mes,giroId,sedeId,ct),Opciones=await api.IngresoOpcionesAsync(ct)});
    [HttpPost("ingresos/crear")] public async Task<IActionResult> CrearIngreso(IngresoCrearViewModel model,CancellationToken ct){await api.CrearIngresoAsync(model,ct);return RedirectToAction(nameof(Ingresos));}
    [HttpPost("ingresos/{id:long}/eliminar"),Authorize(Roles="AdministradorGeneral")] public async Task<IActionResult> EliminarIngreso(long id,CancellationToken ct){await api.EliminarIngresoAsync(id,ct);return RedirectToAction(nameof(Ingresos));}
}

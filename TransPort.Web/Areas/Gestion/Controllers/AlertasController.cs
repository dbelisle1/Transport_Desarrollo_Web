using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Areas.Gestion.Controllers;

[Area("Gestion"),Authorize(Roles="AdministradorGeneral,Gerente,Vendedor,Empleado,Operativo"),Route("gestion/alertas")]
public sealed class AlertasController(ITransportApiClient api):Controller
{
    [HttpGet("")] public async Task<IActionResult> Index(string? estado,bool soloPendientes,CancellationToken ct)=>View(new AlertaPaginaViewModel{Estado=estado,SoloPendientes=soloPendientes,Alertas=await api.AlertasAsync(estado,soloPendientes,ct),Opciones=await api.AlertaOpcionesAsync(ct)});
    [HttpPost("crear"),Authorize(Roles="AdministradorGeneral,Gerente")] public async Task<IActionResult> Crear(AlertaCrearViewModel model,CancellationToken ct){var id=await api.CrearAlertaAsync(model,ct);return RedirectToAction(nameof(Detalle),new{id});}
    [HttpGet("{id:long}")] public async Task<IActionResult> Detalle(long id,CancellationToken ct){var x=await api.AlertaAsync(id,ct);return x is null?NotFound():View(x);}
    [HttpPost("{id:long}/leer")] public async Task<IActionResult> Leer(long id,CancellationToken ct){await api.MarcarAlertaLeidaAsync(id,ct);return RedirectToAction(nameof(Detalle),new{id});}
    [HttpPost("{id:long}/seguimientos")] public async Task<IActionResult> Seguimiento(long id,string comentario,CancellationToken ct){await api.SeguimientoAlertaAsync(id,comentario,ct);return RedirectToAction(nameof(Detalle),new{id});}
    [HttpPost("{id:long}/estado"),Authorize(Roles="AdministradorGeneral,Gerente")] public async Task<IActionResult> Estado(long id,string estado,CancellationToken ct){await api.EstadoAlertaAsync(id,estado,ct);return RedirectToAction(nameof(Detalle),new{id});}
    [HttpPost("{id:long}/eliminar"),Authorize(Roles="AdministradorGeneral")] public async Task<IActionResult> Eliminar(long id,CancellationToken ct){await api.EliminarAlertaAsync(id,ct);return RedirectToAction(nameof(Index));}
}

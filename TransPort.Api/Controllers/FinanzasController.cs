using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Modules.Finanzas.DTOs;
using TransPort.Api.Modules.Finanzas.Repositories;

namespace TransPort.Api.Controllers;

[ApiController,Route("api/finanzas"),Authorize(Roles="AdministradorGeneral,Gerente,Empleado,Operativo")]
public sealed class FinanzasController(IFinanzaRepository finanzas):ControllerBase
{
    [HttpGet] public Task<IReadOnlyList<PresupuestoListadoDto>> Listar(short? anio,byte? mes,int? giroId,int? sedeId,CancellationToken ct)=>finanzas.ListarAsync(anio,mes,giroId,sedeId,Alcance(),ct);
    [HttpGet("opciones")] public Task<FinanzaOpcionesDto> Opciones(CancellationToken ct)=>finanzas.OpcionesAsync(Alcance(),ct);
    [HttpGet("{id:long}")] public async Task<IActionResult> Obtener(long id,CancellationToken ct){var x=await finanzas.ObtenerAsync(id,Alcance(),ct);return x is null?NotFound():Ok(x);}
    [HttpPost,Authorize(Roles="AdministradorGeneral,Gerente")] public async Task<IActionResult> Crear(CrearPresupuestoRequest request,CancellationToken ct)=>Ok(new ResultadoFinanzaDto(await finanzas.CrearAsync(request,Alcance(),ct)));
    [HttpPost("{id:long}/gastos")] public async Task<IActionResult> Gasto(long id,RegistrarGastoRequest request,CancellationToken ct)=>Ok(new ResultadoFinanzaDto(await finanzas.RegistrarGastoAsync(id,request,Alcance(),ct)));
    [HttpPut("{id:long}/estado"),Authorize(Roles="AdministradorGeneral,Gerente")] public async Task<IActionResult> Estado(long id,EstadoPresupuestoRequest request,CancellationToken ct)=>await finanzas.ActualizarEstadoAsync(id,request.Estado,Alcance(),ct)?NoContent():NotFound();
    [HttpDelete("{id:long}"),Authorize(Roles="AdministradorGeneral")] public async Task<IActionResult> Eliminar(long id,CancellationToken ct)=>await finanzas.EliminarAsync(id,Alcance().UsuarioId,ct)?NoContent():NotFound();
    private AlcanceFinanza Alcance()=>new(int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!),User.IsInRole("AdministradorGeneral"));
}

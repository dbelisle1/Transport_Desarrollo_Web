using System.Security.Claims;using System.Text.Json;using Microsoft.AspNetCore.Authorization;using Microsoft.AspNetCore.Mvc;using TransPort.Api.Modules.Gps.DTOs;using TransPort.Api.Modules.Gps.Repositories;
namespace TransPort.Api.Controllers;
[ApiController,Route("api/gps"),Authorize(Roles="AdministradorGeneral,Gerente,Empleado,Operativo")]
public sealed class GpsController(IGpsRepository repo):ControllerBase
{
 private static readonly JsonSerializerOptions JsonOptions=new(JsonSerializerDefaults.Web);
 [HttpGet]public Task<GpsResumenDto>Resumen(CancellationToken ct)=>repo.ResumenAsync(A(),ct);[HttpGet("opciones")]public Task<GpsOpcionesDto>Opciones(CancellationToken ct)=>repo.OpcionesAsync(A(),ct);[HttpGet("dispositivos/{id:int}/recorrido")]public Task<IReadOnlyList<GpsPosicionDto>>Recorrido(int id,DateTime?desde,DateTime?hasta,CancellationToken ct)=>repo.RecorridoAsync(id,desde,hasta,A(),ct);
 [HttpPost("dispositivos"),Authorize(Roles="AdministradorGeneral,Gerente")]public async Task<IActionResult>Crear(CrearGpsDispositivoRequest x,CancellationToken ct)=>Ok(new ResultadoGpsDto(await repo.CrearAsync(x,A(),ct)));
 [HttpPost("simular")]public async Task<IActionResult>Simular(SimularGpsRequest x,CancellationToken ct){GpsEventoFuenteDto?e;try{e=JsonSerializer.Deserialize<GpsEventoFuenteDto>(x.DatosFuente,JsonOptions);}catch(JsonException){return BadRequest(new{mensaje="DatosFuente debe contener JSON válido."});}if(e is null||e.Latitud is<-90 or>90||e.Longitud is<-180 or>180||e.Velocidad<0)return BadRequest(new{mensaje="Coordenadas o velocidad inválidas."});return Ok(new ResultadoGpsDto(await repo.SimularAsync(x.DispositivoId,e,x.DatosFuente,A(),ct)));}
 [HttpPut("alertas/{id:long}/atender")]public async Task<IActionResult>Atender(long id,CancellationToken ct)=>await repo.AtenderAsync(id,A(),ct)?NoContent():NotFound();[HttpDelete("dispositivos/{id:int}"),Authorize(Roles="AdministradorGeneral")]public async Task<IActionResult>Eliminar(int id,CancellationToken ct)=>await repo.EliminarAsync(id,A().UsuarioId,ct)?NoContent():NotFound();private AlcanceGps A()=>new(int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!),User.IsInRole("AdministradorGeneral"));
}

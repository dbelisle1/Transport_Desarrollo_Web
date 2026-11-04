using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Modules.Inventarios.DTOs;
using TransPort.Api.Modules.Inventarios.Repositories;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Controllers;

[ApiController,Route("api/inventarios")]
[Authorize(Roles="AdministradorGeneral,Gerente,Empleado,Operativo")]
public sealed class InventariosController(IInventarioRepository inventario):ControllerBase
{
    private static readonly HashSet<string> Tipos=new(StringComparer.OrdinalIgnoreCase){"Entrada","Salida","Transferencia","Reserva","Liberacion"};
    [HttpGet]public Task<IReadOnlyList<InventarioExistenciaDto>> Listar([FromQuery]string? busqueda,[FromQuery]int? giroId,[FromQuery]int? sedeId,[FromQuery]bool soloBajoMinimo,CancellationToken ct)=>inventario.ListarAsync(busqueda,giroId,sedeId,soloBajoMinimo,Scope(),ct);
    [HttpGet("movimientos")]public Task<IReadOnlyList<InventarioMovimientoDto>> Movimientos([FromQuery]int? articuloId,CancellationToken ct,[FromQuery]int limite=100)=>inventario.MovimientosAsync(articuloId,limite,Scope(),ct);
    [HttpGet("opciones")]public Task<InventarioOpcionesDto> Opciones(CancellationToken ct)=>inventario.OpcionesAsync(Scope(),ct);
    [HttpPost("articulos"),Authorize(Roles="AdministradorGeneral,Gerente")]
    public async Task<IActionResult> CrearArticulo(CrearInventarioArticuloRequest request,CancellationToken ct){var id=await inventario.CrearArticuloAsync(request,Scope(),ct);return Ok(new ResultadoIdDto(id));}
    [HttpPost("movimientos")]
    public async Task<IActionResult> Registrar(RegistrarInventarioMovimientoRequest request,CancellationToken ct){if(!Tipos.Contains(request.Tipo)){ModelState.AddModelError(nameof(request.Tipo),"Tipo inválido.");return ValidationProblem();}var id=await inventario.RegistrarMovimientoAsync(request,Scope(),ct);return Ok(new ResultadoMovimientoInventarioDto(id));}
    [HttpDelete("articulos/{id:int}"),Authorize(Roles="AdministradorGeneral")]
    public async Task<IActionResult> EliminarArticulo(int id,CancellationToken ct)=>await inventario.EliminarArticuloAsync(id,Scope().UsuarioId,ct)?NoContent():NotFound();
    private AlcanceInventario Scope()=>new(int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!),User.IsInRole("AdministradorGeneral"));
}

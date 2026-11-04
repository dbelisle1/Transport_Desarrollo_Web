using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Controllers;
using TransPort.Api.Modules.Inventarios.DTOs;
using TransPort.Api.Modules.Inventarios.Repositories;

namespace TransPort.Api.Tests;
public sealed class InventariosControllerTests
{
    [Fact]public async Task Listar_EmpleadoPropagaAlcanceRestringido(){var r=new Fake();var c=Controller(r,8,"Empleado");await c.Listar(null,null,null,false,default);Assert.Equal(new AlcanceInventario(8,false),r.Alcance);}
    [Fact]public async Task CrearArticulo_AdministradorPropagaIdentidad(){var r=new Fake();var c=Controller(r,3,"AdministradorGeneral");var x=await c.CrearArticulo(new(){GiroNegocioId=1,Codigo="A1",Nombre="Artículo",Categoria="Materia",UnidadMedida="kg"},default);Assert.IsType<OkObjectResult>(x);Assert.Equal(new AlcanceInventario(3,true),r.Alcance);}
    [Fact]public async Task Registrar_TipoInvalido_NoInvocaRepositorio(){var r=new Fake();var c=Controller(r,3,"AdministradorGeneral");var x=await c.Registrar(new(){InventarioArticuloId=1,Tipo="Otro",Cantidad=1},default);Assert.IsType<ObjectResult>(x);Assert.False(r.MovimientoInvocado);}
    [Fact]public async Task Registrar_EntradaValida_DevuelveId(){var r=new Fake{MovimientoId=15};var c=Controller(r,3,"AdministradorGeneral");var x=Assert.IsType<OkObjectResult>(await c.Registrar(new(){InventarioArticuloId=1,Tipo="Entrada",Cantidad=1,SedeDestinoId=2},default));Assert.Equal(15,Assert.IsType<ResultadoMovimientoInventarioDto>(x.Value).Id);}
    [Fact]public void Controlador_NoAutorizaClientes(){var a=typeof(InventariosController).GetCustomAttributes(typeof(AuthorizeAttribute),true).Cast<AuthorizeAttribute>().Single();Assert.DoesNotContain("Cliente",a.Roles??"");Assert.Contains("Operativo",a.Roles??"");}
    private static InventariosController Controller(IInventarioRepository r,int id,params string[] roles){var claims=new List<Claim>{new(ClaimTypes.NameIdentifier,id.ToString())};claims.AddRange(roles.Select(x=>new Claim(ClaimTypes.Role,x)));return new(r){ControllerContext=new(){HttpContext=new DefaultHttpContext{User=new ClaimsPrincipal(new ClaimsIdentity(claims,"Test"))}}};}
    private sealed class Fake:IInventarioRepository
    {
        public AlcanceInventario? Alcance{get;private set;}public bool MovimientoInvocado{get;private set;}public long MovimientoId{get;init;}=1;
        public Task<IReadOnlyList<InventarioExistenciaDto>> ListarAsync(string? b,int? g,int? s,bool m,AlcanceInventario a,CancellationToken ct){Alcance=a;return Task.FromResult<IReadOnlyList<InventarioExistenciaDto>>([]);}
        public Task<IReadOnlyList<InventarioMovimientoDto>> MovimientosAsync(int? a,int l,AlcanceInventario x,CancellationToken ct)=>Task.FromResult<IReadOnlyList<InventarioMovimientoDto>>([]);
        public Task<InventarioOpcionesDto> OpcionesAsync(AlcanceInventario a,CancellationToken ct)=>Task.FromResult(new InventarioOpcionesDto([],[],[]));
        public Task<int> CrearArticuloAsync(CrearInventarioArticuloRequest x,AlcanceInventario a,CancellationToken ct){Alcance=a;return Task.FromResult(7);}
        public Task<long> RegistrarMovimientoAsync(RegistrarInventarioMovimientoRequest x,AlcanceInventario a,CancellationToken ct){Alcance=a;MovimientoInvocado=true;return Task.FromResult(MovimientoId);}
        public Task<bool> EliminarArticuloAsync(int id,int usuarioId,CancellationToken ct)=>Task.FromResult(true);
    }
}

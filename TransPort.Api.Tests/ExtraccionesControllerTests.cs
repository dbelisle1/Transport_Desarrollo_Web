using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Controllers;
using TransPort.Api.Modules.Extraccion.DTOs;
using TransPort.Api.Modules.Extraccion.Repositories;

namespace TransPort.Api.Tests;

public sealed class ExtraccionesControllerTests
{
    [Fact] public async Task Listar_PropagaAlcanceEmpleado(){var r=new Fake();await Controller(r,17,"Empleado").Listar(null,null,null,null,default);Assert.Equal(new AlcanceExtraccion(17,false),r.Alcance);}
    [Fact] public async Task Crear_DevuelveIdentificador(){var r=new Fake{Id=61};var result=Assert.IsType<OkObjectResult>(await Controller(r,1,"AdministradorGeneral").Crear(new(){SedeId=1,InventarioArticuloId=2,FechaOperacion=DateTime.Today,Turno="Diurno",FrenteExtraccion="Frente A",CantidadExtraida=10,CantidadRechazada=1,DestinoTipo="Inventario"},default));Assert.Equal(61,Assert.IsType<ResultadoExtraccionDto>(result.Value).Id);}
    [Fact] public async Task Obtener_Inexistente_DevuelveNotFound()=>Assert.IsType<NotFoundResult>(await Controller(new Fake(),1,"AdministradorGeneral").Obtener(999,default));
    [Fact] public async Task Estado_PropagaAlcance(){var r=new Fake();Assert.IsType<NoContentResult>(await Controller(r,8,"Operativo").Estado(2,new(){Estado="Confirmada"},default));Assert.Equal(new AlcanceExtraccion(8,false),r.Alcance);}
    [Fact] public void Controlador_ExcluyeCliente(){var a=typeof(ExtraccionesController).GetCustomAttributes(typeof(AuthorizeAttribute),true).Cast<AuthorizeAttribute>().Single();Assert.DoesNotContain("Cliente",a.Roles??"");Assert.Contains("Operativo",a.Roles??"");}

    private static ExtraccionesController Controller(IExtraccionRepository r,int id,params string[]roles){var claims=new List<Claim>{new(ClaimTypes.NameIdentifier,id.ToString())};claims.AddRange(roles.Select(x=>new Claim(ClaimTypes.Role,x)));return new(r){ControllerContext=new(){HttpContext=new DefaultHttpContext{User=new ClaimsPrincipal(new ClaimsIdentity(claims,"Test"))}}};}
    private sealed class Fake:IExtraccionRepository
    {
        public long Id{get;init;} public AlcanceExtraccion? Alcance{get;private set;}
        public Task<IReadOnlyList<ExtraccionListadoDto>> ListarAsync(string?e,int?s,DateTime?d,DateTime?h,AlcanceExtraccion a,CancellationToken ct){Alcance=a;return Task.FromResult<IReadOnlyList<ExtraccionListadoDto>>([]);}
        public Task<ExtraccionDetalleDto?> ObtenerAsync(long id,AlcanceExtraccion a,CancellationToken ct){Alcance=a;return Task.FromResult<ExtraccionDetalleDto?>(null);}
        public Task<ExtraccionOpcionesDto> OpcionesAsync(AlcanceExtraccion a,CancellationToken ct){Alcance=a;return Task.FromResult(new ExtraccionOpcionesDto([],[]));}
        public Task<long> CrearAsync(CrearExtraccionRequest x,AlcanceExtraccion a,CancellationToken ct){Alcance=a;return Task.FromResult(Id);}
        public Task<bool> CambiarEstadoAsync(long id,CambiarEstadoExtraccionRequest x,AlcanceExtraccion a,CancellationToken ct){Alcance=a;return Task.FromResult(true);}
        public Task<bool> EliminarAsync(long id,int u,CancellationToken ct)=>Task.FromResult(true);
    }
}

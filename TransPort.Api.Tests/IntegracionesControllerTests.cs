using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Controllers;
using TransPort.Api.Modules.Integraciones.DTOs;
using TransPort.Api.Modules.Integraciones.Repositories;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Tests;

public sealed class IntegracionesControllerTests
{
    [Fact]public async Task Listar_PropagaIdentidadYAlcance(){var r=new Fake();await Controller(r,8,"Empleado").Listar(null,null,null,default);Assert.Equal(new AlcanceIntegracion(8,false),r.Alcance);}
    [Fact]public async Task Simular_RetornaIdYPropagaSolicitud(){var r=new Fake{Id=23};var request=new SimularIntegracionRequest{Canal="Webhook",Direccion="Entrada",SocioTipo="Proveedor",SocioNombre="Demo",Operacion="IntercambioDatos",ClaveIdempotencia="ABC-123",Contenido="{}"};var x=Assert.IsType<CreatedAtActionResult>(await Controller(r,1,"AdministradorGeneral").Simular(request,default));Assert.Same(request,r.Request);Assert.Equal(23,Assert.IsType<ResultadoIdDto>(x.Value).Id);Assert.Equal(new AlcanceIntegracion(1,true),r.Alcance);}
    [Fact]public async Task Obtener_Inexistente_RetornaNotFound()=>Assert.IsType<NotFoundResult>(await Controller(new Fake(),2,"Operativo").Obtener(99,default));
    [Fact]public void Controlador_ExcluyeCliente(){var a=typeof(IntegracionesController).GetCustomAttributes(typeof(AuthorizeAttribute),true).Cast<AuthorizeAttribute>().Single();Assert.DoesNotContain("Cliente",a.Roles??string.Empty);Assert.Contains("Empleado",a.Roles??string.Empty);}
    [Fact]public void Eliminar_ExigeAdministrador(){var m=typeof(IntegracionesController).GetMethod(nameof(IntegracionesController.Eliminar))!;var a=m.GetCustomAttributes(typeof(AuthorizeAttribute),true).Cast<AuthorizeAttribute>().Single();Assert.Equal("AdministradorGeneral",a.Roles);}

    private static IntegracionesController Controller(IIntegracionRepository r,int id,params string[]roles){var c=new List<Claim>{new(ClaimTypes.NameIdentifier,id.ToString())};c.AddRange(roles.Select(x=>new Claim(ClaimTypes.Role,x)));return new(r){ControllerContext=new(){HttpContext=new DefaultHttpContext{User=new ClaimsPrincipal(new ClaimsIdentity(c,"Test"))}}};}
    private sealed class Fake:IIntegracionRepository
    {
        public long Id{get;init;}=1;public AlcanceIntegracion?Alcance{get;private set;}public SimularIntegracionRequest?Request{get;private set;}
        public Task<IReadOnlyList<IntegracionListadoDto>> ListarAsync(string?e,string?c,string?b,AlcanceIntegracion a,CancellationToken ct){Alcance=a;return Task.FromResult<IReadOnlyList<IntegracionListadoDto>>([]);}
        public Task<IntegracionDetalleDto?> ObtenerAsync(long id,AlcanceIntegracion a,CancellationToken ct){Alcance=a;return Task.FromResult<IntegracionDetalleDto?>(null);}
        public Task<IntegracionOpcionesDto> OpcionesAsync(AlcanceIntegracion a,CancellationToken ct){Alcance=a;return Task.FromResult(new IntegracionOpcionesDto([],[]));}
        public Task<long> SimularAsync(SimularIntegracionRequest x,AlcanceIntegracion a,CancellationToken ct){Request=x;Alcance=a;return Task.FromResult(Id);}
        public Task<long> ReintentarAsync(long id,AlcanceIntegracion a,CancellationToken ct){Alcance=a;return Task.FromResult(Id);}
        public Task<bool> EliminarAsync(long id,int usuarioId,CancellationToken ct)=>Task.FromResult(true);
    }
}

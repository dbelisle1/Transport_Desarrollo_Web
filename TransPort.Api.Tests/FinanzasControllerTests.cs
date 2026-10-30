using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Controllers;
using TransPort.Api.Modules.Finanzas.DTOs;
using TransPort.Api.Modules.Finanzas.Repositories;

namespace TransPort.Api.Tests;

public sealed class FinanzasControllerTests
{
    [Fact] public async Task Listar_PropagaAlcance(){var r=new Fake();await Controller(r,8,"Empleado").Listar(null,null,null,null,default);Assert.Equal(new AlcanceFinanza(8,false),r.Alcance);}
    [Fact] public async Task Crear_RetornaId(){var r=new Fake{Id=31};var x=Assert.IsType<OkObjectResult>(await Controller(r,1,"AdministradorGeneral").Crear(new(){GiroId=1,SedeId=1,Anio=2026,Mes=10,Nombre="Operación",Monto=100},default));Assert.Equal(31,Assert.IsType<ResultadoFinanzaDto>(x.Value).Id);}
    [Fact] public async Task Obtener_Inexistente_RetornaNotFound()=>Assert.IsType<NotFoundResult>(await Controller(new Fake(),1,"AdministradorGeneral").Obtener(99,default));
    [Fact] public async Task Gasto_PropagaAlcance(){var r=new Fake();Assert.IsType<OkObjectResult>(await Controller(r,5,"Operativo").Gasto(2,new(){Fecha=DateTime.Today,Categoria="Otro",Concepto="Prueba",Monto=10},default));Assert.Equal(new AlcanceFinanza(5,false),r.Alcance);}
    [Fact] public void Controlador_ExcluyeCliente(){var a=typeof(FinanzasController).GetCustomAttributes(typeof(AuthorizeAttribute),true).Cast<AuthorizeAttribute>().Single();Assert.DoesNotContain("Cliente",a.Roles??string.Empty);}
    [Fact] public async Task Ingresos_PropagaFiltrosYAlcance(){var r=new Fake();await Controller(r,12,"Empleado").Ingresos(2026,10,3,2,default);Assert.Equal(new AlcanceFinanza(12,false),r.Alcance);Assert.Equal((short)2026,r.Anio);Assert.Equal((byte)10,r.Mes);Assert.Equal(3,r.GiroId);Assert.Equal(2,r.SedeId);}
    [Fact] public async Task CrearIngreso_RetornaIdYPropagaSolicitud(){var r=new Fake{Id=77};var request=new CrearIngresoRequest{GiroId=1,SedeId=2,Fecha=DateTime.Today,Categoria="Servicio",Concepto="Cobro",Monto=250,OrigenModulo="Manual"};var x=Assert.IsType<OkObjectResult>(await Controller(r,4,"Operativo").CrearIngreso(request,default));Assert.Equal(77,Assert.IsType<ResultadoFinanzaDto>(x.Value).Id);Assert.Same(request,r.IngresoCreado);Assert.Equal(new AlcanceFinanza(4,false),r.Alcance);}
    [Fact] public async Task Ingreso_Inexistente_RetornaNotFound()=>Assert.IsType<NotFoundResult>(await Controller(new Fake(),1,"AdministradorGeneral").Ingreso(999,default));
    [Fact] public async Task EliminarIngreso_Existente_RetornaNoContent(){var r=new Fake();Assert.IsType<NoContentResult>(await Controller(r,9,"AdministradorGeneral").EliminarIngreso(8,default));Assert.Equal(9,r.UsuarioEliminaIngreso);}
    [Fact] public async Task OpcionesIngreso_PropagaAlcance(){var r=new Fake();await Controller(r,6,"Gerente").OpcionesIngreso(default);Assert.Equal(new AlcanceFinanza(6,false),r.Alcance);}

    private static FinanzasController Controller(IFinanzaRepository r,int id,params string[] roles){var claims=new List<Claim>{new(ClaimTypes.NameIdentifier,id.ToString())};claims.AddRange(roles.Select(x=>new Claim(ClaimTypes.Role,x)));return new(r){ControllerContext=new(){HttpContext=new DefaultHttpContext{User=new ClaimsPrincipal(new ClaimsIdentity(claims,"Test"))}}};}
    private sealed class Fake:IFinanzaRepository
    {
        public long Id{get;init;}=1;public AlcanceFinanza? Alcance{get;private set;}public short? Anio{get;private set;}public byte? Mes{get;private set;}public int? GiroId{get;private set;}public int? SedeId{get;private set;}public CrearIngresoRequest? IngresoCreado{get;private set;}public int? UsuarioEliminaIngreso{get;private set;}
        public Task<IReadOnlyList<PresupuestoListadoDto>> ListarAsync(short? a,byte? m,int? g,int? s,AlcanceFinanza x,CancellationToken ct){Alcance=x;return Task.FromResult<IReadOnlyList<PresupuestoListadoDto>>([]);}
        public Task<PresupuestoDetalleDto?> ObtenerAsync(long id,AlcanceFinanza x,CancellationToken ct)=>Task.FromResult<PresupuestoDetalleDto?>(null);
        public Task<FinanzaOpcionesDto> OpcionesAsync(AlcanceFinanza x,CancellationToken ct)=>Task.FromResult(new FinanzaOpcionesDto([],[]));
        public Task<long> CrearAsync(CrearPresupuestoRequest r,AlcanceFinanza x,CancellationToken ct){Alcance=x;return Task.FromResult(Id);}
        public Task<long> RegistrarGastoAsync(long id,RegistrarGastoRequest r,AlcanceFinanza x,CancellationToken ct){Alcance=x;return Task.FromResult(Id);}
        public Task<bool> ActualizarEstadoAsync(long id,string e,AlcanceFinanza x,CancellationToken ct)=>Task.FromResult(true);
        public Task<bool> EliminarAsync(long id,int u,CancellationToken ct)=>Task.FromResult(true);
        public Task<IReadOnlyList<IngresoDto>> ListarIngresosAsync(short? a,byte? m,int? g,int? s,AlcanceFinanza x,CancellationToken ct){Anio=a;Mes=m;GiroId=g;SedeId=s;Alcance=x;return Task.FromResult<IReadOnlyList<IngresoDto>>([]);}
        public Task<IngresoDto?> ObtenerIngresoAsync(long id,AlcanceFinanza x,CancellationToken ct){Alcance=x;return Task.FromResult<IngresoDto?>(null);}
        public Task<IngresoOpcionesDto> OpcionesIngresoAsync(AlcanceFinanza x,CancellationToken ct){Alcance=x;return Task.FromResult(new IngresoOpcionesDto([],[],[]));}
        public Task<long> CrearIngresoAsync(CrearIngresoRequest r,AlcanceFinanza x,CancellationToken ct){IngresoCreado=r;Alcance=x;return Task.FromResult(Id);}
        public Task<bool> EliminarIngresoAsync(long id,int u,CancellationToken ct){UsuarioEliminaIngreso=u;return Task.FromResult(true);}
    }
}

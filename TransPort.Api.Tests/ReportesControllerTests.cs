using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using TransPort.Api.Controllers;
using TransPort.Api.Modules.Reportes.DTOs;
using TransPort.Api.Modules.Reportes.Repositories;

namespace TransPort.Api.Tests;

public sealed class ReportesControllerTests
{
    [Fact] public async Task Interno_PropagaFiltrosYAlcance(){var r=new Fake();var desde=new DateTime(2026,1,1);var hasta=new DateTime(2026,10,30);await Controller(r,8,"Empleado").Interno(desde,hasta,2,7,default);Assert.Equal(new AlcanceReporte(8,false),r.Alcance);Assert.Equal(desde,r.Desde);Assert.Equal(hasta,r.Hasta);Assert.Equal(2,r.GiroId);Assert.Equal(7,r.SedeId);}
    [Fact] public async Task Cliente_PropagaEmpresaEIdentidad(){var r=new Fake();await Controller(r,3,"Cliente").Cliente(null,null,1,default);Assert.Equal(new AlcanceReporte(3,false),r.Alcance);Assert.Equal(1,r.ClienteId);}
    [Fact] public async Task Opciones_PropagaAdministrador(){var r=new Fake();await Controller(r,1,"AdministradorGeneral").Opciones(default);Assert.Equal(new AlcanceReporte(1,true),r.Alcance);}
    [Fact] public void EndpointCliente_AdmiteClienteYAdministrador(){var a=Metodo(nameof(ReportesController.Cliente));Assert.Contains("Cliente",a.Roles??"");Assert.Contains("AdministradorGeneral",a.Roles??"");}
    [Fact] public void EndpointInterno_ExcluyeCliente(){var a=Metodo(nameof(ReportesController.Interno));Assert.DoesNotContain("Cliente",a.Roles??"");Assert.Contains("Empleado",a.Roles??"");}

    private static AuthorizeAttribute Metodo(string nombre)=>typeof(ReportesController).GetMethod(nombre)!.GetCustomAttributes(typeof(AuthorizeAttribute),true).Cast<AuthorizeAttribute>().Single();
    private static ReportesController Controller(IReporteRepository r,int id,params string[] roles){var claims=new List<Claim>{new(ClaimTypes.NameIdentifier,id.ToString())};claims.AddRange(roles.Select(x=>new Claim(ClaimTypes.Role,x)));return new(r){ControllerContext=new(){HttpContext=new DefaultHttpContext{User=new ClaimsPrincipal(new ClaimsIdentity(claims,"Test"))}}};}
    private sealed class Fake:IReporteRepository
    {
        public AlcanceReporte? Alcance{get;private set;}public DateTime? Desde{get;private set;}public DateTime? Hasta{get;private set;}public int? GiroId{get;private set;}public int? SedeId{get;private set;}public int? ClienteId{get;private set;}
        public Task<ReporteOpcionesDto> OpcionesAsync(AlcanceReporte a,CancellationToken ct){Alcance=a;return Task.FromResult(new ReporteOpcionesDto([],[]));}
        public Task<ReporteInternoDto> InternoAsync(DateTime? d,DateTime? h,int? g,int? s,AlcanceReporte a,CancellationToken ct){Desde=d;Hasta=h;GiroId=g;SedeId=s;Alcance=a;return Task.FromResult(new ReporteInternoDto(new(DateTime.Today,DateTime.Today,0,0,0,0,0,0,0,0),[],[]));}
        public Task<ReporteClienteDto> ClienteAsync(DateTime? d,DateTime? h,int? c,AlcanceReporte a,CancellationToken ct){Desde=d;Hasta=h;ClienteId=c;Alcance=a;return Task.FromResult(new ReporteClienteDto(new(DateTime.Today,DateTime.Today,0,0,0,0,0,0,0,0,0,0,0,0,0),[],[]));}
    }
}

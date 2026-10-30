using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Controllers;
using TransPort.Api.Modules.Alertas.DTOs;
using TransPort.Api.Modules.Alertas.Repositories;

namespace TransPort.Api.Tests;

public sealed class AlertasControllerTests
{
    [Fact] public async Task Listar_PropagaIdentidad(){var r=new Fake();await Controller(r,9,"Empleado").Listar(null,true,default);Assert.Equal(new AlcanceAlerta(9,false),r.Alcance);}
    [Fact] public async Task Crear_RetornaId(){var r=new Fake{Id=41};var x=Assert.IsType<OkObjectResult>(await Controller(r,1,"AdministradorGeneral").Crear(new(){Tipo="Alerta",Titulo="Aviso",Mensaje="Detalle",Severidad="Critica",FechaProgramadaUtc=DateTime.UtcNow},default));Assert.Equal(41,Assert.IsType<ResultadoAlertaDto>(x.Value).Id);}
    [Fact] public async Task Obtener_Inexistente_NotFound()=>Assert.IsType<NotFoundResult>(await Controller(new Fake(),1,"AdministradorGeneral").Obtener(4,default));
    [Fact] public async Task Leer_PropagaIdentidad(){var r=new Fake();Assert.IsType<NoContentResult>(await Controller(r,7,"Operativo").Leer(2,default));Assert.Equal(new AlcanceAlerta(7,false),r.Alcance);}
    [Fact] public void Controlador_ExcluyeCliente(){var a=typeof(AlertasController).GetCustomAttributes(typeof(AuthorizeAttribute),true).Cast<AuthorizeAttribute>().Single();Assert.DoesNotContain("Cliente",a.Roles??string.Empty);}

    private static AlertasController Controller(IAlertaRepository r,int id,params string[] roles){var claims=new List<Claim>{new(ClaimTypes.NameIdentifier,id.ToString())};claims.AddRange(roles.Select(x=>new Claim(ClaimTypes.Role,x)));return new(r){ControllerContext=new(){HttpContext=new DefaultHttpContext{User=new ClaimsPrincipal(new ClaimsIdentity(claims,"Test"))}}};}
    private sealed class Fake:IAlertaRepository
    {
        public long Id{get;init;}=1;public AlcanceAlerta? Alcance{get;private set;}
        public Task<IReadOnlyList<AlertaListadoDto>> ListarAsync(string? e,bool p,AlcanceAlerta a,CancellationToken ct){Alcance=a;return Task.FromResult<IReadOnlyList<AlertaListadoDto>>([]);}
        public Task<AlertaDetalleDto?> ObtenerAsync(long id,AlcanceAlerta a,CancellationToken ct)=>Task.FromResult<AlertaDetalleDto?>(null);
        public Task<AlertaOpcionesDto> OpcionesAsync(AlcanceAlerta a,CancellationToken ct)=>Task.FromResult(new AlertaOpcionesDto([],[],[],[]));
        public Task<long> CrearAsync(CrearAlertaRequest r,AlcanceAlerta a,CancellationToken ct){Alcance=a;return Task.FromResult(Id);}
        public Task<bool> MarcarLeidaAsync(long id,AlcanceAlerta a,CancellationToken ct){Alcance=a;return Task.FromResult(true);}
        public Task<long> SeguimientoAsync(long id,string c,AlcanceAlerta a,CancellationToken ct)=>Task.FromResult(Id);
        public Task<bool> EstadoAsync(long id,string e,AlcanceAlerta a,CancellationToken ct)=>Task.FromResult(true);
        public Task<bool> EliminarAsync(long id,int u,CancellationToken ct)=>Task.FromResult(true);
    }
}

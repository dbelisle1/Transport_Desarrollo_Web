using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Controllers;
using TransPort.Api.Modules.PortalCliente.DTOs;
using TransPort.Api.Modules.PortalCliente.Repositories;

namespace TransPort.Api.Tests;

public sealed class PortalClienteControllerTests
{
    [Fact]
    public async Task Resumen_ClientePropagaIdentidadSinAlcanceAdministrativo()
    {
        var repository = new FakePortalRepository();
        var controller = CrearController(repository, 27, "Cliente");

        var result = await controller.Resumen(default);

        Assert.Same(repository.Respuesta, result);
        Assert.Equal(27, repository.UsuarioId);
        Assert.False(repository.EsAdministrador);
    }

    [Fact]
    public async Task Resumen_AdministradorPropagaAlcanceGlobal()
    {
        var repository = new FakePortalRepository();
        var controller = CrearController(repository, 1, "AdministradorGeneral");

        await controller.Resumen(default);

        Assert.True(repository.EsAdministrador);
    }

    [Fact]
    public void Controlador_NoAutorizaEmpleadosSinRolCliente()
    {
        var atributo = typeof(PortalClienteController)
            .GetCustomAttributes(typeof(AuthorizeAttribute), true)
            .Cast<AuthorizeAttribute>().Single();

        Assert.Contains("Cliente", atributo.Roles ?? string.Empty);
        Assert.Contains("AdministradorGeneral", atributo.Roles ?? string.Empty);
        Assert.DoesNotContain("Empleado", atributo.Roles ?? string.Empty);
    }

    private static PortalClienteController CrearController(
        IPortalClienteRepository repository, int usuarioId, params string[] roles)
    {
        var claims = new List<Claim> { new(ClaimTypes.NameIdentifier, usuarioId.ToString()) };
        claims.AddRange(roles.Select(x => new Claim(ClaimTypes.Role, x)));
        return new PortalClienteController(repository)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext
                {
                    User = new ClaimsPrincipal(new ClaimsIdentity(claims, "Pruebas"))
                }
            }
        };
    }

    private sealed class FakePortalRepository : IPortalClienteRepository
    {
        public PortalClienteResumenDto Respuesta { get; } = new([], 0, 0, 0, 0, 0, []);
        public int UsuarioId { get; private set; }
        public bool EsAdministrador { get; private set; }

        public Task<PortalClienteResumenDto> ResumenAsync(
            int usuarioId, bool esAdministrador, CancellationToken ct)
        {
            UsuarioId = usuarioId;
            EsAdministrador = esAdministrador;
            return Task.FromResult(Respuesta);
        }
    }
}

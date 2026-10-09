using System.Security.Claims;
using Microsoft.Extensions.Options;
using TransPort.Api.Configuration;
using TransPort.Api.Modules.Seguridad.DTOs;
using TransPort.Api.Modules.Seguridad.Services;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Tests;

public sealed class TokenServiceTests
{
    private static readonly JwtOptions Settings = new()
    {
        Issuer = "tests",
        Audience = "tests-web",
        SigningKey = "tests-signing-key-with-at-least-32-characters",
        ExpirationMinutes = 30
    };

    [Fact]
    public void CrearYValidar_ConDatosValidos_ConservaIdentidadYPermisos()
    {
        var service = new TokenService(Options.Create(Settings));
        var user = new UsuarioSesionDto(7, "admin", "Ada Admin", "ada@example.test",
            ["AdministradorGeneral"], [new CatalogoDto(2, "Extracción")],
            [new CatalogoDto(3, "Central")], []);

        var generated = service.Crear(user);
        var principal = service.Validar(generated.Token);

        Assert.NotNull(principal);
        Assert.Equal("7", principal!.FindFirstValue(ClaimTypes.NameIdentifier));
        Assert.True(principal.IsInRole("AdministradorGeneral"));
        Assert.Equal("2", principal.FindFirstValue("giro"));
        Assert.True(generated.ExpiraUtc > DateTime.UtcNow);
    }

    [Fact]
    public void Validar_ConTokenAlterado_RegresaNulo()
    {
        var service = new TokenService(Options.Create(Settings));
        Assert.Null(service.Validar("token.no.valido"));
    }

    [Fact]
    public void Crear_ConClaveCorta_RechazaConfiguracionInsegura()
    {
        var service = new TokenService(Options.Create(new JwtOptions { SigningKey = "corta" }));
        var user = new UsuarioSesionDto(1, "u", "Usuario", "u@example.test", [], [], [], []);
        Assert.Throws<InvalidOperationException>(() => service.Crear(user));
    }
}

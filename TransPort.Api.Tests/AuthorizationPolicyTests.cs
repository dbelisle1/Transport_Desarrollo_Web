using System.Reflection;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Routing;
using TransPort.Api.Controllers;

namespace TransPort.Api.Tests;

public sealed class AuthorizationPolicyTests
{
    [Fact]
    public void CadaAccionApi_DeclaraAutorizacionOAccesoAnonimo()
    {
        var desprotegidas = Actions()
            .Where(x => !HasAuthorize(x.Controller, x.Action) && !HasAllowAnonymous(x.Controller, x.Action))
            .Select(Name)
            .ToArray();

        Assert.True(desprotegidas.Length == 0,
            $"Acciones sin política explícita: {string.Join(", ", desprotegidas)}");
    }

    [Fact]
    public void SoloLoginYCatalogoPublico_PermitenAccesoAnonimo()
    {
        var anonymous = Actions()
            .Where(x => HasAllowAnonymous(x.Controller, x.Action))
            .Select(Name)
            .OrderBy(x => x)
            .ToArray();

        Assert.Equal([
            "AuthController.Login",
            "CatalogoComercialController.Publico"
        ], anonymous);
    }

    [Fact]
    public void ControladoresAdministrativos_ExigenAdministradorGeneral()
    {
        var controllers = new[]
        {
            typeof(AdministracionController),
            typeof(CatalogosController),
            typeof(ClientesController),
            typeof(UsuariosController)
        };

        foreach (var controller in controllers)
            Assert.Contains("AdministradorGeneral", Roles(controller, null));
    }

    [Fact]
    public void CadaEliminacion_DeclaraAlMenosUnRolAutorizado()
    {
        var withoutRoles = Actions()
            .Where(x => x.Action.GetCustomAttributes<HttpDeleteAttribute>(true).Any())
            .Where(x => Roles(x.Controller, x.Action).Count == 0)
            .Select(Name)
            .ToArray();

        Assert.True(withoutRoles.Length == 0,
            $"Eliminaciones sin roles explícitos: {string.Join(", ", withoutRoles)}");
    }

    [Fact]
    public void Reportes_SeparaPermisosInternosYDeCliente()
    {
        var internalRoles = Roles(typeof(ReportesController),
            typeof(ReportesController).GetMethod(nameof(ReportesController.Interno))!);
        var clientRoles = Roles(typeof(ReportesController),
            typeof(ReportesController).GetMethod(nameof(ReportesController.Cliente))!);

        Assert.Contains("Empleado", internalRoles);
        Assert.DoesNotContain("Cliente", internalRoles);
        Assert.Contains("Cliente", clientRoles);
        Assert.DoesNotContain("Empleado", clientRoles);
    }

    private static IReadOnlyList<(Type Controller, MethodInfo Action)> Actions() =>
        typeof(AuthController).Assembly.GetTypes()
            .Where(type => !type.IsAbstract && typeof(ControllerBase).IsAssignableFrom(type))
            .Where(type => type.GetCustomAttribute<ApiControllerAttribute>(true) is not null)
            .SelectMany(type => type.GetMethods(BindingFlags.Instance | BindingFlags.Public | BindingFlags.DeclaredOnly)
                .Where(method => method.GetCustomAttributes<HttpMethodAttribute>(true).Any())
                .Select(method => (type, method)))
            .ToArray();

    private static bool HasAuthorize(Type controller, MethodInfo action) =>
        controller.GetCustomAttributes<AuthorizeAttribute>(true).Any() ||
        action.GetCustomAttributes<AuthorizeAttribute>(true).Any();

    private static bool HasAllowAnonymous(Type controller, MethodInfo action) =>
        controller.GetCustomAttributes<AllowAnonymousAttribute>(true).Any() ||
        action.GetCustomAttributes<AllowAnonymousAttribute>(true).Any();

    private static HashSet<string> Roles(Type controller, MethodInfo? action)
    {
        var attributes = controller.GetCustomAttributes<AuthorizeAttribute>(true)
            .Concat(action?.GetCustomAttributes<AuthorizeAttribute>(true) ?? []);
        return attributes
            .SelectMany(attribute => (attribute.Roles ?? string.Empty)
                .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
            .ToHashSet(StringComparer.Ordinal);
    }

    private static string Name((Type Controller, MethodInfo Action) item) =>
        $"{item.Controller.Name}.{item.Action.Name}";
}

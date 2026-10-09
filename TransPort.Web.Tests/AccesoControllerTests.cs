using System.Diagnostics.CodeAnalysis;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Controllers;
using Microsoft.AspNetCore.Mvc.Routing;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using TransPort.Web.Controllers;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Tests;

public sealed class AccesoControllerTests
{
    [Fact]
    public async Task Salir_LimpiaSesionYCierraAutenticacion()
    {
        var session = new FakeSession();
        session.SetString("ApiToken", "token-prueba");
        var authentication = new RecordingAuthenticationService();
        var services = new ServiceCollection()
            .AddSingleton<IAuthenticationService>(authentication)
            .BuildServiceProvider();
        var httpContext = new DefaultHttpContext
        {
            Session = session,
            RequestServices = services
        };
        var controller = new AccesoController(new UnusedApiClient(), NullLogger<AccesoController>.Instance)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = httpContext,
                RouteData = new RouteData(),
                ActionDescriptor = new ControllerActionDescriptor()
            }
        };
        controller.Url = new UrlHelper(controller.ControllerContext);

        var result = await controller.Salir();

        var redirect = Assert.IsType<RedirectToActionResult>(result);
        Assert.Equal(nameof(AccesoController.Index), redirect.ActionName);
        Assert.Empty(session.Keys);
        Assert.True(session.WasCommitted);
        Assert.Equal(CookieAuthenticationDefaults.AuthenticationScheme, authentication.SignedOutScheme);
        Assert.Contains(httpContext.Response.Headers.SetCookie,
            value => value?.Contains("TransPort.Session=", StringComparison.Ordinal) == true);
    }

    private sealed class FakeSession : ISession
    {
        private readonly Dictionary<string, byte[]> _values = [];

        public bool WasCommitted { get; private set; }
        public bool IsAvailable => true;
        public string Id { get; } = Guid.NewGuid().ToString("N");
        public IEnumerable<string> Keys => _values.Keys;

        public void Clear() => _values.Clear();
        public Task CommitAsync(CancellationToken cancellationToken = default)
        {
            WasCommitted = true;
            return Task.CompletedTask;
        }
        public Task LoadAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
        public void Remove(string key) => _values.Remove(key);
        public void Set(string key, byte[] value) => _values[key] = value;
        public bool TryGetValue(string key, [NotNullWhen(true)] out byte[]? value) =>
            _values.TryGetValue(key, out value);
    }

    private sealed class RecordingAuthenticationService : IAuthenticationService
    {
        public string? SignedOutScheme { get; private set; }

        public Task<AuthenticateResult> AuthenticateAsync(HttpContext context, string? scheme) =>
            Task.FromResult(AuthenticateResult.NoResult());
        public Task ChallengeAsync(HttpContext context, string? scheme, AuthenticationProperties? properties) =>
            Task.CompletedTask;
        public Task ForbidAsync(HttpContext context, string? scheme, AuthenticationProperties? properties) =>
            Task.CompletedTask;
        public Task SignInAsync(HttpContext context, string? scheme, System.Security.Claims.ClaimsPrincipal principal,
            AuthenticationProperties? properties) => Task.CompletedTask;
        public Task SignOutAsync(HttpContext context, string? scheme, AuthenticationProperties? properties)
        {
            SignedOutScheme = scheme;
            return Task.CompletedTask;
        }
    }

    private sealed class UnusedApiClient : ITransportApiClient
    {
        private static Exception NotUsed() => new InvalidOperationException("La API no debe invocarse al cerrar sesión.");

        public Task<LoginResponseModel?> LoginAsync(LoginViewModel model, CancellationToken ct) => throw NotUsed();
        public Task<DashboardModel> ResumenAsync(CancellationToken ct) => throw NotUsed();
        public Task<IReadOnlyList<UsuarioListadoModel>> UsuariosAsync(string? busqueda, bool? esActivo, int? rolId, CancellationToken ct) => throw NotUsed();
        public Task<UsuarioDetalleModel?> UsuarioAsync(int id, CancellationToken ct) => throw NotUsed();
        public Task<int> CrearUsuarioAsync(UsuarioFormViewModel model, CancellationToken ct) => throw NotUsed();
        public Task ActualizarUsuarioAsync(UsuarioFormViewModel model, CancellationToken ct) => throw NotUsed();
        public Task ActualizarAsignacionesAsync(UsuarioFormViewModel model, CancellationToken ct) => throw NotUsed();
        public Task EliminarUsuarioAsync(int id, CancellationToken ct) => throw NotUsed();
        public Task<IReadOnlyList<EntidadCatalogoModel>> CatalogoAsync(string tipo, CancellationToken ct) => throw NotUsed();
    }
}

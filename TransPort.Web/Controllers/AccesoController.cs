using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Controllers;

[Route("acceso")]
public sealed class AccesoController(ITransportApiClient api, ILogger<AccesoController> logger) : Controller
{
    [AllowAnonymous]
    [HttpGet("")]
    public IActionResult Index(string? retorno = null)
    {
        if (User.Identity?.IsAuthenticated == true) return RedirectPorRol();
        return View(new LoginViewModel { Retorno = retorno });
    }

    [AllowAnonymous]
    [HttpPost("")]
    public async Task<IActionResult> Index(LoginViewModel model, CancellationToken ct)
    {
        if (!ModelState.IsValid) return View(model);
        try
        {
            var result = await api.LoginAsync(model, ct);
            if (result is null)
            {
                ModelState.AddModelError(string.Empty, "Usuario o contraseña incorrectos.");
                return View(model);
            }

            var claims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, result.Usuario.UsuarioId.ToString()),
                new(ClaimTypes.Name, result.Usuario.NombreCompleto),
                new(ClaimTypes.Email, result.Usuario.Correo),
                new("nombre_usuario", result.Usuario.NombreUsuario)
            };
            claims.AddRange(result.Usuario.Roles.Select(x => new Claim(ClaimTypes.Role, x)));
            claims.AddRange(result.Usuario.Giros.Select(x => new Claim("giro", x.Nombre)));
            claims.AddRange(result.Usuario.Sedes.Select(x => new Claim("sede", x.Nombre)));
            claims.AddRange(result.Usuario.Clientes.Select(x => new Claim("cliente", x.Nombre)));

            HttpContext.Session.SetString("ApiToken", result.Token);
            var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
            await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme,
                new ClaimsPrincipal(identity), new AuthenticationProperties
                {
                    IsPersistent = false,
                    ExpiresUtc = new DateTimeOffset(result.ExpiraUtc)
                });

            if (Url.IsLocalUrl(model.Retorno)) return LocalRedirect(model.Retorno!);
            return RedirectPorRol(result.Usuario.Roles);
        }
        catch (HttpRequestException ex)
        {
            logger.LogError(ex, "No fue posible contactar la API durante el inicio de sesión.");
            ModelState.AddModelError(string.Empty, "El servicio de acceso no está disponible. Intente nuevamente.");
            return View(model);
        }
        catch (TransportApiException ex)
        {
            logger.LogWarning(ex, "La API rechazó el inicio de sesión.");
            ModelState.AddModelError(string.Empty, "No fue posible iniciar sesión.");
            return View(model);
        }
    }

    [Authorize]
    [HttpPost("salir")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Salir()
    {
        HttpContext.Session.Clear();
        await HttpContext.Session.CommitAsync();
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        Response.Cookies.Delete("TransPort.Session");
        return RedirectToAction(nameof(Index));
    }

    [AllowAnonymous]
    [HttpGet("denegado")]
    public IActionResult Denegado() => View();

    private IActionResult RedirectPorRol(IEnumerable<string>? roles = null)
    {
        var set = roles?.ToHashSet(StringComparer.OrdinalIgnoreCase);
        bool Has(string role) => set?.Contains(role) ?? User.IsInRole(role);
        if (Has("AdministradorGeneral")) return Redirect("/admin");
        if (Has("Cliente")) return Redirect("/cliente");
        return Redirect("/gestion");
    }
}

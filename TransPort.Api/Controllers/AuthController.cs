using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using TransPort.Api.Modules.Seguridad.DTOs;
using TransPort.Api.Modules.Seguridad.Repositories;
using TransPort.Api.Modules.Seguridad.Services;

namespace TransPort.Api.Controllers;

[ApiController]
[Route("api/auth")]
public sealed class AuthController(IAuthService auth, IUsuarioRepository usuarios) : ControllerBase
{
    [AllowAnonymous]
    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginRequest request, CancellationToken ct)
    {
        var result = await auth.LoginAsync(request, ct);
        return result is null ? Unauthorized(new { mensaje = "Usuario o contraseña incorrectos." }) : Ok(result);
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> Me(CancellationToken ct)
    {
        if (!int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id)) return Unauthorized();
        var usuario = await usuarios.ObtenerAsync(id, ct);
        return usuario is null ? NotFound() : Ok(usuario);
    }
}

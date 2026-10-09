using TransPort.Api.Modules.Organizacion.DTOs;
using TransPort.Api.Modules.Organizacion.Repositories;
using TransPort.Api.Modules.Seguridad.DTOs;
using TransPort.Api.Modules.Seguridad.Repositories;

namespace TransPort.Api.Modules.Seguridad.Services;

public sealed class AuthService(
    IUsuarioRepository usuarios,
    ITokenService tokens,
    IOperacionesRepository operaciones) : IAuthService
{
    public async Task<LoginResponse?> LoginAsync(LoginRequest request, CancellationToken ct)
    {
        var credencial = await usuarios.ValidarCredencialesAsync(request.NombreUsuario.Trim(), request.Clave, ct);
        if (credencial is null)
        {
            await operaciones.CrearAuditoriaAsync(new CrearAuditoriaDto(
                null, "Seguridad", "InicioSesion", request.NombreUsuario.Trim(), "Fallido",
                "Credenciales inválidas. La contraseña no fue registrada."), ct);
            return null;
        }

        var roles = await usuarios.LeerRolesAsync(credencial.UsuarioId, ct);
        var giros = await usuarios.LeerGirosAsync(credencial.UsuarioId, ct);
        var sedes = await usuarios.LeerSedesAsync(credencial.UsuarioId, ct);
        var clientes = await usuarios.LeerClientesAsync(credencial.UsuarioId, ct);
        var sesion = new UsuarioSesionDto(
            credencial.UsuarioId, credencial.NombreUsuario, $"{credencial.Nombre} {credencial.Apellido}",
            credencial.Correo, roles.Select(x => x.Nombre).ToArray(), giros, sedes, clientes);
        var (token, expira) = tokens.Crear(sesion);
        await operaciones.CrearAuditoriaAsync(new CrearAuditoriaDto(
            credencial.UsuarioId, "Seguridad", "InicioSesion", credencial.UsuarioId.ToString(), "Exitoso", null), ct);
        return new LoginResponse(token, expira, sesion);
    }
}

using System.Security.Claims;
using TransPort.Api.Modules.Seguridad.DTOs;

namespace TransPort.Api.Modules.Seguridad.Services;

public interface ITokenService
{
    (string Token, DateTime ExpiraUtc) Crear(UsuarioSesionDto usuario);
    ClaimsPrincipal? Validar(string token);
}

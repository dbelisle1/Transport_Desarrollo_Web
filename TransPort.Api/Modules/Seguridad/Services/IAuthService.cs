using TransPort.Api.Modules.Seguridad.DTOs;

namespace TransPort.Api.Modules.Seguridad.Services;

public interface IAuthService
{
    Task<LoginResponse?> LoginAsync(LoginRequest request, CancellationToken ct);
}

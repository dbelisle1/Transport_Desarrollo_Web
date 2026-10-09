using TransPort.Web.Models;

namespace TransPort.Web.Services;

public interface ITransportApiClient
{
    Task<LoginResponseModel?> LoginAsync(LoginViewModel model, CancellationToken ct);
    Task<DashboardModel> ResumenAsync(CancellationToken ct);
    Task<IReadOnlyList<UsuarioListadoModel>> UsuariosAsync(string? busqueda, bool? esActivo, int? rolId, CancellationToken ct);
    Task<UsuarioDetalleModel?> UsuarioAsync(int id, CancellationToken ct);
    Task<int> CrearUsuarioAsync(UsuarioFormViewModel model, CancellationToken ct);
    Task ActualizarUsuarioAsync(UsuarioFormViewModel model, CancellationToken ct);
    Task ActualizarAsignacionesAsync(UsuarioFormViewModel model, CancellationToken ct);
    Task EliminarUsuarioAsync(int id, CancellationToken ct);
    Task<IReadOnlyList<EntidadCatalogoModel>> CatalogoAsync(string tipo, CancellationToken ct);
}

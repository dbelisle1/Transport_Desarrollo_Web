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
    Task<IReadOnlyList<ClienteListadoModel>> ClientesAsync(string? busqueda, bool? esActivo, CancellationToken ct);
    Task<ClienteDetalleModel?> ClienteAsync(int id, CancellationToken ct);
    Task<int> CrearClienteAsync(ClienteFormViewModel model, CancellationToken ct);
    Task ActualizarClienteAsync(ClienteFormViewModel model, CancellationToken ct);
    Task EliminarClienteAsync(int id, CancellationToken ct);
    Task<IReadOnlyList<EntidadCatalogoModel>> CatalogoAsync(string tipo, CancellationToken ct);
    Task<EntidadCatalogoModel?> CatalogoItemAsync(string tipo, int id, CancellationToken ct);
    Task<int> CrearCatalogoAsync(CatalogoFormViewModel model, CancellationToken ct);
    Task ActualizarCatalogoAsync(CatalogoFormViewModel model, CancellationToken ct);
    Task EliminarCatalogoAsync(string tipo, int id, CancellationToken ct);
}

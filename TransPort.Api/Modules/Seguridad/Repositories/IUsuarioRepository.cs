using TransPort.Api.Modules.Seguridad.DTOs;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Modules.Seguridad.Repositories;

public interface IUsuarioRepository
{
    Task<CredencialUsuarioDto?> ValidarCredencialesAsync(string nombreUsuario, string clave, CancellationToken ct);
    Task<IReadOnlyList<UsuarioListadoDto>> ListarAsync(string? busqueda, bool? esActivo, int? rolId, CancellationToken ct);
    Task<UsuarioDetalleDto?> ObtenerAsync(int id, CancellationToken ct);
    Task<int> CrearAsync(CrearUsuarioRequest request, int responsableId, CancellationToken ct);
    Task<bool> ActualizarAsync(int id, ActualizarUsuarioRequest request, int responsableId, CancellationToken ct);
    Task<bool> EliminarAsync(int id, int responsableId, CancellationToken ct);
    Task<IReadOnlyList<CatalogoDto>> LeerRolesAsync(int usuarioId, CancellationToken ct);
    Task<IReadOnlyList<CatalogoDto>> LeerGirosAsync(int usuarioId, CancellationToken ct);
    Task<IReadOnlyList<CatalogoDto>> LeerSedesAsync(int usuarioId, CancellationToken ct);
    Task<IReadOnlyList<CatalogoDto>> LeerClientesAsync(int usuarioId, CancellationToken ct);
    Task ActualizarAsignacionesAsync(int usuarioId, AsignacionesUsuarioRequest request, int responsableId, CancellationToken ct);
}

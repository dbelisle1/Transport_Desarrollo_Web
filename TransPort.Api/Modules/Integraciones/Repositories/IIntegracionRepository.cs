using TransPort.Api.Modules.Integraciones.DTOs;

namespace TransPort.Api.Modules.Integraciones.Repositories;

public interface IIntegracionRepository
{
    Task<IReadOnlyList<IntegracionListadoDto>> ListarAsync(string?estado,string?canal,string?busqueda,AlcanceIntegracion alcance,CancellationToken ct);
    Task<IntegracionDetalleDto?> ObtenerAsync(long id,AlcanceIntegracion alcance,CancellationToken ct);
    Task<IntegracionOpcionesDto> OpcionesAsync(AlcanceIntegracion alcance,CancellationToken ct);
    Task<long> SimularAsync(SimularIntegracionRequest request,AlcanceIntegracion alcance,CancellationToken ct);
    Task<long> ReintentarAsync(long id,AlcanceIntegracion alcance,CancellationToken ct);
    Task<bool> EliminarAsync(long id,int usuarioId,CancellationToken ct);
}

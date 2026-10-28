using TransPort.Api.Modules.Produccion.DTOs;
namespace TransPort.Api.Modules.Produccion.Repositories;
public interface IProduccionRepository
{
 Task<IReadOnlyList<ProduccionListadoDto>>ListarAsync(string?estado,int?sedeId,DateTime?desde,DateTime?hasta,AlcanceProduccion alcance,CancellationToken ct);
 Task<ProduccionDetalleDto?>ObtenerAsync(long id,AlcanceProduccion alcance,CancellationToken ct);
 Task<ProduccionOpcionesDto>OpcionesAsync(AlcanceProduccion alcance,CancellationToken ct);
 Task<long>CrearAsync(CrearProduccionRequest request,AlcanceProduccion alcance,CancellationToken ct);
 Task<bool>CambiarEstadoAsync(long id,CambiarEstadoProduccionRequest request,AlcanceProduccion alcance,CancellationToken ct);
 Task<bool>CompletarEtapaAsync(long id,long etapaId,string?observacion,AlcanceProduccion alcance,CancellationToken ct);
 Task<bool>EliminarAsync(long id,int usuarioId,CancellationToken ct);
}

using TransPort.Api.Modules.Alertas.DTOs;

namespace TransPort.Api.Modules.Alertas.Repositories;

public interface IAlertaRepository
{
    Task<IReadOnlyList<AlertaListadoDto>> ListarAsync(string? estado,bool soloPendientes,AlcanceAlerta alcance,CancellationToken ct);
    Task<AlertaDetalleDto?> ObtenerAsync(long id,AlcanceAlerta alcance,CancellationToken ct);
    Task<AlertaOpcionesDto> OpcionesAsync(AlcanceAlerta alcance,CancellationToken ct);
    Task<long> CrearAsync(CrearAlertaRequest request,AlcanceAlerta alcance,CancellationToken ct);
    Task<bool> MarcarLeidaAsync(long id,AlcanceAlerta alcance,CancellationToken ct);
    Task<long> SeguimientoAsync(long id,string comentario,AlcanceAlerta alcance,CancellationToken ct);
    Task<bool> EstadoAsync(long id,string estado,AlcanceAlerta alcance,CancellationToken ct);
    Task<bool> EliminarAsync(long id,int usuarioId,CancellationToken ct);
}

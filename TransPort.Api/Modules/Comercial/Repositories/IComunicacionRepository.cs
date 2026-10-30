using TransPort.Api.Modules.Comercial.DTOs;

namespace TransPort.Api.Modules.Comercial.Repositories;

public interface IComunicacionRepository
{
    Task<IReadOnlyList<ComunicacionListadoDto>> ListarAsync(string? estado, string? tipo, string? busqueda, AlcanceComunicacion alcance, CancellationToken ct);
    Task<ComunicacionDetalleDto?> ObtenerAsync(long id, AlcanceComunicacion alcance, CancellationToken ct);
    Task<ComunicacionOpcionesDto> OpcionesAsync(AlcanceComunicacion alcance, CancellationToken ct);
    Task<long> CrearAsync(CrearComunicacionRequest request, AlcanceComunicacion alcance, CancellationToken ct);
    Task<long> AgregarMensajeAsync(long id, CrearMensajeComunicacionRequest request, AlcanceComunicacion alcance, CancellationToken ct);
    Task<bool> GestionarAsync(long id, GestionComunicacionRequest request, AlcanceComunicacion alcance, CancellationToken ct);
    Task<bool> EliminarAsync(long id, int usuarioId, CancellationToken ct);
}

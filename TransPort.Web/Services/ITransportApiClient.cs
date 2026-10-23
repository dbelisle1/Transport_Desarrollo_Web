using TransPort.Web.Models.Clientes;

// ... dentro de public interface ITransportApiClient { ...
Task<IReadOnlyList<ClienteListadoWebDto>> ListarClientesAsync(string? busqueda, bool? esActivo, CancellationToken ct = default);
Task<ClienteDetalleWebDto?> ObtenerClienteAsync(int id, CancellationToken ct = default);
Task CrearClienteAsync(CrearClienteWebRequest request, CancellationToken ct = default);
Task ActualizarClienteAsync(int id, ActualizarClienteWebRequest request, CancellationToken ct = default);
Task EliminarClienteAsync(int id, CancellationToken ct = default);
Task ActualizarAsociacionesClienteAsync(int id, AsociacionesClienteWebRequest request, CancellationToken ct = default);
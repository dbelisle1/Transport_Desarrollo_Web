using TransPort.Web.Models.Clientes;

// ... dentro de public class TransportApiClient : ITransportApiClient { ...
public async Task<IReadOnlyList<ClienteListadoWebDto>> ListarClientesAsync(string? busqueda, bool? esActivo, CancellationToken ct = default)
{
    var url = $"api/clientes?busqueda={Uri.EscapeDataString(busqueda ?? "")}";
    if (esActivo.HasValue) url += $"&esActivo={esActivo.Value.ToString().ToLower()}";
    return await _http.GetFromJsonAsync<IReadOnlyList<ClienteListadoWebDto>>(url, ct) ?? [];
}

public async Task<ClienteDetalleWebDto?> ObtenerClienteAsync(int id, CancellationToken ct = default) =>
    await _http.GetFromJsonAsync<ClienteDetalleWebDto?>($"api/clientes/{id}", ct);

public async Task CrearClienteAsync(CrearClienteWebRequest request, CancellationToken ct = default)
{
    var response = await _http.PostAsJsonAsync("api/clientes", request, ct);
    response.EnsureSuccessStatusCode();
}

public async Task ActualizarClienteAsync(int id, ActualizarClienteWebRequest request, CancellationToken ct = default)
{
    var response = await _http.PutAsJsonAsync($"api/clientes/{id}", request, ct);
    response.EnsureSuccessStatusCode();
}

public async Task EliminarClienteAsync(int id, CancellationToken ct = default)
{
    var response = await _http.DeleteAsync($"api/clientes/{id}", ct);
    response.EnsureSuccessStatusCode();
}

public async Task ActualizarAsociacionesClienteAsync(int id, AsociacionesClienteWebRequest request, CancellationToken ct = default)
{
    var response = await _http.PutAsJsonAsync($"api/clientes/{id}/asociaciones", request, ct);
    response.EnsureSuccessStatusCode();
}
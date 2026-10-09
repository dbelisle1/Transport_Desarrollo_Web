using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using TransPort.Web.Models;

namespace TransPort.Web.Services;

public sealed class TransportApiClient(HttpClient http, IHttpContextAccessor context) : ITransportApiClient
{
    private readonly JsonSerializerOptions _json = new(JsonSerializerDefaults.Web);

    public async Task<LoginResponseModel?> LoginAsync(LoginViewModel model, CancellationToken ct)
    {
        using var response = await http.PostAsJsonAsync("api/auth/login", new { model.NombreUsuario, model.Clave }, ct);
        if (response.StatusCode == HttpStatusCode.Unauthorized) return null;
        await EnsureAsync(response, ct);
        return await response.Content.ReadFromJsonAsync<LoginResponseModel>(_json, ct);
    }

    public Task<DashboardModel> ResumenAsync(CancellationToken ct) =>
        GetRequiredAsync<DashboardModel>("api/administracion/resumen", ct);

    public async Task<IReadOnlyList<UsuarioListadoModel>> UsuariosAsync(
        string? busqueda, bool? esActivo, int? rolId, CancellationToken ct)
    {
        var query = new List<string>();
        if (!string.IsNullOrWhiteSpace(busqueda)) query.Add($"busqueda={Uri.EscapeDataString(busqueda)}");
        if (esActivo.HasValue) query.Add($"esActivo={esActivo.Value.ToString().ToLowerInvariant()}");
        if (rolId.HasValue) query.Add($"rolId={rolId.Value}");
        return await GetRequiredAsync<List<UsuarioListadoModel>>("api/usuarios" + (query.Count > 0 ? "?" + string.Join('&', query) : ""), ct);
    }

    public async Task<UsuarioDetalleModel?> UsuarioAsync(int id, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Get, $"api/usuarios/{id}");
        using var response = await http.SendAsync(request, ct);
        if (response.StatusCode == HttpStatusCode.NotFound) return null;
        await EnsureAsync(response, ct);
        return await response.Content.ReadFromJsonAsync<UsuarioDetalleModel>(_json, ct);
    }

    public async Task<int> CrearUsuarioAsync(UsuarioFormViewModel model, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Post, "api/usuarios", new
        {
            model.NombreUsuario, model.Nombre, model.Apellido, model.Correo, model.Clave, model.EsActivo
        });
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
        return (await response.Content.ReadFromJsonAsync<ResultadoIdModel>(_json, ct))!.Id;
    }

    public async Task ActualizarUsuarioAsync(UsuarioFormViewModel model, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Put, $"api/usuarios/{model.UsuarioId}", new
        {
            model.NombreUsuario, model.Nombre, model.Apellido, model.Correo, model.EsActivo
        });
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
    }

    public async Task ActualizarAsignacionesAsync(UsuarioFormViewModel model, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Put, $"api/usuarios/{model.UsuarioId}/asignaciones", new
        {
            Roles = model.RolesSeleccionados, Giros = model.GirosSeleccionados, Sedes = model.SedesSeleccionadas
        });
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
    }

    public async Task EliminarUsuarioAsync(int id, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Delete, $"api/usuarios/{id}");
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
    }

    public async Task<IReadOnlyList<EntidadCatalogoModel>> CatalogoAsync(string tipo, CancellationToken ct) =>
        await GetRequiredAsync<List<EntidadCatalogoModel>>($"api/catalogos/{tipo}", ct);

    private async Task<T> GetRequiredAsync<T>(string uri, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Get, uri);
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
        return (await response.Content.ReadFromJsonAsync<T>(_json, ct))!;
    }

    private HttpRequestMessage Request(HttpMethod method, string uri, object? body = null)
    {
        var request = new HttpRequestMessage(method, uri);
        var token = context.HttpContext?.Session.GetString("ApiToken");
        if (!string.IsNullOrWhiteSpace(token)) request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        if (body is not null) request.Content = JsonContent.Create(body);
        return request;
    }

    private static async Task EnsureAsync(HttpResponseMessage response, CancellationToken ct)
    {
        if (response.IsSuccessStatusCode) return;
        var body = await response.Content.ReadAsStringAsync(ct);
        throw new TransportApiException(
            string.IsNullOrWhiteSpace(body) ? "La API rechazó la operación." : body,
            (int)response.StatusCode);
    }
}

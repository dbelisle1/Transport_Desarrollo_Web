using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Globalization;
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

    public Task<AuditoriaPaginaModel> AuditoriaAsync(AuditoriaFiltroViewModel filtro, CancellationToken ct)
    {
        var query = new List<string>();
        Add(query, "busqueda", filtro.Busqueda);
        Add(query, "modulo", filtro.Modulo);
        Add(query, "tipoOperacion", filtro.TipoOperacion);
        Add(query, "nombreUsuario", filtro.NombreUsuario);
        Add(query, "resultado", filtro.Resultado);
        if (filtro.FechaDesde.HasValue)
            Add(query, "fechaDesdeUtc", GuatemalaDateToUtc(filtro.FechaDesde.Value.Date).ToString("O", CultureInfo.InvariantCulture));
        if (filtro.FechaHasta.HasValue)
            Add(query, "fechaHastaUtc", GuatemalaDateToUtc(filtro.FechaHasta.Value.Date.AddDays(1)).ToString("O", CultureInfo.InvariantCulture));
        query.Add($"pagina={Math.Max(filtro.Pagina, 1)}");
        query.Add($"tamanoPagina={Math.Clamp(filtro.TamanoPagina, 10, 100)}");
        return GetRequiredAsync<AuditoriaPaginaModel>("api/administracion/auditoria?" + string.Join('&', query), ct);
    }

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

    public async Task<IReadOnlyList<ClienteListadoModel>> ClientesAsync(
        string? busqueda, bool? esActivo, CancellationToken ct)
    {
        var query = new List<string>();
        if (!string.IsNullOrWhiteSpace(busqueda)) query.Add($"busqueda={Uri.EscapeDataString(busqueda)}");
        if (esActivo.HasValue) query.Add($"esActivo={esActivo.Value.ToString().ToLowerInvariant()}");
        return await GetRequiredAsync<List<ClienteListadoModel>>(
            "api/clientes" + (query.Count > 0 ? "?" + string.Join('&', query) : ""), ct);
    }

    public async Task<ClienteDetalleModel?> ClienteAsync(int id, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Get, $"api/clientes/{id}");
        using var response = await http.SendAsync(request, ct);
        if (response.StatusCode == HttpStatusCode.NotFound) return null;
        await EnsureAsync(response, ct);
        return await response.Content.ReadFromJsonAsync<ClienteDetalleModel>(_json, ct);
    }

    public async Task<int> CrearClienteAsync(ClienteFormViewModel model, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Post, "api/clientes", new
        {
            model.Nombre, model.Nit, model.CorreoContacto, model.EsActivo,
            Usuarios = model.UsuariosSeleccionados, Giros = model.GirosSeleccionados
        });
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
        return (await response.Content.ReadFromJsonAsync<ResultadoIdModel>(_json, ct))!.Id;
    }

    public async Task ActualizarClienteAsync(ClienteFormViewModel model, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Put, $"api/clientes/{model.ClienteId}", new
        {
            model.Nombre, model.Nit, model.CorreoContacto, model.EsActivo,
            Usuarios = model.UsuariosSeleccionados, Giros = model.GirosSeleccionados
        });
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
    }

    public async Task EliminarClienteAsync(int id, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Delete, $"api/clientes/{id}");
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
    }

    public async Task<IReadOnlyList<EntidadCatalogoModel>> CatalogoAsync(string tipo, CancellationToken ct) =>
        await GetRequiredAsync<List<EntidadCatalogoModel>>($"api/catalogos/{tipo}", ct);

    public async Task<EntidadCatalogoModel?> CatalogoItemAsync(string tipo, int id, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Get, $"api/catalogos/{tipo}/{id}");
        using var response = await http.SendAsync(request, ct);
        if (response.StatusCode == HttpStatusCode.NotFound) return null;
        await EnsureAsync(response, ct);
        return await response.Content.ReadFromJsonAsync<EntidadCatalogoModel>(_json, ct);
    }

    public async Task<int> CrearCatalogoAsync(CatalogoFormViewModel model, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Post, $"api/catalogos/{model.Tipo}", new
        {
            model.Nombre, model.Descripcion, model.EsActivo
        });
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
        return (await response.Content.ReadFromJsonAsync<ResultadoIdModel>(_json, ct))!.Id;
    }

    public async Task ActualizarCatalogoAsync(CatalogoFormViewModel model, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Put, $"api/catalogos/{model.Tipo}/{model.Id}", new
        {
            model.Nombre, model.Descripcion, model.EsActivo
        });
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
    }

    public async Task EliminarCatalogoAsync(string tipo, int id, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Delete, $"api/catalogos/{tipo}/{id}");
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
    }

    public async Task<IReadOnlyList<PedidoListadoModel>> PedidosAsync(
        string? busqueda, string? estado, int? clienteId, int? giroId, CancellationToken ct)
    {
        var query = new List<string>();
        Add(query, "busqueda", busqueda);
        Add(query, "estado", estado);
        if (clienteId.HasValue) query.Add($"clienteId={clienteId.Value}");
        if (giroId.HasValue) query.Add($"giroId={giroId.Value}");
        return await GetRequiredAsync<List<PedidoListadoModel>>(
            "api/pedidos" + (query.Count > 0 ? "?" + string.Join('&', query) : ""), ct);
    }

    public async Task<PedidoDetalleModel?> PedidoAsync(long id, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Get, $"api/pedidos/{id}");
        using var response = await http.SendAsync(request, ct);
        if (response.StatusCode == HttpStatusCode.NotFound) return null;
        await EnsureAsync(response, ct);
        return await response.Content.ReadFromJsonAsync<PedidoDetalleModel>(_json, ct);
    }

    public Task<PedidoOpcionesModel> PedidoOpcionesAsync(CancellationToken ct) =>
        GetRequiredAsync<PedidoOpcionesModel>("api/pedidos/opciones", ct);

    public async Task<long> CrearPedidoAsync(PedidoCrearViewModel model, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Post, "api/pedidos", new
        {
            model.ClienteId, model.GiroNegocioId, model.TipoSolicitud, model.Titulo,
            model.Descripcion, model.FechaRequerida, model.FechaReunionUtc
        });
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
        return (await response.Content.ReadFromJsonAsync<ResultadoIdModel>(_json, ct))!.Id;
    }

    public async Task GestionarPedidoAsync(PedidoGestionViewModel model, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Put, $"api/pedidos/{model.PedidoId}/gestion", new
        {
            model.Estado, model.VendedorUsuarioId, model.MontoCotizado,
            model.FechaReunionUtc, model.EnlaceReunion, model.Comentario
        });
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
    }

    public async Task ComentarPedidoAsync(long id, string comentario, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Post, $"api/pedidos/{id}/comentarios", new { comentario });
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
    }

    public async Task AgregarDocumentoPedidoAsync(
        long id, string nombre, string tipoDocumento, string url, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Post, $"api/pedidos/{id}/documentos", new { nombre, tipoDocumento, url });
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
    }

    public async Task EliminarPedidoAsync(long id, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Delete, $"api/pedidos/{id}");
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
    }

    public Task<PortalClienteResumenModel> PortalClienteResumenAsync(CancellationToken ct) =>
        GetRequiredAsync<PortalClienteResumenModel>("api/portal-cliente/resumen", ct);

    public async Task<IReadOnlyList<InventarioExistenciaModel>> InventarioAsync(string? busqueda,int? giroId,int? sedeId,bool soloBajoMinimo,CancellationToken ct)
    {
        var q=new List<string>();Add(q,"busqueda",busqueda);if(giroId.HasValue)q.Add($"giroId={giroId}");if(sedeId.HasValue)q.Add($"sedeId={sedeId}");if(soloBajoMinimo)q.Add("soloBajoMinimo=true");
        return await GetRequiredAsync<List<InventarioExistenciaModel>>("api/inventarios"+(q.Count>0?"?"+string.Join('&',q):""),ct);
    }
    public async Task<IReadOnlyList<InventarioMovimientoModel>> InventarioMovimientosAsync(int? articuloId,int limite,CancellationToken ct)=>
        await GetRequiredAsync<List<InventarioMovimientoModel>>($"api/inventarios/movimientos?limite={limite}"+(articuloId.HasValue?$"&articuloId={articuloId}":""),ct);
    public Task<InventarioOpcionesModel> InventarioOpcionesAsync(CancellationToken ct)=>GetRequiredAsync<InventarioOpcionesModel>("api/inventarios/opciones",ct);
    public async Task CrearInventarioArticuloAsync(InventarioArticuloFormModel model,CancellationToken ct){using var request=Request(HttpMethod.Post,"api/inventarios/articulos",model);using var response=await http.SendAsync(request,ct);await EnsureAsync(response,ct);}
    public async Task RegistrarInventarioMovimientoAsync(InventarioMovimientoFormModel model,CancellationToken ct){using var request=Request(HttpMethod.Post,"api/inventarios/movimientos",model);using var response=await http.SendAsync(request,ct);await EnsureAsync(response,ct);}
    public async Task<IReadOnlyList<AbastecimientoListadoModel>> AbastecimientosAsync(string? estado,string? busqueda,CancellationToken ct){var q=new List<string>();Add(q,"estado",estado);Add(q,"busqueda",busqueda);return await GetRequiredAsync<List<AbastecimientoListadoModel>>("api/abastecimientos"+(q.Count>0?"?"+string.Join('&',q):""),ct);}
    public async Task<AbastecimientoDetalleModel?> AbastecimientoAsync(long id,CancellationToken ct){using var req=Request(HttpMethod.Get,$"api/abastecimientos/{id}");using var res=await http.SendAsync(req,ct);if(res.StatusCode==HttpStatusCode.NotFound)return null;await EnsureAsync(res,ct);return await res.Content.ReadFromJsonAsync<AbastecimientoDetalleModel>(_json,ct);}
    public Task<AbastecimientoOpcionesModel> AbastecimientoOpcionesAsync(CancellationToken ct)=>GetRequiredAsync<AbastecimientoOpcionesModel>("api/abastecimientos/opciones",ct);
    public async Task<long> CrearAbastecimientoAsync(AbastecimientoCrearViewModel m,CancellationToken ct){using var req=Request(HttpMethod.Post,"api/abastecimientos",new{m.GiroSolicitanteId,m.SedeSolicitanteId,m.GiroProveedorId,m.SedeProveedorId,m.FechaNecesaria,m.Motivo,Detalles=new[]{new{m.ArticuloProveedorId,m.ArticuloDestinoId,m.Cantidad}}});using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);using var json=await JsonDocument.ParseAsync(await res.Content.ReadAsStreamAsync(ct),cancellationToken:ct);return json.RootElement.GetProperty("id").GetInt64();}
    public async Task CambiarEstadoAbastecimientoAsync(long id,string estado,string? comentario,CancellationToken ct){using var req=Request(HttpMethod.Put,$"api/abastecimientos/{id}/estado",new{estado,comentario});using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}
    public async Task ComentarAbastecimientoAsync(long id,string comentario,CancellationToken ct){using var req=Request(HttpMethod.Post,$"api/abastecimientos/{id}/comentarios",new{comentario});using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}
    public async Task EliminarAbastecimientoAsync(long id,CancellationToken ct){using var req=Request(HttpMethod.Delete,$"api/abastecimientos/{id}");using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}

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

    private static void Add(List<string> query, string name, string? value)
    {
        if (!string.IsNullOrWhiteSpace(value)) query.Add($"{name}={Uri.EscapeDataString(value.Trim())}");
    }

    private static DateTime GuatemalaDateToUtc(DateTime value)
    {
        var unspecified = DateTime.SpecifyKind(value, DateTimeKind.Unspecified);
        return TimeZoneInfo.ConvertTimeToUtc(unspecified, GuatemalaTimeZone());
    }

    private static TimeZoneInfo GuatemalaTimeZone()
    {
        try { return TimeZoneInfo.FindSystemTimeZoneById("America/Guatemala"); }
        catch (TimeZoneNotFoundException) { return TimeZoneInfo.FindSystemTimeZoneById("Central America Standard Time"); }
    }
}

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

    public async Task<IReadOnlyList<OfertaCatalogoModel>> CatalogoPublicoAsync(
        int? giroId, string? tipo, CancellationToken ct)
    {
        var query = new List<string>();
        if (giroId.HasValue) query.Add($"giroId={giroId.Value}");
        Add(query, "tipo", tipo);
        return await GetRequiredAsync<List<OfertaCatalogoModel>>(
            "api/catalogo-comercial/publico" + (query.Count > 0 ? "?" + string.Join('&', query) : ""), ct);
    }

    public async Task<IReadOnlyList<OfertaCatalogoModel>> CatalogoComercialAsync(
        string? busqueda, int? giroId, string? tipo, bool? esActivo, CancellationToken ct)
    {
        var query = new List<string>();
        Add(query, "busqueda", busqueda);
        if (giroId.HasValue) query.Add($"giroId={giroId.Value}");
        Add(query, "tipo", tipo);
        if (esActivo.HasValue) query.Add($"esActivo={esActivo.Value.ToString().ToLowerInvariant()}");
        return await GetRequiredAsync<List<OfertaCatalogoModel>>(
            "api/catalogo-comercial" + (query.Count > 0 ? "?" + string.Join('&', query) : ""), ct);
    }

    public Task<CatalogoComercialOpcionesModel> CatalogoComercialOpcionesAsync(CancellationToken ct) =>
        GetRequiredAsync<CatalogoComercialOpcionesModel>("api/catalogo-comercial/opciones", ct);

    public async Task<int> CrearOfertaCatalogoAsync(OfertaCatalogoEditarViewModel model, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Post, "api/catalogo-comercial", model);
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
        return (await response.Content.ReadFromJsonAsync<ResultadoIdModel>(_json, ct))!.Id;
    }

    public async Task ActualizarOfertaCatalogoAsync(OfertaCatalogoEditarViewModel model, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Put, $"api/catalogo-comercial/{model.CatalogoOfertaId}", model);
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
    }

    public async Task EliminarOfertaCatalogoAsync(int id, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Delete, $"api/catalogo-comercial/{id}");
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
    }

    public async Task<IReadOnlyList<ComunicacionListadoModel>> ComunicacionesAsync(
        string? estado, string? tipo, string? busqueda, CancellationToken ct)
    {
        var query = new List<string>();
        Add(query, "estado", estado);
        Add(query, "tipo", tipo);
        Add(query, "busqueda", busqueda);
        return await GetRequiredAsync<List<ComunicacionListadoModel>>(
            "api/comunicaciones" + (query.Count > 0 ? "?" + string.Join('&', query) : ""), ct);
    }

    public async Task<ComunicacionDetalleModel?> ComunicacionAsync(long id, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Get, $"api/comunicaciones/{id}");
        using var response = await http.SendAsync(request, ct);
        if (response.StatusCode == HttpStatusCode.NotFound) return null;
        await EnsureAsync(response, ct);
        return await response.Content.ReadFromJsonAsync<ComunicacionDetalleModel>(_json, ct);
    }

    public Task<ComunicacionOpcionesModel> ComunicacionOpcionesAsync(CancellationToken ct) =>
        GetRequiredAsync<ComunicacionOpcionesModel>("api/comunicaciones/opciones", ct);

    public async Task<long> CrearComunicacionAsync(ComunicacionCrearViewModel model, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Post, "api/comunicaciones", model);
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
        return (await response.Content.ReadFromJsonAsync<ResultadoIdModel>(_json, ct))!.Id;
    }

    public async Task<long> AgregarMensajeComunicacionAsync(
        long id, string mensaje, bool esInterno, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Post, $"api/comunicaciones/{id}/mensajes", new { mensaje, esInterno });
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
        return (await response.Content.ReadFromJsonAsync<ResultadoIdModel>(_json, ct))!.Id;
    }

    public async Task GestionarComunicacionAsync(
        long id, string estado, int? responsableUsuarioId, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Put, $"api/comunicaciones/{id}/gestion", new { estado, responsableUsuarioId });
        using var response = await http.SendAsync(request, ct);
        await EnsureAsync(response, ct);
    }

    public async Task EliminarComunicacionAsync(long id, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Delete, $"api/comunicaciones/{id}");
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
            model.Descripcion, model.FechaRequerida, model.FechaReunionUtc,
            Lineas = model.Lineas.Where(x => x.CatalogoOfertaId > 0 && x.Cantidad > 0)
                .Select(x => new { x.CatalogoOfertaId, x.Cantidad }).ToArray()
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

    public async Task CotizarPedidoLineaAsync(
        long id, long lineaId, decimal precioUnitario, CancellationToken ct)
    {
        using var request = Request(HttpMethod.Put, $"api/pedidos/{id}/lineas/{lineaId}/cotizacion", new { precioUnitario });
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
    public async Task<IReadOnlyList<ExtraccionListadoModel>> ExtraccionesAsync(string? estado,int? sedeId,DateTime? fechaDesde,DateTime? fechaHasta,CancellationToken ct){var q=new List<string>();Add(q,"estado",estado);if(sedeId.HasValue)q.Add($"sedeId={sedeId.Value}");if(fechaDesde.HasValue)q.Add($"fechaDesde={fechaDesde:yyyy-MM-dd}");if(fechaHasta.HasValue)q.Add($"fechaHasta={fechaHasta:yyyy-MM-dd}");return await GetRequiredAsync<List<ExtraccionListadoModel>>("api/extracciones"+(q.Count>0?"?"+string.Join('&',q):""),ct);}
    public async Task<ExtraccionDetalleModel?> ExtraccionAsync(long id,CancellationToken ct){using var req=Request(HttpMethod.Get,$"api/extracciones/{id}");using var res=await http.SendAsync(req,ct);if(res.StatusCode==HttpStatusCode.NotFound)return null;await EnsureAsync(res,ct);return await res.Content.ReadFromJsonAsync<ExtraccionDetalleModel>(_json,ct);}
    public Task<ExtraccionOpcionesModel> ExtraccionOpcionesAsync(CancellationToken ct)=>GetRequiredAsync<ExtraccionOpcionesModel>("api/extracciones/opciones",ct);
    public async Task<long> CrearExtraccionAsync(ExtraccionCrearViewModel m,CancellationToken ct){using var req=Request(HttpMethod.Post,"api/extracciones",m);using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);using var json=await JsonDocument.ParseAsync(await res.Content.ReadAsStreamAsync(ct),cancellationToken:ct);return json.RootElement.GetProperty("id").GetInt64();}
    public async Task CambiarEstadoExtraccionAsync(long id,string estado,string? comentario,CancellationToken ct){using var req=Request(HttpMethod.Put,$"api/extracciones/{id}/estado",new{estado,comentario});using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}
    public async Task EliminarExtraccionAsync(long id,CancellationToken ct){using var req=Request(HttpMethod.Delete,$"api/extracciones/{id}");using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}
    public async Task<IReadOnlyList<ProduccionListadoModel>> ProduccionesAsync(string?estado,int?sedeId,DateTime?desde,DateTime?hasta,CancellationToken ct){var q=new List<string>();Add(q,"estado",estado);if(sedeId.HasValue)q.Add($"sedeId={sedeId}");if(desde.HasValue)q.Add($"fechaDesde={desde:yyyy-MM-dd}");if(hasta.HasValue)q.Add($"fechaHasta={hasta:yyyy-MM-dd}");return await GetRequiredAsync<List<ProduccionListadoModel>>("api/producciones"+(q.Count>0?"?"+string.Join('&',q):""),ct);}
    public async Task<ProduccionDetalleModel?> ProduccionAsync(long id,CancellationToken ct){using var req=Request(HttpMethod.Get,$"api/producciones/{id}");using var res=await http.SendAsync(req,ct);if(res.StatusCode==HttpStatusCode.NotFound)return null;await EnsureAsync(res,ct);return await res.Content.ReadFromJsonAsync<ProduccionDetalleModel>(_json,ct);}
    public Task<ProduccionOpcionesModel> ProduccionOpcionesAsync(CancellationToken ct)=>GetRequiredAsync<ProduccionOpcionesModel>("api/producciones/opciones",ct);
    public async Task<long> CrearProduccionAsync(ProduccionCrearViewModel m,CancellationToken ct){using var req=Request(HttpMethod.Post,"api/producciones",m);using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);using var json=await JsonDocument.ParseAsync(await res.Content.ReadAsStreamAsync(ct),cancellationToken:ct);return json.RootElement.GetProperty("id").GetInt64();}
    public async Task CambiarEstadoProduccionAsync(long id,string estado,decimal?cantidadSalidaReal,decimal?cantidadMerma,decimal?costoUnitario,string?comentario,CancellationToken ct){using var req=Request(HttpMethod.Put,$"api/producciones/{id}/estado",new{estado,cantidadSalidaReal,cantidadMerma,costoUnitario,comentario});using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}
    public async Task CompletarEtapaProduccionAsync(long id,long etapaId,string?observacion,CancellationToken ct){using var req=Request(HttpMethod.Put,$"api/producciones/{id}/etapas/{etapaId}/completar",new{observacion});using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}
    public async Task EliminarProduccionAsync(long id,CancellationToken ct){using var req=Request(HttpMethod.Delete,$"api/producciones/{id}");using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}
    public async Task<IReadOnlyList<MaquinariaEquipoModel>> MaquinariasAsync(string?estado,int?sedeId,string?busqueda,CancellationToken ct){var q=new List<string>();Add(q,"estado",estado);Add(q,"busqueda",busqueda);if(sedeId.HasValue)q.Add($"sedeId={sedeId}");return await GetRequiredAsync<List<MaquinariaEquipoModel>>("api/maquinarias"+(q.Count>0?"?"+string.Join('&',q):""),ct);}public async Task<MaquinariaDetalleModel?> MaquinariaAsync(int id,CancellationToken ct){using var req=Request(HttpMethod.Get,$"api/maquinarias/{id}");using var res=await http.SendAsync(req,ct);if(res.StatusCode==HttpStatusCode.NotFound)return null;await EnsureAsync(res,ct);return await res.Content.ReadFromJsonAsync<MaquinariaDetalleModel>(_json,ct);}public Task<MaquinariaOpcionesModel> MaquinariaOpcionesAsync(CancellationToken ct)=>GetRequiredAsync<MaquinariaOpcionesModel>("api/maquinarias/opciones",ct);public async Task<int> CrearMaquinariaAsync(MaquinariaCrearViewModel m,CancellationToken ct){using var req=Request(HttpMethod.Post,"api/maquinarias",m);using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);using var j=await JsonDocument.ParseAsync(await res.Content.ReadAsStreamAsync(ct),cancellationToken:ct);return j.RootElement.GetProperty("id").GetInt32();}public async Task<long> CrearContratoMaquinariaAsync(MaquinariaContratoCrearViewModel m,CancellationToken ct){using var req=Request(HttpMethod.Post,"api/maquinarias/contratos",m);using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);using var j=await JsonDocument.ParseAsync(await res.Content.ReadAsStreamAsync(ct),cancellationToken:ct);return j.RootElement.GetProperty("id").GetInt64();}public async Task EstadoContratoMaquinariaAsync(long id,string estado,decimal?horasDevolucion,string?observacion,CancellationToken ct){using var req=Request(HttpMethod.Put,$"api/maquinarias/contratos/{id}/estado",new{estado,horasDevolucion,observacion});using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}public async Task<long> CrearMantenimientoMaquinariaAsync(MaquinariaMantenimientoCrearViewModel m,CancellationToken ct){using var req=Request(HttpMethod.Post,"api/maquinarias/mantenimientos",m);using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);using var j=await JsonDocument.ParseAsync(await res.Content.ReadAsStreamAsync(ct),cancellationToken:ct);return j.RootElement.GetProperty("id").GetInt64();}public async Task EstadoMantenimientoMaquinariaAsync(long id,string estado,string?observacion,CancellationToken ct){using var req=Request(HttpMethod.Put,$"api/maquinarias/mantenimientos/{id}/estado",new{estado,observacion});using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}public async Task EliminarMaquinariaAsync(int id,CancellationToken ct){using var req=Request(HttpMethod.Delete,$"api/maquinarias/{id}");using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}
    public async Task<IReadOnlyList<TransporteViajeListadoModel>> TransportesAsync(string?estado,string?tipo,int?sedeId,CancellationToken ct){var q=new List<string>();Add(q,"estado",estado);Add(q,"tipo",tipo);if(sedeId.HasValue)q.Add($"sedeId={sedeId}");return await GetRequiredAsync<List<TransporteViajeListadoModel>>("api/transportes"+(q.Count>0?"?"+string.Join('&',q):""),ct);}public async Task<TransporteViajeDetalleModel?> TransporteAsync(long id,CancellationToken ct){using var req=Request(HttpMethod.Get,$"api/transportes/{id}");using var res=await http.SendAsync(req,ct);if(res.StatusCode==HttpStatusCode.NotFound)return null;await EnsureAsync(res,ct);return await res.Content.ReadFromJsonAsync<TransporteViajeDetalleModel>(_json,ct);}public Task<TransporteOpcionesModel> TransporteOpcionesAsync(CancellationToken ct)=>GetRequiredAsync<TransporteOpcionesModel>("api/transportes/opciones",ct);private async Task<long> PostId(string uri,object body,CancellationToken ct){using var req=Request(HttpMethod.Post,uri,body);using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);using var j=await JsonDocument.ParseAsync(await res.Content.ReadAsStreamAsync(ct),cancellationToken:ct);return j.RootElement.GetProperty("id").GetInt64();}public async Task<int> CrearVehiculoTransporteAsync(TransporteVehiculoCrearViewModel m,CancellationToken ct)=>(int)await PostId("api/transportes/vehiculos",m,ct);public async Task<int> CrearConductorTransporteAsync(TransporteConductorCrearViewModel m,CancellationToken ct)=>(int)await PostId("api/transportes/conductores",m,ct);public Task<long> CrearViajeTransporteAsync(TransporteViajeCrearViewModel m,CancellationToken ct)=>PostId("api/transportes",m,ct);public async Task EstadoViajeTransporteAsync(long id,string estado,string?observacion,CancellationToken ct){using var req=Request(HttpMethod.Put,$"api/transportes/{id}/estado",new{estado,observacion});using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}public Task<long> CrearIncidenciaTransporteAsync(long id,string tipo,string severidad,string descripcion,CancellationToken ct)=>PostId($"api/transportes/{id}/incidencias",new{tipo,severidad,descripcion},ct);public async Task ResolverIncidenciaTransporteAsync(long id,string resolucion,CancellationToken ct){using var req=Request(HttpMethod.Put,$"api/transportes/incidencias/{id}/resolver",new{resolucion});using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}public async Task EliminarViajeTransporteAsync(long id,CancellationToken ct){using var req=Request(HttpMethod.Delete,$"api/transportes/{id}");using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}public async Task EliminarRecursoTransporteAsync(string tipo,int id,CancellationToken ct){using var req=Request(HttpMethod.Delete,$"api/transportes/recursos/{tipo}/{id}");using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}
    public Task<GpsResumenModel> GpsResumenAsync(CancellationToken ct)=>GetRequiredAsync<GpsResumenModel>("api/gps",ct);public Task<GpsOpcionesModel> GpsOpcionesAsync(CancellationToken ct)=>GetRequiredAsync<GpsOpcionesModel>("api/gps/opciones",ct);public async Task<IReadOnlyList<GpsPosicionModel>> GpsRecorridoAsync(int id,DateTime?desde,DateTime?hasta,CancellationToken ct){var q=new List<string>();if(desde.HasValue)q.Add($"desde={Uri.EscapeDataString(desde.Value.ToString("O"))}");if(hasta.HasValue)q.Add($"hasta={Uri.EscapeDataString(hasta.Value.ToString("O"))}");return await GetRequiredAsync<List<GpsPosicionModel>>($"api/gps/dispositivos/{id}/recorrido"+(q.Count>0?"?"+string.Join('&',q):""),ct);}public async Task<int> CrearGpsDispositivoAsync(GpsDispositivoCrearViewModel m,CancellationToken ct)=>(int)await PostId("api/gps/dispositivos",m,ct);public Task<long> SimularGpsAsync(int dispositivoId,string datosFuente,CancellationToken ct)=>PostId("api/gps/simular",new{dispositivoId,datosFuente},ct);public async Task AtenderGpsAlertaAsync(long id,CancellationToken ct){using var req=Request(HttpMethod.Put,$"api/gps/alertas/{id}/atender");using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}public async Task EliminarGpsDispositivoAsync(int id,CancellationToken ct){using var req=Request(HttpMethod.Delete,$"api/gps/dispositivos/{id}");using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}
    public async Task<IReadOnlyList<ConstruccionListadoModel>> ConstruccionesAsync(string?estado,int?sedeId,string?busqueda,CancellationToken ct){var q=new List<string>();Add(q,"estado",estado);Add(q,"busqueda",busqueda);if(sedeId.HasValue)q.Add($"sedeId={sedeId}");return await GetRequiredAsync<List<ConstruccionListadoModel>>("api/construcciones"+(q.Count>0?"?"+string.Join('&',q):""),ct);}public async Task<ConstruccionDetalleModel?> ConstruccionAsync(long id,CancellationToken ct){using var req=Request(HttpMethod.Get,$"api/construcciones/{id}");using var res=await http.SendAsync(req,ct);if(res.StatusCode==HttpStatusCode.NotFound)return null;await EnsureAsync(res,ct);return await res.Content.ReadFromJsonAsync<ConstruccionDetalleModel>(_json,ct);}public Task<ConstruccionOpcionesModel> ConstruccionOpcionesAsync(CancellationToken ct)=>GetRequiredAsync<ConstruccionOpcionesModel>("api/construcciones/opciones",ct);public Task<long> CrearConstruccionAsync(ConstruccionCrearViewModel m,CancellationToken ct)=>PostId("api/construcciones",m,ct);public Task<long> CrearActividadConstruccionAsync(long id,ConstruccionActividadCrearViewModel m,CancellationToken ct)=>PostId($"api/construcciones/{id}/actividades",m,ct);public Task<long> RegistrarAvanceConstruccionAsync(long id,decimal porcentaje,string comentario,string?evidenciaUrl,CancellationToken ct)=>PostId($"api/construcciones/actividades/{id}/avances",new{porcentaje,comentario,evidenciaUrl},ct);public Task<long> AsignarRecursoConstruccionAsync(long id,ConstruccionRecursoCrearViewModel m,CancellationToken ct)=>PostId($"api/construcciones/{id}/recursos",m,ct);public async Task EstadoConstruccionAsync(long id,string estado,CancellationToken ct){using var req=Request(HttpMethod.Put,$"api/construcciones/{id}/estado",new{estado});using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}public async Task EliminarConstruccionAsync(long id,CancellationToken ct){using var req=Request(HttpMethod.Delete,$"api/construcciones/{id}");using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}
    public async Task<IReadOnlyList<PresupuestoListadoModel>> PresupuestosAsync(short?anio,byte?mes,int?giroId,int?sedeId,CancellationToken ct){var q=new List<string>();if(anio.HasValue)q.Add($"anio={anio}");if(mes.HasValue)q.Add($"mes={mes}");if(giroId.HasValue)q.Add($"giroId={giroId}");if(sedeId.HasValue)q.Add($"sedeId={sedeId}");return await GetRequiredAsync<List<PresupuestoListadoModel>>("api/finanzas"+(q.Count>0?"?"+string.Join('&',q):""),ct);}public async Task<PresupuestoDetalleModel?> PresupuestoAsync(long id,CancellationToken ct){using var req=Request(HttpMethod.Get,$"api/finanzas/{id}");using var res=await http.SendAsync(req,ct);if(res.StatusCode==HttpStatusCode.NotFound)return null;await EnsureAsync(res,ct);return await res.Content.ReadFromJsonAsync<PresupuestoDetalleModel>(_json,ct);}public Task<FinanzaOpcionesModel> FinanzaOpcionesAsync(CancellationToken ct)=>GetRequiredAsync<FinanzaOpcionesModel>("api/finanzas/opciones",ct);public Task<long> CrearPresupuestoAsync(PresupuestoCrearViewModel m,CancellationToken ct)=>PostId("api/finanzas",m,ct);public Task<long> RegistrarGastoAsync(long id,GastoCrearViewModel m,CancellationToken ct)=>PostId($"api/finanzas/{id}/gastos",m,ct);public async Task EstadoPresupuestoAsync(long id,string estado,CancellationToken ct){using var req=Request(HttpMethod.Put,$"api/finanzas/{id}/estado",new{estado});using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}public async Task EliminarPresupuestoAsync(long id,CancellationToken ct){using var req=Request(HttpMethod.Delete,$"api/finanzas/{id}");using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}
    public async Task<IReadOnlyList<AlertaListadoModel>> AlertasAsync(string?estado,bool soloPendientes,CancellationToken ct){var q=new List<string>();Add(q,"estado",estado);if(soloPendientes)q.Add("soloPendientes=true");return await GetRequiredAsync<List<AlertaListadoModel>>("api/alertas"+(q.Count>0?"?"+string.Join('&',q):""),ct);}public async Task<AlertaDetalleModel?> AlertaAsync(long id,CancellationToken ct){using var req=Request(HttpMethod.Get,$"api/alertas/{id}");using var res=await http.SendAsync(req,ct);if(res.StatusCode==HttpStatusCode.NotFound)return null;await EnsureAsync(res,ct);return await res.Content.ReadFromJsonAsync<AlertaDetalleModel>(_json,ct);}public Task<AlertaOpcionesModel> AlertaOpcionesAsync(CancellationToken ct)=>GetRequiredAsync<AlertaOpcionesModel>("api/alertas/opciones",ct);public Task<long> CrearAlertaAsync(AlertaCrearViewModel m,CancellationToken ct)=>PostId("api/alertas",m,ct);public async Task MarcarAlertaLeidaAsync(long id,CancellationToken ct){using var req=Request(HttpMethod.Put,$"api/alertas/{id}/leer");using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}public Task<long> SeguimientoAlertaAsync(long id,string comentario,CancellationToken ct)=>PostId($"api/alertas/{id}/seguimientos",new{comentario},ct);public async Task EstadoAlertaAsync(long id,string estado,CancellationToken ct){using var req=Request(HttpMethod.Put,$"api/alertas/{id}/estado",new{estado});using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}public async Task EliminarAlertaAsync(long id,CancellationToken ct){using var req=Request(HttpMethod.Delete,$"api/alertas/{id}");using var res=await http.SendAsync(req,ct);await EnsureAsync(res,ct);}

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

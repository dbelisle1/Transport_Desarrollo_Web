using System.Diagnostics.CodeAnalysis;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Controllers;
using Microsoft.AspNetCore.Mvc.Routing;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using TransPort.Web.Controllers;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Tests;

public sealed class AccesoControllerTests
{
    [Fact]
    public async Task Salir_LimpiaSesionYCierraAutenticacion()
    {
        var session = new FakeSession();
        session.SetString("ApiToken", "token-prueba");
        var authentication = new RecordingAuthenticationService();
        var services = new ServiceCollection()
            .AddSingleton<IAuthenticationService>(authentication)
            .BuildServiceProvider();
        var httpContext = new DefaultHttpContext
        {
            Session = session,
            RequestServices = services
        };
        var controller = new AccesoController(new UnusedApiClient(), NullLogger<AccesoController>.Instance)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = httpContext,
                RouteData = new RouteData(),
                ActionDescriptor = new ControllerActionDescriptor()
            }
        };
        controller.Url = new UrlHelper(controller.ControllerContext);

        var result = await controller.Salir();

        var redirect = Assert.IsType<RedirectToActionResult>(result);
        Assert.Equal(nameof(AccesoController.Index), redirect.ActionName);
        Assert.Empty(session.Keys);
        Assert.True(session.WasCommitted);
        Assert.Equal(CookieAuthenticationDefaults.AuthenticationScheme, authentication.SignedOutScheme);
        Assert.Contains(httpContext.Response.Headers.SetCookie,
            value => value?.Contains("TransPort.Session=", StringComparison.Ordinal) == true);
    }

    private sealed class FakeSession : ISession
    {
        private readonly Dictionary<string, byte[]> _values = [];

        public bool WasCommitted { get; private set; }
        public bool IsAvailable => true;
        public string Id { get; } = Guid.NewGuid().ToString("N");
        public IEnumerable<string> Keys => _values.Keys;

        public void Clear() => _values.Clear();
        public Task CommitAsync(CancellationToken cancellationToken = default)
        {
            WasCommitted = true;
            return Task.CompletedTask;
        }
        public Task LoadAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
        public void Remove(string key) => _values.Remove(key);
        public void Set(string key, byte[] value) => _values[key] = value;
        public bool TryGetValue(string key, [NotNullWhen(true)] out byte[]? value) =>
            _values.TryGetValue(key, out value);
    }

    private sealed class RecordingAuthenticationService : IAuthenticationService
    {
        public string? SignedOutScheme { get; private set; }

        public Task<AuthenticateResult> AuthenticateAsync(HttpContext context, string? scheme) =>
            Task.FromResult(AuthenticateResult.NoResult());
        public Task ChallengeAsync(HttpContext context, string? scheme, AuthenticationProperties? properties) =>
            Task.CompletedTask;
        public Task ForbidAsync(HttpContext context, string? scheme, AuthenticationProperties? properties) =>
            Task.CompletedTask;
        public Task SignInAsync(HttpContext context, string? scheme, System.Security.Claims.ClaimsPrincipal principal,
            AuthenticationProperties? properties) => Task.CompletedTask;
        public Task SignOutAsync(HttpContext context, string? scheme, AuthenticationProperties? properties)
        {
            SignedOutScheme = scheme;
            return Task.CompletedTask;
        }
    }

    private sealed class UnusedApiClient : ITransportApiClient
    {
        private static Exception NotUsed() => new InvalidOperationException("La API no debe invocarse al cerrar sesión.");

        public Task<LoginResponseModel?> LoginAsync(LoginViewModel model, CancellationToken ct) => throw NotUsed();
        public Task<DashboardModel> ResumenAsync(CancellationToken ct) => throw NotUsed();
        public Task<AuditoriaPaginaModel> AuditoriaAsync(AuditoriaFiltroViewModel filtro, CancellationToken ct) => throw NotUsed();
        public Task<IReadOnlyList<UsuarioListadoModel>> UsuariosAsync(string? busqueda, bool? esActivo, int? rolId, CancellationToken ct) => throw NotUsed();
        public Task<UsuarioDetalleModel?> UsuarioAsync(int id, CancellationToken ct) => throw NotUsed();
        public Task<int> CrearUsuarioAsync(UsuarioFormViewModel model, CancellationToken ct) => throw NotUsed();
        public Task ActualizarUsuarioAsync(UsuarioFormViewModel model, CancellationToken ct) => throw NotUsed();
        public Task ActualizarAsignacionesAsync(UsuarioFormViewModel model, CancellationToken ct) => throw NotUsed();
        public Task EliminarUsuarioAsync(int id, CancellationToken ct) => throw NotUsed();
        public Task<IReadOnlyList<ClienteListadoModel>> ClientesAsync(string? busqueda, bool? esActivo, CancellationToken ct) => throw NotUsed();
        public Task<ClienteDetalleModel?> ClienteAsync(int id, CancellationToken ct) => throw NotUsed();
        public Task<int> CrearClienteAsync(ClienteFormViewModel model, CancellationToken ct) => throw NotUsed();
        public Task ActualizarClienteAsync(ClienteFormViewModel model, CancellationToken ct) => throw NotUsed();
        public Task EliminarClienteAsync(int id, CancellationToken ct) => throw NotUsed();
        public Task<IReadOnlyList<EntidadCatalogoModel>> CatalogoAsync(string tipo, CancellationToken ct) => throw NotUsed();
        public Task<EntidadCatalogoModel?> CatalogoItemAsync(string tipo, int id, CancellationToken ct) => throw NotUsed();
        public Task<int> CrearCatalogoAsync(CatalogoFormViewModel model, CancellationToken ct) => throw NotUsed();
        public Task ActualizarCatalogoAsync(CatalogoFormViewModel model, CancellationToken ct) => throw NotUsed();
        public Task EliminarCatalogoAsync(string tipo, int id, CancellationToken ct) => throw NotUsed();
        public Task<IReadOnlyList<PedidoListadoModel>> PedidosAsync(string? busqueda, string? estado, int? clienteId, int? giroId, CancellationToken ct) => throw NotUsed();
        public Task<PedidoDetalleModel?> PedidoAsync(long id, CancellationToken ct) => throw NotUsed();
        public Task<PedidoOpcionesModel> PedidoOpcionesAsync(CancellationToken ct) => throw NotUsed();
        public Task<long> CrearPedidoAsync(PedidoCrearViewModel model, CancellationToken ct) => throw NotUsed();
        public Task GestionarPedidoAsync(PedidoGestionViewModel model, CancellationToken ct) => throw NotUsed();
        public Task ComentarPedidoAsync(long id, string comentario, CancellationToken ct) => throw NotUsed();
        public Task AgregarDocumentoPedidoAsync(long id, string nombre, string tipoDocumento, string url, CancellationToken ct) => throw NotUsed();
        public Task EliminarPedidoAsync(long id, CancellationToken ct) => throw NotUsed();
        public Task<IReadOnlyList<OfertaCatalogoModel>> CatalogoPublicoAsync(int? giroId,string? tipo,CancellationToken ct)=>throw NotUsed();public Task<IReadOnlyList<OfertaCatalogoModel>> CatalogoComercialAsync(string? busqueda,int? giroId,string? tipo,bool? esActivo,CancellationToken ct)=>throw NotUsed();public Task<CatalogoComercialOpcionesModel> CatalogoComercialOpcionesAsync(CancellationToken ct)=>throw NotUsed();public Task<int> CrearOfertaCatalogoAsync(OfertaCatalogoEditarViewModel model,CancellationToken ct)=>throw NotUsed();public Task ActualizarOfertaCatalogoAsync(OfertaCatalogoEditarViewModel model,CancellationToken ct)=>throw NotUsed();public Task EliminarOfertaCatalogoAsync(int id,CancellationToken ct)=>throw NotUsed();public Task CotizarPedidoLineaAsync(long id,long lineaId,decimal precioUnitario,CancellationToken ct)=>throw NotUsed();
        public Task<PortalClienteResumenModel> PortalClienteResumenAsync(CancellationToken ct) => throw NotUsed();
        public Task<IReadOnlyList<InventarioExistenciaModel>> InventarioAsync(string? busqueda,int? giroId,int? sedeId,bool soloBajoMinimo,CancellationToken ct)=>throw NotUsed();
        public Task<IReadOnlyList<InventarioMovimientoModel>> InventarioMovimientosAsync(int? articuloId,int limite,CancellationToken ct)=>throw NotUsed();
        public Task<InventarioOpcionesModel> InventarioOpcionesAsync(CancellationToken ct)=>throw NotUsed();
        public Task CrearInventarioArticuloAsync(InventarioArticuloFormModel model,CancellationToken ct)=>throw NotUsed();
        public Task RegistrarInventarioMovimientoAsync(InventarioMovimientoFormModel model,CancellationToken ct)=>throw NotUsed();
        public Task<IReadOnlyList<AbastecimientoListadoModel>> AbastecimientosAsync(string? estado,string? busqueda,CancellationToken ct)=>throw NotUsed();
        public Task<AbastecimientoDetalleModel?> AbastecimientoAsync(long id,CancellationToken ct)=>throw NotUsed();
        public Task<AbastecimientoOpcionesModel> AbastecimientoOpcionesAsync(CancellationToken ct)=>throw NotUsed();
        public Task<long> CrearAbastecimientoAsync(AbastecimientoCrearViewModel model,CancellationToken ct)=>throw NotUsed();
        public Task CambiarEstadoAbastecimientoAsync(long id,string estado,string? comentario,CancellationToken ct)=>throw NotUsed();
        public Task ComentarAbastecimientoAsync(long id,string comentario,CancellationToken ct)=>throw NotUsed();
        public Task EliminarAbastecimientoAsync(long id,CancellationToken ct)=>throw NotUsed();
        public Task<IReadOnlyList<ExtraccionListadoModel>> ExtraccionesAsync(string? estado,int? sedeId,DateTime? fechaDesde,DateTime? fechaHasta,CancellationToken ct)=>throw NotUsed();
        public Task<ExtraccionDetalleModel?> ExtraccionAsync(long id,CancellationToken ct)=>throw NotUsed();
        public Task<ExtraccionOpcionesModel> ExtraccionOpcionesAsync(CancellationToken ct)=>throw NotUsed();
        public Task<long> CrearExtraccionAsync(ExtraccionCrearViewModel model,CancellationToken ct)=>throw NotUsed();
        public Task CambiarEstadoExtraccionAsync(long id,string estado,string? comentario,CancellationToken ct)=>throw NotUsed();
        public Task EliminarExtraccionAsync(long id,CancellationToken ct)=>throw NotUsed();
        public Task<IReadOnlyList<ProduccionListadoModel>> ProduccionesAsync(string?estado,int?sedeId,DateTime?desde,DateTime?hasta,CancellationToken ct)=>throw NotUsed();
        public Task<ProduccionDetalleModel?> ProduccionAsync(long id,CancellationToken ct)=>throw NotUsed();
        public Task<ProduccionOpcionesModel> ProduccionOpcionesAsync(CancellationToken ct)=>throw NotUsed();
        public Task<long> CrearProduccionAsync(ProduccionCrearViewModel model,CancellationToken ct)=>throw NotUsed();
        public Task CambiarEstadoProduccionAsync(long id,string estado,decimal?cantidadSalidaReal,decimal?cantidadMerma,decimal?costoUnitario,string?comentario,CancellationToken ct)=>throw NotUsed();
        public Task CompletarEtapaProduccionAsync(long id,long etapaId,string?observacion,CancellationToken ct)=>throw NotUsed();
        public Task EliminarProduccionAsync(long id,CancellationToken ct)=>throw NotUsed();
        public Task<IReadOnlyList<MaquinariaEquipoModel>> MaquinariasAsync(string?estado,int?sedeId,string?busqueda,CancellationToken ct)=>throw NotUsed();public Task<MaquinariaDetalleModel?> MaquinariaAsync(int id,CancellationToken ct)=>throw NotUsed();public Task<MaquinariaOpcionesModel> MaquinariaOpcionesAsync(CancellationToken ct)=>throw NotUsed();public Task<int> CrearMaquinariaAsync(MaquinariaCrearViewModel m,CancellationToken ct)=>throw NotUsed();public Task<long> CrearContratoMaquinariaAsync(MaquinariaContratoCrearViewModel m,CancellationToken ct)=>throw NotUsed();public Task EstadoContratoMaquinariaAsync(long id,string estado,decimal?horasDevolucion,string?observacion,CancellationToken ct)=>throw NotUsed();public Task<long> CrearMantenimientoMaquinariaAsync(MaquinariaMantenimientoCrearViewModel m,CancellationToken ct)=>throw NotUsed();public Task EstadoMantenimientoMaquinariaAsync(long id,string estado,string?observacion,CancellationToken ct)=>throw NotUsed();public Task EliminarMaquinariaAsync(int id,CancellationToken ct)=>throw NotUsed();
        public Task<IReadOnlyList<TransporteViajeListadoModel>> TransportesAsync(string?estado,string?tipo,int?sedeId,CancellationToken ct)=>throw NotUsed();public Task<TransporteViajeDetalleModel?> TransporteAsync(long id,CancellationToken ct)=>throw NotUsed();public Task<TransporteOpcionesModel> TransporteOpcionesAsync(CancellationToken ct)=>throw NotUsed();public Task<int> CrearVehiculoTransporteAsync(TransporteVehiculoCrearViewModel m,CancellationToken ct)=>throw NotUsed();public Task<int> CrearConductorTransporteAsync(TransporteConductorCrearViewModel m,CancellationToken ct)=>throw NotUsed();public Task<long> CrearViajeTransporteAsync(TransporteViajeCrearViewModel m,CancellationToken ct)=>throw NotUsed();public Task EstadoViajeTransporteAsync(long id,string estado,string?observacion,CancellationToken ct)=>throw NotUsed();public Task<long> CrearIncidenciaTransporteAsync(long id,string tipo,string severidad,string descripcion,CancellationToken ct)=>throw NotUsed();public Task ResolverIncidenciaTransporteAsync(long id,string resolucion,CancellationToken ct)=>throw NotUsed();public Task EliminarViajeTransporteAsync(long id,CancellationToken ct)=>throw NotUsed();public Task EliminarRecursoTransporteAsync(string tipo,int id,CancellationToken ct)=>throw NotUsed();
        public Task<GpsResumenModel> GpsResumenAsync(CancellationToken ct)=>throw NotUsed();public Task<GpsOpcionesModel> GpsOpcionesAsync(CancellationToken ct)=>throw NotUsed();public Task<IReadOnlyList<GpsPosicionModel>> GpsRecorridoAsync(int id,DateTime?desde,DateTime?hasta,CancellationToken ct)=>throw NotUsed();public Task<int> CrearGpsDispositivoAsync(GpsDispositivoCrearViewModel m,CancellationToken ct)=>throw NotUsed();public Task<long> SimularGpsAsync(int dispositivoId,string datosFuente,CancellationToken ct)=>throw NotUsed();public Task AtenderGpsAlertaAsync(long id,CancellationToken ct)=>throw NotUsed();public Task EliminarGpsDispositivoAsync(int id,CancellationToken ct)=>throw NotUsed();
        public Task<IReadOnlyList<ConstruccionListadoModel>> ConstruccionesAsync(string?estado,int?sedeId,string?busqueda,CancellationToken ct)=>throw NotUsed();public Task<ConstruccionDetalleModel?> ConstruccionAsync(long id,CancellationToken ct)=>throw NotUsed();public Task<ConstruccionOpcionesModel> ConstruccionOpcionesAsync(CancellationToken ct)=>throw NotUsed();public Task<long> CrearConstruccionAsync(ConstruccionCrearViewModel m,CancellationToken ct)=>throw NotUsed();public Task<long> CrearActividadConstruccionAsync(long id,ConstruccionActividadCrearViewModel m,CancellationToken ct)=>throw NotUsed();public Task<long> RegistrarAvanceConstruccionAsync(long actividadId,decimal porcentaje,string comentario,string?evidenciaUrl,CancellationToken ct)=>throw NotUsed();public Task<long> AsignarRecursoConstruccionAsync(long id,ConstruccionRecursoCrearViewModel m,CancellationToken ct)=>throw NotUsed();public Task EstadoConstruccionAsync(long id,string estado,CancellationToken ct)=>throw NotUsed();public Task EliminarConstruccionAsync(long id,CancellationToken ct)=>throw NotUsed();
        public Task<IReadOnlyList<PresupuestoListadoModel>> PresupuestosAsync(short?anio,byte?mes,int?giroId,int?sedeId,CancellationToken ct)=>throw NotUsed();public Task<PresupuestoDetalleModel?> PresupuestoAsync(long id,CancellationToken ct)=>throw NotUsed();public Task<FinanzaOpcionesModel> FinanzaOpcionesAsync(CancellationToken ct)=>throw NotUsed();public Task<long> CrearPresupuestoAsync(PresupuestoCrearViewModel m,CancellationToken ct)=>throw NotUsed();public Task<long> RegistrarGastoAsync(long id,GastoCrearViewModel m,CancellationToken ct)=>throw NotUsed();public Task EstadoPresupuestoAsync(long id,string estado,CancellationToken ct)=>throw NotUsed();public Task EliminarPresupuestoAsync(long id,CancellationToken ct)=>throw NotUsed();
        public Task<IReadOnlyList<AlertaListadoModel>> AlertasAsync(string?estado,bool soloPendientes,CancellationToken ct)=>throw NotUsed();public Task<AlertaDetalleModel?> AlertaAsync(long id,CancellationToken ct)=>throw NotUsed();public Task<AlertaOpcionesModel> AlertaOpcionesAsync(CancellationToken ct)=>throw NotUsed();public Task<long> CrearAlertaAsync(AlertaCrearViewModel m,CancellationToken ct)=>throw NotUsed();public Task MarcarAlertaLeidaAsync(long id,CancellationToken ct)=>throw NotUsed();public Task<long> SeguimientoAlertaAsync(long id,string comentario,CancellationToken ct)=>throw NotUsed();public Task EstadoAlertaAsync(long id,string estado,CancellationToken ct)=>throw NotUsed();public Task EliminarAlertaAsync(long id,CancellationToken ct)=>throw NotUsed();
    }
}

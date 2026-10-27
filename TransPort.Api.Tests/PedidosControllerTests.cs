using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Controllers;
using TransPort.Api.Modules.Comercial.DTOs;
using TransPort.Api.Modules.Comercial.Repositories;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Tests;

public sealed class PedidosControllerTests
{
    [Fact]
    public async Task Crear_ClienteUsaSuIdentidadYAlcance()
    {
        var repository = new FakePedidoRepository { IdCreado = 42 };
        var controller = CrearController(repository, 9, "Cliente");

        var result = await controller.Crear(new CrearPedidoRequest
        {
            ClienteId = 2, GiroNegocioId = 3, TipoSolicitud = "Pedido",
            Titulo = "Material requerido", Descripcion = "Detalle de la solicitud"
        }, default);

        var created = Assert.IsType<CreatedAtActionResult>(result);
        Assert.Equal(42, Assert.IsType<ResultadoIdDto>(created.Value).Id);
        Assert.Equal(new AlcancePedido(9, false, true), repository.AlcanceRecibido);
    }

    [Fact]
    public async Task Obtener_SinAccesoOInexistente_DevuelveNotFound()
    {
        var controller = CrearController(new FakePedidoRepository(), 5, "Vendedor");

        var result = await controller.Obtener(99, default);

        Assert.IsType<NotFoundResult>(result);
    }

    [Fact]
    public async Task Gestionar_EstadoInvalido_NoInvocaRepositorio()
    {
        var repository = new FakePedidoRepository();
        var controller = CrearController(repository, 1, "AdministradorGeneral");

        var result = await controller.Gestionar(4, new GestionPedidoRequest { Estado = "Desconocido" }, default);

        Assert.IsType<ObjectResult>(result);
        Assert.False(repository.GestionInvocada);
    }

    [Fact]
    public async Task Eliminar_PedidoExistente_UsaAdministradorAutenticado()
    {
        var repository = new FakePedidoRepository { EliminarResultado = true };
        var controller = CrearController(repository, 11, "AdministradorGeneral");

        var result = await controller.Eliminar(8, default);

        Assert.IsType<NoContentResult>(result);
        Assert.Equal(11, repository.UsuarioEliminacion);
    }

    [Fact]
    public void Gestionar_RestringeClienteMedianteAtributoDeRol()
    {
        var atributo = typeof(PedidosController).GetMethod(nameof(PedidosController.Gestionar))!
            .GetCustomAttributes(typeof(AuthorizeAttribute), true).Cast<AuthorizeAttribute>().Single();

        Assert.DoesNotContain("Cliente", atributo.Roles ?? string.Empty);
        Assert.Contains("Vendedor", atributo.Roles ?? string.Empty);
    }

    private static PedidosController CrearController(IPedidoRepository repository, int usuarioId, params string[] roles)
    {
        var claims = new List<Claim> { new(ClaimTypes.NameIdentifier, usuarioId.ToString()) };
        claims.AddRange(roles.Select(x => new Claim(ClaimTypes.Role, x)));
        return new PedidosController(repository)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext
                {
                    User = new ClaimsPrincipal(new ClaimsIdentity(claims, "Pruebas"))
                }
            }
        };
    }

    private sealed class FakePedidoRepository : IPedidoRepository
    {
        public long IdCreado { get; init; }
        public bool EliminarResultado { get; init; }
        public AlcancePedido? AlcanceRecibido { get; private set; }
        public bool GestionInvocada { get; private set; }
        public int? UsuarioEliminacion { get; private set; }

        public Task<IReadOnlyList<PedidoListadoDto>> ListarAsync(string? busqueda, string? estado, int? clienteId, int? giroId, AlcancePedido alcance, CancellationToken ct) =>
            Task.FromResult<IReadOnlyList<PedidoListadoDto>>([]);
        public Task<PedidoDetalleDto?> ObtenerAsync(long id, AlcancePedido alcance, CancellationToken ct) =>
            Task.FromResult<PedidoDetalleDto?>(null);
        public Task<PedidoOpcionesDto> OpcionesAsync(AlcancePedido alcance, CancellationToken ct) =>
            Task.FromResult(new PedidoOpcionesDto([], [], []));
        public Task<long> CrearAsync(CrearPedidoRequest request, AlcancePedido alcance, CancellationToken ct)
        {
            AlcanceRecibido = alcance;
            return Task.FromResult(IdCreado);
        }
        public Task<bool> GestionarAsync(long id, GestionPedidoRequest request, AlcancePedido alcance, CancellationToken ct)
        {
            GestionInvocada = true;
            return Task.FromResult(true);
        }
        public Task ComentarAsync(long id, AgregarComentarioPedidoRequest request, AlcancePedido alcance, CancellationToken ct) => Task.CompletedTask;
        public Task<long> AgregarDocumentoAsync(long id, AgregarDocumentoPedidoRequest request, AlcancePedido alcance, CancellationToken ct) => Task.FromResult(1L);
        public Task<bool> EliminarAsync(long id, int usuarioId, CancellationToken ct)
        {
            UsuarioEliminacion = usuarioId;
            return Task.FromResult(EliminarResultado);
        }
    }
}

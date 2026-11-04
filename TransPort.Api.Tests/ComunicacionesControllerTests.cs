using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Controllers;
using TransPort.Api.Modules.Comercial.DTOs;
using TransPort.Api.Modules.Comercial.Repositories;

namespace TransPort.Api.Tests;

public sealed class ComunicacionesControllerTests
{
    [Fact]
    public async Task Crear_Cliente_FuerzaTipoYPropagaAlcance()
    {
        var repository = new Fake { Id = 27 };
        var request = new CrearComunicacionRequest { Tipo = "Interna", Asunto = "Consulta", MensajeInicial = "Necesito ayuda" };

        var result = Assert.IsType<CreatedAtActionResult>(await Controller(repository, 8, "Cliente").Crear(request, default));

        Assert.Equal("Cliente", repository.CrearRequest!.Tipo);
        Assert.Equal(new AlcanceComunicacion(8, false, true), repository.Alcance);
        Assert.Equal(27, Assert.IsType<TransPort.Api.Modules.Shared.DTOs.ResultadoIdDto>(result.Value).Id);
    }

    [Fact]
    public async Task Mensaje_Cliente_NoPuedeCrearNotaInterna()
    {
        var repository = new Fake();
        var request = new CrearMensajeComunicacionRequest { Mensaje = "Respuesta", EsInterno = true };

        await Controller(repository, 3, "Cliente").Mensaje(4, request, default);

        Assert.False(repository.MensajeRequest!.EsInterno);
        Assert.Equal(new AlcanceComunicacion(3, false, true), repository.Alcance);
    }

    [Fact]
    public async Task Obtener_FueraDeAlcance_RetornaNotFound() =>
        Assert.IsType<NotFoundResult>(await Controller(new Fake(), 4, "Empleado").Obtener(99, default));

    [Fact]
    public async Task Gestionar_PropagaResponsableYAlcance()
    {
        var repository = new Fake();
        var request = new GestionComunicacionRequest { Estado = "Cerrada", ResponsableUsuarioId = 6 };

        Assert.IsType<NoContentResult>(await Controller(repository, 1, "AdministradorGeneral").Gestionar(5, request, default));

        Assert.Same(request, repository.GestionRequest);
        Assert.Equal(new AlcanceComunicacion(1, true, false), repository.Alcance);
    }

    [Fact]
    public void Gestionar_AutorizaRolesComercialesPeroNoCliente()
    {
        var method = typeof(ComunicacionesController).GetMethod(nameof(ComunicacionesController.Gestionar))!;
        var authorization = method.GetCustomAttributes(typeof(AuthorizeAttribute), true).Cast<AuthorizeAttribute>().Single();
        Assert.Contains("Vendedor", authorization.Roles ?? string.Empty);
        Assert.DoesNotContain("Cliente", authorization.Roles ?? string.Empty);
    }

    private static ComunicacionesController Controller(IComunicacionRepository repository, int id, params string[] roles)
    {
        var claims = new List<Claim> { new(ClaimTypes.NameIdentifier, id.ToString()) };
        claims.AddRange(roles.Select(x => new Claim(ClaimTypes.Role, x)));
        return new(repository)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext
                {
                    User = new ClaimsPrincipal(new ClaimsIdentity(claims, "Test"))
                }
            }
        };
    }

    private sealed class Fake : IComunicacionRepository
    {
        public long Id { get; init; } = 1;
        public AlcanceComunicacion? Alcance { get; private set; }
        public CrearComunicacionRequest? CrearRequest { get; private set; }
        public CrearMensajeComunicacionRequest? MensajeRequest { get; private set; }
        public GestionComunicacionRequest? GestionRequest { get; private set; }

        public Task<IReadOnlyList<ComunicacionListadoDto>> ListarAsync(string? estado, string? tipo, string? busqueda, AlcanceComunicacion alcance, CancellationToken ct)
        { Alcance = alcance; return Task.FromResult<IReadOnlyList<ComunicacionListadoDto>>([]); }
        public Task<ComunicacionDetalleDto?> ObtenerAsync(long id, AlcanceComunicacion alcance, CancellationToken ct)
        { Alcance = alcance; return Task.FromResult<ComunicacionDetalleDto?>(null); }
        public Task<ComunicacionOpcionesDto> OpcionesAsync(AlcanceComunicacion alcance, CancellationToken ct)
        { Alcance = alcance; return Task.FromResult(new ComunicacionOpcionesDto([], [], [], [])); }
        public Task<long> CrearAsync(CrearComunicacionRequest request, AlcanceComunicacion alcance, CancellationToken ct)
        { CrearRequest = request; Alcance = alcance; return Task.FromResult(Id); }
        public Task<long> AgregarMensajeAsync(long id, CrearMensajeComunicacionRequest request, AlcanceComunicacion alcance, CancellationToken ct)
        { MensajeRequest = request; Alcance = alcance; return Task.FromResult(Id); }
        public Task<bool> GestionarAsync(long id, GestionComunicacionRequest request, AlcanceComunicacion alcance, CancellationToken ct)
        { GestionRequest = request; Alcance = alcance; return Task.FromResult(true); }
        public Task<bool> EliminarAsync(long id, int usuarioId, CancellationToken ct) => Task.FromResult(true);
    }
}

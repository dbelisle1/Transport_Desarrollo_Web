using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Controllers;
using TransPort.Api.Modules.Comercial.DTOs;
using TransPort.Api.Modules.Comercial.Repositories;

namespace TransPort.Api.Tests;

public sealed class CatalogoComercialControllerTests
{
    [Fact]
    public async Task Publico_NoRequiereIdentidad()
    {
        var repository = new Fake();
        await new CatalogoComercialController(repository).Publico(2, "Servicio", default);
        Assert.Equal((2, "Servicio"), repository.FiltroPublico);
    }

    [Fact]
    public async Task Crear_PropagaAlcanceDelGerente()
    {
        var repository = new Fake { Id = 12 };
        var result = await Controller(repository, 7, "Gerente").Crear(Valida(), default);
        Assert.IsType<CreatedAtActionResult>(result);
        Assert.Equal(new AlcanceCatalogoComercial(7, false), repository.Alcance);
    }

    [Fact]
    public async Task Crear_TipoInvalido_NoInvocaRepositorio()
    {
        var repository = new Fake();
        var request = Valida();
        request.Tipo = "Otro";
        var result = await Controller(repository, 1, "AdministradorGeneral").Crear(request, default);
        Assert.IsType<ObjectResult>(result);
        Assert.False(repository.CrearInvocado);
    }

    [Fact]
    public async Task Actualizar_Inexistente_DevuelveNotFound()
    {
        var result = await Controller(new Fake(), 1, "AdministradorGeneral").Actualizar(99, Valida(), default);
        Assert.IsType<NotFoundResult>(result);
    }

    [Fact]
    public void EndpointPublico_TieneAllowAnonymous()
    {
        var attributes = typeof(CatalogoComercialController).GetMethod(nameof(CatalogoComercialController.Publico))!
            .GetCustomAttributes(typeof(AllowAnonymousAttribute), true);
        Assert.Single(attributes);
    }

    private static GuardarOfertaCatalogoRequest Valida() => new()
    {
        GiroNegocioId = 1,
        Codigo = "PRUEBA",
        Tipo = "Producto",
        Nombre = "Oferta de prueba",
        Descripcion = "Descripción funcional de prueba",
        UnidadMedida = "Unidad",
        PrecioBase = 10,
        EsPublico = true,
        EsActivo = true
    };

    private static CatalogoComercialController Controller(Fake repository, int userId, string role)
    {
        var identity = new ClaimsIdentity(new[]
        {
            new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
            new Claim(ClaimTypes.Role, role)
        }, "Test");
        return new CatalogoComercialController(repository)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = new ClaimsPrincipal(identity) }
            }
        };
    }

    private sealed class Fake : ICatalogoComercialRepository
    {
        public int Id { get; init; } = 1;
        public bool CrearInvocado { get; private set; }
        public AlcanceCatalogoComercial? Alcance { get; private set; }
        public (int?, string?) FiltroPublico { get; private set; }

        public Task<IReadOnlyList<OfertaCatalogoDto>> ListarPublicoAsync(int? giroId, string? tipo, CancellationToken ct)
        {
            FiltroPublico = (giroId, tipo);
            return Task.FromResult<IReadOnlyList<OfertaCatalogoDto>>([]);
        }

        public Task<IReadOnlyList<OfertaCatalogoDto>> ListarAsync(string? busqueda, int? giroId, string? tipo, bool? esActivo, AlcanceCatalogoComercial alcance, CancellationToken ct) => Task.FromResult<IReadOnlyList<OfertaCatalogoDto>>([]);
        public Task<CatalogoComercialOpcionesDto> OpcionesAsync(AlcanceCatalogoComercial alcance, CancellationToken ct) => Task.FromResult(new CatalogoComercialOpcionesDto([]));
        public Task<int> CrearAsync(GuardarOfertaCatalogoRequest request, AlcanceCatalogoComercial alcance, CancellationToken ct)
        {
            CrearInvocado = true;
            Alcance = alcance;
            return Task.FromResult(Id);
        }
        public Task<bool> ActualizarAsync(int id, GuardarOfertaCatalogoRequest request, AlcanceCatalogoComercial alcance, CancellationToken ct) => Task.FromResult(false);
        public Task<bool> EliminarAsync(int id, AlcanceCatalogoComercial alcance, CancellationToken ct) => Task.FromResult(false);
    }
}

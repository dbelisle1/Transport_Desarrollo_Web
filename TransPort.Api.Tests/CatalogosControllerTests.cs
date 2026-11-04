using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Controllers;
using TransPort.Api.Modules.Organizacion.Repositories;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Tests;

public sealed class CatalogosControllerTests
{
    [Fact]
    public async Task Crear_TipoValido_UsaResponsableYDevuelveUbicacion()
    {
        var repository = new FakeCatalogoRepository { IdCreado = 18 };
        var controller = CrearController(repository, 7);

        var result = await controller.Crear("giros", new GuardarCatalogoRequest
        {
            Nombre = "Giro de prueba"
        }, default);

        var created = Assert.IsType<CreatedAtActionResult>(result);
        Assert.Equal(nameof(CatalogosController.Obtener), created.ActionName);
        Assert.Equal(18, Assert.IsType<ResultadoIdDto>(created.Value).Id);
        Assert.Equal(7, repository.ResponsableRecibido);
        Assert.Equal("giros", repository.TipoRecibido);
    }

    [Fact]
    public async Task Listar_TipoInvalido_DevuelveNotFoundSinConsultarRepositorio()
    {
        var repository = new FakeCatalogoRepository();
        var controller = CrearController(repository, 7);

        var result = await controller.Listar("desconocido", default);

        Assert.IsType<NotFoundResult>(result);
        Assert.False(repository.FueInvocado);
    }

    [Fact]
    public async Task Actualizar_AdministradorGeneralInactivo_DevuelveBadRequest()
    {
        var repository = new FakeCatalogoRepository
        {
            Item = new EntidadCatalogoDto(1, "AdministradorGeneral", "Rol protegido", true, DateTime.UtcNow)
        };
        var controller = CrearController(repository, 7);

        var result = await controller.Actualizar("roles", 1, new GuardarCatalogoRequest
        {
            Nombre = "AdministradorGeneral",
            EsActivo = false
        }, default);

        Assert.IsType<BadRequestObjectResult>(result);
        Assert.False(repository.Actualizado);
    }

    [Fact]
    public async Task Eliminar_AdministradorGeneral_DevuelveBadRequest()
    {
        var repository = new FakeCatalogoRepository
        {
            Item = new EntidadCatalogoDto(1, "AdministradorGeneral", null, true, DateTime.UtcNow)
        };
        var controller = CrearController(repository, 7);

        var result = await controller.Eliminar("roles", 1, default);

        Assert.IsType<BadRequestObjectResult>(result);
        Assert.False(repository.Eliminado);
    }

    [Fact]
    public async Task Eliminar_SedeNormal_DevuelveNoContent()
    {
        var repository = new FakeCatalogoRepository { EliminarResultado = true };
        var controller = CrearController(repository, 11);

        var result = await controller.Eliminar("sedes", 3, default);

        Assert.IsType<NoContentResult>(result);
        Assert.True(repository.Eliminado);
        Assert.Equal(11, repository.ResponsableRecibido);
    }

    private static CatalogosController CrearController(ICatalogoRepository repository, int usuarioId)
    {
        var identity = new ClaimsIdentity(
            [new Claim(ClaimTypes.NameIdentifier, usuarioId.ToString())], "Pruebas");
        return new CatalogosController(repository)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext
                {
                    User = new ClaimsPrincipal(identity)
                }
            }
        };
    }

    private sealed class FakeCatalogoRepository : ICatalogoRepository
    {
        public int IdCreado { get; init; }
        public bool EliminarResultado { get; init; }
        public EntidadCatalogoDto? Item { get; init; }
        public int? ResponsableRecibido { get; private set; }
        public string? TipoRecibido { get; private set; }
        public bool FueInvocado { get; private set; }
        public bool Actualizado { get; private set; }
        public bool Eliminado { get; private set; }

        public Task<IReadOnlyList<EntidadCatalogoDto>> ListarAsync(string tipo, CancellationToken ct)
        {
            FueInvocado = true;
            return Task.FromResult<IReadOnlyList<EntidadCatalogoDto>>([]);
        }

        public Task<EntidadCatalogoDto?> ObtenerAsync(string tipo, int id, CancellationToken ct)
        {
            FueInvocado = true;
            return Task.FromResult(Item);
        }

        public Task<int> CrearAsync(string tipo, GuardarCatalogoRequest request, int responsableId, CancellationToken ct)
        {
            FueInvocado = true;
            TipoRecibido = tipo;
            ResponsableRecibido = responsableId;
            return Task.FromResult(IdCreado);
        }

        public Task<bool> ActualizarAsync(
            string tipo, int id, GuardarCatalogoRequest request, int responsableId, CancellationToken ct)
        {
            FueInvocado = true;
            Actualizado = true;
            ResponsableRecibido = responsableId;
            return Task.FromResult(true);
        }

        public Task<bool> EliminarAsync(string tipo, int id, int responsableId, CancellationToken ct)
        {
            FueInvocado = true;
            Eliminado = true;
            ResponsableRecibido = responsableId;
            return Task.FromResult(EliminarResultado);
        }
    }
}

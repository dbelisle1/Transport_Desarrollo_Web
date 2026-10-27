using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Controllers;
using TransPort.Api.Modules.Clientes.DTOs;
using TransPort.Api.Modules.Clientes.Repositories;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Tests;

public sealed class ClientesControllerTests
{
    [Fact]
    public async Task Crear_UsaResponsableAutenticadoYDevuelveUbicacion()
    {
        var repository = new FakeClienteRepository { IdCreado = 42 };
        var controller = CrearController(repository, 7);

        var result = await controller.Crear(new CrearClienteRequest
        {
            Nombre = "Cliente de prueba",
            Nit = "1234-5"
        }, default);

        var created = Assert.IsType<CreatedAtActionResult>(result);
        Assert.Equal(nameof(ClientesController.Obtener), created.ActionName);
        Assert.Equal(42, Assert.IsType<ResultadoIdDto>(created.Value).Id);
        Assert.Equal(7, repository.ResponsableRecibido);
    }

    [Fact]
    public async Task Asignaciones_ClienteInexistente_DevuelveNotFound()
    {
        var repository = new FakeClienteRepository();
        var controller = CrearController(repository, 7);

        var result = await controller.Asignaciones(99, new AsignacionesClienteRequest
        {
            Usuarios = [2],
            Giros = [3]
        }, default);

        Assert.IsType<NotFoundResult>(result);
        Assert.False(repository.AsignacionesActualizadas);
    }

    [Fact]
    public async Task Eliminar_ClienteExistente_DevuelveNoContent()
    {
        var repository = new FakeClienteRepository { EliminarResultado = true };
        var controller = CrearController(repository, 11);

        var result = await controller.Eliminar(5, default);

        Assert.IsType<NoContentResult>(result);
        Assert.Equal(11, repository.ResponsableRecibido);
    }

    private static ClientesController CrearController(IClienteRepository repository, int usuarioId)
    {
        var identity = new ClaimsIdentity(
            [new Claim(ClaimTypes.NameIdentifier, usuarioId.ToString())], "Pruebas");
        return new ClientesController(repository)
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

    private sealed class FakeClienteRepository : IClienteRepository
    {
        public int IdCreado { get; init; }
        public bool EliminarResultado { get; init; }
        public int? ResponsableRecibido { get; private set; }
        public bool AsignacionesActualizadas { get; private set; }

        public Task<IReadOnlyList<ClienteListadoDto>> ListarAsync(
            string? busqueda, bool? esActivo, CancellationToken ct) =>
            Task.FromResult<IReadOnlyList<ClienteListadoDto>>([]);

        public Task<ClienteDetalleDto?> ObtenerAsync(int id, CancellationToken ct) =>
            Task.FromResult<ClienteDetalleDto?>(null);

        public Task<int> CrearAsync(CrearClienteRequest request, int responsableId, CancellationToken ct)
        {
            ResponsableRecibido = responsableId;
            return Task.FromResult(IdCreado);
        }

        public Task<bool> ActualizarAsync(
            int id, ActualizarClienteRequest request, int responsableId, CancellationToken ct)
        {
            ResponsableRecibido = responsableId;
            return Task.FromResult(true);
        }

        public Task<bool> EliminarAsync(int id, int responsableId, CancellationToken ct)
        {
            ResponsableRecibido = responsableId;
            return Task.FromResult(EliminarResultado);
        }

        public Task ActualizarAsignacionesAsync(
            int id, AsignacionesClienteRequest request, int responsableId, CancellationToken ct)
        {
            ResponsableRecibido = responsableId;
            AsignacionesActualizadas = true;
            return Task.CompletedTask;
        }
    }
}

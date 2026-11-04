using Microsoft.AspNetCore.Authorization;
using TransPort.Api.Controllers;
using TransPort.Api.Modules.Organizacion.DTOs;
using TransPort.Api.Modules.Organizacion.Repositories;

namespace TransPort.Api.Tests;

public sealed class AdministracionControllerTests
{
    [Fact]
    public async Task Auditoria_EnviaFiltrosYPaginacionAlRepositorio()
    {
        var repository = new FakeOperacionesRepository();
        var controller = new AdministracionController(repository);
        var consulta = new AuditoriaConsultaDto
        {
            Busqueda = "cliente",
            Modulo = "Clientes",
            TipoOperacion = "Actualizar",
            NombreUsuario = "admin.demo",
            Resultado = "Exitoso",
            Pagina = 2,
            TamanoPagina = 10,
            FechaDesdeUtc = new DateTime(2026, 10, 1, 6, 0, 0, DateTimeKind.Utc),
            FechaHastaUtc = new DateTime(2026, 11, 1, 6, 0, 0, DateTimeKind.Utc)
        };

        var result = await controller.Auditoria(consulta, default);

        Assert.Same(consulta, repository.ConsultaRecibida);
        Assert.Equal(2, result.Pagina);
        Assert.Equal(3, result.TotalPaginas);
        Assert.Equal(21, result.TotalRegistros);
    }

    [Fact]
    public void Controlador_RequiereRolAdministradorGeneral()
    {
        var attribute = Assert.Single(typeof(AdministracionController)
            .GetCustomAttributes(typeof(AuthorizeAttribute), true)
            .Cast<AuthorizeAttribute>());

        Assert.Equal("AdministradorGeneral", attribute.Roles);
    }

    private sealed class FakeOperacionesRepository : IOperacionesRepository
    {
        public AuditoriaConsultaDto? ConsultaRecibida { get; private set; }

        public Task<DashboardDto> ObtenerResumenAsync(CancellationToken ct) =>
            Task.FromResult(new DashboardDto(0, 0, 0, 0));

        public Task CrearAuditoriaAsync(CrearAuditoriaDto evento, CancellationToken ct) => Task.CompletedTask;

        public Task<AuditoriaPaginaDto> ListarAuditoriaAsync(AuditoriaConsultaDto consulta, CancellationToken ct)
        {
            ConsultaRecibida = consulta;
            return Task.FromResult(new AuditoriaPaginaDto([], 21, consulta.Pagina, consulta.TamanoPagina));
        }
    }
}

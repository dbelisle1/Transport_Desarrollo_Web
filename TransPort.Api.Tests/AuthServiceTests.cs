using TransPort.Api.Modules.Organizacion.DTOs;
using TransPort.Api.Modules.Organizacion.Repositories;
using TransPort.Api.Modules.Seguridad.DTOs;
using TransPort.Api.Modules.Seguridad.Repositories;
using TransPort.Api.Modules.Seguridad.Services;
using TransPort.Api.Modules.Shared.DTOs;

namespace TransPort.Api.Tests;

public sealed class AuthServiceTests
{
    [Fact]
    public async Task Login_CredencialesInvalidas_AuditaSinGuardarClave()
    {
        var usuarios = new FakeUsuarios { Credencial = null };
        var auditoria = new FakeOperaciones();
        var service = new AuthService(usuarios, new FakeTokens(), auditoria);

        var result = await service.LoginAsync(new LoginRequest { NombreUsuario = "nadie", Clave = "secreto" }, default);

        Assert.Null(result);
        var evento = Assert.Single(auditoria.Eventos);
        Assert.Equal("Fallido", evento.Resultado);
        Assert.DoesNotContain("secreto", evento.Detalle ?? string.Empty);
    }

    [Fact]
    public async Task Login_CredencialesValidas_DevuelveSesionConAlcances()
    {
        var usuarios = new FakeUsuarios
        {
            Credencial = new CredencialUsuarioDto(9, "empleado", "Eva", "Pérez", "eva@example.test", true),
            Roles = [new CatalogoDto(2, "Empleado")],
            Giros = [new CatalogoDto(4, "Maquinaria")],
            Sedes = [new CatalogoDto(5, "Zacapa")]
        };
        var auditoria = new FakeOperaciones();
        var service = new AuthService(usuarios, new FakeTokens(), auditoria);

        var result = await service.LoginAsync(new LoginRequest { NombreUsuario = "empleado", Clave = "demo" }, default);

        Assert.NotNull(result);
        Assert.Equal("Eva Pérez", result!.Usuario.NombreCompleto);
        Assert.Contains("Empleado", result.Usuario.Roles);
        Assert.Equal("Maquinaria", Assert.Single(result.Usuario.Giros).Nombre);
        Assert.Equal("Exitoso", Assert.Single(auditoria.Eventos).Resultado);
    }

    private sealed class FakeTokens : ITokenService
    {
        public (string Token, DateTime ExpiraUtc) Crear(UsuarioSesionDto usuario) => ("token-prueba", DateTime.UtcNow.AddMinutes(5));
        public System.Security.Claims.ClaimsPrincipal? Validar(string token) => null;
    }

    private sealed class FakeOperaciones : IOperacionesRepository
    {
        public List<CrearAuditoriaDto> Eventos { get; } = [];
        public Task CrearAuditoriaAsync(CrearAuditoriaDto evento, CancellationToken ct) { Eventos.Add(evento); return Task.CompletedTask; }
        public Task<DashboardDto> ObtenerResumenAsync(CancellationToken ct) => Task.FromResult(new DashboardDto(0,0,0,0));
        public Task<AuditoriaPaginaDto> ListarAuditoriaAsync(AuditoriaConsultaDto consulta, CancellationToken ct) =>
            Task.FromResult(new AuditoriaPaginaDto([], 0, 1, 25));
    }

    private sealed class FakeUsuarios : IUsuarioRepository
    {
        public CredencialUsuarioDto? Credencial { get; init; }
        public IReadOnlyList<CatalogoDto> Roles { get; init; } = [];
        public IReadOnlyList<CatalogoDto> Giros { get; init; } = [];
        public IReadOnlyList<CatalogoDto> Sedes { get; init; } = [];
        public Task<CredencialUsuarioDto?> ValidarCredencialesAsync(string n, string c, CancellationToken ct) => Task.FromResult(Credencial);
        public Task<IReadOnlyList<CatalogoDto>> LeerRolesAsync(int id, CancellationToken ct) => Task.FromResult(Roles);
        public Task<IReadOnlyList<CatalogoDto>> LeerGirosAsync(int id, CancellationToken ct) => Task.FromResult(Giros);
        public Task<IReadOnlyList<CatalogoDto>> LeerSedesAsync(int id, CancellationToken ct) => Task.FromResult(Sedes);
        public Task<IReadOnlyList<CatalogoDto>> LeerClientesAsync(int id, CancellationToken ct) => Task.FromResult<IReadOnlyList<CatalogoDto>>([]);
        public Task<IReadOnlyList<UsuarioListadoDto>> ListarAsync(string? b, bool? a, int? r, CancellationToken ct) => throw new NotSupportedException();
        public Task<UsuarioDetalleDto?> ObtenerAsync(int id, CancellationToken ct) => throw new NotSupportedException();
        public Task<int> CrearAsync(CrearUsuarioRequest r, int id, CancellationToken ct) => throw new NotSupportedException();
        public Task<bool> ActualizarAsync(int id, ActualizarUsuarioRequest r, int responsable, CancellationToken ct) => throw new NotSupportedException();
        public Task<bool> EliminarAsync(int id, int responsable, CancellationToken ct) => throw new NotSupportedException();
        public Task ActualizarAsignacionesAsync(int id, AsignacionesUsuarioRequest r, int responsable, CancellationToken ct) => throw new NotSupportedException();
    }
}

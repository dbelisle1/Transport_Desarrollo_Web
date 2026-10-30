using Microsoft.AspNetCore.Authentication;
using TransPort.Api.Authorization;
using TransPort.Api.Configuration;
using TransPort.Api.Middleware;
using TransPort.Api.Modules.Clientes.Repositories;
using TransPort.Api.Modules.Abastecimiento.Repositories;
using TransPort.Api.Modules.Alertas.Repositories;
using TransPort.Api.Modules.Comercial.Repositories;
using TransPort.Api.Modules.Construccion.Repositories;
using TransPort.Api.Modules.Extraccion.Repositories;
using TransPort.Api.Modules.Finanzas.Repositories;
using TransPort.Api.Modules.Gps.Repositories;
using TransPort.Api.Modules.Inventarios.Repositories;
using TransPort.Api.Modules.Maquinaria.Repositories;
using TransPort.Api.Modules.Organizacion.Repositories;
using TransPort.Api.Modules.PortalCliente.Repositories;
using TransPort.Api.Modules.Produccion.Repositories;
using TransPort.Api.Modules.Seguridad.Repositories;
using TransPort.Api.Modules.Seguridad.Services;
using TransPort.Api.Modules.Transporte.Repositories;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.Configure<JwtOptions>(builder.Configuration.GetSection(JwtOptions.SectionName));
builder.Services.AddSingleton<ISqlConnectionFactory, SqlConnectionFactory>();
builder.Services.AddScoped<IClienteRepository, ClienteRepository>();
builder.Services.AddScoped<IAbastecimientoRepository, AbastecimientoRepository>();
builder.Services.AddScoped<IAlertaRepository, AlertaRepository>();
builder.Services.AddScoped<ICatalogoComercialRepository, CatalogoComercialRepository>();
builder.Services.AddScoped<IComunicacionRepository, ComunicacionRepository>();
builder.Services.AddScoped<IPedidoRepository, PedidoRepository>();
builder.Services.AddScoped<IConstruccionRepository, ConstruccionRepository>();
builder.Services.AddScoped<IExtraccionRepository, ExtraccionRepository>();
builder.Services.AddScoped<IFinanzaRepository, FinanzaRepository>();
builder.Services.AddScoped<IGpsRepository, GpsRepository>();
builder.Services.AddScoped<IInventarioRepository, InventarioRepository>();
builder.Services.AddScoped<IMaquinariaRepository, MaquinariaRepository>();
builder.Services.AddScoped<IUsuarioRepository, UsuarioRepository>();
builder.Services.AddScoped<ICatalogoRepository, CatalogoRepository>();
builder.Services.AddScoped<IOperacionesRepository, OperacionesRepository>();
builder.Services.AddScoped<IPortalClienteRepository, PortalClienteRepository>();
builder.Services.AddScoped<IProduccionRepository, ProduccionRepository>();
builder.Services.AddScoped<ITransporteRepository, TransporteRepository>();
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddAuthentication("Bearer")
    .AddScheme<AuthenticationSchemeOptions, ApiTokenAuthenticationHandler>("Bearer", _ => { });
builder.Services.AddAuthorization();

var app = builder.Build();

// Configure the HTTP request pipeline.
app.UseMiddleware<ApiExceptionMiddleware>();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapGet("/salud", () => Results.Ok(new { estado = "ok", servicio = "TransPort.Api" })).AllowAnonymous();

app.Run();

public partial class Program;

using Microsoft.AspNetCore.Authentication;
using TransPort.Api.Authorization;
using TransPort.Api.Configuration;
using TransPort.Api.Middleware;
using TransPort.Api.Modules.Organizacion.Repositories;
using TransPort.Api.Modules.Seguridad.Repositories;
using TransPort.Api.Modules.Seguridad.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.Configure<JwtOptions>(builder.Configuration.GetSection(JwtOptions.SectionName));
builder.Services.AddSingleton<ISqlConnectionFactory, SqlConnectionFactory>();
builder.Services.AddScoped<IUsuarioRepository, UsuarioRepository>();
builder.Services.AddScoped<ICatalogoRepository, CatalogoRepository>();
builder.Services.AddScoped<IOperacionesRepository, OperacionesRepository>();
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

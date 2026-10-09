using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using TransPort.Api.Configuration;
using TransPort.Api.Modules.Seguridad.DTOs;

namespace TransPort.Api.Modules.Seguridad.Services;

public sealed class TokenService(IOptions<JwtOptions> options) : ITokenService
{
    private readonly JwtOptions _options = options.Value;

    public (string Token, DateTime ExpiraUtc) Crear(UsuarioSesionDto usuario)
    {
        EnsureKey();
        var expira = DateTime.UtcNow.AddMinutes(Math.Clamp(_options.ExpirationMinutes, 5, 1440));
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, usuario.UsuarioId.ToString()),
            new(ClaimTypes.NameIdentifier, usuario.UsuarioId.ToString()),
            new(ClaimTypes.Name, usuario.NombreCompleto),
            new("nombre_usuario", usuario.NombreUsuario),
            new(JwtRegisteredClaimNames.Email, usuario.Correo),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString("N"))
        };
        claims.AddRange(usuario.Roles.Select(r => new Claim(ClaimTypes.Role, r)));
        claims.AddRange(usuario.Giros.Select(g => new Claim("giro", g.Id.ToString())));
        claims.AddRange(usuario.Sedes.Select(s => new Claim("sede", s.Id.ToString())));
        claims.AddRange(usuario.Clientes.Select(c => new Claim("cliente", c.Id.ToString())));

        var credentials = new SigningCredentials(
            new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_options.SigningKey)),
            SecurityAlgorithms.HmacSha256);
        var jwt = new JwtSecurityToken(_options.Issuer, _options.Audience, claims,
            notBefore: DateTime.UtcNow, expires: expira, signingCredentials: credentials);
        return (new JwtSecurityTokenHandler().WriteToken(jwt), expira);
    }

    public ClaimsPrincipal? Validar(string token)
    {
        try
        {
            EnsureKey();
            return new JwtSecurityTokenHandler().ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_options.SigningKey)),
                ValidateIssuer = true,
                ValidIssuer = _options.Issuer,
                ValidateAudience = true,
                ValidAudience = _options.Audience,
                ValidateLifetime = true,
                ClockSkew = TimeSpan.FromMinutes(1),
                NameClaimType = ClaimTypes.Name,
                RoleClaimType = ClaimTypes.Role
            }, out _);
        }
        catch (SecurityTokenException) { return null; }
        catch (ArgumentException) { return null; }
    }

    private void EnsureKey()
    {
        if (string.IsNullOrWhiteSpace(_options.SigningKey) || _options.SigningKey.Length < 32)
            throw new InvalidOperationException("Jwt__SigningKey debe contener al menos 32 caracteres.");
    }
}

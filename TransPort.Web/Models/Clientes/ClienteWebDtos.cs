using System.ComponentModel.DataAnnotations;

namespace TransPort.Web.Models.Clientes;

public sealed record ClienteListadoWebDto(int ClienteId, string Nombre, string? Nit, string? CorreoContacto, bool EsActivo, DateTime? FechaModificacion);
public sealed record ClienteDetalleWebDto(int ClienteId, string Nombre, string? Nit, string? CorreoContacto, bool EsActivo, DateTime? FechaModificacion, IReadOnlyList<CatalogoWebDto> Usuarios, IReadOnlyList<CatalogoWebDto> Giros);
public sealed record CatalogoWebDto(int Id, string Nombre);

public sealed class CrearClienteWebRequest
{
    [Required, StringLength(200, MinimumLength = 2)] public string Nombre { get; set; } = string.Empty;
    [StringLength(50)] public string? Nit { get; set; }
    [EmailAddress, StringLength(150)] public string? CorreoContacto { get; set; }
    public bool EsActivo { get; set; } = true;
}

public sealed class ActualizarClienteWebRequest
{
    [Required, StringLength(200, MinimumLength = 2)] public string Nombre { get; set; } = string.Empty;
    [StringLength(50)] public string? Nit { get; set; }
    [EmailAddress, StringLength(150)] public string? CorreoContacto { get; set; }
    public bool EsActivo { get; set; }
}

public sealed class AsociacionesClienteWebRequest
{
    public IReadOnlyList<int> Usuarios { get; set; } = [];
    public IReadOnlyList<int> Giros { get; set; } = [];
}
using System.ComponentModel.DataAnnotations;

namespace TransPort.Web.Models;

public sealed record CatalogoModel(int Id, string Nombre);
public sealed record EntidadCatalogoModel(int Id, string Nombre, string? Descripcion, bool EsActivo, DateTime FechaCreacion);
public sealed record ResultadoIdModel(int Id);
public sealed record DashboardModel(int Usuarios, int Clientes, int Giros, int Sedes);
public sealed record AuditoriaModel(
    long AuditoriaId, int? UsuarioId, string? NombreUsuario, DateTime Fecha,
    string Modulo, string TipoOperacion, string? IdentificadorRegistro,
    string Resultado, string? Detalle);
public sealed record AuditoriaPaginaModel(
    IReadOnlyList<AuditoriaModel> Elementos, long TotalRegistros,
    int Pagina, int TamanoPagina, int TotalPaginas);

public sealed record UsuarioSesionModel(
    int UsuarioId, string NombreUsuario, string NombreCompleto, string Correo,
    IReadOnlyList<string> Roles, IReadOnlyList<CatalogoModel> Giros,
    IReadOnlyList<CatalogoModel> Sedes, IReadOnlyList<CatalogoModel> Clientes);
public sealed record LoginResponseModel(string Token, DateTime ExpiraUtc, UsuarioSesionModel Usuario);

public sealed record UsuarioListadoModel(
    int UsuarioId, string NombreUsuario, string Nombre, string Apellido, string Correo,
    bool EsActivo, DateTime FechaCreacion, string Roles);
public sealed record UsuarioDetalleModel(
    int UsuarioId, string NombreUsuario, string Nombre, string Apellido, string Correo,
    bool EsActivo, DateTime FechaCreacion, DateTime? FechaModificacion,
    IReadOnlyList<CatalogoModel> Roles, IReadOnlyList<CatalogoModel> Giros, IReadOnlyList<CatalogoModel> Sedes);

public sealed record ClienteListadoModel(
    int ClienteId, string Nombre, string? Nit, string? CorreoContacto,
    bool EsActivo, DateTime FechaCreacion, string Usuarios, string Giros);
public sealed record ClienteDetalleModel(
    int ClienteId, string Nombre, string? Nit, string? CorreoContacto,
    bool EsActivo, DateTime FechaCreacion, DateTime? FechaModificacion,
    IReadOnlyList<CatalogoModel> Usuarios, IReadOnlyList<CatalogoModel> Giros);

public sealed class LoginViewModel
{
    [Required(ErrorMessage = "Ingrese su usuario.")]
    [Display(Name = "Usuario")]
    public string NombreUsuario { get; set; } = string.Empty;

    [Required(ErrorMessage = "Ingrese su contraseña.")]
    [DataType(DataType.Password)]
    [Display(Name = "Contraseña")]
    public string Clave { get; set; } = string.Empty;

    public string? Retorno { get; set; }
}

public sealed class UsuarioFiltroViewModel
{
    public string? Busqueda { get; set; }
    public bool? EsActivo { get; set; }
    public int? RolId { get; set; }
    public IReadOnlyList<UsuarioListadoModel> Usuarios { get; set; } = [];
    public IReadOnlyList<EntidadCatalogoModel> Roles { get; set; } = [];
}

public sealed class UsuarioFormViewModel
{
    public int UsuarioId { get; set; }
    [Required, StringLength(80, MinimumLength = 3)] [Display(Name="Nombre de usuario")]
    public string NombreUsuario { get; set; } = string.Empty;
    [Required, StringLength(100)] public string Nombre { get; set; } = string.Empty;
    [Required, StringLength(100)] public string Apellido { get; set; } = string.Empty;
    [Required, EmailAddress, StringLength(200)] public string Correo { get; set; } = string.Empty;
    [DataType(DataType.Password)] [StringLength(200)] public string? Clave { get; set; }
    [Display(Name="Usuario activo")] public bool EsActivo { get; set; } = true;
    public List<int> RolesSeleccionados { get; set; } = [];
    public List<int> GirosSeleccionados { get; set; } = [];
    public List<int> SedesSeleccionadas { get; set; } = [];
    public IReadOnlyList<EntidadCatalogoModel> RolesDisponibles { get; set; } = [];
    public IReadOnlyList<EntidadCatalogoModel> GirosDisponibles { get; set; } = [];
    public IReadOnlyList<EntidadCatalogoModel> SedesDisponibles { get; set; } = [];
}

public sealed class ClienteFiltroViewModel
{
    public string? Busqueda { get; set; }
    public bool? EsActivo { get; set; }
    public IReadOnlyList<ClienteListadoModel> Clientes { get; set; } = [];
}

public sealed class ClienteFormViewModel
{
    public int ClienteId { get; set; }

    [Required(ErrorMessage = "Ingrese el nombre de la empresa.")]
    [StringLength(200, MinimumLength = 2)]
    [Display(Name = "Empresa cliente")]
    public string Nombre { get; set; } = string.Empty;

    [StringLength(30)]
    [Display(Name = "NIT")]
    public string? Nit { get; set; }

    [EmailAddress(ErrorMessage = "Ingrese un correo electrónico válido.")]
    [StringLength(200)]
    [Display(Name = "Correo de contacto")]
    public string? CorreoContacto { get; set; }

    [Display(Name = "Cliente activo")]
    public bool EsActivo { get; set; } = true;

    public List<int> UsuariosSeleccionados { get; set; } = [];
    public List<int> GirosSeleccionados { get; set; } = [];
    public IReadOnlyList<UsuarioListadoModel> UsuariosDisponibles { get; set; } = [];
    public IReadOnlyList<EntidadCatalogoModel> GirosDisponibles { get; set; } = [];
}

public sealed class CatalogoFiltroViewModel
{
    public string Tipo { get; set; } = string.Empty;
    public string Titulo { get; set; } = string.Empty;
    public string Singular { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public string? Busqueda { get; set; }
    public bool? EsActivo { get; set; }
    public IReadOnlyList<EntidadCatalogoModel> Elementos { get; set; } = [];
}

public sealed class CatalogoFormViewModel
{
    public int Id { get; set; }
    public string Tipo { get; set; } = string.Empty;
    public string Titulo { get; set; } = string.Empty;
    public string Singular { get; set; } = string.Empty;
    public bool Protegido { get; set; }

    [Required(ErrorMessage = "Ingrese el nombre.")]
    [StringLength(120, MinimumLength = 2)]
    public string Nombre { get; set; } = string.Empty;

    [StringLength(500)]
    [Display(Name = "Descripción")]
    public string? Descripcion { get; set; }

    [Display(Name = "Registro activo")]
    public bool EsActivo { get; set; } = true;
}

public sealed class AuditoriaFiltroViewModel
{
    [StringLength(200)]
    public string? Busqueda { get; set; }

    [DataType(DataType.Date)]
    [Display(Name = "Desde")]
    public DateTime? FechaDesde { get; set; }

    [DataType(DataType.Date)]
    [Display(Name = "Hasta")]
    public DateTime? FechaHasta { get; set; }

    [StringLength(80)]
    public string? Modulo { get; set; }

    [StringLength(80)]
    [Display(Name = "Operación")]
    public string? TipoOperacion { get; set; }

    [StringLength(80)]
    [Display(Name = "Usuario")]
    public string? NombreUsuario { get; set; }

    [StringLength(40)]
    public string? Resultado { get; set; }

    public int Pagina { get; set; } = 1;
    public int TamanoPagina { get; set; } = 25;
    public AuditoriaPaginaModel Resultados { get; set; } = new([], 0, 1, 25, 0);
}

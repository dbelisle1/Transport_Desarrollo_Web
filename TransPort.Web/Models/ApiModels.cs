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

public sealed record PedidoListadoModel(
    long PedidoId, int ClienteId, string Cliente, int GiroNegocioId, string Giro,
    string TipoSolicitud, string Titulo, string Estado, DateTime? FechaRequerida,
    decimal? MontoCotizado, int? VendedorUsuarioId, string? Vendedor,
    DateTime FechaCreacion, DateTime? FechaModificacion);

public sealed record PedidoHistorialModel(
    long PedidoHistorialId, int UsuarioId, string NombreUsuario,
    string? EstadoAnterior, string EstadoNuevo, string? Comentario, DateTime Fecha);

public sealed record PedidoDocumentoModel(
    long PedidoDocumentoId, int UsuarioId, string NombreUsuario,
    string Nombre, string TipoDocumento, string Url, DateTime FechaCreacion);

public sealed record PedidoDetalleModel(
    long PedidoId, int ClienteId, string Cliente, int GiroNegocioId, string Giro,
    int SolicitanteUsuarioId, string Solicitante, int? VendedorUsuarioId, string? Vendedor,
    string TipoSolicitud, string Titulo, string Descripcion, string Estado,
    DateTime? FechaRequerida, decimal? MontoCotizado, DateTime? FechaReunionUtc,
    string? EnlaceReunion, DateTime FechaCreacion, DateTime? FechaModificacion,
    IReadOnlyList<PedidoHistorialModel> Historial, IReadOnlyList<PedidoDocumentoModel> Documentos);

public sealed record PedidoOpcionesModel(
    IReadOnlyList<CatalogoModel> Clientes,
    IReadOnlyList<CatalogoModel> Giros,
    IReadOnlyList<CatalogoModel> Vendedores);

public sealed class PedidoFiltroViewModel
{
    public string? Busqueda { get; set; }
    public string? Estado { get; set; }
    public int? ClienteId { get; set; }
    public int? GiroId { get; set; }
    public IReadOnlyList<PedidoListadoModel> Pedidos { get; set; } = [];
    public PedidoOpcionesModel Opciones { get; set; } = new([], [], []);
}

public sealed class PedidoCrearViewModel
{
    [Range(1, int.MaxValue, ErrorMessage = "Seleccione un cliente.")]
    [Display(Name = "Cliente")]
    public int ClienteId { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "Seleccione un giro.")]
    [Display(Name = "Giro de negocio")]
    public int GiroNegocioId { get; set; }

    [Required, StringLength(30)]
    [Display(Name = "Tipo de solicitud")]
    public string TipoSolicitud { get; set; } = "Pedido";

    [Required(ErrorMessage = "Ingrese un título."), StringLength(180, MinimumLength = 3)]
    [Display(Name = "Título")]
    public string Titulo { get; set; } = string.Empty;

    [Required(ErrorMessage = "Describa la solicitud."), StringLength(2000, MinimumLength = 5)]
    [Display(Name = "Descripción")]
    public string Descripcion { get; set; } = string.Empty;

    [DataType(DataType.Date)]
    [Display(Name = "Fecha requerida")]
    public DateTime? FechaRequerida { get; set; }

    [Display(Name = "Fecha propuesta para reunión")]
    public DateTime? FechaReunionUtc { get; set; }
    public PedidoOpcionesModel Opciones { get; set; } = new([], [], []);
}

public sealed class PedidoGestionViewModel
{
    public long PedidoId { get; set; }
    [Required] public string Estado { get; set; } = "EnRevision";
    [Display(Name = "Vendedor asignado")] public int? VendedorUsuarioId { get; set; }
    [Range(0, 9999999999999999.99)] [Display(Name = "Monto cotizado")]
    public decimal? MontoCotizado { get; set; }
    [Display(Name = "Fecha de reunión")] public DateTime? FechaReunionUtc { get; set; }
    [Url, StringLength(500)] [Display(Name = "Enlace de reunión")]
    public string? EnlaceReunion { get; set; }
    [StringLength(1000)] [Display(Name = "Comentario del cambio")]
    public string? Comentario { get; set; }
}

public sealed class PedidoDetalleViewModel
{
    public PedidoDetalleModel Pedido { get; set; } = null!;
    public PedidoOpcionesModel Opciones { get; set; } = new([], [], []);
}

public sealed record EmpresaPortalClienteModel(
    int ClienteId, string Nombre, string? Nit, string? CorreoContacto,
    IReadOnlyList<CatalogoModel> ServiciosContratados);

public sealed record PortalClienteResumenModel(
    IReadOnlyList<EmpresaPortalClienteModel> Empresas,
    long TotalSolicitudes, long Solicitadas, long EnGestion,
    long Completadas, long Documentos,
    IReadOnlyList<PedidoListadoModel> SolicitudesRecientes)
{
    public static PortalClienteResumenModel Vacio => new([], 0, 0, 0, 0, 0, []);
}

public sealed record InventarioExistenciaModel(
    int InventarioArticuloId,string Codigo,string Nombre,string Categoria,string UnidadMedida,
    int GiroNegocioId,string Giro,decimal StockMinimo,int? SedeId,string? Sede,
    decimal Cantidad,decimal CantidadReservada,decimal CantidadDisponible,bool BajoMinimo);
public sealed record InventarioMovimientoModel(
    long InventarioMovimientoId,int InventarioArticuloId,string Codigo,string Articulo,string Tipo,
    int? SedeOrigenId,string? SedeOrigen,int? SedeDestinoId,string? SedeDestino,decimal Cantidad,
    string UnidadMedida,string? Referencia,string? Observacion,int UsuarioId,string NombreUsuario,DateTime Fecha);
public sealed record InventarioOpcionesModel(
    IReadOnlyList<CatalogoModel> Giros,IReadOnlyList<CatalogoModel> Sedes,IReadOnlyList<CatalogoModel> Articulos);

public sealed class InventarioPaginaViewModel
{
    public string? Busqueda { get; set; } public int? GiroId { get; set; } public int? SedeId { get; set; }
    public bool SoloBajoMinimo { get; set; }
    public IReadOnlyList<InventarioExistenciaModel> Existencias { get; set; }=[];
    public IReadOnlyList<InventarioMovimientoModel> Movimientos { get; set; }=[];
    public InventarioOpcionesModel Opciones { get; set; }=new([],[],[]);
}
public sealed class InventarioArticuloFormModel
{
    [Range(1,int.MaxValue)]public int GiroNegocioId{get;set;}
    [Required,StringLength(50,MinimumLength=2)]public string Codigo{get;set;}=string.Empty;
    [Required,StringLength(180,MinimumLength=2)]public string Nombre{get;set;}=string.Empty;
    [Required,StringLength(80,MinimumLength=2)]public string Categoria{get;set;}=string.Empty;
    [Required,StringLength(30)]public string UnidadMedida{get;set;}=string.Empty;
    [Range(0,999999999999999.999)]public decimal StockMinimo{get;set;}
}
public sealed class InventarioMovimientoFormModel
{
    [Range(1,int.MaxValue)]public int InventarioArticuloId{get;set;}
    [Required]public string Tipo{get;set;}="Entrada";
    public int? SedeOrigenId{get;set;} public int? SedeDestinoId{get;set;}
    [Range(0.001,999999999999999.999)]public decimal Cantidad{get;set;}
    [StringLength(120)]public string? Referencia{get;set;}
    [StringLength(500)]public string? Observacion{get;set;}
}
public sealed record AbastecimientoListadoModel(long AbastecimientoSolicitudId,string Estado,DateTime FechaNecesaria,string Motivo,int GiroSolicitanteId,string GiroSolicitante,int SedeSolicitanteId,string SedeSolicitante,int GiroProveedorId,string GiroProveedor,int SedeProveedorId,string SedeProveedor,string Solicitante,DateTime FechaCreacion,DateTime? FechaModificacion,int Lineas);
public sealed record AbastecimientoLineaModel(long AbastecimientoDetalleId,int ArticuloProveedorId,string CodigoProveedor,string ArticuloProveedor,int ArticuloDestinoId,string CodigoDestino,string ArticuloDestino,decimal Cantidad,string UnidadMedida);
public sealed record AbastecimientoHistorialModel(long AbastecimientoHistorialId,int UsuarioId,string NombreUsuario,string? EstadoAnterior,string EstadoNuevo,string? Comentario,DateTime Fecha);
public sealed record AbastecimientoDetalleModel(long AbastecimientoSolicitudId,string Estado,DateTime FechaNecesaria,string Motivo,int GiroSolicitanteId,string GiroSolicitante,int SedeSolicitanteId,string SedeSolicitante,int GiroProveedorId,string GiroProveedor,int SedeProveedorId,string SedeProveedor,int SolicitanteUsuarioId,string Solicitante,DateTime FechaCreacion,DateTime? FechaModificacion,IReadOnlyList<AbastecimientoLineaModel> Detalles,IReadOnlyList<AbastecimientoHistorialModel> Historial);
public sealed record AbastecimientoOpcionesModel(IReadOnlyList<CatalogoModel> GirosSolicitante,IReadOnlyList<CatalogoModel> SedesSolicitante,IReadOnlyList<CatalogoModel> GirosProveedor,IReadOnlyList<CatalogoModel> SedesProveedor,IReadOnlyList<CatalogoModel> Articulos);
public sealed class AbastecimientoPaginaViewModel{public string? Estado{get;set;}public string? Busqueda{get;set;}public IReadOnlyList<AbastecimientoListadoModel> Solicitudes{get;set;}=[];public AbastecimientoOpcionesModel Opciones{get;set;}=new([],[],[],[],[]);}
public sealed class AbastecimientoCrearViewModel
{
 [Range(1,int.MaxValue)]public int GiroSolicitanteId{get;set;}[Range(1,int.MaxValue)]public int SedeSolicitanteId{get;set;}[Range(1,int.MaxValue)]public int GiroProveedorId{get;set;}[Range(1,int.MaxValue)]public int SedeProveedorId{get;set;}
 [DataType(DataType.Date)]public DateTime FechaNecesaria{get;set;}=DateTime.Today.AddDays(1);[Required,StringLength(500,MinimumLength=5)]public string Motivo{get;set;}=string.Empty;
 [Range(1,int.MaxValue)]public int ArticuloProveedorId{get;set;}[Range(1,int.MaxValue)]public int ArticuloDestinoId{get;set;}[Range(0.001,999999999999999.999)]public decimal Cantidad{get;set;}
}

public sealed record ExtraccionListadoModel(long ExtraccionJornadaId,int SedeId,string Sede,int InventarioArticuloId,string Codigo,string Articulo,string UnidadMedida,DateTime FechaOperacion,string Turno,string FrenteExtraccion,decimal CantidadExtraida,decimal CantidadRechazada,decimal CantidadAprovechable,string DestinoTipo,string? DestinoDescripcion,string Estado,string Responsable,DateTime FechaCreacion);
public sealed record ExtraccionHistorialModel(long ExtraccionHistorialId,int UsuarioId,string NombreUsuario,string? EstadoAnterior,string EstadoNuevo,string? Comentario,DateTime Fecha);
public sealed record ExtraccionDetalleModel(long ExtraccionJornadaId,int SedeId,string Sede,int InventarioArticuloId,string Codigo,string Articulo,string UnidadMedida,DateTime FechaOperacion,string Turno,string FrenteExtraccion,decimal CantidadExtraida,decimal CantidadRechazada,decimal CantidadAprovechable,string DestinoTipo,string? DestinoDescripcion,string Estado,int ResponsableUsuarioId,string Responsable,string? Observacion,DateTime FechaCreacion,DateTime? FechaModificacion,IReadOnlyList<ExtraccionHistorialModel> Historial);
public sealed record ExtraccionOpcionesModel(IReadOnlyList<CatalogoModel> Sedes,IReadOnlyList<CatalogoModel> Articulos);
public sealed class ExtraccionPaginaViewModel{public string? Estado{get;set;}public int? SedeId{get;set;}public DateTime? FechaDesde{get;set;}public DateTime? FechaHasta{get;set;}public IReadOnlyList<ExtraccionListadoModel> Jornadas{get;set;}=[];public ExtraccionOpcionesModel Opciones{get;set;}=new([],[]);}
public sealed class ExtraccionCrearViewModel
{
 [System.ComponentModel.DataAnnotations.Range(1,int.MaxValue)]public int SedeId{get;set;}
 [System.ComponentModel.DataAnnotations.Range(1,int.MaxValue)]public int InventarioArticuloId{get;set;}
 public DateTime FechaOperacion{get;set;}=DateTime.Today;
 [System.ComponentModel.DataAnnotations.Required,System.ComponentModel.DataAnnotations.StringLength(30,MinimumLength=2)]public string Turno{get;set;}=string.Empty;
 [System.ComponentModel.DataAnnotations.Required,System.ComponentModel.DataAnnotations.StringLength(120,MinimumLength=2)]public string FrenteExtraccion{get;set;}=string.Empty;
 [System.ComponentModel.DataAnnotations.Range(0.001,999999999999999.999)]public decimal CantidadExtraida{get;set;}
 [System.ComponentModel.DataAnnotations.Range(0,999999999999999.999)]public decimal CantidadRechazada{get;set;}
 [System.ComponentModel.DataAnnotations.Required,System.ComponentModel.DataAnnotations.StringLength(30)]public string DestinoTipo{get;set;}=string.Empty;
 [System.ComponentModel.DataAnnotations.StringLength(200)]public string? DestinoDescripcion{get;set;}
 [System.ComponentModel.DataAnnotations.StringLength(500)]public string? Observacion{get;set;}
}

public sealed record ProduccionListadoModel(long ProduccionOrdenId,int SedeId,string Sede,int ArticuloEntradaId,string CodigoEntrada,string ArticuloEntrada,string UnidadEntrada,int ArticuloSalidaId,string CodigoSalida,string ArticuloSalida,string UnidadSalida,DateTime FechaPlanificada,decimal CantidadEntrada,decimal CantidadSalidaPlanificada,decimal? CantidadSalidaReal,decimal? CantidadMerma,decimal? CostoUnitario,string Estado,string Responsable,DateTime FechaCreacion,string? EtapaActual);
public sealed record ProduccionEtapaModel(long ProduccionEtapaId,int Secuencia,string Nombre,string Estado,DateTime? FechaInicio,DateTime? FechaFin,string? Observacion);
public sealed record ProduccionHistorialModel(long ProduccionHistorialId,int UsuarioId,string NombreUsuario,string? EstadoAnterior,string EstadoNuevo,string? Comentario,DateTime Fecha);
public sealed record ProduccionDetalleModel(long ProduccionOrdenId,int SedeId,string Sede,int ArticuloEntradaId,string CodigoEntrada,string ArticuloEntrada,string UnidadEntrada,int ArticuloSalidaId,string CodigoSalida,string ArticuloSalida,string UnidadSalida,DateTime FechaPlanificada,decimal CantidadEntrada,decimal CantidadSalidaPlanificada,decimal? CantidadSalidaReal,decimal? CantidadMerma,decimal? CostoUnitario,string Estado,int ResponsableUsuarioId,string Responsable,string? Observacion,DateTime FechaCreacion,DateTime? FechaModificacion,IReadOnlyList<ProduccionEtapaModel> Etapas,IReadOnlyList<ProduccionHistorialModel> Historial);
public sealed record ProduccionOpcionesModel(IReadOnlyList<CatalogoModel>Sedes,IReadOnlyList<CatalogoModel>Articulos);
public sealed class ProduccionPaginaViewModel{public string?Estado{get;set;}public int?SedeId{get;set;}public DateTime?FechaDesde{get;set;}public DateTime?FechaHasta{get;set;}public IReadOnlyList<ProduccionListadoModel>Ordenes{get;set;}=[];public ProduccionOpcionesModel Opciones{get;set;}=new([],[]);}
public sealed class ProduccionCrearViewModel
{
 [System.ComponentModel.DataAnnotations.Range(1,int.MaxValue)]public int SedeId{get;set;}[System.ComponentModel.DataAnnotations.Range(1,int.MaxValue)]public int ArticuloEntradaId{get;set;}[System.ComponentModel.DataAnnotations.Range(1,int.MaxValue)]public int ArticuloSalidaId{get;set;}public DateTime FechaPlanificada{get;set;}=DateTime.Today;
 [System.ComponentModel.DataAnnotations.Range(0.001,999999999999999.999)]public decimal CantidadEntrada{get;set;}[System.ComponentModel.DataAnnotations.Range(0.001,999999999999999.999)]public decimal CantidadSalidaPlanificada{get;set;}[System.ComponentModel.DataAnnotations.StringLength(500)]public string?Observacion{get;set;}
}

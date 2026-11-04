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

public sealed record OfertaCatalogoModel(
    int CatalogoOfertaId, int GiroNegocioId, string Giro, string Codigo, string Tipo,
    string Nombre, string Descripcion, string UnidadMedida, decimal PrecioBase,
    bool EsPublico, bool EsActivo, DateTime FechaCreacion, DateTime? FechaModificacion);

public sealed record PedidoLineaModel(
    long PedidoLineaId, int CatalogoOfertaId, string Codigo, string Tipo, string Nombre,
    string UnidadMedida, decimal Cantidad, decimal PrecioUnitarioBase,
    decimal? PrecioUnitarioCotizado, decimal SubtotalBase, decimal? SubtotalCotizado);

public sealed record PedidoDetalleModel(
    long PedidoId, int ClienteId, string Cliente, int GiroNegocioId, string Giro,
    int SolicitanteUsuarioId, string Solicitante, int? VendedorUsuarioId, string? Vendedor,
    string TipoSolicitud, string Titulo, string Descripcion, string Estado,
    DateTime? FechaRequerida, decimal? MontoCotizado, DateTime? FechaReunionUtc,
    string? EnlaceReunion, DateTime FechaCreacion, DateTime? FechaModificacion,
    IReadOnlyList<PedidoHistorialModel> Historial, IReadOnlyList<PedidoDocumentoModel> Documentos,
    IReadOnlyList<PedidoLineaModel> Lineas);

public sealed record PedidoOpcionesModel(
    IReadOnlyList<CatalogoModel> Clientes,
    IReadOnlyList<CatalogoModel> Giros,
    IReadOnlyList<CatalogoModel> Vendedores,
    IReadOnlyList<OfertaCatalogoModel> Ofertas);

public sealed class PedidoFiltroViewModel
{
    public string? Busqueda { get; set; }
    public string? Estado { get; set; }
    public int? ClienteId { get; set; }
    public int? GiroId { get; set; }
    public IReadOnlyList<PedidoListadoModel> Pedidos { get; set; } = [];
    public PedidoOpcionesModel Opciones { get; set; } = new([], [], [], []);
}

public sealed class PedidoCrearLineaViewModel
{
    public int CatalogoOfertaId { get; set; }
    [Range(typeof(decimal), "0", "999999999999999.999")]
    public decimal Cantidad { get; set; }
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
    public List<PedidoCrearLineaViewModel> Lineas { get; set; } = [];
    public PedidoOpcionesModel Opciones { get; set; } = new([], [], [], []);
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
    public PedidoOpcionesModel Opciones { get; set; } = new([], [], [], []);
}

public sealed record CatalogoComercialOpcionesModel(IReadOnlyList<CatalogoModel> Giros);

public sealed class CatalogoComercialPaginaViewModel
{
    public string? Busqueda { get; set; }
    public int? GiroId { get; set; }
    public string? Tipo { get; set; }
    public bool? EsActivo { get; set; }
    public IReadOnlyList<OfertaCatalogoModel> Ofertas { get; set; } = [];
    public CatalogoComercialOpcionesModel Opciones { get; set; } = new([]);
    public OfertaCatalogoEditarViewModel Nueva { get; set; } = new();
}

public sealed class OfertaCatalogoEditarViewModel
{
    public int CatalogoOfertaId { get; set; }
    [Range(1, int.MaxValue, ErrorMessage = "Seleccione un giro.")]
    [Display(Name = "Giro de negocio")]
    public int GiroNegocioId { get; set; }
    [Required, StringLength(50, MinimumLength = 2)] public string Codigo { get; set; } = string.Empty;
    [Required, StringLength(20)] public string Tipo { get; set; } = "Producto";
    [Required, StringLength(180, MinimumLength = 3)] public string Nombre { get; set; } = string.Empty;
    [Required, StringLength(1000, MinimumLength = 5)] public string Descripcion { get; set; } = string.Empty;
    [Required, StringLength(40)] [Display(Name = "Unidad de medida")]
    public string UnidadMedida { get; set; } = string.Empty;
    [Range(0, 9999999999999999.99)] [Display(Name = "Precio base")]
    public decimal PrecioBase { get; set; }
    [Display(Name = "Visible en el catálogo público")] public bool EsPublico { get; set; } = true;
    [Display(Name = "Oferta activa")] public bool EsActivo { get; set; } = true;
    public CatalogoComercialOpcionesModel Opciones { get; set; } = new([]);
}

public sealed record ComunicacionListadoModel(
    long ComunicacionHiloId, string Tipo, string Asunto, string Estado,
    int? ClienteId, string? Cliente, int? GiroNegocioId, string? Giro, long? PedidoId,
    int? ResponsableUsuarioId, string? Responsable, string? ModuloOrigen,
    long? RegistroOrigenId, DateTime UltimaActividad, DateTime FechaCreacion, int Mensajes);
public sealed record ComunicacionMensajeModel(
    long ComunicacionMensajeId, int UsuarioId, string NombreUsuario,
    string Mensaje, bool EsInterno, DateTime Fecha);
public sealed record ComunicacionDetalleModel(
    long ComunicacionHiloId, string Tipo, string Asunto, string Estado,
    int? ClienteId, string? Cliente, int? GiroNegocioId, string? Giro, long? PedidoId,
    int? ResponsableUsuarioId, string? Responsable, string? ModuloOrigen,
    long? RegistroOrigenId, string CreadoPor, DateTime UltimaActividad,
    DateTime FechaCreacion, DateTime? FechaModificacion,
    IReadOnlyList<ComunicacionMensajeModel> Mensajes);
public sealed record ComunicacionPedidoOpcionModel(long Id, string Nombre);
public sealed record ComunicacionOpcionesModel(
    IReadOnlyList<CatalogoModel> Clientes, IReadOnlyList<CatalogoModel> Giros,
    IReadOnlyList<ComunicacionPedidoOpcionModel> Pedidos, IReadOnlyList<CatalogoModel> Responsables);
public sealed class ComunicacionCrearViewModel
{
    public string Tipo { get; set; } = "Cliente";
    public int? ClienteId { get; set; }
    public int? GiroNegocioId { get; set; }
    public long? PedidoId { get; set; }
    [Required, StringLength(180, MinimumLength = 3)] public string Asunto { get; set; } = string.Empty;
    [Required, StringLength(2000, MinimumLength = 2)] [Display(Name = "Mensaje inicial")]
    public string MensajeInicial { get; set; } = string.Empty;
    [StringLength(50)] public string? ModuloOrigen { get; set; }
    public long? RegistroOrigenId { get; set; }
}
public sealed class ComunicacionPaginaViewModel
{
    public string? Estado { get; set; }
    public string? Tipo { get; set; }
    public string? Busqueda { get; set; }
    public IReadOnlyList<ComunicacionListadoModel> Comunicaciones { get; set; } = [];
    public ComunicacionOpcionesModel Opciones { get; set; } = new([], [], [], []);
    public ComunicacionCrearViewModel Nueva { get; set; } = new();
}
public sealed class ComunicacionDetalleViewModel
{
    public ComunicacionDetalleModel Comunicacion { get; set; } = null!;
    public ComunicacionOpcionesModel Opciones { get; set; } = new([], [], [], []);
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
    public PortalClienteOperacionesModel Operaciones { get; init; } = PortalClienteOperacionesModel.Vacio;
}

public sealed record PortalClienteViajeModel(
    long TransporteViajeId,int ClienteId,string Cliente,string Tipo,string Origen,string Destino,
    string DescripcionCarga,DateTime FechaSalidaPlanificada,DateTime?FechaSalidaReal,
    DateTime?FechaEntrega,string Estado,string Placa,string Conductor,int IncidenciasAbiertas);
public sealed record PortalClienteContratoModel(
    long MaquinariaContratoId,int ClienteId,string Cliente,int MaquinariaEquipoId,string Codigo,
    string Equipo,string Tipo,DateTime FechaInicio,DateTime?FechaFin,decimal MontoTotal,
    string Estado,decimal?HorasEntrega,decimal?HorasDevolucion);
public sealed record PortalClienteProyectoModel(
    long ConstruccionProyectoId,int ClienteId,string Cliente,string Nombre,string TipoObra,
    string Ubicacion,DateTime FechaInicioPlanificada,DateTime FechaFinPlanificada,
    decimal Presupuesto,string Estado,decimal PorcentajeAvance,decimal CostoReal);
public sealed record PortalClienteOperacionesModel(
    long ViajesActivos,long ContratosActivos,long ProyectosActivos,
    IReadOnlyList<PortalClienteViajeModel>Viajes,
    IReadOnlyList<PortalClienteContratoModel>Contratos,
    IReadOnlyList<PortalClienteProyectoModel>Proyectos)
{
    public static PortalClienteOperacionesModel Vacio => new(0,0,0,[],[],[]);
}
public sealed class PortalClienteOperacionesPaginaViewModel
{
    public int? ClienteId{get;set;}
    public IReadOnlyList<EmpresaPortalClienteModel> Empresas{get;set;}=[];
    public PortalClienteOperacionesModel Operaciones{get;set;}=PortalClienteOperacionesModel.Vacio;
}

public sealed record IntegracionListadoModel(long IntegracionEventoId,string Canal,string Direccion,string SocioTipo,string SocioNombre,string Operacion,string ClaveIdempotencia,string?DocumentoExterno,string Estado,int Intentos,string?Error,int?InventarioArticuloId,string?ArticuloCodigo,string?Articulo,int?SedeId,string?Sede,decimal?Cantidad,long?InventarioMovimientoId,string NombreUsuario,DateTime?FechaProcesamiento,DateTime FechaCreacion);
public sealed record IntegracionDetalleModel(long IntegracionEventoId,string Canal,string Direccion,string SocioTipo,string SocioNombre,string Operacion,string ClaveIdempotencia,string?DocumentoExterno,string Contenido,string Estado,int Intentos,string?Error,int?InventarioArticuloId,string?ArticuloCodigo,string?Articulo,string?UnidadMedida,int?SedeId,string?Sede,decimal?Cantidad,long?InventarioMovimientoId,string NombreUsuario,DateTime?FechaProcesamiento,DateTime FechaCreacion,DateTime?FechaModificacion);
public sealed record IntegracionOpcionesModel(IReadOnlyList<CatalogoModel>Articulos,IReadOnlyList<CatalogoModel>Sedes);
public sealed class IntegracionSimularViewModel
{
    [Required]public string Canal{get;set;}="Webhook";
    [Required]public string Direccion{get;set;}="Entrada";
    [Required]public string SocioTipo{get;set;}="Proveedor";
    [Required,StringLength(180,MinimumLength=2)]public string SocioNombre{get;set;}="Proveedor externo de demostración";
    [Required]public string Operacion{get;set;}="RecepcionMateriaPrima";
    [Required,StringLength(120,MinimumLength=3)]public string ClaveIdempotencia{get;set;}=string.Empty;
    [StringLength(120)]public string?DocumentoExterno{get;set;}
    [Required,StringLength(4000,MinimumLength=2)]public string Contenido{get;set;}="{\"proveedor\":\"Proveedor externo de demostración\",\"documento\":\"REC-001\",\"articulo\":\"MP-EXT-DEMO\",\"cantidad\":25.5,\"ubicacion\":\"Ciudad de Guatemala\"}";
    public int?InventarioArticuloId{get;set;}public int?SedeId{get;set;}
    [Range(0.001,999999999999999.999)]public decimal?Cantidad{get;set;}=25.5m;
}
public sealed class IntegracionPaginaViewModel
{
    public string?Estado{get;set;}public string?Canal{get;set;}public string?Busqueda{get;set;}
    public IReadOnlyList<IntegracionListadoModel>Eventos{get;set;}=[];
    public IntegracionOpcionesModel Opciones{get;set;}=new([],[]);
    public IntegracionSimularViewModel Nueva{get;set;}=new();
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
public sealed record MaquinariaEquipoModel(int MaquinariaEquipoId,int SedeId,string Sede,string Codigo,string Tipo,string Marca,string Modelo,short?Anio,string Estado,decimal?PrecioVenta,decimal?TarifaDiaria,decimal HorasUso,string?Observacion,DateTime FechaCreacion);
public sealed record MaquinariaContratoModel(long MaquinariaContratoId,int ClienteId,string Cliente,string Tipo,DateTime FechaInicio,DateTime?FechaFin,decimal MontoTotal,decimal Deposito,string Estado,decimal?HorasEntrega,decimal?HorasDevolucion,string Responsable,string?Observacion,DateTime FechaCreacion);
public sealed record MaquinariaMantenimientoModel(long MaquinariaMantenimientoId,string Tipo,DateTime FechaProgramada,DateTime?FechaCompletada,decimal Costo,string Estado,string Responsable,string?Observacion,DateTime FechaCreacion);
public sealed record MaquinariaDetalleModel(int MaquinariaEquipoId,int SedeId,string Sede,string Codigo,string Tipo,string Marca,string Modelo,short?Anio,string Estado,decimal?PrecioVenta,decimal?TarifaDiaria,decimal HorasUso,string?Observacion,DateTime FechaCreacion,DateTime?FechaModificacion,IReadOnlyList<MaquinariaContratoModel>Contratos,IReadOnlyList<MaquinariaMantenimientoModel>Mantenimientos);
public sealed record MaquinariaOpcionesModel(IReadOnlyList<CatalogoModel>Sedes,IReadOnlyList<CatalogoModel>Clientes);
public sealed class MaquinariaPaginaViewModel{public string?Estado{get;set;}public int?SedeId{get;set;}public string?Busqueda{get;set;}public IReadOnlyList<MaquinariaEquipoModel>Equipos{get;set;}=[];public MaquinariaOpcionesModel Opciones{get;set;}=new([],[]);}
public sealed class MaquinariaCrearViewModel{public int SedeId{get;set;}public string Codigo{get;set;}="";public string Tipo{get;set;}="";public string Marca{get;set;}="";public string Modelo{get;set;}="";public short?Anio{get;set;}public decimal?PrecioVenta{get;set;}public decimal?TarifaDiaria{get;set;}public decimal HorasUso{get;set;}public string?Observacion{get;set;}}
public sealed class MaquinariaContratoCrearViewModel{public int EquipoId{get;set;}public int ClienteId{get;set;}public string Tipo{get;set;}="";public DateTime FechaInicio{get;set;}public DateTime?FechaFin{get;set;}public decimal MontoTotal{get;set;}public decimal Deposito{get;set;}public string?Observacion{get;set;}}
public sealed class MaquinariaMantenimientoCrearViewModel{public int EquipoId{get;set;}public string Tipo{get;set;}="";public DateTime FechaProgramada{get;set;}public decimal Costo{get;set;}public string?Observacion{get;set;}}
public sealed record TransporteViajeListadoModel(long TransporteViajeId,int SedeId,string Sede,string Tipo,string Origen,string Destino,string DescripcionCarga,decimal PesoCarga,DateTime FechaSalidaPlanificada,DateTime?FechaSalidaReal,DateTime?FechaEntrega,string Estado,string Placa,string Conductor,string?Cliente,string Responsable,int IncidenciasAbiertas);
public sealed record TransporteIncidenciaModel(long TransporteIncidenciaId,string Tipo,string Severidad,string Descripcion,bool Resuelta,string?Resolucion,string NombreUsuario,DateTime Fecha,DateTime?FechaResolucion);
public sealed record TransporteViajeDetalleModel(long TransporteViajeId,int SedeId,string Sede,int TransporteVehiculoId,string Placa,string TipoVehiculo,int TransporteConductorId,string Conductor,string Licencia,int?ClienteId,string?Cliente,string Tipo,string Origen,string Destino,string DescripcionCarga,decimal PesoCarga,DateTime FechaSalidaPlanificada,DateTime?FechaSalidaReal,DateTime?FechaEntrega,string Estado,string Responsable,string?Observacion,DateTime FechaCreacion,IReadOnlyList<TransporteIncidenciaModel>Incidencias);
public sealed record TransporteOpcionesModel(IReadOnlyList<CatalogoModel>Sedes,IReadOnlyList<CatalogoModel>Vehiculos,IReadOnlyList<CatalogoModel>Conductores,IReadOnlyList<CatalogoModel>Clientes);
public sealed class TransportePaginaViewModel{public string?Estado{get;set;}public string?Tipo{get;set;}public int?SedeId{get;set;}public IReadOnlyList<TransporteViajeListadoModel>Viajes{get;set;}=[];public TransporteOpcionesModel Opciones{get;set;}=new([],[],[],[]);}
public sealed class TransporteVehiculoCrearViewModel{public int SedeId{get;set;}public string Placa{get;set;}="";public string Tipo{get;set;}="";public string Marca{get;set;}="";public string Modelo{get;set;}="";public decimal Capacidad{get;set;}public string UnidadCapacidad{get;set;}="t";public bool EsInternacional{get;set;}}
public sealed class TransporteConductorCrearViewModel{public string Nombre{get;set;}="";public string Licencia{get;set;}="";public string Categoria{get;set;}="";public DateTime FechaVencimiento{get;set;}public string?Telefono{get;set;}}
public sealed class TransporteViajeCrearViewModel{public int SedeId{get;set;}public int VehiculoId{get;set;}public int ConductorId{get;set;}public int?ClienteId{get;set;}public string Tipo{get;set;}="";public string Origen{get;set;}="";public string Destino{get;set;}="";public string DescripcionCarga{get;set;}="";public decimal PesoCarga{get;set;}public DateTime FechaSalidaPlanificada{get;set;}public string?Observacion{get;set;}}
public sealed record GpsDispositivoResumenModel(int GpsDispositivoId,string IdentificadorExterno,string NombreActivo,int?TransporteVehiculoId,string?Placa,int?MaquinariaEquipoId,string?MaquinariaCodigo,string Proveedor,decimal VelocidadMaxima,bool EsActivo,DateTime?UltimaSincronizacion,DateTime?FechaEvento,decimal?Latitud,decimal?Longitud,decimal?Velocidad,decimal?HorasUso,decimal?Kilometraje,string?Evento,int AlertasAbiertas);
public sealed record GpsAlertaModel(long GpsAlertaId,int GpsDispositivoId,string NombreActivo,string Tipo,string Severidad,string Mensaje,bool Atendida,DateTime Fecha,DateTime?FechaAtencion,string?AtendidaPor);
public sealed record GpsPosicionModel(long GpsPosicionId,int GpsDispositivoId,DateTime FechaEvento,decimal Latitud,decimal Longitud,decimal Velocidad,decimal?HorasUso,decimal?Kilometraje,string?Evento,string OrigenDato,string?DatosFuente,DateTime Recibido);
public sealed record GpsResumenModel(IReadOnlyList<GpsDispositivoResumenModel>Dispositivos,IReadOnlyList<GpsAlertaModel>Alertas);
public sealed record GpsOpcionesModel(IReadOnlyList<CatalogoModel>Vehiculos,IReadOnlyList<CatalogoModel>Maquinarias);
public sealed class GpsPaginaViewModel{public GpsResumenModel Resumen{get;set;}=new([],[]);public GpsOpcionesModel Opciones{get;set;}=new([],[]);public string DatosFuenteEjemplo{get;set;}="{\"latitud\":14.634915,\"longitud\":-90.506882,\"velocidad\":35.5,\"horasUso\":125.4,\"kilometraje\":48210.7,\"evento\":\"Posicion Ciudad de Guatemala\"}";}
public sealed class GpsDispositivoCrearViewModel{public string IdentificadorExterno{get;set;}="GPS-DEMO-001";public string NombreActivo{get;set;}="Unidad de demostración";public int?VehiculoId{get;set;}public int?MaquinariaId{get;set;}public string Proveedor{get;set;}="GPS-Inversiones";public decimal VelocidadMaxima{get;set;}=80;}
public sealed record ConstruccionListadoModel(long ConstruccionProyectoId,int SedeId,string Sede,int?ClienteId,string?Cliente,string Nombre,string TipoObra,string Ubicacion,DateTime FechaInicioPlanificada,DateTime FechaFinPlanificada,decimal Presupuesto,string Estado,string Responsable,DateTime FechaCreacion,decimal PorcentajeAvance,decimal CostoReal);
public sealed record ConstruccionActividadModel(long ConstruccionActividadId,string Nombre,int ResponsableUsuarioId,string Responsable,DateTime FechaInicio,DateTime FechaFin,decimal Presupuesto,decimal PorcentajeAvance,string Estado,string?Observacion,decimal CostoReal);
public sealed record ConstruccionRecursoModel(long ConstruccionRecursoId,long?ConstruccionActividadId,string Tipo,string Descripcion,decimal Cantidad,string Unidad,decimal CostoUnitario,int?InventarioArticuloId,string?ArticuloCodigo,int?MaquinariaEquipoId,string?MaquinariaCodigo,string NombreUsuario,DateTime Fecha);
public sealed record ConstruccionAvanceModel(long ConstruccionAvanceId,long ConstruccionActividadId,string Actividad,decimal PorcentajeAnterior,decimal PorcentajeNuevo,string Comentario,string?EvidenciaUrl,string NombreUsuario,DateTime Fecha);
public sealed record ConstruccionDetalleModel(long ConstruccionProyectoId,int SedeId,string Sede,int?ClienteId,string?Cliente,string Nombre,string TipoObra,string Ubicacion,DateTime FechaInicioPlanificada,DateTime FechaFinPlanificada,decimal Presupuesto,string Estado,int ResponsableUsuarioId,string Responsable,string?Descripcion,DateTime FechaCreacion,DateTime?FechaModificacion,IReadOnlyList<ConstruccionActividadModel>Actividades,IReadOnlyList<ConstruccionRecursoModel>Recursos,IReadOnlyList<ConstruccionAvanceModel>Avances);
public sealed record ConstruccionOpcionesModel(IReadOnlyList<CatalogoModel>Sedes,IReadOnlyList<CatalogoModel>Clientes,IReadOnlyList<CatalogoModel>Usuarios,IReadOnlyList<CatalogoModel>Articulos,IReadOnlyList<CatalogoModel>Maquinarias);
public sealed class ConstruccionPaginaViewModel{public string?Estado{get;set;}public int?SedeId{get;set;}public string?Busqueda{get;set;}public IReadOnlyList<ConstruccionListadoModel>Proyectos{get;set;}=[];public ConstruccionOpcionesModel Opciones{get;set;}=new([],[],[],[],[]);}
public sealed class ConstruccionCrearViewModel{public int SedeId{get;set;}public int?ClienteId{get;set;}public string Nombre{get;set;}="";public string TipoObra{get;set;}="";public string Ubicacion{get;set;}="";public DateTime FechaInicio{get;set;}public DateTime FechaFin{get;set;}public decimal Presupuesto{get;set;}public int ResponsableId{get;set;}public string?Descripcion{get;set;}}
public sealed class ConstruccionActividadCrearViewModel{public string Nombre{get;set;}="";public int ResponsableId{get;set;}public DateTime FechaInicio{get;set;}public DateTime FechaFin{get;set;}public decimal Presupuesto{get;set;}public string?Observacion{get;set;}}
public sealed class ConstruccionRecursoCrearViewModel{public long?ActividadId{get;set;}public string Tipo{get;set;}="";public string Descripcion{get;set;}="";public decimal Cantidad{get;set;}public string Unidad{get;set;}="";public decimal CostoUnitario{get;set;}public int?ArticuloId{get;set;}public int?MaquinariaId{get;set;}}
public sealed record PresupuestoListadoModel(long FinanzaPresupuestoId,int GiroNegocioId,string Giro,int SedeId,string Sede,short Anio,byte Mes,string Nombre,decimal Monto,string Estado,decimal GastoReal,decimal Disponible,decimal PorcentajeEjecutado,DateTime FechaCreacion);
public sealed record FinanzaGastoModel(long FinanzaGastoId,DateTime Fecha,string Categoria,string Concepto,decimal Monto,string OrigenModulo,long?OrigenRegistroId,string?Referencia,string NombreUsuario,DateTime FechaCreacion);
public sealed record PresupuestoDetalleModel(long FinanzaPresupuestoId,int GiroNegocioId,string Giro,int SedeId,string Sede,short Anio,byte Mes,string Nombre,decimal Monto,string Estado,string?Observacion,decimal GastoReal,decimal Disponible,decimal PorcentajeEjecutado,DateTime FechaCreacion,IReadOnlyList<FinanzaGastoModel>Gastos);
public sealed record FinanzaOpcionesModel(IReadOnlyList<CatalogoModel>Giros,IReadOnlyList<CatalogoModel>Sedes);
public sealed class FinanzaPaginaViewModel{public short?Anio{get;set;}public byte?Mes{get;set;}public int?GiroId{get;set;}public int?SedeId{get;set;}public IReadOnlyList<PresupuestoListadoModel>Presupuestos{get;set;}=[];public FinanzaOpcionesModel Opciones{get;set;}=new([],[]);}
public sealed class PresupuestoCrearViewModel{public int GiroId{get;set;}public int SedeId{get;set;}public short Anio{get;set;}public byte Mes{get;set;}public string Nombre{get;set;}="";public decimal Monto{get;set;}public string?Observacion{get;set;}}
public sealed class GastoCrearViewModel{public DateTime Fecha{get;set;}public string Categoria{get;set;}="";public string Concepto{get;set;}="";public decimal Monto{get;set;}public string OrigenModulo{get;set;}="Manual";public long?OrigenRegistroId{get;set;}public string?Referencia{get;set;}}
public sealed record IngresoModel(long FinanzaIngresoId,int GiroNegocioId,string Giro,int SedeId,string Sede,int?ClienteId,string?Cliente,DateTime Fecha,string Categoria,string Concepto,decimal Monto,string OrigenModulo,long?OrigenRegistroId,string?Referencia,string NombreUsuario,DateTime FechaCreacion);
public sealed record IngresoOpcionesModel(IReadOnlyList<CatalogoModel>Giros,IReadOnlyList<CatalogoModel>Sedes,IReadOnlyList<CatalogoModel>Clientes);
public sealed class IngresoPaginaViewModel{public short?Anio{get;set;}public byte?Mes{get;set;}public int?GiroId{get;set;}public int?SedeId{get;set;}public IReadOnlyList<IngresoModel>Ingresos{get;set;}=[];public IngresoOpcionesModel Opciones{get;set;}=new([],[],[]);}
public sealed class IngresoCrearViewModel{public int GiroId{get;set;}public int SedeId{get;set;}public int?ClienteId{get;set;}public DateTime Fecha{get;set;}public string Categoria{get;set;}="";public string Concepto{get;set;}="";public decimal Monto{get;set;}public string OrigenModulo{get;set;}="Manual";public long?OrigenRegistroId{get;set;}public string?Referencia{get;set;}}
public sealed record ReporteOpcionesModel(IReadOnlyList<CatalogoModel>Giros,IReadOnlyList<CatalogoModel>Sedes);
public sealed record ReporteInternoResumenModel(DateTime Desde,DateTime Hasta,int Giros,int Sedes,long Operaciones,long Completadas,decimal Presupuesto,decimal Gastos,decimal Ingresos,decimal Resultado);
public sealed record ReporteGiroModel(int GiroNegocioId,string Giro,long Operaciones,long Completadas,string Indicador,decimal ValorIndicador,string UnidadIndicador,decimal Presupuesto,decimal Gastos,decimal Ingresos,decimal Resultado);
public sealed record ReportePeriodoModel(short Anio,byte Mes,string Periodo,decimal Presupuesto,decimal Gastos,decimal Ingresos,decimal Resultado);
public sealed record ReporteInternoModel(ReporteInternoResumenModel Resumen,IReadOnlyList<ReporteGiroModel>Giros,IReadOnlyList<ReportePeriodoModel>Periodos);
public sealed class ReporteInternoPaginaViewModel{public DateTime?Desde{get;set;}public DateTime?Hasta{get;set;}public int?GiroId{get;set;}public int?SedeId{get;set;}public ReporteOpcionesModel Opciones{get;set;}=new([],[]);public required ReporteInternoModel Reporte{get;set;}}
public sealed record ReporteClienteResumenModel(DateTime Desde,DateTime Hasta,int Empresas,long Pedidos,long Completados,decimal MontoCotizado,long Viajes,long Entregados,decimal PesoTransportado,long Contratos,decimal MontoContratos,long Proyectos,decimal PresupuestoObras,decimal AvancePromedio,decimal IngresosRegistrados);
public sealed record ReporteClienteEmpresaModel(int ClienteId,string Cliente,long Pedidos,long Completados,decimal MontoCotizado,long Viajes,long Entregados,decimal PesoTransportado,long Contratos,decimal MontoContratos,long Proyectos,decimal PresupuestoObras,decimal AvancePromedio,decimal IngresosRegistrados);
public sealed record ReporteClientePeriodoModel(short Anio,byte Mes,string Periodo,long Pedidos,long Operaciones,decimal IngresosRegistrados);
public sealed record ReporteClienteModel(ReporteClienteResumenModel Resumen,IReadOnlyList<ReporteClienteEmpresaModel>Empresas,IReadOnlyList<ReporteClientePeriodoModel>Periodos);
public sealed class ReporteClientePaginaViewModel{public DateTime?Desde{get;set;}public DateTime?Hasta{get;set;}public int?ClienteId{get;set;}public IReadOnlyList<EmpresaPortalClienteModel>Empresas{get;set;}=[];public required ReporteClienteModel Reporte{get;set;}}
public sealed record AlertaListadoModel(long AlertaNotificacionId,string Tipo,string Titulo,string Mensaje,string Severidad,string Estado,DateTime FechaProgramadaUtc,DateTime?FechaVencimientoUtc,string?Rol,string?Giro,string?Sede,string?UsuarioDestino,string?ModuloOrigen,long?RegistroOrigenId,bool Leida,int Seguimientos);
public sealed record AlertaSeguimientoModel(long AlertaSeguimientoId,string Comentario,string NombreUsuario,DateTime Fecha);
public sealed record AlertaDetalleModel(long AlertaNotificacionId,string Tipo,string Titulo,string Mensaje,string Severidad,string Estado,DateTime FechaProgramadaUtc,DateTime?FechaVencimientoUtc,int?RolId,string?Rol,int?GiroNegocioId,string?Giro,int?SedeId,string?Sede,int?UsuarioDestinoId,string?UsuarioDestino,string?ModuloOrigen,long?RegistroOrigenId,string CreadoPor,DateTime FechaCreacion,bool Leida,DateTime?FechaLectura,IReadOnlyList<AlertaSeguimientoModel>Seguimientos);
public sealed record AlertaOpcionesModel(IReadOnlyList<CatalogoModel>Roles,IReadOnlyList<CatalogoModel>Giros,IReadOnlyList<CatalogoModel>Sedes,IReadOnlyList<CatalogoModel>Usuarios);
public sealed class AlertaPaginaViewModel{public string?Estado{get;set;}public bool SoloPendientes{get;set;}public IReadOnlyList<AlertaListadoModel>Alertas{get;set;}=[];public AlertaOpcionesModel Opciones{get;set;}=new([],[],[],[]);}
public sealed class AlertaCrearViewModel{public string Tipo{get;set;}="Alerta";public string Titulo{get;set;}="";public string Mensaje{get;set;}="";public string Severidad{get;set;}="Informativa";public int?RolId{get;set;}public int?GiroId{get;set;}public int?SedeId{get;set;}public int?UsuarioDestinoId{get;set;}public DateTime FechaProgramadaUtc{get;set;}public DateTime?FechaVencimientoUtc{get;set;}public string?ModuloOrigen{get;set;}public long?RegistroOrigenId{get;set;}}

USE [TransPortDB];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Usuario', N'U') IS NULL
CREATE TABLE dbo.Usuario
(
    UsuarioId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Usuario PRIMARY KEY,
    NombreUsuario NVARCHAR(80) NOT NULL,
    Nombre NVARCHAR(100) NOT NULL,
    Apellido NVARCHAR(100) NOT NULL,
    Correo NVARCHAR(200) NOT NULL,
    Clave NVARCHAR(200) NOT NULL,
    EsActivo BIT NOT NULL CONSTRAINT DF_Usuario_EsActivo DEFAULT (1),
    Eliminado BIT NOT NULL CONSTRAINT DF_Usuario_Eliminado DEFAULT (0),
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Usuario_FechaCreacion DEFAULT (SYSUTCDATETIME()),
    FechaModificacion DATETIME2(0) NULL
);
GO

IF OBJECT_ID(N'dbo.Rol', N'U') IS NULL
CREATE TABLE dbo.Rol
(
    RolId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Rol PRIMARY KEY,
    Nombre NVARCHAR(120) NOT NULL,
    Descripcion NVARCHAR(500) NULL,
    EsActivo BIT NOT NULL CONSTRAINT DF_Rol_EsActivo DEFAULT (1),
    Eliminado BIT NOT NULL CONSTRAINT DF_Rol_Eliminado DEFAULT (0),
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Rol_FechaCreacion DEFAULT (SYSUTCDATETIME()),
    FechaModificacion DATETIME2(0) NULL
);
GO

IF OBJECT_ID(N'dbo.GiroNegocio', N'U') IS NULL
CREATE TABLE dbo.GiroNegocio
(
    GiroNegocioId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_GiroNegocio PRIMARY KEY,
    Nombre NVARCHAR(120) NOT NULL,
    Descripcion NVARCHAR(500) NULL,
    EsActivo BIT NOT NULL CONSTRAINT DF_GiroNegocio_EsActivo DEFAULT (1),
    Eliminado BIT NOT NULL CONSTRAINT DF_GiroNegocio_Eliminado DEFAULT (0),
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_GiroNegocio_FechaCreacion DEFAULT (SYSUTCDATETIME()),
    FechaModificacion DATETIME2(0) NULL
);
GO

IF OBJECT_ID(N'dbo.Sede', N'U') IS NULL
CREATE TABLE dbo.Sede
(
    SedeId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Sede PRIMARY KEY,
    Nombre NVARCHAR(120) NOT NULL,
    Descripcion NVARCHAR(500) NULL,
    EsActivo BIT NOT NULL CONSTRAINT DF_Sede_EsActivo DEFAULT (1),
    Eliminado BIT NOT NULL CONSTRAINT DF_Sede_Eliminado DEFAULT (0),
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Sede_FechaCreacion DEFAULT (SYSUTCDATETIME()),
    FechaModificacion DATETIME2(0) NULL
);
GO

IF OBJECT_ID(N'dbo.Cliente', N'U') IS NULL
CREATE TABLE dbo.Cliente
(
    ClienteId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Cliente PRIMARY KEY,
    Nombre NVARCHAR(200) NOT NULL,
    Nit NVARCHAR(30) NULL,
    CorreoContacto NVARCHAR(200) NULL,
    EsActivo BIT NOT NULL CONSTRAINT DF_Cliente_EsActivo DEFAULT (1),
    Eliminado BIT NOT NULL CONSTRAINT DF_Cliente_Eliminado DEFAULT (0),
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Cliente_FechaCreacion DEFAULT (SYSUTCDATETIME()),
    FechaModificacion DATETIME2(0) NULL
);
GO

IF OBJECT_ID(N'dbo.UsuarioRol', N'U') IS NULL
CREATE TABLE dbo.UsuarioRol
(
    UsuarioRolId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_UsuarioRol PRIMARY KEY,
    UsuarioId INT NOT NULL,
    RolId INT NOT NULL,
    Eliminado BIT NOT NULL CONSTRAINT DF_UsuarioRol_Eliminado DEFAULT (0),
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_UsuarioRol_FechaCreacion DEFAULT (SYSUTCDATETIME()),
    FechaModificacion DATETIME2(0) NULL
);
GO

IF OBJECT_ID(N'dbo.SedeGiroNegocio', N'U') IS NULL
CREATE TABLE dbo.SedeGiroNegocio
(
    SedeGiroNegocioId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_SedeGiroNegocio PRIMARY KEY,
    SedeId INT NOT NULL,
    GiroNegocioId INT NOT NULL,
    Eliminado BIT NOT NULL CONSTRAINT DF_SedeGiroNegocio_Eliminado DEFAULT (0),
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_SedeGiroNegocio_FechaCreacion DEFAULT (SYSUTCDATETIME()),
    FechaModificacion DATETIME2(0) NULL
);
GO

IF OBJECT_ID(N'dbo.UsuarioGiroNegocio', N'U') IS NULL
CREATE TABLE dbo.UsuarioGiroNegocio
(
    UsuarioGiroNegocioId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_UsuarioGiroNegocio PRIMARY KEY,
    UsuarioId INT NOT NULL,
    GiroNegocioId INT NOT NULL,
    Eliminado BIT NOT NULL CONSTRAINT DF_UsuarioGiroNegocio_Eliminado DEFAULT (0),
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_UsuarioGiroNegocio_FechaCreacion DEFAULT (SYSUTCDATETIME()),
    FechaModificacion DATETIME2(0) NULL
);
GO

IF OBJECT_ID(N'dbo.UsuarioSede', N'U') IS NULL
CREATE TABLE dbo.UsuarioSede
(
    UsuarioSedeId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_UsuarioSede PRIMARY KEY,
    UsuarioId INT NOT NULL,
    SedeId INT NOT NULL,
    Eliminado BIT NOT NULL CONSTRAINT DF_UsuarioSede_Eliminado DEFAULT (0),
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_UsuarioSede_FechaCreacion DEFAULT (SYSUTCDATETIME()),
    FechaModificacion DATETIME2(0) NULL
);
GO

IF OBJECT_ID(N'dbo.ClienteUsuario', N'U') IS NULL
CREATE TABLE dbo.ClienteUsuario
(
    ClienteUsuarioId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ClienteUsuario PRIMARY KEY,
    ClienteId INT NOT NULL,
    UsuarioId INT NOT NULL,
    Eliminado BIT NOT NULL CONSTRAINT DF_ClienteUsuario_Eliminado DEFAULT (0),
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_ClienteUsuario_FechaCreacion DEFAULT (SYSUTCDATETIME()),
    FechaModificacion DATETIME2(0) NULL
);
GO

IF OBJECT_ID(N'dbo.ClienteGiroNegocio', N'U') IS NULL
CREATE TABLE dbo.ClienteGiroNegocio
(
    ClienteGiroNegocioId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ClienteGiroNegocio PRIMARY KEY,
    ClienteId INT NOT NULL,
    GiroNegocioId INT NOT NULL,
    Eliminado BIT NOT NULL CONSTRAINT DF_ClienteGiroNegocio_Eliminado DEFAULT (0),
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_ClienteGiroNegocio_FechaCreacion DEFAULT (SYSUTCDATETIME()),
    FechaModificacion DATETIME2(0) NULL
);
GO

IF OBJECT_ID(N'dbo.Auditoria', N'U') IS NULL
CREATE TABLE dbo.Auditoria
(
    AuditoriaId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Auditoria PRIMARY KEY,
    UsuarioId INT NULL,
    Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_Auditoria_Fecha DEFAULT (SYSUTCDATETIME()),
    Modulo NVARCHAR(80) NOT NULL,
    TipoOperacion NVARCHAR(80) NOT NULL,
    IdentificadorRegistro NVARCHAR(100) NULL,
    Resultado NVARCHAR(40) NOT NULL,
    Detalle NVARCHAR(1000) NULL
);
GO

IF OBJECT_ID(N'dbo.Pedido', N'U') IS NULL
CREATE TABLE dbo.Pedido
(
    PedidoId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Pedido PRIMARY KEY,
    ClienteId INT NOT NULL,
    GiroNegocioId INT NOT NULL,
    SolicitanteUsuarioId INT NOT NULL,
    VendedorUsuarioId INT NULL,
    TipoSolicitud NVARCHAR(30) NOT NULL,
    Titulo NVARCHAR(180) NOT NULL,
    Descripcion NVARCHAR(2000) NOT NULL,
    Estado NVARCHAR(30) NOT NULL CONSTRAINT DF_Pedido_Estado DEFAULT (N'Solicitado'),
    FechaRequerida DATE NULL,
    MontoCotizado DECIMAL(18,2) NULL,
    FechaReunionUtc DATETIME2(0) NULL,
    EnlaceReunion NVARCHAR(500) NULL,
    Eliminado BIT NOT NULL CONSTRAINT DF_Pedido_Eliminado DEFAULT (0),
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Pedido_FechaCreacion DEFAULT (SYSUTCDATETIME()),
    FechaModificacion DATETIME2(0) NULL,
    CONSTRAINT CK_Pedido_TipoSolicitud CHECK (TipoSolicitud IN (N'Pedido',N'Cotizacion',N'Reunion')),
    CONSTRAINT CK_Pedido_Estado CHECK (Estado IN (N'Solicitado',N'EnRevision',N'Cotizado',N'Aprobado',N'EnProceso',N'Completado',N'Rechazado',N'Cancelado')),
    CONSTRAINT CK_Pedido_MontoCotizado CHECK (MontoCotizado IS NULL OR MontoCotizado >= 0)
);
GO

IF OBJECT_ID(N'dbo.PedidoHistorial', N'U') IS NULL
CREATE TABLE dbo.PedidoHistorial
(
    PedidoHistorialId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PedidoHistorial PRIMARY KEY,
    PedidoId BIGINT NOT NULL,
    UsuarioId INT NOT NULL,
    EstadoAnterior NVARCHAR(30) NULL,
    EstadoNuevo NVARCHAR(30) NOT NULL,
    Comentario NVARCHAR(1000) NULL,
    Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_PedidoHistorial_Fecha DEFAULT (SYSUTCDATETIME())
);
GO

IF OBJECT_ID(N'dbo.PedidoDocumento', N'U') IS NULL
CREATE TABLE dbo.PedidoDocumento
(
    PedidoDocumentoId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PedidoDocumento PRIMARY KEY,
    PedidoId BIGINT NOT NULL,
    UsuarioId INT NOT NULL,
    Nombre NVARCHAR(200) NOT NULL,
    TipoDocumento NVARCHAR(60) NOT NULL,
    Url NVARCHAR(1000) NOT NULL,
    Eliminado BIT NOT NULL CONSTRAINT DF_PedidoDocumento_Eliminado DEFAULT (0),
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_PedidoDocumento_FechaCreacion DEFAULT (SYSUTCDATETIME())
);
GO

IF OBJECT_ID(N'dbo.InventarioArticulo', N'U') IS NULL
CREATE TABLE dbo.InventarioArticulo
(
    InventarioArticuloId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_InventarioArticulo PRIMARY KEY,
    GiroNegocioId INT NOT NULL,
    Codigo NVARCHAR(50) NOT NULL,
    Nombre NVARCHAR(180) NOT NULL,
    Categoria NVARCHAR(80) NOT NULL,
    UnidadMedida NVARCHAR(30) NOT NULL,
    StockMinimo DECIMAL(18,3) NOT NULL CONSTRAINT DF_InventarioArticulo_StockMinimo DEFAULT (0),
    EsActivo BIT NOT NULL CONSTRAINT DF_InventarioArticulo_EsActivo DEFAULT (1),
    Eliminado BIT NOT NULL CONSTRAINT DF_InventarioArticulo_Eliminado DEFAULT (0),
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_InventarioArticulo_FechaCreacion DEFAULT (SYSUTCDATETIME()),
    FechaModificacion DATETIME2(0) NULL,
    CONSTRAINT CK_InventarioArticulo_StockMinimo CHECK (StockMinimo>=0)
);
GO

IF OBJECT_ID(N'dbo.InventarioExistencia', N'U') IS NULL
CREATE TABLE dbo.InventarioExistencia
(
    InventarioExistenciaId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_InventarioExistencia PRIMARY KEY,
    InventarioArticuloId INT NOT NULL,
    SedeId INT NOT NULL,
    Cantidad DECIMAL(18,3) NOT NULL CONSTRAINT DF_InventarioExistencia_Cantidad DEFAULT (0),
    CantidadReservada DECIMAL(18,3) NOT NULL CONSTRAINT DF_InventarioExistencia_Reservada DEFAULT (0),
    FechaModificacion DATETIME2(0) NOT NULL CONSTRAINT DF_InventarioExistencia_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT CK_InventarioExistencia_Cantidades CHECK (Cantidad>=0 AND CantidadReservada>=0 AND CantidadReservada<=Cantidad)
);
GO

IF OBJECT_ID(N'dbo.InventarioMovimiento', N'U') IS NULL
CREATE TABLE dbo.InventarioMovimiento
(
    InventarioMovimientoId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_InventarioMovimiento PRIMARY KEY,
    InventarioArticuloId INT NOT NULL,
    Tipo NVARCHAR(30) NOT NULL,
    SedeOrigenId INT NULL,
    SedeDestinoId INT NULL,
    Cantidad DECIMAL(18,3) NOT NULL,
    Referencia NVARCHAR(120) NULL,
    Observacion NVARCHAR(500) NULL,
    UsuarioId INT NOT NULL,
    Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_InventarioMovimiento_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT CK_InventarioMovimiento_Tipo CHECK (Tipo IN(N'Entrada',N'Salida',N'Transferencia',N'Reserva',N'Liberacion')),
    CONSTRAINT CK_InventarioMovimiento_Cantidad CHECK (Cantidad>0)
);
GO

IF OBJECT_ID(N'dbo.AbastecimientoSolicitud',N'U') IS NULL
CREATE TABLE dbo.AbastecimientoSolicitud
(
    AbastecimientoSolicitudId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AbastecimientoSolicitud PRIMARY KEY,
    GiroSolicitanteId INT NOT NULL,SedeSolicitanteId INT NOT NULL,
    GiroProveedorId INT NOT NULL,SedeProveedorId INT NOT NULL,
    SolicitanteUsuarioId INT NOT NULL,Estado NVARCHAR(30) NOT NULL CONSTRAINT DF_Abastecimiento_Estado DEFAULT(N'Solicitado'),
    FechaNecesaria DATE NOT NULL,Motivo NVARCHAR(500) NOT NULL,Eliminado BIT NOT NULL CONSTRAINT DF_Abastecimiento_Eliminado DEFAULT(0),
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Abastecimiento_Fecha DEFAULT(SYSUTCDATETIME()),FechaModificacion DATETIME2(0) NULL,
    CONSTRAINT CK_Abastecimiento_Giros CHECK(GiroSolicitanteId<>GiroProveedorId),
    CONSTRAINT CK_Abastecimiento_Estado CHECK(Estado IN(N'Solicitado',N'Aprobado',N'Preparacion',N'Despachado',N'Recibido',N'Rechazado',N'Cancelado'))
);
GO
IF OBJECT_ID(N'dbo.AbastecimientoDetalle',N'U') IS NULL
CREATE TABLE dbo.AbastecimientoDetalle
(
    AbastecimientoDetalleId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AbastecimientoDetalle PRIMARY KEY,
    AbastecimientoSolicitudId BIGINT NOT NULL,ArticuloProveedorId INT NOT NULL,ArticuloDestinoId INT NOT NULL,
    Cantidad DECIMAL(18,3) NOT NULL,CONSTRAINT CK_AbastecimientoDetalle_Cantidad CHECK(Cantidad>0)
);
GO
IF OBJECT_ID(N'dbo.AbastecimientoHistorial',N'U') IS NULL
CREATE TABLE dbo.AbastecimientoHistorial
(
    AbastecimientoHistorialId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AbastecimientoHistorial PRIMARY KEY,
    AbastecimientoSolicitudId BIGINT NOT NULL,UsuarioId INT NOT NULL,EstadoAnterior NVARCHAR(30) NULL,EstadoNuevo NVARCHAR(30) NOT NULL,
    Comentario NVARCHAR(1000) NULL,Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_AbastecimientoHistorial_Fecha DEFAULT(SYSUTCDATETIME())
);
GO
IF OBJECT_ID(N'dbo.ExtraccionJornada',N'U') IS NULL
CREATE TABLE dbo.ExtraccionJornada
(
 ExtraccionJornadaId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ExtraccionJornada PRIMARY KEY,SedeId INT NOT NULL,InventarioArticuloId INT NOT NULL,
 FechaOperacion DATE NOT NULL,Turno NVARCHAR(30) NOT NULL,FrenteExtraccion NVARCHAR(120) NOT NULL,CantidadExtraida DECIMAL(18,3) NOT NULL,CantidadRechazada DECIMAL(18,3) NOT NULL CONSTRAINT DF_Extraccion_Rechazada DEFAULT(0),
 CantidadAprovechable AS (CantidadExtraida-CantidadRechazada) PERSISTED,DestinoTipo NVARCHAR(30) NOT NULL,DestinoDescripcion NVARCHAR(200) NULL,
 Estado NVARCHAR(30) NOT NULL CONSTRAINT DF_Extraccion_Estado DEFAULT(N'Registrada'),ResponsableUsuarioId INT NOT NULL,Observacion NVARCHAR(500) NULL,
 Eliminado BIT NOT NULL CONSTRAINT DF_Extraccion_Eliminado DEFAULT(0),FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Extraccion_Fecha DEFAULT(SYSUTCDATETIME()),FechaModificacion DATETIME2(0) NULL,
 CONSTRAINT CK_Extraccion_Cantidades CHECK(CantidadExtraida>0 AND CantidadRechazada>=0 AND CantidadRechazada<CantidadExtraida),
 CONSTRAINT CK_Extraccion_Destino CHECK(DestinoTipo IN(N'Inventario',N'Procesamiento',N'Transporte',N'Tercero')),
 CONSTRAINT CK_Extraccion_Estado CHECK(Estado IN(N'Registrada',N'Confirmada',N'Entregada',N'Cancelada'))
);
GO
IF OBJECT_ID(N'dbo.ExtraccionJornada',N'U') IS NOT NULL AND OBJECT_ID(N'dbo.CK_Extraccion_Cantidades',N'C') IS NOT NULL
BEGIN
 ALTER TABLE dbo.ExtraccionJornada DROP CONSTRAINT CK_Extraccion_Cantidades;
 ALTER TABLE dbo.ExtraccionJornada WITH CHECK ADD CONSTRAINT CK_Extraccion_Cantidades CHECK(CantidadExtraida>0 AND CantidadRechazada>=0 AND CantidadRechazada<CantidadExtraida);
END;
GO
IF OBJECT_ID(N'dbo.ExtraccionHistorial',N'U') IS NULL
CREATE TABLE dbo.ExtraccionHistorial
(
 ExtraccionHistorialId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ExtraccionHistorial PRIMARY KEY,ExtraccionJornadaId BIGINT NOT NULL,UsuarioId INT NOT NULL,
 EstadoAnterior NVARCHAR(30) NULL,EstadoNuevo NVARCHAR(30) NOT NULL,Comentario NVARCHAR(500) NULL,Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_ExtraccionHistorial_Fecha DEFAULT(SYSUTCDATETIME())
);
GO

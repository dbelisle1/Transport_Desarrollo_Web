USE [TransPortDB];
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

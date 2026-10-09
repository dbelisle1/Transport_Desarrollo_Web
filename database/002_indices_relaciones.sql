USE [TransPortDB];
GO

IF OBJECT_ID(N'dbo.FK_UsuarioRol_Usuario', N'F') IS NULL
    ALTER TABLE dbo.UsuarioRol ADD CONSTRAINT FK_UsuarioRol_Usuario FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuario(UsuarioId);
IF OBJECT_ID(N'dbo.FK_UsuarioRol_Rol', N'F') IS NULL
    ALTER TABLE dbo.UsuarioRol ADD CONSTRAINT FK_UsuarioRol_Rol FOREIGN KEY (RolId) REFERENCES dbo.Rol(RolId);
IF OBJECT_ID(N'dbo.FK_SedeGiroNegocio_Sede', N'F') IS NULL
    ALTER TABLE dbo.SedeGiroNegocio ADD CONSTRAINT FK_SedeGiroNegocio_Sede FOREIGN KEY (SedeId) REFERENCES dbo.Sede(SedeId);
IF OBJECT_ID(N'dbo.FK_SedeGiroNegocio_GiroNegocio', N'F') IS NULL
    ALTER TABLE dbo.SedeGiroNegocio ADD CONSTRAINT FK_SedeGiroNegocio_GiroNegocio FOREIGN KEY (GiroNegocioId) REFERENCES dbo.GiroNegocio(GiroNegocioId);
IF OBJECT_ID(N'dbo.FK_UsuarioGiroNegocio_Usuario', N'F') IS NULL
    ALTER TABLE dbo.UsuarioGiroNegocio ADD CONSTRAINT FK_UsuarioGiroNegocio_Usuario FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuario(UsuarioId);
IF OBJECT_ID(N'dbo.FK_UsuarioGiroNegocio_GiroNegocio', N'F') IS NULL
    ALTER TABLE dbo.UsuarioGiroNegocio ADD CONSTRAINT FK_UsuarioGiroNegocio_GiroNegocio FOREIGN KEY (GiroNegocioId) REFERENCES dbo.GiroNegocio(GiroNegocioId);
IF OBJECT_ID(N'dbo.FK_UsuarioSede_Usuario', N'F') IS NULL
    ALTER TABLE dbo.UsuarioSede ADD CONSTRAINT FK_UsuarioSede_Usuario FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuario(UsuarioId);
IF OBJECT_ID(N'dbo.FK_UsuarioSede_Sede', N'F') IS NULL
    ALTER TABLE dbo.UsuarioSede ADD CONSTRAINT FK_UsuarioSede_Sede FOREIGN KEY (SedeId) REFERENCES dbo.Sede(SedeId);
IF OBJECT_ID(N'dbo.FK_ClienteUsuario_Cliente', N'F') IS NULL
    ALTER TABLE dbo.ClienteUsuario ADD CONSTRAINT FK_ClienteUsuario_Cliente FOREIGN KEY (ClienteId) REFERENCES dbo.Cliente(ClienteId);
IF OBJECT_ID(N'dbo.FK_ClienteUsuario_Usuario', N'F') IS NULL
    ALTER TABLE dbo.ClienteUsuario ADD CONSTRAINT FK_ClienteUsuario_Usuario FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuario(UsuarioId);
IF OBJECT_ID(N'dbo.FK_ClienteGiroNegocio_Cliente', N'F') IS NULL
    ALTER TABLE dbo.ClienteGiroNegocio ADD CONSTRAINT FK_ClienteGiroNegocio_Cliente FOREIGN KEY (ClienteId) REFERENCES dbo.Cliente(ClienteId);
IF OBJECT_ID(N'dbo.FK_ClienteGiroNegocio_GiroNegocio', N'F') IS NULL
    ALTER TABLE dbo.ClienteGiroNegocio ADD CONSTRAINT FK_ClienteGiroNegocio_GiroNegocio FOREIGN KEY (GiroNegocioId) REFERENCES dbo.GiroNegocio(GiroNegocioId);
IF OBJECT_ID(N'dbo.FK_Auditoria_Usuario', N'F') IS NULL
    ALTER TABLE dbo.Auditoria ADD CONSTRAINT FK_Auditoria_Usuario FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuario(UsuarioId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Usuario') AND name = N'UX_Usuario_NombreUsuario')
    CREATE UNIQUE INDEX UX_Usuario_NombreUsuario ON dbo.Usuario(NombreUsuario) WHERE Eliminado = 0;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Usuario') AND name = N'UX_Usuario_Correo')
    CREATE UNIQUE INDEX UX_Usuario_Correo ON dbo.Usuario(Correo) WHERE Eliminado = 0;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Rol') AND name = N'UX_Rol_Nombre')
    CREATE UNIQUE INDEX UX_Rol_Nombre ON dbo.Rol(Nombre) WHERE Eliminado = 0;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.GiroNegocio') AND name = N'UX_GiroNegocio_Nombre')
    CREATE UNIQUE INDEX UX_GiroNegocio_Nombre ON dbo.GiroNegocio(Nombre) WHERE Eliminado = 0;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Sede') AND name = N'UX_Sede_Nombre')
    CREATE UNIQUE INDEX UX_Sede_Nombre ON dbo.Sede(Nombre) WHERE Eliminado = 0;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Cliente') AND name = N'UX_Cliente_Nit')
    CREATE UNIQUE INDEX UX_Cliente_Nit ON dbo.Cliente(Nit) WHERE Eliminado = 0 AND Nit IS NOT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.UsuarioRol') AND name = N'UX_UsuarioRol_Activo')
    CREATE UNIQUE INDEX UX_UsuarioRol_Activo ON dbo.UsuarioRol(UsuarioId, RolId) WHERE Eliminado = 0;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.UsuarioGiroNegocio') AND name = N'UX_UsuarioGiroNegocio_Activo')
    CREATE UNIQUE INDEX UX_UsuarioGiroNegocio_Activo ON dbo.UsuarioGiroNegocio(UsuarioId, GiroNegocioId) WHERE Eliminado = 0;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.UsuarioSede') AND name = N'UX_UsuarioSede_Activo')
    CREATE UNIQUE INDEX UX_UsuarioSede_Activo ON dbo.UsuarioSede(UsuarioId, SedeId) WHERE Eliminado = 0;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.SedeGiroNegocio') AND name = N'UX_SedeGiroNegocio_Activo')
    CREATE UNIQUE INDEX UX_SedeGiroNegocio_Activo ON dbo.SedeGiroNegocio(SedeId, GiroNegocioId) WHERE Eliminado = 0;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.ClienteUsuario') AND name = N'UX_ClienteUsuario_Activo')
    CREATE UNIQUE INDEX UX_ClienteUsuario_Activo ON dbo.ClienteUsuario(ClienteId, UsuarioId) WHERE Eliminado = 0;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.ClienteGiroNegocio') AND name = N'UX_ClienteGiroNegocio_Activo')
    CREATE UNIQUE INDEX UX_ClienteGiroNegocio_Activo ON dbo.ClienteGiroNegocio(ClienteId, GiroNegocioId) WHERE Eliminado = 0;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Auditoria') AND name = N'IX_Auditoria_Fecha')
    CREATE INDEX IX_Auditoria_Fecha ON dbo.Auditoria(Fecha DESC) INCLUDE (UsuarioId, Modulo, TipoOperacion, Resultado);
GO

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

IF OBJECT_ID(N'dbo.ProduccionOrden',N'U') IS NULL
CREATE TABLE dbo.ProduccionOrden
(
 ProduccionOrdenId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ProduccionOrden PRIMARY KEY,
 SedeId INT NOT NULL,ArticuloEntradaId INT NOT NULL,ArticuloSalidaId INT NOT NULL,
 FechaPlanificada DATE NOT NULL,CantidadEntrada DECIMAL(18,3) NOT NULL,CantidadSalidaPlanificada DECIMAL(18,3) NOT NULL,
 CantidadSalidaReal DECIMAL(18,3) NULL,CantidadMerma DECIMAL(18,3) NULL,CostoUnitario DECIMAL(18,2) NULL,
 Estado NVARCHAR(30) NOT NULL CONSTRAINT DF_ProduccionOrden_Estado DEFAULT(N'Planificada'),ResponsableUsuarioId INT NOT NULL,Observacion NVARCHAR(500) NULL,
 Eliminado BIT NOT NULL CONSTRAINT DF_ProduccionOrden_Eliminado DEFAULT(0),FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_ProduccionOrden_Fecha DEFAULT(SYSUTCDATETIME()),FechaModificacion DATETIME2(0) NULL,
 CONSTRAINT CK_ProduccionOrden_Cantidades CHECK(CantidadEntrada>0 AND CantidadSalidaPlanificada>0 AND (CantidadSalidaReal IS NULL OR CantidadSalidaReal>0) AND (CantidadMerma IS NULL OR CantidadMerma>=0)),
 CONSTRAINT CK_ProduccionOrden_Costo CHECK(CostoUnitario IS NULL OR CostoUnitario>=0),
 CONSTRAINT CK_ProduccionOrden_Estado CHECK(Estado IN(N'Planificada',N'EnProceso',N'Completada',N'Cancelada')),
 CONSTRAINT CK_ProduccionOrden_Articulos CHECK(ArticuloEntradaId<>ArticuloSalidaId)
);
GO
IF OBJECT_ID(N'dbo.ProduccionEtapa',N'U') IS NULL
CREATE TABLE dbo.ProduccionEtapa
(
 ProduccionEtapaId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ProduccionEtapa PRIMARY KEY,ProduccionOrdenId BIGINT NOT NULL,
 Secuencia INT NOT NULL,Nombre NVARCHAR(100) NOT NULL,Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_ProduccionEtapa_Estado DEFAULT(N'Pendiente'),
 FechaInicio DATETIME2(0) NULL,FechaFin DATETIME2(0) NULL,Observacion NVARCHAR(500) NULL,
 CONSTRAINT CK_ProduccionEtapa_Secuencia CHECK(Secuencia>0),CONSTRAINT CK_ProduccionEtapa_Estado CHECK(Estado IN(N'Pendiente',N'EnProceso',N'Completada'))
);
GO
IF OBJECT_ID(N'dbo.ProduccionHistorial',N'U') IS NULL
CREATE TABLE dbo.ProduccionHistorial
(
 ProduccionHistorialId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ProduccionHistorial PRIMARY KEY,ProduccionOrdenId BIGINT NOT NULL,UsuarioId INT NOT NULL,
 EstadoAnterior NVARCHAR(30) NULL,EstadoNuevo NVARCHAR(30) NOT NULL,Comentario NVARCHAR(500) NULL,Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_ProduccionHistorial_Fecha DEFAULT(SYSUTCDATETIME())
);
GO

IF OBJECT_ID(N'dbo.MaquinariaEquipo',N'U') IS NULL
CREATE TABLE dbo.MaquinariaEquipo
(
 MaquinariaEquipoId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_MaquinariaEquipo PRIMARY KEY,SedeId INT NOT NULL,Codigo NVARCHAR(50) NOT NULL,Tipo NVARCHAR(80) NOT NULL,Marca NVARCHAR(80) NOT NULL,Modelo NVARCHAR(80) NOT NULL,Anio SMALLINT NULL,
 Estado NVARCHAR(30) NOT NULL CONSTRAINT DF_MaquinariaEquipo_Estado DEFAULT(N'Disponible'),PrecioVenta DECIMAL(18,2) NULL,TarifaDiaria DECIMAL(18,2) NULL,HorasUso DECIMAL(18,2) NOT NULL CONSTRAINT DF_MaquinariaEquipo_Horas DEFAULT(0),Observacion NVARCHAR(500) NULL,
 Eliminado BIT NOT NULL CONSTRAINT DF_MaquinariaEquipo_Eliminado DEFAULT(0),FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_MaquinariaEquipo_Fecha DEFAULT(SYSUTCDATETIME()),FechaModificacion DATETIME2(0) NULL,
 CONSTRAINT CK_MaquinariaEquipo_Estado CHECK(Estado IN(N'Disponible',N'Reservada',N'Alquilada',N'Mantenimiento',N'Vendida',N'Baja')),CONSTRAINT CK_MaquinariaEquipo_Valores CHECK((PrecioVenta IS NULL OR PrecioVenta>=0) AND (TarifaDiaria IS NULL OR TarifaDiaria>=0) AND HorasUso>=0)
);
GO
IF OBJECT_ID(N'dbo.MaquinariaContrato',N'U') IS NULL
CREATE TABLE dbo.MaquinariaContrato
(
 MaquinariaContratoId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_MaquinariaContrato PRIMARY KEY,MaquinariaEquipoId INT NOT NULL,ClienteId INT NOT NULL,Tipo NVARCHAR(20) NOT NULL,FechaInicio DATE NOT NULL,FechaFin DATE NULL,MontoTotal DECIMAL(18,2) NOT NULL,Deposito DECIMAL(18,2) NOT NULL CONSTRAINT DF_MaquinariaContrato_Deposito DEFAULT(0),Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_MaquinariaContrato_Estado DEFAULT(N'Reservado'),HorasEntrega DECIMAL(18,2) NULL,HorasDevolucion DECIMAL(18,2) NULL,ResponsableUsuarioId INT NOT NULL,Observacion NVARCHAR(500) NULL,Eliminado BIT NOT NULL CONSTRAINT DF_MaquinariaContrato_Eliminado DEFAULT(0),FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_MaquinariaContrato_Fecha DEFAULT(SYSUTCDATETIME()),FechaModificacion DATETIME2(0) NULL,
 CONSTRAINT CK_MaquinariaContrato_Tipo CHECK(Tipo IN(N'Venta',N'Alquiler')),CONSTRAINT CK_MaquinariaContrato_Estado CHECK(Estado IN(N'Reservado',N'Activo',N'Finalizado',N'Cancelado')),CONSTRAINT CK_MaquinariaContrato_Valores CHECK(MontoTotal>=0 AND Deposito>=0 AND (HorasDevolucion IS NULL OR HorasEntrega IS NULL OR HorasDevolucion>=HorasEntrega))
);
GO
IF OBJECT_ID(N'dbo.MaquinariaMantenimiento',N'U') IS NULL
CREATE TABLE dbo.MaquinariaMantenimiento
(
 MaquinariaMantenimientoId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_MaquinariaMantenimiento PRIMARY KEY,MaquinariaEquipoId INT NOT NULL,Tipo NVARCHAR(80) NOT NULL,FechaProgramada DATE NOT NULL,FechaCompletada DATE NULL,Costo DECIMAL(18,2) NOT NULL CONSTRAINT DF_MaquinariaMantenimiento_Costo DEFAULT(0),Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_MaquinariaMantenimiento_Estado DEFAULT(N'Programado'),ResponsableUsuarioId INT NOT NULL,Observacion NVARCHAR(500) NULL,FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_MaquinariaMantenimiento_Fecha DEFAULT(SYSUTCDATETIME()),CONSTRAINT CK_MaquinariaMantenimiento_Estado CHECK(Estado IN(N'Programado',N'EnProceso',N'Completado',N'Cancelado')),CONSTRAINT CK_MaquinariaMantenimiento_Costo CHECK(Costo>=0)
);
GO

IF OBJECT_ID(N'dbo.TransporteVehiculo',N'U') IS NULL
CREATE TABLE dbo.TransporteVehiculo(TransporteVehiculoId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TransporteVehiculo PRIMARY KEY,SedeId INT NOT NULL,Placa NVARCHAR(20) NOT NULL,Tipo NVARCHAR(60) NOT NULL,Marca NVARCHAR(60) NOT NULL,Modelo NVARCHAR(60) NOT NULL,Capacidad DECIMAL(18,3) NOT NULL,UnidadCapacidad NVARCHAR(20) NOT NULL,EsInternacional BIT NOT NULL CONSTRAINT DF_TransporteVehiculo_Internacional DEFAULT(0),Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_TransporteVehiculo_Estado DEFAULT(N'Disponible'),Eliminado BIT NOT NULL CONSTRAINT DF_TransporteVehiculo_Eliminado DEFAULT(0),FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_TransporteVehiculo_Fecha DEFAULT(SYSUTCDATETIME()),CONSTRAINT CK_TransporteVehiculo_Capacidad CHECK(Capacidad>0),CONSTRAINT CK_TransporteVehiculo_Estado CHECK(Estado IN(N'Disponible',N'Asignado',N'Mantenimiento',N'Baja')));
GO
IF OBJECT_ID(N'dbo.TransporteConductor',N'U') IS NULL
CREATE TABLE dbo.TransporteConductor(TransporteConductorId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TransporteConductor PRIMARY KEY,Nombre NVARCHAR(160) NOT NULL,Licencia NVARCHAR(50) NOT NULL,Categoria NVARCHAR(20) NOT NULL,FechaVencimiento DATE NOT NULL,Telefono NVARCHAR(30) NULL,Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_TransporteConductor_Estado DEFAULT(N'Disponible'),Eliminado BIT NOT NULL CONSTRAINT DF_TransporteConductor_Eliminado DEFAULT(0),FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_TransporteConductor_Fecha DEFAULT(SYSUTCDATETIME()),CONSTRAINT CK_TransporteConductor_Estado CHECK(Estado IN(N'Disponible',N'Asignado',N'Inactivo')));
GO
IF OBJECT_ID(N'dbo.TransporteViaje',N'U') IS NULL
CREATE TABLE dbo.TransporteViaje(TransporteViajeId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TransporteViaje PRIMARY KEY,SedeId INT NOT NULL,TransporteVehiculoId INT NOT NULL,TransporteConductorId INT NOT NULL,ClienteId INT NULL,Tipo NVARCHAR(30) NOT NULL,Origen NVARCHAR(200) NOT NULL,Destino NVARCHAR(200) NOT NULL,DescripcionCarga NVARCHAR(300) NOT NULL,PesoCarga DECIMAL(18,3) NOT NULL,FechaSalidaPlanificada DATETIME2(0) NOT NULL,FechaSalidaReal DATETIME2(0) NULL,FechaEntrega DATETIME2(0) NULL,Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_TransporteViaje_Estado DEFAULT(N'Programado'),ResponsableUsuarioId INT NOT NULL,Observacion NVARCHAR(500) NULL,Eliminado BIT NOT NULL CONSTRAINT DF_TransporteViaje_Eliminado DEFAULT(0),FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_TransporteViaje_Fecha DEFAULT(SYSUTCDATETIME()),FechaModificacion DATETIME2(0) NULL,CONSTRAINT CK_TransporteViaje_Tipo CHECK(Tipo IN(N'MateriaPrima',N'Nacional',N'Internacional')),CONSTRAINT CK_TransporteViaje_Estado CHECK(Estado IN(N'Programado',N'EnRuta',N'Entregado',N'Cancelado')),CONSTRAINT CK_TransporteViaje_Peso CHECK(PesoCarga>0));
GO
IF OBJECT_ID(N'dbo.TransporteIncidencia',N'U') IS NULL
CREATE TABLE dbo.TransporteIncidencia(TransporteIncidenciaId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TransporteIncidencia PRIMARY KEY,TransporteViajeId BIGINT NOT NULL,Tipo NVARCHAR(80) NOT NULL,Severidad NVARCHAR(20) NOT NULL,Descripcion NVARCHAR(500) NOT NULL,Resuelta BIT NOT NULL CONSTRAINT DF_TransporteIncidencia_Resuelta DEFAULT(0),Resolucion NVARCHAR(500) NULL,UsuarioId INT NOT NULL,Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_TransporteIncidencia_Fecha DEFAULT(SYSUTCDATETIME()),FechaResolucion DATETIME2(0) NULL,CONSTRAINT CK_TransporteIncidencia_Severidad CHECK(Severidad IN(N'Baja',N'Media',N'Alta',N'Critica')));
GO

IF OBJECT_ID(N'dbo.GpsDispositivo',N'U') IS NULL
CREATE TABLE dbo.GpsDispositivo
(
 GpsDispositivoId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_GpsDispositivo PRIMARY KEY,
 IdentificadorExterno NVARCHAR(100) NOT NULL,NombreActivo NVARCHAR(160) NOT NULL,
 TransporteVehiculoId INT NULL,MaquinariaEquipoId INT NULL,
 Proveedor NVARCHAR(80) NOT NULL CONSTRAINT DF_GpsDispositivo_Proveedor DEFAULT(N'GPS-Inversiones'),
 VelocidadMaxima DECIMAL(8,2) NOT NULL CONSTRAINT DF_GpsDispositivo_Velocidad DEFAULT(80),
 EsActivo BIT NOT NULL CONSTRAINT DF_GpsDispositivo_Activo DEFAULT(1),UltimaSincronizacion DATETIME2(0) NULL,
 Eliminado BIT NOT NULL CONSTRAINT DF_GpsDispositivo_Eliminado DEFAULT(0),FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_GpsDispositivo_Fecha DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT CK_GpsDispositivo_Entidad CHECK(NOT(TransporteVehiculoId IS NOT NULL AND MaquinariaEquipoId IS NOT NULL)),
 CONSTRAINT CK_GpsDispositivo_Velocidad CHECK(VelocidadMaxima>0)
);
GO
IF OBJECT_ID(N'dbo.GpsPosicion',N'U') IS NULL
CREATE TABLE dbo.GpsPosicion
(
 GpsPosicionId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_GpsPosicion PRIMARY KEY,GpsDispositivoId INT NOT NULL,
 FechaEvento DATETIME2(0) NOT NULL,Latitud DECIMAL(9,6) NOT NULL,Longitud DECIMAL(9,6) NOT NULL,Velocidad DECIMAL(8,2) NOT NULL,
 HorasUso DECIMAL(18,2) NULL,Kilometraje DECIMAL(18,2) NULL,Evento NVARCHAR(80) NULL,OrigenDato NVARCHAR(80) NOT NULL,DatosFuente NVARCHAR(2000) NULL,
 Recibido DATETIME2(0) NOT NULL CONSTRAINT DF_GpsPosicion_Recibido DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT CK_GpsPosicion_Coordenadas CHECK(Latitud BETWEEN -90 AND 90 AND Longitud BETWEEN -180 AND 180),
 CONSTRAINT CK_GpsPosicion_Valores CHECK(Velocidad>=0 AND (HorasUso IS NULL OR HorasUso>=0) AND (Kilometraje IS NULL OR Kilometraje>=0))
);
GO
IF OBJECT_ID(N'dbo.GpsAlerta',N'U') IS NULL
CREATE TABLE dbo.GpsAlerta
(
 GpsAlertaId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_GpsAlerta PRIMARY KEY,GpsDispositivoId INT NOT NULL,GpsPosicionId BIGINT NULL,
 Tipo NVARCHAR(50) NOT NULL,Severidad NVARCHAR(20) NOT NULL,Mensaje NVARCHAR(300) NOT NULL,
 Atendida BIT NOT NULL CONSTRAINT DF_GpsAlerta_Atendida DEFAULT(0),AtendidaPorUsuarioId INT NULL,
 Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_GpsAlerta_Fecha DEFAULT(SYSUTCDATETIME()),FechaAtencion DATETIME2(0) NULL,
 CONSTRAINT CK_GpsAlerta_Severidad CHECK(Severidad IN(N'Baja',N'Media',N'Alta',N'Critica'))
);
GO

IF OBJECT_ID(N'dbo.ConstruccionProyecto',N'U') IS NULL
CREATE TABLE dbo.ConstruccionProyecto(ConstruccionProyectoId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ConstruccionProyecto PRIMARY KEY,SedeId INT NOT NULL,ClienteId INT NULL,Nombre NVARCHAR(180) NOT NULL,TipoObra NVARCHAR(30) NOT NULL,Ubicacion NVARCHAR(250) NOT NULL,FechaInicioPlanificada DATE NOT NULL,FechaFinPlanificada DATE NOT NULL,Presupuesto DECIMAL(18,2) NOT NULL,Estado NVARCHAR(30) NOT NULL CONSTRAINT DF_ConstruccionProyecto_Estado DEFAULT(N'Planificado'),ResponsableUsuarioId INT NOT NULL,Descripcion NVARCHAR(1000) NULL,Eliminado BIT NOT NULL CONSTRAINT DF_ConstruccionProyecto_Eliminado DEFAULT(0),FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_ConstruccionProyecto_Fecha DEFAULT(SYSUTCDATETIME()),FechaModificacion DATETIME2(0) NULL,CONSTRAINT CK_ConstruccionProyecto_Tipo CHECK(TipoObra IN(N'Puente',N'Carretera',N'Edificio',N'Otro')),CONSTRAINT CK_ConstruccionProyecto_Estado CHECK(Estado IN(N'Planificado',N'EnEjecucion',N'Suspendido',N'Completado',N'Cancelado')),CONSTRAINT CK_ConstruccionProyecto_Fechas CHECK(FechaFinPlanificada>=FechaInicioPlanificada),CONSTRAINT CK_ConstruccionProyecto_Presupuesto CHECK(Presupuesto>=0));
GO
IF OBJECT_ID(N'dbo.ConstruccionActividad',N'U') IS NULL
CREATE TABLE dbo.ConstruccionActividad(ConstruccionActividadId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ConstruccionActividad PRIMARY KEY,ConstruccionProyectoId BIGINT NOT NULL,Nombre NVARCHAR(180) NOT NULL,ResponsableUsuarioId INT NOT NULL,FechaInicio DATE NOT NULL,FechaFin DATE NOT NULL,Presupuesto DECIMAL(18,2) NOT NULL,PorcentajeAvance DECIMAL(5,2) NOT NULL CONSTRAINT DF_ConstruccionActividad_Avance DEFAULT(0),Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_ConstruccionActividad_Estado DEFAULT(N'Pendiente'),Observacion NVARCHAR(500) NULL,CONSTRAINT CK_ConstruccionActividad_Fechas CHECK(FechaFin>=FechaInicio),CONSTRAINT CK_ConstruccionActividad_Avance CHECK(PorcentajeAvance BETWEEN 0 AND 100),CONSTRAINT CK_ConstruccionActividad_Estado CHECK(Estado IN(N'Pendiente',N'EnProceso',N'Completada',N'Bloqueada')),CONSTRAINT CK_ConstruccionActividad_Presupuesto CHECK(Presupuesto>=0));
GO
IF OBJECT_ID(N'dbo.ConstruccionRecurso',N'U') IS NULL
CREATE TABLE dbo.ConstruccionRecurso(ConstruccionRecursoId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ConstruccionRecurso PRIMARY KEY,ConstruccionProyectoId BIGINT NOT NULL,ConstruccionActividadId BIGINT NULL,Tipo NVARCHAR(20) NOT NULL,Descripcion NVARCHAR(200) NOT NULL,Cantidad DECIMAL(18,3) NOT NULL,Unidad NVARCHAR(30) NOT NULL,CostoUnitario DECIMAL(18,2) NOT NULL,InventarioArticuloId INT NULL,MaquinariaEquipoId INT NULL,UsuarioId INT NOT NULL,Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_ConstruccionRecurso_Fecha DEFAULT(SYSUTCDATETIME()),CONSTRAINT CK_ConstruccionRecurso_Tipo CHECK(Tipo IN(N'Material',N'Maquinaria',N'Personal',N'Otro')),CONSTRAINT CK_ConstruccionRecurso_Valores CHECK(Cantidad>0 AND CostoUnitario>=0));
GO
IF OBJECT_ID(N'dbo.ConstruccionAvance',N'U') IS NULL
CREATE TABLE dbo.ConstruccionAvance(ConstruccionAvanceId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ConstruccionAvance PRIMARY KEY,ConstruccionActividadId BIGINT NOT NULL,PorcentajeAnterior DECIMAL(5,2) NOT NULL,PorcentajeNuevo DECIMAL(5,2) NOT NULL,Comentario NVARCHAR(500) NOT NULL,EvidenciaUrl NVARCHAR(500) NULL,UsuarioId INT NOT NULL,Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_ConstruccionAvance_Fecha DEFAULT(SYSUTCDATETIME()),CONSTRAINT CK_ConstruccionAvance_Porcentaje CHECK(PorcentajeAnterior BETWEEN 0 AND 100 AND PorcentajeNuevo BETWEEN 0 AND 100));
GO

IF OBJECT_ID(N'dbo.FinanzaPresupuesto',N'U') IS NULL
CREATE TABLE dbo.FinanzaPresupuesto(FinanzaPresupuestoId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_FinanzaPresupuesto PRIMARY KEY,GiroNegocioId INT NOT NULL,SedeId INT NOT NULL,Anio SMALLINT NOT NULL,Mes TINYINT NOT NULL,Nombre NVARCHAR(180) NOT NULL,Monto DECIMAL(18,2) NOT NULL,Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_FinanzaPresupuesto_Estado DEFAULT(N'Abierto'),CreadoPorUsuarioId INT NOT NULL,Observacion NVARCHAR(500) NULL,Eliminado BIT NOT NULL CONSTRAINT DF_FinanzaPresupuesto_Eliminado DEFAULT(0),FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_FinanzaPresupuesto_Fecha DEFAULT(SYSUTCDATETIME()),FechaModificacion DATETIME2(0) NULL,CONSTRAINT CK_FinanzaPresupuesto_Periodo CHECK(Anio BETWEEN 2000 AND 2100 AND Mes BETWEEN 1 AND 12),CONSTRAINT CK_FinanzaPresupuesto_Monto CHECK(Monto>0),CONSTRAINT CK_FinanzaPresupuesto_Estado CHECK(Estado IN(N'Abierto',N'Cerrado',N'Cancelado')));
GO
IF OBJECT_ID(N'dbo.FinanzaGasto',N'U') IS NULL
CREATE TABLE dbo.FinanzaGasto(FinanzaGastoId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_FinanzaGasto PRIMARY KEY,FinanzaPresupuestoId BIGINT NOT NULL,Fecha DATE NOT NULL,Categoria NVARCHAR(30) NOT NULL,Concepto NVARCHAR(250) NOT NULL,Monto DECIMAL(18,2) NOT NULL,OrigenModulo NVARCHAR(30) NOT NULL,OrigenRegistroId BIGINT NULL,Referencia NVARCHAR(120) NULL,UsuarioId INT NOT NULL,FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_FinanzaGasto_Fecha DEFAULT(SYSUTCDATETIME()),CONSTRAINT CK_FinanzaGasto_Categoria CHECK(Categoria IN(N'Material',N'Personal',N'Transporte',N'Servicios',N'Maquinaria',N'Otro')),CONSTRAINT CK_FinanzaGasto_Monto CHECK(Monto>0),CONSTRAINT CK_FinanzaGasto_Origen CHECK(OrigenModulo IN(N'Manual',N'Pedido',N'Produccion',N'Transporte',N'Construccion') AND ((OrigenModulo=N'Manual' AND OrigenRegistroId IS NULL) OR (OrigenModulo<>N'Manual' AND OrigenRegistroId IS NOT NULL))));
GO

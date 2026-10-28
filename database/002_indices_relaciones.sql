USE [TransPortDB];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
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
IF OBJECT_ID(N'dbo.FK_Pedido_Cliente', N'F') IS NULL
    ALTER TABLE dbo.Pedido ADD CONSTRAINT FK_Pedido_Cliente FOREIGN KEY (ClienteId) REFERENCES dbo.Cliente(ClienteId);
IF OBJECT_ID(N'dbo.FK_Pedido_GiroNegocio', N'F') IS NULL
    ALTER TABLE dbo.Pedido ADD CONSTRAINT FK_Pedido_GiroNegocio FOREIGN KEY (GiroNegocioId) REFERENCES dbo.GiroNegocio(GiroNegocioId);
IF OBJECT_ID(N'dbo.FK_Pedido_SolicitanteUsuario', N'F') IS NULL
    ALTER TABLE dbo.Pedido ADD CONSTRAINT FK_Pedido_SolicitanteUsuario FOREIGN KEY (SolicitanteUsuarioId) REFERENCES dbo.Usuario(UsuarioId);
IF OBJECT_ID(N'dbo.FK_Pedido_VendedorUsuario', N'F') IS NULL
    ALTER TABLE dbo.Pedido ADD CONSTRAINT FK_Pedido_VendedorUsuario FOREIGN KEY (VendedorUsuarioId) REFERENCES dbo.Usuario(UsuarioId);
IF OBJECT_ID(N'dbo.FK_PedidoHistorial_Pedido', N'F') IS NULL
    ALTER TABLE dbo.PedidoHistorial ADD CONSTRAINT FK_PedidoHistorial_Pedido FOREIGN KEY (PedidoId) REFERENCES dbo.Pedido(PedidoId);
IF OBJECT_ID(N'dbo.FK_PedidoHistorial_Usuario', N'F') IS NULL
    ALTER TABLE dbo.PedidoHistorial ADD CONSTRAINT FK_PedidoHistorial_Usuario FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuario(UsuarioId);
IF OBJECT_ID(N'dbo.FK_PedidoDocumento_Pedido', N'F') IS NULL
    ALTER TABLE dbo.PedidoDocumento ADD CONSTRAINT FK_PedidoDocumento_Pedido FOREIGN KEY (PedidoId) REFERENCES dbo.Pedido(PedidoId);
IF OBJECT_ID(N'dbo.FK_PedidoDocumento_Usuario', N'F') IS NULL
    ALTER TABLE dbo.PedidoDocumento ADD CONSTRAINT FK_PedidoDocumento_Usuario FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuario(UsuarioId);
IF OBJECT_ID(N'dbo.FK_InventarioArticulo_Giro', N'F') IS NULL
    ALTER TABLE dbo.InventarioArticulo ADD CONSTRAINT FK_InventarioArticulo_Giro FOREIGN KEY (GiroNegocioId) REFERENCES dbo.GiroNegocio(GiroNegocioId);
IF OBJECT_ID(N'dbo.FK_InventarioExistencia_Articulo', N'F') IS NULL
    ALTER TABLE dbo.InventarioExistencia ADD CONSTRAINT FK_InventarioExistencia_Articulo FOREIGN KEY (InventarioArticuloId) REFERENCES dbo.InventarioArticulo(InventarioArticuloId);
IF OBJECT_ID(N'dbo.FK_InventarioExistencia_Sede', N'F') IS NULL
    ALTER TABLE dbo.InventarioExistencia ADD CONSTRAINT FK_InventarioExistencia_Sede FOREIGN KEY (SedeId) REFERENCES dbo.Sede(SedeId);
IF OBJECT_ID(N'dbo.FK_InventarioMovimiento_Articulo', N'F') IS NULL
    ALTER TABLE dbo.InventarioMovimiento ADD CONSTRAINT FK_InventarioMovimiento_Articulo FOREIGN KEY (InventarioArticuloId) REFERENCES dbo.InventarioArticulo(InventarioArticuloId);
IF OBJECT_ID(N'dbo.FK_InventarioMovimiento_SedeOrigen', N'F') IS NULL
    ALTER TABLE dbo.InventarioMovimiento ADD CONSTRAINT FK_InventarioMovimiento_SedeOrigen FOREIGN KEY (SedeOrigenId) REFERENCES dbo.Sede(SedeId);
IF OBJECT_ID(N'dbo.FK_InventarioMovimiento_SedeDestino', N'F') IS NULL
    ALTER TABLE dbo.InventarioMovimiento ADD CONSTRAINT FK_InventarioMovimiento_SedeDestino FOREIGN KEY (SedeDestinoId) REFERENCES dbo.Sede(SedeId);
IF OBJECT_ID(N'dbo.FK_InventarioMovimiento_Usuario', N'F') IS NULL
    ALTER TABLE dbo.InventarioMovimiento ADD CONSTRAINT FK_InventarioMovimiento_Usuario FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuario(UsuarioId);
IF OBJECT_ID(N'dbo.FK_Abastecimiento_GiroSolicitante',N'F') IS NULL ALTER TABLE dbo.AbastecimientoSolicitud ADD CONSTRAINT FK_Abastecimiento_GiroSolicitante FOREIGN KEY(GiroSolicitanteId) REFERENCES dbo.GiroNegocio(GiroNegocioId);
IF OBJECT_ID(N'dbo.FK_Abastecimiento_GiroProveedor',N'F') IS NULL ALTER TABLE dbo.AbastecimientoSolicitud ADD CONSTRAINT FK_Abastecimiento_GiroProveedor FOREIGN KEY(GiroProveedorId) REFERENCES dbo.GiroNegocio(GiroNegocioId);
IF OBJECT_ID(N'dbo.FK_Abastecimiento_SedeSolicitante',N'F') IS NULL ALTER TABLE dbo.AbastecimientoSolicitud ADD CONSTRAINT FK_Abastecimiento_SedeSolicitante FOREIGN KEY(SedeSolicitanteId) REFERENCES dbo.Sede(SedeId);
IF OBJECT_ID(N'dbo.FK_Abastecimiento_SedeProveedor',N'F') IS NULL ALTER TABLE dbo.AbastecimientoSolicitud ADD CONSTRAINT FK_Abastecimiento_SedeProveedor FOREIGN KEY(SedeProveedorId) REFERENCES dbo.Sede(SedeId);
IF OBJECT_ID(N'dbo.FK_Abastecimiento_Solicitante',N'F') IS NULL ALTER TABLE dbo.AbastecimientoSolicitud ADD CONSTRAINT FK_Abastecimiento_Solicitante FOREIGN KEY(SolicitanteUsuarioId) REFERENCES dbo.Usuario(UsuarioId);
IF OBJECT_ID(N'dbo.FK_AbastecimientoDetalle_Solicitud',N'F') IS NULL ALTER TABLE dbo.AbastecimientoDetalle ADD CONSTRAINT FK_AbastecimientoDetalle_Solicitud FOREIGN KEY(AbastecimientoSolicitudId) REFERENCES dbo.AbastecimientoSolicitud(AbastecimientoSolicitudId);
IF OBJECT_ID(N'dbo.FK_AbastecimientoDetalle_Proveedor',N'F') IS NULL ALTER TABLE dbo.AbastecimientoDetalle ADD CONSTRAINT FK_AbastecimientoDetalle_Proveedor FOREIGN KEY(ArticuloProveedorId) REFERENCES dbo.InventarioArticulo(InventarioArticuloId);
IF OBJECT_ID(N'dbo.FK_AbastecimientoDetalle_Destino',N'F') IS NULL ALTER TABLE dbo.AbastecimientoDetalle ADD CONSTRAINT FK_AbastecimientoDetalle_Destino FOREIGN KEY(ArticuloDestinoId) REFERENCES dbo.InventarioArticulo(InventarioArticuloId);
IF OBJECT_ID(N'dbo.FK_AbastecimientoHistorial_Solicitud',N'F') IS NULL ALTER TABLE dbo.AbastecimientoHistorial ADD CONSTRAINT FK_AbastecimientoHistorial_Solicitud FOREIGN KEY(AbastecimientoSolicitudId) REFERENCES dbo.AbastecimientoSolicitud(AbastecimientoSolicitudId);
IF OBJECT_ID(N'dbo.FK_AbastecimientoHistorial_Usuario',N'F') IS NULL ALTER TABLE dbo.AbastecimientoHistorial ADD CONSTRAINT FK_AbastecimientoHistorial_Usuario FOREIGN KEY(UsuarioId) REFERENCES dbo.Usuario(UsuarioId);
IF OBJECT_ID(N'dbo.FK_ExtraccionJornada_Sede',N'F') IS NULL ALTER TABLE dbo.ExtraccionJornada ADD CONSTRAINT FK_ExtraccionJornada_Sede FOREIGN KEY(SedeId) REFERENCES dbo.Sede(SedeId);
IF OBJECT_ID(N'dbo.FK_ExtraccionJornada_Articulo',N'F') IS NULL ALTER TABLE dbo.ExtraccionJornada ADD CONSTRAINT FK_ExtraccionJornada_Articulo FOREIGN KEY(InventarioArticuloId) REFERENCES dbo.InventarioArticulo(InventarioArticuloId);
IF OBJECT_ID(N'dbo.FK_ExtraccionJornada_Responsable',N'F') IS NULL ALTER TABLE dbo.ExtraccionJornada ADD CONSTRAINT FK_ExtraccionJornada_Responsable FOREIGN KEY(ResponsableUsuarioId) REFERENCES dbo.Usuario(UsuarioId);
IF OBJECT_ID(N'dbo.FK_ExtraccionHistorial_Jornada',N'F') IS NULL ALTER TABLE dbo.ExtraccionHistorial ADD CONSTRAINT FK_ExtraccionHistorial_Jornada FOREIGN KEY(ExtraccionJornadaId) REFERENCES dbo.ExtraccionJornada(ExtraccionJornadaId);
IF OBJECT_ID(N'dbo.FK_ExtraccionHistorial_Usuario',N'F') IS NULL ALTER TABLE dbo.ExtraccionHistorial ADD CONSTRAINT FK_ExtraccionHistorial_Usuario FOREIGN KEY(UsuarioId) REFERENCES dbo.Usuario(UsuarioId);
IF OBJECT_ID(N'dbo.FK_ProduccionOrden_Sede',N'F') IS NULL ALTER TABLE dbo.ProduccionOrden ADD CONSTRAINT FK_ProduccionOrden_Sede FOREIGN KEY(SedeId) REFERENCES dbo.Sede(SedeId);
IF OBJECT_ID(N'dbo.FK_ProduccionOrden_Entrada',N'F') IS NULL ALTER TABLE dbo.ProduccionOrden ADD CONSTRAINT FK_ProduccionOrden_Entrada FOREIGN KEY(ArticuloEntradaId) REFERENCES dbo.InventarioArticulo(InventarioArticuloId);
IF OBJECT_ID(N'dbo.FK_ProduccionOrden_Salida',N'F') IS NULL ALTER TABLE dbo.ProduccionOrden ADD CONSTRAINT FK_ProduccionOrden_Salida FOREIGN KEY(ArticuloSalidaId) REFERENCES dbo.InventarioArticulo(InventarioArticuloId);
IF OBJECT_ID(N'dbo.FK_ProduccionOrden_Responsable',N'F') IS NULL ALTER TABLE dbo.ProduccionOrden ADD CONSTRAINT FK_ProduccionOrden_Responsable FOREIGN KEY(ResponsableUsuarioId) REFERENCES dbo.Usuario(UsuarioId);
IF OBJECT_ID(N'dbo.FK_ProduccionEtapa_Orden',N'F') IS NULL ALTER TABLE dbo.ProduccionEtapa ADD CONSTRAINT FK_ProduccionEtapa_Orden FOREIGN KEY(ProduccionOrdenId) REFERENCES dbo.ProduccionOrden(ProduccionOrdenId);
IF OBJECT_ID(N'dbo.FK_ProduccionHistorial_Orden',N'F') IS NULL ALTER TABLE dbo.ProduccionHistorial ADD CONSTRAINT FK_ProduccionHistorial_Orden FOREIGN KEY(ProduccionOrdenId) REFERENCES dbo.ProduccionOrden(ProduccionOrdenId);
IF OBJECT_ID(N'dbo.FK_ProduccionHistorial_Usuario',N'F') IS NULL ALTER TABLE dbo.ProduccionHistorial ADD CONSTRAINT FK_ProduccionHistorial_Usuario FOREIGN KEY(UsuarioId) REFERENCES dbo.Usuario(UsuarioId);
IF OBJECT_ID(N'dbo.FK_MaquinariaEquipo_Sede',N'F') IS NULL ALTER TABLE dbo.MaquinariaEquipo ADD CONSTRAINT FK_MaquinariaEquipo_Sede FOREIGN KEY(SedeId) REFERENCES dbo.Sede(SedeId);
IF OBJECT_ID(N'dbo.FK_MaquinariaContrato_Equipo',N'F') IS NULL ALTER TABLE dbo.MaquinariaContrato ADD CONSTRAINT FK_MaquinariaContrato_Equipo FOREIGN KEY(MaquinariaEquipoId) REFERENCES dbo.MaquinariaEquipo(MaquinariaEquipoId);
IF OBJECT_ID(N'dbo.FK_MaquinariaContrato_Cliente',N'F') IS NULL ALTER TABLE dbo.MaquinariaContrato ADD CONSTRAINT FK_MaquinariaContrato_Cliente FOREIGN KEY(ClienteId) REFERENCES dbo.Cliente(ClienteId);
IF OBJECT_ID(N'dbo.FK_MaquinariaContrato_Responsable',N'F') IS NULL ALTER TABLE dbo.MaquinariaContrato ADD CONSTRAINT FK_MaquinariaContrato_Responsable FOREIGN KEY(ResponsableUsuarioId) REFERENCES dbo.Usuario(UsuarioId);
IF OBJECT_ID(N'dbo.FK_MaquinariaMantenimiento_Equipo',N'F') IS NULL ALTER TABLE dbo.MaquinariaMantenimiento ADD CONSTRAINT FK_MaquinariaMantenimiento_Equipo FOREIGN KEY(MaquinariaEquipoId) REFERENCES dbo.MaquinariaEquipo(MaquinariaEquipoId);
IF OBJECT_ID(N'dbo.FK_MaquinariaMantenimiento_Responsable',N'F') IS NULL ALTER TABLE dbo.MaquinariaMantenimiento ADD CONSTRAINT FK_MaquinariaMantenimiento_Responsable FOREIGN KEY(ResponsableUsuarioId) REFERENCES dbo.Usuario(UsuarioId);
IF OBJECT_ID(N'dbo.FK_TransporteVehiculo_Sede',N'F') IS NULL ALTER TABLE dbo.TransporteVehiculo ADD CONSTRAINT FK_TransporteVehiculo_Sede FOREIGN KEY(SedeId) REFERENCES dbo.Sede(SedeId);
IF OBJECT_ID(N'dbo.FK_TransporteViaje_Sede',N'F') IS NULL ALTER TABLE dbo.TransporteViaje ADD CONSTRAINT FK_TransporteViaje_Sede FOREIGN KEY(SedeId) REFERENCES dbo.Sede(SedeId);
IF OBJECT_ID(N'dbo.FK_TransporteViaje_Vehiculo',N'F') IS NULL ALTER TABLE dbo.TransporteViaje ADD CONSTRAINT FK_TransporteViaje_Vehiculo FOREIGN KEY(TransporteVehiculoId) REFERENCES dbo.TransporteVehiculo(TransporteVehiculoId);
IF OBJECT_ID(N'dbo.FK_TransporteViaje_Conductor',N'F') IS NULL ALTER TABLE dbo.TransporteViaje ADD CONSTRAINT FK_TransporteViaje_Conductor FOREIGN KEY(TransporteConductorId) REFERENCES dbo.TransporteConductor(TransporteConductorId);
IF OBJECT_ID(N'dbo.FK_TransporteViaje_Cliente',N'F') IS NULL ALTER TABLE dbo.TransporteViaje ADD CONSTRAINT FK_TransporteViaje_Cliente FOREIGN KEY(ClienteId) REFERENCES dbo.Cliente(ClienteId);
IF OBJECT_ID(N'dbo.FK_TransporteViaje_Responsable',N'F') IS NULL ALTER TABLE dbo.TransporteViaje ADD CONSTRAINT FK_TransporteViaje_Responsable FOREIGN KEY(ResponsableUsuarioId) REFERENCES dbo.Usuario(UsuarioId);
IF OBJECT_ID(N'dbo.FK_TransporteIncidencia_Viaje',N'F') IS NULL ALTER TABLE dbo.TransporteIncidencia ADD CONSTRAINT FK_TransporteIncidencia_Viaje FOREIGN KEY(TransporteViajeId) REFERENCES dbo.TransporteViaje(TransporteViajeId);
IF OBJECT_ID(N'dbo.FK_TransporteIncidencia_Usuario',N'F') IS NULL ALTER TABLE dbo.TransporteIncidencia ADD CONSTRAINT FK_TransporteIncidencia_Usuario FOREIGN KEY(UsuarioId) REFERENCES dbo.Usuario(UsuarioId);
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
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Pedido') AND name = N'IX_Pedido_ClienteEstado')
    CREATE INDEX IX_Pedido_ClienteEstado ON dbo.Pedido(ClienteId, Estado, FechaCreacion DESC) INCLUDE (GiroNegocioId, VendedorUsuarioId, Eliminado);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Pedido') AND name = N'IX_Pedido_GiroEstado')
    CREATE INDEX IX_Pedido_GiroEstado ON dbo.Pedido(GiroNegocioId, Estado, FechaCreacion DESC) INCLUDE (ClienteId, VendedorUsuarioId, Eliminado);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Pedido') AND name = N'IX_Pedido_VendedorEstado')
    CREATE INDEX IX_Pedido_VendedorEstado ON dbo.Pedido(VendedorUsuarioId, Estado, FechaCreacion DESC) INCLUDE (ClienteId, GiroNegocioId, Eliminado);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.PedidoHistorial') AND name = N'IX_PedidoHistorial_PedidoFecha')
    CREATE INDEX IX_PedidoHistorial_PedidoFecha ON dbo.PedidoHistorial(PedidoId, Fecha DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.PedidoDocumento') AND name = N'IX_PedidoDocumento_Pedido')
    CREATE INDEX IX_PedidoDocumento_Pedido ON dbo.PedidoDocumento(PedidoId, FechaCreacion DESC) INCLUDE (Eliminado);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.InventarioArticulo') AND name = N'UX_InventarioArticulo_CodigoActivo')
    CREATE UNIQUE INDEX UX_InventarioArticulo_CodigoActivo ON dbo.InventarioArticulo(Codigo) WHERE Eliminado=0;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.InventarioArticulo') AND name = N'IX_InventarioArticulo_Giro')
    CREATE INDEX IX_InventarioArticulo_Giro ON dbo.InventarioArticulo(GiroNegocioId,EsActivo) INCLUDE (Nombre,Categoria,StockMinimo,Eliminado);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.InventarioExistencia') AND name = N'UX_InventarioExistencia_ArticuloSede')
    CREATE UNIQUE INDEX UX_InventarioExistencia_ArticuloSede ON dbo.InventarioExistencia(InventarioArticuloId,SedeId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.InventarioMovimiento') AND name = N'IX_InventarioMovimiento_ArticuloFecha')
    CREATE INDEX IX_InventarioMovimiento_ArticuloFecha ON dbo.InventarioMovimiento(InventarioArticuloId,Fecha DESC) INCLUDE (Tipo,SedeOrigenId,SedeDestinoId,Cantidad);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.AbastecimientoSolicitud') AND name=N'IX_Abastecimiento_Solicitante') CREATE INDEX IX_Abastecimiento_Solicitante ON dbo.AbastecimientoSolicitud(GiroSolicitanteId,SedeSolicitanteId,Estado,FechaCreacion DESC) INCLUDE(GiroProveedorId,SedeProveedorId,Eliminado);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.AbastecimientoSolicitud') AND name=N'IX_Abastecimiento_Proveedor') CREATE INDEX IX_Abastecimiento_Proveedor ON dbo.AbastecimientoSolicitud(GiroProveedorId,SedeProveedorId,Estado,FechaCreacion DESC) INCLUDE(GiroSolicitanteId,SedeSolicitanteId,Eliminado);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.AbastecimientoDetalle') AND name=N'IX_AbastecimientoDetalle_Solicitud') CREATE INDEX IX_AbastecimientoDetalle_Solicitud ON dbo.AbastecimientoDetalle(AbastecimientoSolicitudId);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.AbastecimientoHistorial') AND name=N'IX_AbastecimientoHistorial_Solicitud') CREATE INDEX IX_AbastecimientoHistorial_Solicitud ON dbo.AbastecimientoHistorial(AbastecimientoSolicitudId,Fecha DESC);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.ExtraccionJornada') AND name=N'IX_ExtraccionJornada_SedeFecha') CREATE INDEX IX_ExtraccionJornada_SedeFecha ON dbo.ExtraccionJornada(SedeId,FechaOperacion DESC,Estado) INCLUDE(InventarioArticuloId,CantidadExtraida,CantidadRechazada,Eliminado);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.ExtraccionHistorial') AND name=N'IX_ExtraccionHistorial_Jornada') CREATE INDEX IX_ExtraccionHistorial_Jornada ON dbo.ExtraccionHistorial(ExtraccionJornadaId,Fecha DESC);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.ProduccionOrden') AND name=N'IX_ProduccionOrden_SedeFecha') CREATE INDEX IX_ProduccionOrden_SedeFecha ON dbo.ProduccionOrden(SedeId,FechaPlanificada DESC,Estado) INCLUDE(ArticuloEntradaId,ArticuloSalidaId,Eliminado);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.ProduccionEtapa') AND name=N'UX_ProduccionEtapa_OrdenSecuencia') CREATE UNIQUE INDEX UX_ProduccionEtapa_OrdenSecuencia ON dbo.ProduccionEtapa(ProduccionOrdenId,Secuencia);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.ProduccionHistorial') AND name=N'IX_ProduccionHistorial_Orden') CREATE INDEX IX_ProduccionHistorial_Orden ON dbo.ProduccionHistorial(ProduccionOrdenId,Fecha DESC);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.MaquinariaEquipo') AND name=N'UX_MaquinariaEquipo_Codigo') CREATE UNIQUE INDEX UX_MaquinariaEquipo_Codigo ON dbo.MaquinariaEquipo(Codigo) WHERE Eliminado=0;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.MaquinariaContrato') AND name=N'IX_MaquinariaContrato_Equipo') CREATE INDEX IX_MaquinariaContrato_Equipo ON dbo.MaquinariaContrato(MaquinariaEquipoId,Estado,FechaInicio DESC) INCLUDE(ClienteId,Eliminado);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.MaquinariaMantenimiento') AND name=N'IX_MaquinariaMantenimiento_Equipo') CREATE INDEX IX_MaquinariaMantenimiento_Equipo ON dbo.MaquinariaMantenimiento(MaquinariaEquipoId,Estado,FechaProgramada DESC);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.TransporteVehiculo') AND name=N'UX_TransporteVehiculo_Placa') CREATE UNIQUE INDEX UX_TransporteVehiculo_Placa ON dbo.TransporteVehiculo(Placa) WHERE Eliminado=0;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.TransporteConductor') AND name=N'UX_TransporteConductor_Licencia') CREATE UNIQUE INDEX UX_TransporteConductor_Licencia ON dbo.TransporteConductor(Licencia) WHERE Eliminado=0;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.TransporteViaje') AND name=N'IX_TransporteViaje_SedeEstado') CREATE INDEX IX_TransporteViaje_SedeEstado ON dbo.TransporteViaje(SedeId,Estado,FechaSalidaPlanificada DESC) INCLUDE(TransporteVehiculoId,TransporteConductorId,Eliminado);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.TransporteIncidencia') AND name=N'IX_TransporteIncidencia_Viaje') CREATE INDEX IX_TransporteIncidencia_Viaje ON dbo.TransporteIncidencia(TransporteViajeId,Resuelta,Fecha DESC);
GO

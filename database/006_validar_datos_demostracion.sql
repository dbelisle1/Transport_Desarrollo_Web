USE [TransPortDB];
GO
SET NOCOUNT ON;

IF NOT EXISTS(SELECT 1 FROM dbo.IntegracionEvento WHERE ClaveIdempotencia=N'DEMO-SEED-V1' AND Eliminado=0)
    THROW 51001,N'No se encontró la marca DEMO-SEED-V1.',1;

IF (SELECT COUNT(*) FROM dbo.Usuario WHERE NombreUsuario IN
    (N'admin.demo',N'empleado.demo',N'cliente.demo',N'gerente.demo',N'operativo.demo',N'vendedor.demo',N'cliente2.demo',N'cliente3.demo')
    AND EsActivo=1 AND Eliminado=0)<>8
    THROW 51002,N'Faltan cuentas de demostración activas.',1;

IF EXISTS
(
    SELECT esperado.NombreUsuario,esperado.Rol
    FROM (VALUES
      (N'admin.demo',N'AdministradorGeneral'),(N'empleado.demo',N'Empleado'),
      (N'cliente.demo',N'Cliente'),(N'gerente.demo',N'Gerente'),
      (N'operativo.demo',N'Operativo'),(N'vendedor.demo',N'Vendedor'),
      (N'cliente2.demo',N'Cliente'),(N'cliente3.demo',N'Cliente')
    ) esperado(NombreUsuario,Rol)
    WHERE NOT EXISTS
    (
      SELECT 1 FROM dbo.Usuario u
      JOIN dbo.UsuarioRol ur ON ur.UsuarioId=u.UsuarioId AND ur.Eliminado=0
      JOIN dbo.Rol r ON r.RolId=ur.RolId AND r.Eliminado=0 AND r.EsActivo=1
      WHERE u.NombreUsuario=esperado.NombreUsuario AND u.Eliminado=0 AND r.Nombre=esperado.Rol
    )
)
    THROW 51003,N'Una cuenta de demostración no tiene el rol esperado.',1;

IF (SELECT COUNT(*) FROM dbo.Cliente WHERE (Nit=N'CF-DEMO' OR Nit LIKE N'DEMO-%') AND EsActivo=1 AND Eliminado=0)<4
    THROW 51004,N'Faltan empresas ficticias activas.',1;
IF (SELECT COUNT(*) FROM dbo.ClienteUsuario cu JOIN dbo.Cliente c ON c.ClienteId=cu.ClienteId
    WHERE c.Nit LIKE N'DEMO-%' AND cu.Eliminado=0)<3
    THROW 51005,N'Faltan asociaciones entre clientes y usuarios demo.',1;
IF (SELECT COUNT(*) FROM dbo.ClienteGiroNegocio cg JOIN dbo.Cliente c ON c.ClienteId=cg.ClienteId
    WHERE c.Nit LIKE N'DEMO-%' AND cg.Eliminado=0)<7
    THROW 51006,N'Faltan giros contratados por las empresas demo.',1;

IF (SELECT COUNT(*) FROM dbo.CatalogoOferta WHERE Codigo LIKE N'DEMO-%' AND Eliminado=0)<5
    THROW 51007,N'Faltan ofertas comerciales demo.',1;
IF (SELECT COUNT(*) FROM dbo.Pedido WHERE Titulo LIKE N'DEMO - %' AND Eliminado=0)<6
    THROW 51008,N'Faltan pedidos demo.',1;
IF (SELECT COUNT(DISTINCT Estado) FROM dbo.Pedido WHERE Titulo LIKE N'DEMO - %' AND Eliminado=0)<6
    THROW 51009,N'Los pedidos demo no cubren suficientes estados.',1;

IF (SELECT COUNT(*) FROM dbo.InventarioArticulo WHERE Codigo LIKE N'DEMO-%' AND Eliminado=0)<4
    THROW 51010,N'Faltan artículos de inventario demo.',1;
IF (SELECT COUNT(*) FROM dbo.InventarioExistencia e JOIN dbo.InventarioArticulo a ON a.InventarioArticuloId=e.InventarioArticuloId
    WHERE a.Codigo LIKE N'DEMO-%')<4
    THROW 51011,N'Faltan existencias demo.',1;
IF (SELECT COUNT(*) FROM dbo.InventarioMovimiento WHERE Referencia LIKE N'DEMO-%')<10
    THROW 51012,N'Faltan movimientos de inventario demo.',1;

IF (SELECT COUNT(*) FROM dbo.AbastecimientoSolicitud WHERE Motivo LIKE N'%DEMO%' AND Eliminado=0)<2
    THROW 51013,N'Faltan solicitudes de abastecimiento demo.',1;
IF (SELECT COUNT(*) FROM dbo.ExtraccionJornada WHERE FrenteExtraccion LIKE N'%DEMO%' AND Eliminado=0)<3
    THROW 51014,N'Faltan jornadas de extracción demo.',1;
IF (SELECT COUNT(*) FROM dbo.ProduccionOrden p JOIN dbo.InventarioArticulo a ON a.InventarioArticuloId=p.ArticuloSalidaId
    WHERE a.Codigo=N'DEMO-PRO-PISO' AND p.Eliminado=0)<3
    THROW 51015,N'Faltan órdenes de producción demo.',1;

IF (SELECT COUNT(*) FROM dbo.MaquinariaEquipo WHERE Codigo LIKE N'DEMO-%' AND Eliminado=0)<4
    THROW 51016,N'Faltan equipos de maquinaria demo.',1;
IF (SELECT COUNT(*) FROM dbo.MaquinariaContrato c JOIN dbo.MaquinariaEquipo e ON e.MaquinariaEquipoId=c.MaquinariaEquipoId
    WHERE e.Codigo LIKE N'DEMO-%' AND c.Eliminado=0)<3
    THROW 51017,N'Faltan contratos de maquinaria demo.',1;
IF (SELECT COUNT(*) FROM dbo.MaquinariaMantenimiento m JOIN dbo.MaquinariaEquipo e ON e.MaquinariaEquipoId=m.MaquinariaEquipoId
    WHERE e.Codigo LIKE N'DEMO-%')<3
    THROW 51018,N'Faltan mantenimientos de maquinaria demo.',1;

IF (SELECT COUNT(*) FROM dbo.TransporteVehiculo WHERE Placa LIKE N'DEMO-%' AND Eliminado=0)<4
    THROW 51019,N'Faltan vehículos demo.',1;
IF (SELECT COUNT(*) FROM dbo.TransporteViaje v JOIN dbo.TransporteVehiculo x ON x.TransporteVehiculoId=v.TransporteVehiculoId
    WHERE x.Placa LIKE N'DEMO-%' AND v.Eliminado=0)<4
    THROW 51020,N'Faltan viajes demo.',1;
IF (SELECT COUNT(*) FROM dbo.GpsDispositivo WHERE IdentificadorExterno LIKE N'DEMO-%' AND Eliminado=0)<2
    THROW 51021,N'Faltan dispositivos GPS demo.',1;
IF (SELECT COUNT(*) FROM dbo.GpsPosicion p JOIN dbo.GpsDispositivo d ON d.GpsDispositivoId=p.GpsDispositivoId
    WHERE d.IdentificadorExterno LIKE N'DEMO-%')<3
    THROW 51022,N'Faltan posiciones GPS demo.',1;

IF (SELECT COUNT(*) FROM dbo.ConstruccionProyecto WHERE Nombre LIKE N'DEMO - %' AND Eliminado=0)<3
    THROW 51023,N'Faltan proyectos de construcción demo.',1;
IF (SELECT COUNT(*) FROM dbo.FinanzaPresupuesto WHERE Nombre LIKE N'DEMO - %' AND Eliminado=0)<4
    THROW 51024,N'Faltan presupuestos demo.',1;
IF (SELECT COUNT(*) FROM dbo.FinanzaIngreso WHERE Referencia LIKE N'FAC-DEMO-%' AND Eliminado=0)<5
    THROW 51025,N'Faltan ingresos financieros demo.',1;

IF (SELECT COUNT(*) FROM dbo.AlertaNotificacion WHERE Titulo LIKE N'DEMO - %' AND Eliminado=0)<3
    THROW 51026,N'Faltan alertas demo.',1;
IF (SELECT COUNT(*) FROM dbo.ComunicacionHilo WHERE Asunto LIKE N'DEMO - %' AND Eliminado=0)<3
    THROW 51027,N'Faltan comunicaciones demo.',1;
IF (SELECT COUNT(*) FROM dbo.IntegracionEvento WHERE ClaveIdempotencia LIKE N'DEMO-%' AND Eliminado=0)<3
    THROW 51028,N'Faltan integraciones simuladas demo.',1;

SELECT Modulo,Registros
FROM
(
    SELECT 1 Orden,N'Seguridad y usuarios' Modulo,COUNT_BIG(*) Registros FROM dbo.Usuario WHERE NombreUsuario LIKE N'%.demo' AND Eliminado=0
    UNION ALL SELECT 2,N'Clientes',COUNT_BIG(*) FROM dbo.Cliente WHERE Nit=N'CF-DEMO' OR Nit LIKE N'DEMO-%'
    UNION ALL SELECT 3,N'Pedidos',COUNT_BIG(*) FROM dbo.Pedido WHERE Titulo LIKE N'DEMO - %' AND Eliminado=0
    UNION ALL SELECT 4,N'Inventario',COUNT_BIG(*) FROM dbo.InventarioArticulo WHERE Codigo LIKE N'DEMO-%' AND Eliminado=0
    UNION ALL SELECT 5,N'Abastecimiento',COUNT_BIG(*) FROM dbo.AbastecimientoSolicitud WHERE Motivo LIKE N'%DEMO%' AND Eliminado=0
    UNION ALL SELECT 6,N'Extracción',COUNT_BIG(*) FROM dbo.ExtraccionJornada WHERE FrenteExtraccion LIKE N'%DEMO%' AND Eliminado=0
    UNION ALL SELECT 7,N'Producción',COUNT_BIG(*) FROM dbo.ProduccionOrden p JOIN dbo.InventarioArticulo a ON a.InventarioArticuloId=p.ArticuloSalidaId WHERE a.Codigo=N'DEMO-PRO-PISO' AND p.Eliminado=0
    UNION ALL SELECT 8,N'Maquinaria',COUNT_BIG(*) FROM dbo.MaquinariaEquipo WHERE Codigo LIKE N'DEMO-%' AND Eliminado=0
    UNION ALL SELECT 9,N'Transporte',COUNT_BIG(*) FROM dbo.TransporteVehiculo WHERE Placa LIKE N'DEMO-%' AND Eliminado=0
    UNION ALL SELECT 10,N'GPS',COUNT_BIG(*) FROM dbo.GpsDispositivo WHERE IdentificadorExterno LIKE N'DEMO-%' AND Eliminado=0
    UNION ALL SELECT 11,N'Construcción',COUNT_BIG(*) FROM dbo.ConstruccionProyecto WHERE Nombre LIKE N'DEMO - %' AND Eliminado=0
    UNION ALL SELECT 12,N'Finanzas',COUNT_BIG(*) FROM dbo.FinanzaIngreso WHERE Referencia LIKE N'FAC-DEMO-%' AND Eliminado=0
    UNION ALL SELECT 13,N'Alertas',COUNT_BIG(*) FROM dbo.AlertaNotificacion WHERE Titulo LIKE N'DEMO - %' AND Eliminado=0
    UNION ALL SELECT 14,N'Comunicaciones',COUNT_BIG(*) FROM dbo.ComunicacionHilo WHERE Asunto LIKE N'DEMO - %' AND Eliminado=0
    UNION ALL SELECT 15,N'Integraciones',COUNT_BIG(*) FROM dbo.IntegracionEvento WHERE ClaveIdempotencia LIKE N'DEMO-%' AND Eliminado=0
) resumen
ORDER BY Orden;

PRINT N'Validación de datos ficticios DEMO-SEED-V1 correcta.';
GO

USE [TransPortDB];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_WARNINGS ON;
SET ANSI_PADDING ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

/*
  Datos ficticios integrales para recorrer los módulos de TransPort.
  La clave DEMO-SEED-V1 se inserta al final de la misma transacción y funciona
  como marcador: una segunda ejecución no duplica el conjunto.
*/
IF EXISTS
(
    SELECT 1 FROM dbo.IntegracionEvento
    WHERE ClaveIdempotencia=N'DEMO-SEED-V1' AND Eliminado=0
)
BEGIN
    PRINT N'Los datos ficticios integrales DEMO-SEED-V1 ya están instalados.';
    RETURN;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @Ahora DATETIME2(0)=SYSUTCDATETIME();
    DECLARE @Hoy DATE=CONVERT(DATE,GETDATE());
    DECLARE @Anio SMALLINT=YEAR(@Hoy);
    DECLARE @Mes TINYINT=MONTH(@Hoy);

    /* Catálogos y cuentas base creados por 004_datos_iniciales.sql. */
    DECLARE @AdminId INT=(SELECT UsuarioId FROM dbo.Usuario WHERE NombreUsuario=N'admin.demo' AND Eliminado=0);
    DECLARE @EmpleadoId INT=(SELECT UsuarioId FROM dbo.Usuario WHERE NombreUsuario=N'empleado.demo' AND Eliminado=0);
    DECLARE @Cliente1UsuarioId INT=(SELECT UsuarioId FROM dbo.Usuario WHERE NombreUsuario=N'cliente.demo' AND Eliminado=0);
    DECLARE @RolGerente INT=(SELECT RolId FROM dbo.Rol WHERE Nombre=N'Gerente' AND Eliminado=0);
    DECLARE @RolOperativo INT=(SELECT RolId FROM dbo.Rol WHERE Nombre=N'Operativo' AND Eliminado=0);
    DECLARE @RolVendedor INT=(SELECT RolId FROM dbo.Rol WHERE Nombre=N'Vendedor' AND Eliminado=0);
    DECLARE @RolCliente INT=(SELECT RolId FROM dbo.Rol WHERE Nombre=N'Cliente' AND Eliminado=0);
    DECLARE @RolEmpleado INT=(SELECT RolId FROM dbo.Rol WHERE Nombre=N'Empleado' AND Eliminado=0);
    DECLARE @GiroExtraccion INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Extracción minera' AND Eliminado=0);
    DECLARE @GiroProceso INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Procesamiento de materia prima' AND Eliminado=0);
    DECLARE @GiroMaquinaria INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Venta y alquiler de maquinaria' AND Eliminado=0);
    DECLARE @GiroMateriaPrima INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Transporte de materia prima' AND Eliminado=0);
    DECLARE @GiroTransporte INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Transporte nacional e internacional' AND Eliminado=0);
    DECLARE @GiroConstruccion INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Servicios de construcción' AND Eliminado=0);
    DECLARE @SedeCentral INT=(SELECT SedeId FROM dbo.Sede WHERE Nombre=N'Sede central' AND Eliminado=0);
    DECLARE @SedeCoban INT=(SELECT SedeId FROM dbo.Sede WHERE Nombre=N'Cobán - Extracción' AND Eliminado=0);
    DECLARE @SedeZacapaProceso INT=(SELECT SedeId FROM dbo.Sede WHERE Nombre=N'Zacapa - Procesamiento' AND Eliminado=0);
    DECLARE @SedeGuatemalaMaquinaria INT=(SELECT SedeId FROM dbo.Sede WHERE Nombre=N'Guatemala - Maquinaria' AND Eliminado=0);
    DECLARE @Cliente1Id INT=(SELECT ClienteId FROM dbo.Cliente WHERE Nit=N'CF-DEMO' AND Eliminado=0);

    IF @AdminId IS NULL OR @EmpleadoId IS NULL OR @Cliente1UsuarioId IS NULL
       OR @RolGerente IS NULL OR @RolOperativo IS NULL OR @RolVendedor IS NULL
       OR @RolCliente IS NULL OR @RolEmpleado IS NULL OR @GiroExtraccion IS NULL OR @GiroProceso IS NULL
       OR @GiroMaquinaria IS NULL OR @GiroMateriaPrima IS NULL OR @GiroTransporte IS NULL OR @GiroConstruccion IS NULL
       OR @SedeCentral IS NULL OR @SedeCoban IS NULL OR @SedeZacapaProceso IS NULL
       OR @SedeGuatemalaMaquinaria IS NULL OR @Cliente1Id IS NULL
        THROW 50002,N'Faltan datos iniciales. Ejecute primero 004_datos_iniciales.sql.',1;

    /* Usuarios de cada perfil para probar autorización y alcances. */
    INSERT dbo.Usuario(NombreUsuario,Nombre,Apellido,Correo,Clave)
    VALUES
      (N'gerente.demo',N'Gabriela',N'Gerente',N'gerente.demo@transport.local',N'TransPortGerente2026!'),
      (N'operativo.demo',N'Óscar',N'Operativo',N'operativo.demo@transport.local',N'TransPortOperativo2026!'),
      (N'vendedor.demo',N'Valeria',N'Vendedora',N'vendedor.demo@transport.local',N'TransPortVendedor2026!'),
      (N'cliente2.demo',N'María',N'Minerales',N'cliente2.demo@transport.local',N'TransPortCliente22026!'),
      (N'cliente3.demo',N'Carlos',N'Constructor',N'cliente3.demo@transport.local',N'TransPortCliente32026!');

    DECLARE @GerenteId INT=(SELECT UsuarioId FROM dbo.Usuario WHERE NombreUsuario=N'gerente.demo' AND Eliminado=0);
    DECLARE @OperativoId INT=(SELECT UsuarioId FROM dbo.Usuario WHERE NombreUsuario=N'operativo.demo' AND Eliminado=0);
    DECLARE @VendedorId INT=(SELECT UsuarioId FROM dbo.Usuario WHERE NombreUsuario=N'vendedor.demo' AND Eliminado=0);
    DECLARE @Cliente2UsuarioId INT=(SELECT UsuarioId FROM dbo.Usuario WHERE NombreUsuario=N'cliente2.demo' AND Eliminado=0);
    DECLARE @Cliente3UsuarioId INT=(SELECT UsuarioId FROM dbo.Usuario WHERE NombreUsuario=N'cliente3.demo' AND Eliminado=0);

    INSERT dbo.UsuarioRol(UsuarioId,RolId)
    VALUES(@GerenteId,@RolGerente),(@OperativoId,@RolOperativo),(@VendedorId,@RolVendedor),
          (@Cliente2UsuarioId,@RolCliente),(@Cliente3UsuarioId,@RolCliente);

    INSERT dbo.UsuarioGiroNegocio(UsuarioId,GiroNegocioId)
    SELECT @GerenteId,GiroNegocioId FROM dbo.GiroNegocio WHERE EsActivo=1 AND Eliminado=0;
    INSERT dbo.UsuarioGiroNegocio(UsuarioId,GiroNegocioId)
    VALUES(@OperativoId,@GiroProceso),(@OperativoId,@GiroMateriaPrima),(@OperativoId,@GiroTransporte);
    INSERT dbo.UsuarioGiroNegocio(UsuarioId,GiroNegocioId)
    SELECT @VendedorId,GiroNegocioId FROM dbo.GiroNegocio WHERE EsActivo=1 AND Eliminado=0;

    INSERT dbo.UsuarioSede(UsuarioId,SedeId)
    SELECT @GerenteId,SedeId FROM dbo.Sede WHERE EsActivo=1 AND Eliminado=0;
    INSERT dbo.UsuarioSede(UsuarioId,SedeId)
    VALUES(@OperativoId,@SedeCentral),(@OperativoId,@SedeZacapaProceso);
    INSERT dbo.UsuarioSede(UsuarioId,SedeId) VALUES(@VendedorId,@SedeCentral);

    /* Empresas para validar aislamiento y clientes con más de una empresa. */
    INSERT dbo.Cliente(Nombre,Nit,CorreoContacto)
    VALUES
      (N'Minerales del Norte, S.A.',N'DEMO-MIN-001',N'compras@minerales-demo.local'),
      (N'Constructora Horizonte, S.A.',N'DEMO-CON-001',N'proyectos@horizonte-demo.local'),
      (N'Distribuidora Cerámica Maya',N'DEMO-CER-001',N'pedidos@ceramica-demo.local');

    DECLARE @ClienteMinerales INT=(SELECT ClienteId FROM dbo.Cliente WHERE Nit=N'DEMO-MIN-001' AND Eliminado=0);
    DECLARE @ClienteConstructora INT=(SELECT ClienteId FROM dbo.Cliente WHERE Nit=N'DEMO-CON-001' AND Eliminado=0);
    DECLARE @ClienteCeramica INT=(SELECT ClienteId FROM dbo.Cliente WHERE Nit=N'DEMO-CER-001' AND Eliminado=0);

    INSERT dbo.ClienteUsuario(ClienteId,UsuarioId)
    VALUES(@ClienteMinerales,@Cliente2UsuarioId),(@ClienteConstructora,@Cliente3UsuarioId),
          (@ClienteCeramica,@Cliente3UsuarioId);
    INSERT dbo.ClienteGiroNegocio(ClienteId,GiroNegocioId)
    VALUES
      (@ClienteMinerales,@GiroExtraccion),(@ClienteMinerales,@GiroProceso),
      (@ClienteConstructora,@GiroConstruccion),(@ClienteConstructora,@GiroMaquinaria),
      (@ClienteConstructora,@GiroTransporte),
      (@ClienteCeramica,@GiroProceso),(@ClienteCeramica,@GiroTransporte);

    /* Ofertas adicionales: públicas, privadas y de distintos tipos. */
    INSERT dbo.CatalogoOferta
      (GiroNegocioId,Codigo,Tipo,Nombre,Descripcion,UnidadMedida,PrecioBase,EsPublico,EsActivo)
    VALUES
      (@GiroExtraccion,N'DEMO-MIN-ARENA',N'Producto',N'Arena sílica clasificada',N'Arena industrial lavada y clasificada.',N'Tonelada',510,1,1),
      (@GiroProceso,N'DEMO-PRO-BLOQUE',N'Producto',N'Bloque estructural',N'Bloque de concreto para obra gris.',N'Unidad',8.75,1,1),
      (@GiroMaquinaria,N'DEMO-MAQ-RETRO',N'Servicio',N'Alquiler de retroexcavadora',N'Alquiler diario con horómetro.',N'Día',2400,1,1),
      (@GiroTransporte,N'DEMO-TRA-EXP',N'Servicio',N'Transporte internacional expreso',N'Traslado terrestre prioritario hacia Centroamérica.',N'Viaje',8900,1,1),
      (@GiroConstruccion,N'DEMO-CON-SUP',N'Servicio',N'Supervisión técnica mensual',N'Seguimiento de obra y control de calidad.',N'Mes',12500,0,1);

    DECLARE @OfertaMineral INT=(SELECT CatalogoOfertaId FROM dbo.CatalogoOferta WHERE Codigo=N'MIN-CALIZA-TON' AND Eliminado=0);
    DECLARE @OfertaProceso INT=(SELECT CatalogoOfertaId FROM dbo.CatalogoOferta WHERE Codigo=N'PRO-PISO-45' AND Eliminado=0);
    DECLARE @OfertaMaquinaria INT=(SELECT CatalogoOfertaId FROM dbo.CatalogoOferta WHERE Codigo=N'MAQ-EXC-DIA' AND Eliminado=0);
    DECLARE @OfertaTransporte INT=(SELECT CatalogoOfertaId FROM dbo.CatalogoOferta WHERE Codigo=N'TNI-CARGA-NAC' AND Eliminado=0);
    DECLARE @OfertaConstruccion INT=(SELECT CatalogoOfertaId FROM dbo.CatalogoOferta WHERE Codigo=N'CON-EVAL-TEC' AND Eliminado=0);

    /* Pedidos en diferentes estados para gestión comercial y portal cliente. */
    INSERT dbo.Pedido(ClienteId,GiroNegocioId,SolicitanteUsuarioId,TipoSolicitud,Titulo,Descripcion,Estado,FechaRequerida)
    VALUES(@Cliente1Id,@GiroTransporte,@Cliente1UsuarioId,N'Cotizacion',N'DEMO - Transporte Puerto Quetzal a Guatemala',N'Se requiere cotizar un contenedor de materia prima.',N'Solicitado',DATEADD(DAY,12,@Hoy));
    DECLARE @PedidoSolicitado BIGINT=SCOPE_IDENTITY();

    INSERT dbo.Pedido(ClienteId,GiroNegocioId,SolicitanteUsuarioId,VendedorUsuarioId,TipoSolicitud,Titulo,Descripcion,Estado,FechaRequerida,MontoCotizado,FechaModificacion)
    VALUES(@ClienteMinerales,@GiroExtraccion,@Cliente2UsuarioId,@VendedorId,N'Pedido',N'DEMO - Compra de caliza seleccionada',N'Pedido mensual para planta de procesamiento.',N'Cotizado',DATEADD(DAY,8,@Hoy),43750,@Ahora);
    DECLARE @PedidoCotizado BIGINT=SCOPE_IDENTITY();

    INSERT dbo.Pedido(ClienteId,GiroNegocioId,SolicitanteUsuarioId,VendedorUsuarioId,TipoSolicitud,Titulo,Descripcion,Estado,FechaRequerida,MontoCotizado,FechaModificacion)
    VALUES(@ClienteConstructora,@GiroMaquinaria,@Cliente3UsuarioId,@VendedorId,N'Pedido',N'DEMO - Alquiler de excavadora para obra',N'Equipo requerido durante diez días.',N'EnProceso',DATEADD(DAY,4,@Hoy),28500,@Ahora);
    DECLARE @PedidoEnProceso BIGINT=SCOPE_IDENTITY();

    INSERT dbo.Pedido(ClienteId,GiroNegocioId,SolicitanteUsuarioId,VendedorUsuarioId,TipoSolicitud,Titulo,Descripcion,Estado,FechaRequerida,MontoCotizado,FechaModificacion)
    VALUES(@ClienteConstructora,@GiroConstruccion,@Cliente3UsuarioId,@VendedorId,N'Cotizacion',N'DEMO - Evaluación y diseño de puente',N'Evaluación técnica completada para puente rural.',N'Completado',DATEADD(DAY,-10,@Hoy),24000,@Ahora);
    DECLARE @PedidoCompletado BIGINT=SCOPE_IDENTITY();

    INSERT dbo.Pedido(ClienteId,GiroNegocioId,SolicitanteUsuarioId,VendedorUsuarioId,TipoSolicitud,Titulo,Descripcion,Estado,FechaReunionUtc,EnlaceReunion)
    VALUES(@ClienteCeramica,@GiroProceso,@Cliente3UsuarioId,@VendedorId,N'Reunion',N'DEMO - Reunión por suministro de piso',N'Revisión de catálogo y condiciones de entrega.',N'EnRevision',DATEADD(DAY,3,@Ahora),N'https://meet.example/demo-ceramica');
    DECLARE @PedidoReunion BIGINT=SCOPE_IDENTITY();

    INSERT dbo.Pedido(ClienteId,GiroNegocioId,SolicitanteUsuarioId,VendedorUsuarioId,TipoSolicitud,Titulo,Descripcion,Estado,FechaRequerida,MontoCotizado,FechaModificacion)
    VALUES(@ClienteMinerales,@GiroProceso,@Cliente2UsuarioId,@VendedorId,N'Pedido',N'DEMO - Lote de piso para oficinas',N'Remodelación de oficinas administrativas.',N'Aprobado',DATEADD(DAY,15,@Hoy),18900,@Ahora);
    DECLARE @PedidoAprobado BIGINT=SCOPE_IDENTITY();

    INSERT dbo.PedidoLinea(PedidoId,CatalogoOfertaId,Codigo,Tipo,Nombre,UnidadMedida,Cantidad,PrecioUnitarioBase,PrecioUnitarioCotizado)
    SELECT @PedidoSolicitado,CatalogoOfertaId,Codigo,Tipo,Nombre,UnidadMedida,1,PrecioBase,NULL FROM dbo.CatalogoOferta WHERE CatalogoOfertaId=@OfertaTransporte
    UNION ALL SELECT @PedidoCotizado,CatalogoOfertaId,Codigo,Tipo,Nombre,UnidadMedida,100,PrecioBase,437.50 FROM dbo.CatalogoOferta WHERE CatalogoOfertaId=@OfertaMineral
    UNION ALL SELECT @PedidoEnProceso,CatalogoOfertaId,Codigo,Tipo,Nombre,UnidadMedida,10,PrecioBase,2850 FROM dbo.CatalogoOferta WHERE CatalogoOfertaId=@OfertaMaquinaria
    UNION ALL SELECT @PedidoCompletado,CatalogoOfertaId,Codigo,Tipo,Nombre,UnidadMedida,20,PrecioBase,1200 FROM dbo.CatalogoOferta WHERE CatalogoOfertaId=@OfertaConstruccion
    UNION ALL SELECT @PedidoReunion,CatalogoOfertaId,Codigo,Tipo,Nombre,UnidadMedida,50,PrecioBase,NULL FROM dbo.CatalogoOferta WHERE CatalogoOfertaId=@OfertaProceso
    UNION ALL SELECT @PedidoAprobado,CatalogoOfertaId,Codigo,Tipo,Nombre,UnidadMedida,100,PrecioBase,189 FROM dbo.CatalogoOferta WHERE CatalogoOfertaId=@OfertaProceso;

    INSERT dbo.PedidoHistorial(PedidoId,UsuarioId,EstadoAnterior,EstadoNuevo,Comentario,Fecha)
    VALUES
      (@PedidoSolicitado,@Cliente1UsuarioId,NULL,N'Solicitado',N'Solicitud creada por el cliente.',DATEADD(DAY,-1,@Ahora)),
      (@PedidoCotizado,@Cliente2UsuarioId,NULL,N'Solicitado',N'Pedido registrado.',DATEADD(DAY,-6,@Ahora)),
      (@PedidoCotizado,@VendedorId,N'Solicitado',N'EnRevision',N'Información validada.',DATEADD(DAY,-5,@Ahora)),
      (@PedidoCotizado,@VendedorId,N'EnRevision',N'Cotizado',N'Cotización enviada al cliente.',DATEADD(DAY,-4,@Ahora)),
      (@PedidoEnProceso,@Cliente3UsuarioId,NULL,N'Solicitado',N'Equipo solicitado.',DATEADD(DAY,-12,@Ahora)),
      (@PedidoEnProceso,@VendedorId,N'Solicitado',N'Aprobado',N'Disponibilidad confirmada.',DATEADD(DAY,-11,@Ahora)),
      (@PedidoEnProceso,@VendedorId,N'Aprobado',N'EnProceso',N'Equipo entregado.',DATEADD(DAY,-3,@Ahora)),
      (@PedidoCompletado,@Cliente3UsuarioId,NULL,N'Solicitado',N'Evaluación solicitada.',DATEADD(DAY,-35,@Ahora)),
      (@PedidoCompletado,@VendedorId,N'Solicitado',N'Cotizado',N'Propuesta aceptada.',DATEADD(DAY,-32,@Ahora)),
      (@PedidoCompletado,@VendedorId,N'Cotizado',N'Completado',N'Informe técnico entregado.',DATEADD(DAY,-20,@Ahora)),
      (@PedidoReunion,@Cliente3UsuarioId,NULL,N'Solicitado',N'Reunión solicitada.',DATEADD(DAY,-2,@Ahora)),
      (@PedidoReunion,@VendedorId,N'Solicitado',N'EnRevision',N'Reunión confirmada.',DATEADD(DAY,-1,@Ahora)),
      (@PedidoAprobado,@Cliente2UsuarioId,NULL,N'Solicitado',N'Pedido registrado.',DATEADD(DAY,-4,@Ahora)),
      (@PedidoAprobado,@VendedorId,N'Solicitado',N'Aprobado',N'Pedido aprobado.',DATEADD(DAY,-2,@Ahora));

    INSERT dbo.PedidoDocumento(PedidoId,UsuarioId,Nombre,TipoDocumento,Url)
    VALUES
      (@PedidoCotizado,@VendedorId,N'Cotización caliza DEMO',N'Cotizacion',N'https://example.local/documentos/cotizacion-caliza.pdf'),
      (@PedidoCompletado,@VendedorId,N'Informe técnico DEMO',N'Informe',N'https://example.local/documentos/informe-puente.pdf');

    /* Inventarios y movimientos con existencias suficientes y stock mínimo. */
    INSERT dbo.InventarioArticulo(GiroNegocioId,Codigo,Nombre,Categoria,UnidadMedida,StockMinimo)
    VALUES
      (@GiroExtraccion,N'DEMO-MIN-CALIZA',N'Caliza extraída DEMO',N'Materia prima',N't',300),
      (@GiroProceso,N'DEMO-PRO-CALIZA',N'Caliza para procesamiento DEMO',N'Materia prima',N't',120),
      (@GiroProceso,N'DEMO-PRO-PISO',N'Piso cerámico DEMO',N'Producto terminado',N'caja',150),
      (@GiroConstruccion,N'DEMO-CON-CEMENTO',N'Cemento estructural DEMO',N'Material',N'saco',250);

    DECLARE @ArticuloMineral INT=(SELECT InventarioArticuloId FROM dbo.InventarioArticulo WHERE Codigo=N'DEMO-MIN-CALIZA' AND Eliminado=0);
    DECLARE @ArticuloProcesoEntrada INT=(SELECT InventarioArticuloId FROM dbo.InventarioArticulo WHERE Codigo=N'DEMO-PRO-CALIZA' AND Eliminado=0);
    DECLARE @ArticuloProcesoSalida INT=(SELECT InventarioArticuloId FROM dbo.InventarioArticulo WHERE Codigo=N'DEMO-PRO-PISO' AND Eliminado=0);
    DECLARE @ArticuloConstruccion INT=(SELECT InventarioArticuloId FROM dbo.InventarioArticulo WHERE Codigo=N'DEMO-CON-CEMENTO' AND Eliminado=0);

    INSERT dbo.InventarioExistencia(InventarioArticuloId,SedeId,Cantidad,CantidadReservada)
    VALUES
      (@ArticuloMineral,@SedeCoban,1675,50),
      (@ArticuloProcesoEntrada,@SedeZacapaProceso,420,80),
      (@ArticuloProcesoSalida,@SedeZacapaProceso,640,25),
      (@ArticuloConstruccion,@SedeCentral,800,100);

    INSERT dbo.InventarioMovimiento(InventarioArticuloId,Tipo,SedeOrigenId,SedeDestinoId,Cantidad,Referencia,Observacion,UsuarioId,Fecha)
    VALUES
      (@ArticuloMineral,N'Entrada',NULL,@SedeCoban,1600,N'DEMO-INICIAL-MIN',N'Inventario ficticio inicial.',@GerenteId,DATEADD(DAY,-45,@Ahora)),
      (@ArticuloMineral,N'Reserva',@SedeCoban,NULL,50,N'DEMO-RESERVA-MIN',N'Reserva para pedido cotizado.',@EmpleadoId,DATEADD(DAY,-4,@Ahora)),
      (@ArticuloProcesoEntrada,N'Entrada',NULL,@SedeZacapaProceso,500,N'DEMO-INICIAL-PRO',N'Materia prima ficticia inicial.',@OperativoId,DATEADD(DAY,-30,@Ahora)),
      (@ArticuloProcesoSalida,N'Entrada',NULL,@SedeZacapaProceso,700,N'DEMO-PRODUCCION',N'Producto terminado de demostración.',@OperativoId,DATEADD(DAY,-20,@Ahora)),
      (@ArticuloProcesoSalida,N'Salida',@SedeZacapaProceso,NULL,60,N'DEMO-VENTA',N'Despacho a cliente.',@OperativoId,DATEADD(DAY,-8,@Ahora)),
      (@ArticuloProcesoSalida,N'Reserva',@SedeZacapaProceso,NULL,25,N'DEMO-RESERVA-PISO',N'Reserva para pedido aprobado.',@OperativoId,DATEADD(DAY,-2,@Ahora)),
      (@ArticuloConstruccion,N'Entrada',NULL,@SedeCentral,1000,N'DEMO-INICIAL-CON',N'Material ficticio inicial.',@GerenteId,DATEADD(DAY,-50,@Ahora)),
      (@ArticuloConstruccion,N'Salida',@SedeCentral,NULL,200,N'DEMO-OBRA-CONSUMO',N'Consumo acumulado de obras.',@GerenteId,DATEADD(DAY,-12,@Ahora)),
      (@ArticuloConstruccion,N'Reserva',@SedeCentral,NULL,100,N'DEMO-OBRA-RESERVA',N'Reserva para obra en ejecución.',@GerenteId,DATEADD(DAY,-3,@Ahora));

    /* Abastecimiento pendiente y ciclo recibido. */
    INSERT dbo.AbastecimientoSolicitud
      (GiroSolicitanteId,SedeSolicitanteId,GiroProveedorId,SedeProveedorId,SolicitanteUsuarioId,Estado,FechaNecesaria,Motivo)
    VALUES(@GiroProceso,@SedeZacapaProceso,@GiroExtraccion,@SedeCoban,@OperativoId,N'Solicitado',DATEADD(DAY,7,@Hoy),N'Reposición mensual de caliza DEMO.');
    DECLARE @AbastecimientoPendiente BIGINT=SCOPE_IDENTITY();
    INSERT dbo.AbastecimientoDetalle(AbastecimientoSolicitudId,ArticuloProveedorId,ArticuloDestinoId,Cantidad)
    VALUES(@AbastecimientoPendiente,@ArticuloMineral,@ArticuloProcesoEntrada,120);
    INSERT dbo.AbastecimientoHistorial(AbastecimientoSolicitudId,UsuarioId,EstadoAnterior,EstadoNuevo,Comentario,Fecha)
    VALUES(@AbastecimientoPendiente,@OperativoId,NULL,N'Solicitado',N'Solicitud pendiente para probar aprobación.',DATEADD(DAY,-1,@Ahora));

    INSERT dbo.AbastecimientoSolicitud
      (GiroSolicitanteId,SedeSolicitanteId,GiroProveedorId,SedeProveedorId,SolicitanteUsuarioId,Estado,FechaNecesaria,Motivo,FechaModificacion)
    VALUES(@GiroProceso,@SedeZacapaProceso,@GiroExtraccion,@SedeCoban,@OperativoId,N'Recibido',DATEADD(DAY,-2,@Hoy),N'Traslado completo de caliza DEMO.',@Ahora);
    DECLARE @AbastecimientoRecibido BIGINT=SCOPE_IDENTITY();
    INSERT dbo.AbastecimientoDetalle(AbastecimientoSolicitudId,ArticuloProveedorId,ArticuloDestinoId,Cantidad)
    VALUES(@AbastecimientoRecibido,@ArticuloMineral,@ArticuloProcesoEntrada,80);
    INSERT dbo.AbastecimientoHistorial(AbastecimientoSolicitudId,UsuarioId,EstadoAnterior,EstadoNuevo,Comentario,Fecha)
    VALUES
      (@AbastecimientoRecibido,@OperativoId,NULL,N'Solicitado',N'Solicitud creada.',DATEADD(DAY,-8,@Ahora)),
      (@AbastecimientoRecibido,@GerenteId,N'Solicitado',N'Aprobado',N'Solicitud aprobada.',DATEADD(DAY,-7,@Ahora)),
      (@AbastecimientoRecibido,@EmpleadoId,N'Aprobado',N'Preparacion',N'Producto reservado.',DATEADD(DAY,-6,@Ahora)),
      (@AbastecimientoRecibido,@EmpleadoId,N'Preparacion',N'Despachado',N'Carga despachada.',DATEADD(DAY,-5,@Ahora)),
      (@AbastecimientoRecibido,@OperativoId,N'Despachado',N'Recibido',N'Recepción confirmada.',DATEADD(DAY,-4,@Ahora));
    INSERT dbo.InventarioMovimiento(InventarioArticuloId,Tipo,SedeOrigenId,SedeDestinoId,Cantidad,Referencia,Observacion,UsuarioId,Fecha)
    VALUES
      (@ArticuloMineral,N'Salida',@SedeCoban,NULL,80,CONCAT(N'ABAST-',@AbastecimientoRecibido),N'Despacho entre giros.',@EmpleadoId,DATEADD(DAY,-5,@Ahora)),
      (@ArticuloProcesoEntrada,N'Entrada',NULL,@SedeZacapaProceso,80,CONCAT(N'ABAST-',@AbastecimientoRecibido),N'Recepción entre giros.',@OperativoId,DATEADD(DAY,-4,@Ahora));

    /* Extracción: registrada, confirmada y entregada. */
    INSERT dbo.ExtraccionJornada(SedeId,InventarioArticuloId,FechaOperacion,Turno,FrenteExtraccion,CantidadExtraida,CantidadRechazada,DestinoTipo,DestinoDescripcion,Estado,ResponsableUsuarioId,Observacion)
    VALUES(@SedeCoban,@ArticuloMineral,@Hoy,N'Matutino',N'Frente Norte DEMO',250,10,N'Inventario',N'Bodega principal',N'Registrada',@EmpleadoId,N'Lista para confirmar.');
    DECLARE @ExtraccionRegistrada BIGINT=SCOPE_IDENTITY();
    INSERT dbo.ExtraccionJornada(SedeId,InventarioArticuloId,FechaOperacion,Turno,FrenteExtraccion,CantidadExtraida,CantidadRechazada,DestinoTipo,DestinoDescripcion,Estado,ResponsableUsuarioId,Observacion,FechaModificacion)
    VALUES(@SedeCoban,@ArticuloMineral,DATEADD(DAY,-1,@Hoy),N'Vespertino',N'Frente Este DEMO',400,20,N'Procesamiento',N'Planta Zacapa',N'Confirmada',@EmpleadoId,N'Pendiente de entrega.',@Ahora);
    DECLARE @ExtraccionConfirmada BIGINT=SCOPE_IDENTITY();
    INSERT dbo.ExtraccionJornada(SedeId,InventarioArticuloId,FechaOperacion,Turno,FrenteExtraccion,CantidadExtraida,CantidadRechazada,DestinoTipo,DestinoDescripcion,Estado,ResponsableUsuarioId,Observacion,FechaModificacion)
    VALUES(@SedeCoban,@ArticuloMineral,DATEADD(DAY,-12,@Hoy),N'Matutino',N'Frente Sur DEMO',500,25,N'Transporte',N'Viaje interno completado',N'Entregada',@EmpleadoId,N'Jornada cerrada.',@Ahora);
    DECLARE @ExtraccionEntregada BIGINT=SCOPE_IDENTITY();
    INSERT dbo.ExtraccionHistorial(ExtraccionJornadaId,UsuarioId,EstadoAnterior,EstadoNuevo,Comentario,Fecha)
    VALUES
      (@ExtraccionRegistrada,@EmpleadoId,NULL,N'Registrada',N'Jornada creada.',@Ahora),
      (@ExtraccionConfirmada,@EmpleadoId,NULL,N'Registrada',N'Jornada creada.',DATEADD(DAY,-1,@Ahora)),
      (@ExtraccionConfirmada,@EmpleadoId,N'Registrada',N'Confirmada',N'Cantidades confirmadas.',@Ahora),
      (@ExtraccionEntregada,@EmpleadoId,NULL,N'Registrada',N'Jornada creada.',DATEADD(DAY,-12,@Ahora)),
      (@ExtraccionEntregada,@EmpleadoId,N'Registrada',N'Confirmada',N'Producción confirmada.',DATEADD(DAY,-11,@Ahora)),
      (@ExtraccionEntregada,@EmpleadoId,N'Confirmada',N'Entregada',N'Inventario entregado.',DATEADD(DAY,-10,@Ahora));

    /* Producción: planificada, en proceso y completada con tres etapas. */
    INSERT dbo.ProduccionOrden(SedeId,ArticuloEntradaId,ArticuloSalidaId,FechaPlanificada,CantidadEntrada,CantidadSalidaPlanificada,Estado,ResponsableUsuarioId,Observacion)
    VALUES(@SedeZacapaProceso,@ArticuloProcesoEntrada,@ArticuloProcesoSalida,DATEADD(DAY,3,@Hoy),200,180,N'Planificada',@OperativoId,N'Orden lista para iniciar.');
    DECLARE @ProduccionPlanificada BIGINT=SCOPE_IDENTITY();
    INSERT dbo.ProduccionOrden(SedeId,ArticuloEntradaId,ArticuloSalidaId,FechaPlanificada,CantidadEntrada,CantidadSalidaPlanificada,Estado,ResponsableUsuarioId,Observacion,FechaModificacion)
    VALUES(@SedeZacapaProceso,@ArticuloProcesoEntrada,@ArticuloProcesoSalida,@Hoy,300,270,N'EnProceso',@OperativoId,N'Orden en transformación.',@Ahora);
    DECLARE @ProduccionEnProceso BIGINT=SCOPE_IDENTITY();
    INSERT dbo.ProduccionOrden(SedeId,ArticuloEntradaId,ArticuloSalidaId,FechaPlanificada,CantidadEntrada,CantidadSalidaPlanificada,CantidadSalidaReal,CantidadMerma,CostoUnitario,Estado,ResponsableUsuarioId,Observacion,FechaModificacion)
    VALUES(@SedeZacapaProceso,@ArticuloProcesoEntrada,@ArticuloProcesoSalida,DATEADD(DAY,-20,@Hoy),500,450,445,55,18.50,N'Completada',@OperativoId,N'Lote de demostración completado.',@Ahora);
    DECLARE @ProduccionCompletada BIGINT=SCOPE_IDENTITY();

    INSERT dbo.ProduccionEtapa(ProduccionOrdenId,Secuencia,Nombre,Estado,FechaInicio,FechaFin,Observacion)
    VALUES
      (@ProduccionPlanificada,1,N'Preparación',N'Pendiente',NULL,NULL,NULL),
      (@ProduccionPlanificada,2,N'Transformación',N'Pendiente',NULL,NULL,NULL),
      (@ProduccionPlanificada,3,N'Control de calidad',N'Pendiente',NULL,NULL,NULL),
      (@ProduccionEnProceso,1,N'Preparación',N'Completada',DATEADD(HOUR,-8,@Ahora),DATEADD(HOUR,-6,@Ahora),N'Materia prima preparada.'),
      (@ProduccionEnProceso,2,N'Transformación',N'EnProceso',DATEADD(HOUR,-5,@Ahora),NULL,N'Hornos activos.'),
      (@ProduccionEnProceso,3,N'Control de calidad',N'Pendiente',NULL,NULL,NULL),
      (@ProduccionCompletada,1,N'Preparación',N'Completada',DATEADD(DAY,-20,@Ahora),DATEADD(DAY,-19,@Ahora),NULL),
      (@ProduccionCompletada,2,N'Transformación',N'Completada',DATEADD(DAY,-19,@Ahora),DATEADD(DAY,-18,@Ahora),NULL),
      (@ProduccionCompletada,3,N'Control de calidad',N'Completada',DATEADD(DAY,-18,@Ahora),DATEADD(DAY,-17,@Ahora),N'Lote aprobado.');
    INSERT dbo.ProduccionHistorial(ProduccionOrdenId,UsuarioId,EstadoAnterior,EstadoNuevo,Comentario,Fecha)
    VALUES
      (@ProduccionPlanificada,@OperativoId,NULL,N'Planificada',N'Orden creada.',@Ahora),
      (@ProduccionEnProceso,@OperativoId,NULL,N'Planificada',N'Orden creada.',DATEADD(DAY,-2,@Ahora)),
      (@ProduccionEnProceso,@OperativoId,N'Planificada',N'EnProceso',N'Producción iniciada.',DATEADD(DAY,-1,@Ahora)),
      (@ProduccionCompletada,@OperativoId,NULL,N'Planificada',N'Orden creada.',DATEADD(DAY,-20,@Ahora)),
      (@ProduccionCompletada,@OperativoId,N'Planificada',N'EnProceso',N'Producción iniciada.',DATEADD(DAY,-19,@Ahora)),
      (@ProduccionCompletada,@OperativoId,N'EnProceso',N'Completada',N'Producción finalizada.',DATEADD(DAY,-17,@Ahora));

    /* Maquinaria: disponibilidad, alquiler, reserva y mantenimiento. */
    INSERT dbo.MaquinariaEquipo(SedeId,Codigo,Tipo,Marca,Modelo,Anio,Estado,PrecioVenta,TarifaDiaria,HorasUso,Observacion)
    VALUES
      (@SedeGuatemalaMaquinaria,N'DEMO-EXC-001',N'Excavadora',N'Caterpillar',N'320',2022,N'Disponible',950000,2850,820,N'Equipo disponible para pruebas.'),
      (@SedeGuatemalaMaquinaria,N'DEMO-RET-002',N'Retroexcavadora',N'JCB',N'3CX',2021,N'Alquilada',620000,2400,1260,N'Contrato activo.'),
      (@SedeGuatemalaMaquinaria,N'DEMO-CAR-003',N'Cargador frontal',N'Volvo',N'L90H',2020,N'Mantenimiento',780000,2600,2150,N'Mantenimiento preventivo en curso.'),
      (@SedeGuatemalaMaquinaria,N'DEMO-COM-004',N'Compactadora',N'Bomag',N'BW211',2023,N'Reservada',540000,2100,430,N'Reservada por cliente.');
    DECLARE @EquipoDisponible INT=(SELECT MaquinariaEquipoId FROM dbo.MaquinariaEquipo WHERE Codigo=N'DEMO-EXC-001' AND Eliminado=0);
    DECLARE @EquipoAlquilado INT=(SELECT MaquinariaEquipoId FROM dbo.MaquinariaEquipo WHERE Codigo=N'DEMO-RET-002' AND Eliminado=0);
    DECLARE @EquipoMantenimiento INT=(SELECT MaquinariaEquipoId FROM dbo.MaquinariaEquipo WHERE Codigo=N'DEMO-CAR-003' AND Eliminado=0);
    DECLARE @EquipoReservado INT=(SELECT MaquinariaEquipoId FROM dbo.MaquinariaEquipo WHERE Codigo=N'DEMO-COM-004' AND Eliminado=0);

    INSERT dbo.MaquinariaContrato(MaquinariaEquipoId,ClienteId,Tipo,FechaInicio,FechaFin,MontoTotal,Deposito,Estado,HorasEntrega,HorasDevolucion,ResponsableUsuarioId,Observacion,FechaModificacion)
    VALUES(@EquipoAlquilado,@ClienteConstructora,N'Alquiler',DATEADD(DAY,-3,@Hoy),DATEADD(DAY,7,@Hoy),24000,5000,N'Activo',1250,NULL,@GerenteId,N'Equipo en obra.',@Ahora);
    DECLARE @ContratoActivo BIGINT=SCOPE_IDENTITY();
    INSERT dbo.MaquinariaContrato(MaquinariaEquipoId,ClienteId,Tipo,FechaInicio,FechaFin,MontoTotal,Deposito,Estado,HorasEntrega,HorasDevolucion,ResponsableUsuarioId,Observacion,FechaModificacion)
    VALUES(@EquipoDisponible,@ClienteConstructora,N'Alquiler',DATEADD(DAY,-40,@Hoy),DATEADD(DAY,-30,@Hoy),28500,5000,N'Finalizado',780,810,@GerenteId,N'Contrato histórico finalizado.',DATEADD(DAY,-30,@Ahora));
    DECLARE @ContratoFinalizado BIGINT=SCOPE_IDENTITY();
    INSERT dbo.MaquinariaContrato(MaquinariaEquipoId,ClienteId,Tipo,FechaInicio,FechaFin,MontoTotal,Deposito,Estado,ResponsableUsuarioId,Observacion)
    VALUES(@EquipoReservado,@ClienteConstructora,N'Alquiler',DATEADD(DAY,5,@Hoy),DATEADD(DAY,12,@Hoy),14700,3000,N'Reservado',@GerenteId,N'Reserva futura.');
    DECLARE @ContratoReservado BIGINT=SCOPE_IDENTITY();

    INSERT dbo.MaquinariaMantenimiento(MaquinariaEquipoId,Tipo,FechaProgramada,FechaCompletada,Costo,Estado,ResponsableUsuarioId,Observacion)
    VALUES
      (@EquipoDisponible,N'Revisión de 1000 horas',DATEADD(DAY,15,@Hoy),NULL,3200,N'Programado',@GerenteId,N'Mantenimiento próximo.'),
      (@EquipoMantenimiento,N'Cambio de sistema hidráulico',DATEADD(DAY,-2,@Hoy),NULL,18500,N'EnProceso',@GerenteId,N'Repuesto en instalación.'),
      (@EquipoAlquilado,N'Mantenimiento preventivo',DATEADD(DAY,-45,@Hoy),DATEADD(DAY,-44,@Hoy),2800,N'Completado',@GerenteId,N'Equipo liberado para alquiler.');

    /* Transporte: viajes programado, en ruta, entregado y cancelado. */
    INSERT dbo.TransporteVehiculo(SedeId,Placa,Tipo,Marca,Modelo,Capacidad,UnidadCapacidad,EsInternacional,Estado)
    VALUES
      (@SedeCentral,N'DEMO-T001',N'Cabezal',N'Freightliner',N'Cascadia',28,N't',1,N'Asignado'),
      (@SedeCentral,N'DEMO-T002',N'Camión',N'Hino',N'500',12,N't',0,N'Asignado'),
      (@SedeCentral,N'DEMO-T003',N'Cabezal',N'Kenworth',N'T680',30,N't',1,N'Disponible'),
      (@SedeCentral,N'DEMO-T004',N'Camión',N'Isuzu',N'FTR',10,N't',0,N'Disponible');
    INSERT dbo.TransporteConductor(Nombre,Licencia,Categoria,FechaVencimiento,Telefono,Estado)
    VALUES
      (N'Luis Pérez DEMO',N'DEMO-A001',N'A',DATEADD(YEAR,2,@Hoy),N'5555-0101',N'Asignado'),
      (N'Ana López DEMO',N'DEMO-A002',N'A',DATEADD(YEAR,3,@Hoy),N'5555-0102',N'Asignado'),
      (N'José Ramírez DEMO',N'DEMO-A003',N'A',DATEADD(YEAR,1,@Hoy),N'5555-0103',N'Disponible'),
      (N'Elena García DEMO',N'DEMO-A004',N'B',DATEADD(YEAR,2,@Hoy),N'5555-0104',N'Disponible');
    DECLARE @Vehiculo1 INT=(SELECT TransporteVehiculoId FROM dbo.TransporteVehiculo WHERE Placa=N'DEMO-T001' AND Eliminado=0);
    DECLARE @Vehiculo2 INT=(SELECT TransporteVehiculoId FROM dbo.TransporteVehiculo WHERE Placa=N'DEMO-T002' AND Eliminado=0);
    DECLARE @Vehiculo3 INT=(SELECT TransporteVehiculoId FROM dbo.TransporteVehiculo WHERE Placa=N'DEMO-T003' AND Eliminado=0);
    DECLARE @Vehiculo4 INT=(SELECT TransporteVehiculoId FROM dbo.TransporteVehiculo WHERE Placa=N'DEMO-T004' AND Eliminado=0);
    DECLARE @Conductor1 INT=(SELECT TransporteConductorId FROM dbo.TransporteConductor WHERE Licencia=N'DEMO-A001' AND Eliminado=0);
    DECLARE @Conductor2 INT=(SELECT TransporteConductorId FROM dbo.TransporteConductor WHERE Licencia=N'DEMO-A002' AND Eliminado=0);
    DECLARE @Conductor3 INT=(SELECT TransporteConductorId FROM dbo.TransporteConductor WHERE Licencia=N'DEMO-A003' AND Eliminado=0);
    DECLARE @Conductor4 INT=(SELECT TransporteConductorId FROM dbo.TransporteConductor WHERE Licencia=N'DEMO-A004' AND Eliminado=0);

    INSERT dbo.TransporteViaje(SedeId,TransporteVehiculoId,TransporteConductorId,ClienteId,Tipo,Origen,Destino,DescripcionCarga,PesoCarga,FechaSalidaPlanificada,Estado,ResponsableUsuarioId,Observacion)
    VALUES(@SedeCentral,@Vehiculo1,@Conductor1,@Cliente1Id,N'Internacional',N'Puerto Quetzal, Guatemala',N'San Salvador, El Salvador',N'Contenedor de materiales DEMO',22,DATEADD(DAY,2,@Ahora),N'Programado',@OperativoId,N'Documentación aduanera lista.');
    DECLARE @ViajeProgramado BIGINT=SCOPE_IDENTITY();
    INSERT dbo.TransporteViaje(SedeId,TransporteVehiculoId,TransporteConductorId,ClienteId,Tipo,Origen,Destino,DescripcionCarga,PesoCarga,FechaSalidaPlanificada,FechaSalidaReal,Estado,ResponsableUsuarioId,Observacion,FechaModificacion)
    VALUES(@SedeCentral,@Vehiculo2,@Conductor2,@ClienteConstructora,N'Nacional',N'Ciudad de Guatemala',N'Cobán, Alta Verapaz',N'Cemento y herramienta DEMO',9.5,DATEADD(HOUR,-8,@Ahora),DATEADD(HOUR,-7,@Ahora),N'EnRuta',@OperativoId,N'Viaje en seguimiento GPS.',@Ahora);
    DECLARE @ViajeEnRuta BIGINT=SCOPE_IDENTITY();
    INSERT dbo.TransporteViaje(SedeId,TransporteVehiculoId,TransporteConductorId,ClienteId,Tipo,Origen,Destino,DescripcionCarga,PesoCarga,FechaSalidaPlanificada,FechaSalidaReal,FechaEntrega,Estado,ResponsableUsuarioId,Observacion,FechaModificacion)
    VALUES(@SedeCentral,@Vehiculo3,@Conductor3,@ClienteCeramica,N'Internacional',N'Quetzaltenango, Guatemala',N'Tapachula, México',N'Piso cerámico DEMO',24,DATEADD(DAY,-10,@Ahora),DATEADD(DAY,-10,@Ahora),DATEADD(DAY,-9,@Ahora),N'Entregado',@OperativoId,N'Entrega confirmada.',DATEADD(DAY,-9,@Ahora));
    DECLARE @ViajeEntregado BIGINT=SCOPE_IDENTITY();
    INSERT dbo.TransporteViaje(SedeId,TransporteVehiculoId,TransporteConductorId,ClienteId,Tipo,Origen,Destino,DescripcionCarga,PesoCarga,FechaSalidaPlanificada,Estado,ResponsableUsuarioId,Observacion,FechaModificacion)
    VALUES(@SedeCentral,@Vehiculo4,@Conductor4,@ClienteMinerales,N'MateriaPrima',N'Cobán',N'Zacapa',N'Caliza DEMO',8,DATEADD(DAY,-5,@Ahora),N'Cancelado',@OperativoId,N'Cancelado por solicitud del cliente.',DATEADD(DAY,-4,@Ahora));
    DECLARE @ViajeCancelado BIGINT=SCOPE_IDENTITY();

    INSERT dbo.TransporteIncidencia(TransporteViajeId,Tipo,Severidad,Descripcion,Resuelta,Resolucion,UsuarioId,Fecha,FechaResolucion)
    VALUES
      (@ViajeEnRuta,N'Tráfico',N'Media',N'Congestión en ruta al Atlántico.',0,NULL,@OperativoId,DATEADD(HOUR,-2,@Ahora),NULL),
      (@ViajeEntregado,N'Llanta',N'Alta',N'Pinchazo resuelto durante el trayecto.',1,N'Llanta sustituida y unidad inspeccionada.',@OperativoId,DATEADD(DAY,-10,@Ahora),DATEADD(DAY,-10,@Ahora));

    /* GPS simulado con posiciones de Ciudad de Guatemala y alertas. */
    INSERT dbo.GpsDispositivo(IdentificadorExterno,NombreActivo,TransporteVehiculoId,MaquinariaEquipoId,Proveedor,VelocidadMaxima,UltimaSincronizacion)
    VALUES
      (N'DEMO-GPS-TRUCK-02',N'Camión DEMO-T002',@Vehiculo2,NULL,N'GPS-Simulado',80,@Ahora),
      (N'DEMO-GPS-MAQ-03',N'Cargador DEMO-CAR-003',NULL,@EquipoMantenimiento,N'GPS-Simulado',25,@Ahora);
    DECLARE @GpsVehiculo INT=(SELECT GpsDispositivoId FROM dbo.GpsDispositivo WHERE IdentificadorExterno=N'DEMO-GPS-TRUCK-02' AND Eliminado=0);
    DECLARE @GpsMaquinaria INT=(SELECT GpsDispositivoId FROM dbo.GpsDispositivo WHERE IdentificadorExterno=N'DEMO-GPS-MAQ-03' AND Eliminado=0);
    INSERT dbo.GpsPosicion(GpsDispositivoId,FechaEvento,Latitud,Longitud,Velocidad,HorasUso,Kilometraje,Evento,OrigenDato,DatosFuente)
    VALUES(@GpsVehiculo,DATEADD(MINUTE,-40,@Ahora),14.634915,-90.506882,42,NULL,125430,N'Posición',N'Simulado',N'{"latitud":14.634915,"longitud":-90.506882,"ciudad":"Guatemala"}');
    DECLARE @PosicionNormal BIGINT=SCOPE_IDENTITY();
    INSERT dbo.GpsPosicion(GpsDispositivoId,FechaEvento,Latitud,Longitud,Velocidad,HorasUso,Kilometraje,Evento,OrigenDato,DatosFuente)
    VALUES(@GpsVehiculo,DATEADD(MINUTE,-15,@Ahora),14.655000,-90.490000,96,NULL,125455,N'ExcesoVelocidad',N'Simulado',N'{"latitud":14.655,"longitud":-90.49,"velocidad":96}');
    DECLARE @PosicionRapida BIGINT=SCOPE_IDENTITY();
    INSERT dbo.GpsPosicion(GpsDispositivoId,FechaEvento,Latitud,Longitud,Velocidad,HorasUso,Kilometraje,Evento,OrigenDato,DatosFuente)
    VALUES(@GpsMaquinaria,DATEADD(HOUR,-3,@Ahora),14.589000,-90.520000,0,2150,NULL,N'Encendido',N'Simulado',N'{"latitud":14.589,"longitud":-90.52,"horasUso":2150}');
    DECLARE @PosicionMaquina BIGINT=SCOPE_IDENTITY();
    INSERT dbo.GpsAlerta(GpsDispositivoId,GpsPosicionId,Tipo,Severidad,Mensaje,Atendida,AtendidaPorUsuarioId,Fecha,FechaAtencion)
    VALUES
      (@GpsVehiculo,@PosicionRapida,N'Velocidad',N'Alta',N'Velocidad de 96 km/h supera el máximo de 80 km/h.',0,NULL,DATEADD(MINUTE,-15,@Ahora),NULL),
      (@GpsMaquinaria,@PosicionMaquina,N'Mantenimiento',N'Media',N'Equipo alcanzó el umbral de horas de mantenimiento.',1,@GerenteId,DATEADD(HOUR,-3,@Ahora),DATEADD(HOUR,-2,@Ahora));

    /* Construcción: proyecto por iniciar, en ejecución y completado. */
    INSERT dbo.ConstruccionProyecto(SedeId,ClienteId,Nombre,TipoObra,Ubicacion,FechaInicioPlanificada,FechaFinPlanificada,Presupuesto,Estado,ResponsableUsuarioId,Descripcion)
    VALUES(@SedeCentral,@ClienteConstructora,N'DEMO - Remodelación de oficinas',N'Edificio',N'Zona 10, Ciudad de Guatemala',DATEADD(DAY,10,@Hoy),DATEADD(DAY,70,@Hoy),450000,N'Planificado',@GerenteId,N'Proyecto listo para iniciar.');
    DECLARE @ObraPlanificada BIGINT=SCOPE_IDENTITY();
    INSERT dbo.ConstruccionProyecto(SedeId,ClienteId,Nombre,TipoObra,Ubicacion,FechaInicioPlanificada,FechaFinPlanificada,Presupuesto,Estado,ResponsableUsuarioId,Descripcion,FechaModificacion)
    VALUES(@SedeCentral,@ClienteConstructora,N'DEMO - Puente Las Flores',N'Puente',N'Villa Canales, Guatemala',DATEADD(DAY,-30,@Hoy),DATEADD(DAY,90,@Hoy),1800000,N'EnEjecucion',@GerenteId,N'Obra con avances y recursos.',@Ahora);
    DECLARE @ObraEnEjecucion BIGINT=SCOPE_IDENTITY();
    INSERT dbo.ConstruccionProyecto(SedeId,ClienteId,Nombre,TipoObra,Ubicacion,FechaInicioPlanificada,FechaFinPlanificada,Presupuesto,Estado,ResponsableUsuarioId,Descripcion,FechaModificacion)
    VALUES(@SedeCentral,@ClienteConstructora,N'DEMO - Bodega logística',N'Edificio',N'Amatitlán, Guatemala',DATEADD(DAY,-120,@Hoy),DATEADD(DAY,-20,@Hoy),950000,N'Completado',@GerenteId,N'Proyecto histórico completado.',DATEADD(DAY,-18,@Ahora));
    DECLARE @ObraCompletada BIGINT=SCOPE_IDENTITY();

    INSERT dbo.ConstruccionActividad(ConstruccionProyectoId,Nombre,ResponsableUsuarioId,FechaInicio,FechaFin,Presupuesto,PorcentajeAvance,Estado,Observacion)
    VALUES(@ObraEnEjecucion,N'Cimentación',@GerenteId,DATEADD(DAY,-30,@Hoy),DATEADD(DAY,10,@Hoy),420000,60,N'EnProceso',N'Avance según programa.');
    DECLARE @ActividadCimentacion BIGINT=SCOPE_IDENTITY();
    INSERT dbo.ConstruccionActividad(ConstruccionProyectoId,Nombre,ResponsableUsuarioId,FechaInicio,FechaFin,Presupuesto,PorcentajeAvance,Estado,Observacion)
    VALUES(@ObraEnEjecucion,N'Estructura',@GerenteId,DATEADD(DAY,5,@Hoy),DATEADD(DAY,50,@Hoy),780000,20,N'EnProceso',N'Preparación de acero.');
    DECLARE @ActividadEstructura BIGINT=SCOPE_IDENTITY();
    INSERT dbo.ConstruccionActividad(ConstruccionProyectoId,Nombre,ResponsableUsuarioId,FechaInicio,FechaFin,Presupuesto,PorcentajeAvance,Estado,Observacion)
    VALUES(@ObraCompletada,N'Construcción integral',@GerenteId,DATEADD(DAY,-120,@Hoy),DATEADD(DAY,-20,@Hoy),900000,100,N'Completada',N'Actividad cerrada.');
    DECLARE @ActividadCompletada BIGINT=SCOPE_IDENTITY();
    INSERT dbo.ConstruccionAvance(ConstruccionActividadId,PorcentajeAnterior,PorcentajeNuevo,Comentario,EvidenciaUrl,UsuarioId,Fecha)
    VALUES
      (@ActividadCimentacion,0,35,N'Fundición inicial completada.',N'https://example.local/evidencias/cimentacion-35.jpg',@GerenteId,DATEADD(DAY,-15,@Ahora)),
      (@ActividadCimentacion,35,60,N'Zapatas y vigas de amarre listas.',N'https://example.local/evidencias/cimentacion-60.jpg',@GerenteId,DATEADD(DAY,-3,@Ahora)),
      (@ActividadEstructura,0,20,N'Armado inicial de columnas.',N'https://example.local/evidencias/estructura-20.jpg',@GerenteId,DATEADD(DAY,-2,@Ahora)),
      (@ActividadCompletada,0,100,N'Bodega entregada al cliente.',N'https://example.local/evidencias/bodega-final.jpg',@GerenteId,DATEADD(DAY,-20,@Ahora));
    INSERT dbo.ConstruccionRecurso(ConstruccionProyectoId,ConstruccionActividadId,Tipo,Descripcion,Cantidad,Unidad,CostoUnitario,InventarioArticuloId,MaquinariaEquipoId,UsuarioId,Fecha)
    VALUES
      (@ObraEnEjecucion,@ActividadCimentacion,N'Material',N'Cemento para cimentación',200,N'saco',82,@ArticuloConstruccion,NULL,@GerenteId,DATEADD(DAY,-15,@Ahora)),
      (@ObraEnEjecucion,@ActividadCimentacion,N'Maquinaria',N'Excavadora para movimiento de tierra',5,N'día',2850,NULL,@EquipoDisponible,@GerenteId,DATEADD(DAY,-18,@Ahora)),
      (@ObraEnEjecucion,@ActividadEstructura,N'Personal',N'Cuadrilla de armado',120,N'hora',45,NULL,NULL,@GerenteId,DATEADD(DAY,-5,@Ahora)),
      (@ObraCompletada,@ActividadCompletada,N'Otro',N'Inspección final',1,N'servicio',6500,NULL,NULL,@GerenteId,DATEADD(DAY,-20,@Ahora));

    /* Presupuestos y gastos reales por giro/sede. */
    INSERT dbo.FinanzaPresupuesto(GiroNegocioId,SedeId,Anio,Mes,Nombre,Monto,Estado,CreadoPorUsuarioId,Observacion)
    VALUES(@GiroExtraccion,@SedeCoban,@Anio,@Mes,N'DEMO - Operación minera mensual',250000,N'Abierto',@GerenteId,N'Presupuesto ficticio para extracción.');
    DECLARE @PresupuestoExtraccion BIGINT=SCOPE_IDENTITY();
    INSERT dbo.FinanzaPresupuesto(GiroNegocioId,SedeId,Anio,Mes,Nombre,Monto,Estado,CreadoPorUsuarioId,Observacion)
    VALUES(@GiroProceso,@SedeZacapaProceso,@Anio,@Mes,N'DEMO - Producción mensual',400000,N'Abierto',@GerenteId,N'Presupuesto ficticio para procesamiento.');
    DECLARE @PresupuestoProceso BIGINT=SCOPE_IDENTITY();
    INSERT dbo.FinanzaPresupuesto(GiroNegocioId,SedeId,Anio,Mes,Nombre,Monto,Estado,CreadoPorUsuarioId,Observacion,FechaModificacion)
    VALUES(@GiroConstruccion,@SedeCentral,@Anio,@Mes,N'DEMO - Obras mensual',1200000,N'Cerrado',@GerenteId,N'Presupuesto cerrado con ejecución.',@Ahora);
    DECLARE @PresupuestoConstruccion BIGINT=SCOPE_IDENTITY();
    INSERT dbo.FinanzaPresupuesto(GiroNegocioId,SedeId,Anio,Mes,Nombre,Monto,Estado,CreadoPorUsuarioId,Observacion)
    VALUES(@GiroTransporte,@SedeCentral,@Anio,@Mes,N'DEMO - Transporte mensual',300000,N'Abierto',@GerenteId,N'Presupuesto ficticio de logística.');
    DECLARE @PresupuestoTransporte BIGINT=SCOPE_IDENTITY();
    INSERT dbo.FinanzaGasto(FinanzaPresupuestoId,Fecha,Categoria,Concepto,Monto,OrigenModulo,OrigenRegistroId,Referencia,UsuarioId)
    VALUES
      (@PresupuestoExtraccion,DATEADD(DAY,-5,@Hoy),N'Personal',N'Pago de cuadrilla minera DEMO',42000,N'Manual',NULL,N'NOM-DEMO-001',@GerenteId),
      (@PresupuestoProceso,DATEADD(DAY,-3,@Hoy),N'Material',N'Costo del lote de producción DEMO',92500,N'Produccion',@ProduccionCompletada,N'PROD-DEMO',@GerenteId),
      (@PresupuestoConstruccion,DATEADD(DAY,-8,@Hoy),N'Material',N'Materiales del puente DEMO',185000,N'Construccion',@ObraEnEjecucion,N'OBRA-DEMO',@GerenteId),
      (@PresupuestoConstruccion,DATEADD(DAY,-6,@Hoy),N'Servicios',N'Evaluación técnica comercial',24000,N'Pedido',@PedidoCompletado,N'PED-DEMO',@GerenteId),
      (@PresupuestoTransporte,DATEADD(DAY,-9,@Hoy),N'Transporte',N'Costo del viaje entregado DEMO',18500,N'Transporte',@ViajeEntregado,N'VIAJE-DEMO',@GerenteId);

    /* Ingresos manuales y vinculados a los cuatro orígenes operativos. */
    INSERT dbo.FinanzaIngreso(GiroNegocioId,SedeId,ClienteId,Fecha,Categoria,Concepto,Monto,OrigenModulo,OrigenRegistroId,Referencia,UsuarioId)
    VALUES
      (@GiroExtraccion,@SedeCoban,@ClienteMinerales,DATEADD(DAY,-5,@Hoy),N'VentaProducto',N'Venta de caliza DEMO',43750,N'Manual',NULL,N'FAC-DEMO-001',@GerenteId),
      (@GiroProceso,@SedeZacapaProceso,@ClienteMinerales,DATEADD(DAY,-2,@Hoy),N'VentaProducto',N'Pedido de piso aprobado DEMO',18900,N'Pedido',@PedidoAprobado,N'FAC-DEMO-002',@GerenteId),
      (@GiroMaquinaria,@SedeGuatemalaMaquinaria,@ClienteConstructora,DATEADD(DAY,-30,@Hoy),N'Alquiler',N'Alquiler finalizado de excavadora DEMO',28500,N'Maquinaria',@ContratoFinalizado,N'FAC-DEMO-003',@GerenteId),
      (@GiroTransporte,@SedeCentral,@ClienteCeramica,DATEADD(DAY,-9,@Hoy),N'Transporte',N'Viaje internacional entregado DEMO',32000,N'Transporte',@ViajeEntregado,N'FAC-DEMO-004',@GerenteId),
      (@GiroConstruccion,@SedeCentral,@ClienteConstructora,DATEADD(DAY,-20,@Hoy),N'Construccion',N'Entrega de bodega logística DEMO',950000,N'Construccion',@ObraCompletada,N'FAC-DEMO-005',@GerenteId);

    /* Alertas activas, leídas, críticas y resueltas. */
    INSERT dbo.AlertaNotificacion(Tipo,Titulo,Mensaje,Severidad,RolId,GiroNegocioId,SedeId,UsuarioDestinoId,FechaProgramadaUtc,FechaVencimientoUtc,ModuloOrigen,RegistroOrigenId,Estado,CreadoPorUsuarioId)
    VALUES(N'Alerta',N'DEMO - Stock de caliza cercano al mínimo',N'Revisar abastecimiento de la planta de extracción.',N'Advertencia',@RolEmpleado,@GiroExtraccion,@SedeCoban,@EmpleadoId,DATEADD(HOUR,-2,@Ahora),DATEADD(DAY,2,@Ahora),N'Inventario',@ArticuloMineral,N'Activa',@AdminId);
    DECLARE @AlertaInventario BIGINT=SCOPE_IDENTITY();
    INSERT dbo.AlertaNotificacion(Tipo,Titulo,Mensaje,Severidad,RolId,GiroNegocioId,SedeId,UsuarioDestinoId,FechaProgramadaUtc,FechaVencimientoUtc,ModuloOrigen,RegistroOrigenId,Estado,CreadoPorUsuarioId)
    VALUES(N'Alerta',N'DEMO - Exceso de velocidad',N'Atender alerta GPS del viaje en ruta.',N'Critica',@RolOperativo,@GiroTransporte,@SedeCentral,@OperativoId,DATEADD(MINUTE,-15,@Ahora),DATEADD(DAY,1,@Ahora),N'GPS',@ViajeEnRuta,N'Activa',@AdminId);
    DECLARE @AlertaGps BIGINT=SCOPE_IDENTITY();
    INSERT dbo.AlertaNotificacion(Tipo,Titulo,Mensaje,Severidad,RolId,GiroNegocioId,SedeId,UsuarioDestinoId,FechaProgramadaUtc,FechaVencimientoUtc,ModuloOrigen,RegistroOrigenId,Estado,CreadoPorUsuarioId,FechaModificacion)
    VALUES(N'Recordatorio',N'DEMO - Mantenimiento atendido',N'El mantenimiento preventivo fue registrado.',N'Informativa',@RolGerente,@GiroMaquinaria,@SedeGuatemalaMaquinaria,@GerenteId,DATEADD(DAY,-5,@Ahora),DATEADD(DAY,-1,@Ahora),N'Maquinaria',@EquipoAlquilado,N'Resuelta',@AdminId,@Ahora);
    DECLARE @AlertaResuelta BIGINT=SCOPE_IDENTITY();
    INSERT dbo.AlertaLectura(AlertaNotificacionId,UsuarioId,FechaLectura)
    VALUES(@AlertaInventario,@EmpleadoId,DATEADD(HOUR,-1,@Ahora)),(@AlertaGps,@OperativoId,DATEADD(MINUTE,-10,@Ahora)),(@AlertaResuelta,@GerenteId,DATEADD(DAY,-4,@Ahora));
    INSERT dbo.AlertaSeguimiento(AlertaNotificacionId,UsuarioId,Comentario,Fecha)
    VALUES
      (@AlertaGps,@OperativoId,N'Conductor contactado; se normalizó la velocidad.',DATEADD(MINUTE,-5,@Ahora)),
      (@AlertaResuelta,@GerenteId,N'Mantenimiento verificado y equipo liberado.',DATEADD(DAY,-3,@Ahora));

    /* Comunicación de cliente e interna, con mensajes públicos y notas privadas. */
    INSERT dbo.ComunicacionHilo(Tipo,ClienteId,GiroNegocioId,PedidoId,Asunto,Estado,ResponsableUsuarioId,ModuloOrigen,RegistroOrigenId,CreadoPorUsuarioId,UltimaActividad)
    VALUES(N'Cliente',@Cliente1Id,@GiroTransporte,@PedidoSolicitado,N'DEMO - Consulta sobre documentación aduanera',N'Abierta',@VendedorId,N'Pedidos',@PedidoSolicitado,@Cliente1UsuarioId,@Ahora);
    DECLARE @HiloCliente BIGINT=SCOPE_IDENTITY();
    INSERT dbo.ComunicacionHilo(Tipo,ClienteId,GiroNegocioId,PedidoId,Asunto,Estado,ResponsableUsuarioId,ModuloOrigen,RegistroOrigenId,CreadoPorUsuarioId,UltimaActividad,FechaModificacion)
    VALUES(N'Cliente',@ClienteConstructora,@GiroConstruccion,@PedidoCompletado,N'DEMO - Entrega de informe técnico',N'Cerrada',@VendedorId,N'Construccion',@ObraCompletada,@Cliente3UsuarioId,DATEADD(DAY,-18,@Ahora),DATEADD(DAY,-18,@Ahora));
    DECLARE @HiloCerrado BIGINT=SCOPE_IDENTITY();
    INSERT dbo.ComunicacionHilo(Tipo,ClienteId,GiroNegocioId,PedidoId,Asunto,Estado,ResponsableUsuarioId,ModuloOrigen,RegistroOrigenId,CreadoPorUsuarioId,UltimaActividad)
    VALUES(N'Interna',NULL,@GiroTransporte,NULL,N'DEMO - Coordinación por incidencia en ruta',N'Abierta',@OperativoId,N'Transporte',@ViajeEnRuta,@GerenteId,@Ahora);
    DECLARE @HiloInterno BIGINT=SCOPE_IDENTITY();
    INSERT dbo.ComunicacionMensaje(ComunicacionHiloId,UsuarioId,Mensaje,EsInterno,Fecha)
    VALUES
      (@HiloCliente,@Cliente1UsuarioId,N'¿Qué documentos necesita el conductor en frontera?',0,DATEADD(HOUR,-3,@Ahora)),
      (@HiloCliente,@VendedorId,N'Se requieren factura, manifiesto y declaración aduanera.',0,DATEADD(HOUR,-2,@Ahora)),
      (@HiloCliente,@VendedorId,N'Nota interna: validar número de marchamo antes de salir.',1,DATEADD(HOUR,-1,@Ahora)),
      (@HiloCerrado,@Cliente3UsuarioId,N'Recibimos el informe técnico correctamente.',0,DATEADD(DAY,-19,@Ahora)),
      (@HiloCerrado,@VendedorId,N'Gracias. Cerramos la consulta.',0,DATEADD(DAY,-18,@Ahora)),
      (@HiloInterno,@GerenteId,N'Confirmar que la unidad retome la velocidad autorizada.',1,DATEADD(MINUTE,-12,@Ahora)),
      (@HiloInterno,@OperativoId,N'Conductor notificado; seguimiento activo.',1,DATEADD(MINUTE,-5,@Ahora));

    /* Integraciones simuladas, incluida la marca idempotente de este conjunto. */
    INSERT dbo.InventarioMovimiento(InventarioArticuloId,Tipo,SedeOrigenId,SedeDestinoId,Cantidad,Referencia,Observacion,UsuarioId,Fecha)
    VALUES(@ArticuloMineral,N'Entrada',NULL,@SedeCoban,75,N'DEMO-EXT-001',N'Recepción externa simulada.',@GerenteId,DATEADD(DAY,-1,@Ahora));
    DECLARE @MovimientoExterno BIGINT=SCOPE_IDENTITY();
    INSERT dbo.IntegracionEvento(Canal,Direccion,SocioTipo,SocioNombre,Operacion,ClaveIdempotencia,DocumentoExterno,Contenido,Estado,Intentos,InventarioArticuloId,SedeId,Cantidad,InventarioMovimientoId,UsuarioId,FechaProcesamiento)
    VALUES(N'Webhook',N'Entrada',N'Proveedor',N'Cantera Externa DEMO',N'RecepcionMateriaPrima',N'DEMO-SEED-V1',N'REC-DEMO-001',N'{"articulo":"DEMO-MIN-CALIZA","cantidad":75,"latitud":14.634915,"longitud":-90.506882,"origen":"simulado"}',N'Procesado',1,@ArticuloMineral,@SedeCoban,75,@MovimientoExterno,@GerenteId,DATEADD(DAY,-1,@Ahora));
    INSERT dbo.IntegracionEvento(Canal,Direccion,SocioTipo,SocioNombre,Operacion,ClaveIdempotencia,DocumentoExterno,Contenido,Estado,Intentos,Error,UsuarioId,FechaProcesamiento)
    VALUES
      (N'CSV',N'Entrada',N'Proveedor',N'Proveedor CSV DEMO',N'IntercambioDatos',N'DEMO-CSV-ERROR-001',N'lote-invalido.csv',N'codigo,cantidad\nDESCONOCIDO,-5',N'Error',2,N'El artículo o la cantidad del archivo no es válido.',@GerenteId,@Ahora),
      (N'REST',N'Salida',N'Cliente',N'Constructora Horizonte',N'EstadoPedido',N'DEMO-REST-SALIDA-001',N'PED-DEMO-001',N'{"estado":"Completado","origen":"simulado"}',N'Procesado',1,NULL,@VendedorId,@Ahora);

    /* Auditoría ficticia útil para filtros administrativos. */
    INSERT dbo.Auditoria(UsuarioId,Fecha,Modulo,TipoOperacion,IdentificadorRegistro,Resultado,Detalle)
    VALUES
      (@AdminId,DATEADD(DAY,-30,@Ahora),N'DatosDemo',N'Instalar',N'DEMO-SEED-V1',N'Exitoso',N'Conjunto integral de datos ficticios.'),
      (@VendedorId,DATEADD(DAY,-6,@Ahora),N'Pedidos',N'CotizarLinea',CONVERT(NVARCHAR(100),@PedidoCotizado),N'Exitoso',N'Cotización ficticia de caliza.'),
      (@OperativoId,DATEADD(DAY,-4,@Ahora),N'Abastecimiento',N'Recibir',CONVERT(NVARCHAR(100),@AbastecimientoRecibido),N'Exitoso',N'Recepción entre giros.'),
      (@EmpleadoId,DATEADD(DAY,-10,@Ahora),N'Extraccion',N'CambiarEstado',CONVERT(NVARCHAR(100),@ExtraccionEntregada),N'Exitoso',N'Entregada'),
      (@OperativoId,DATEADD(DAY,-17,@Ahora),N'Produccion',N'Completar',CONVERT(NVARCHAR(100),@ProduccionCompletada),N'Exitoso',N'Lote completado.'),
      (@GerenteId,DATEADD(DAY,-3,@Ahora),N'Maquinaria',N'CrearContrato',CONVERT(NVARCHAR(100),@ContratoActivo),N'Exitoso',N'Alquiler activo.'),
      (@OperativoId,DATEADD(DAY,-9,@Ahora),N'Transporte',N'CambiarEstado',CONVERT(NVARCHAR(100),@ViajeEntregado),N'Exitoso',N'Entregado'),
      (@GerenteId,DATEADD(HOUR,-2,@Ahora),N'GPS',N'AtenderAlerta',CONVERT(NVARCHAR(100),@GpsMaquinaria),N'Exitoso',N'Alerta simulada atendida.'),
      (@GerenteId,DATEADD(DAY,-3,@Ahora),N'Construccion',N'RegistrarAvance',CONVERT(NVARCHAR(100),@ObraEnEjecucion),N'Exitoso',N'Avance 60 por ciento.'),
      (@GerenteId,DATEADD(DAY,-2,@Ahora),N'Finanzas',N'RegistrarIngreso',N'DEMO',N'Exitoso',N'Ingresos ficticios vinculados.'),
      (@AdminId,DATEADD(MINUTE,-15,@Ahora),N'Alertas',N'Crear',CONVERT(NVARCHAR(100),@AlertaGps),N'Exitoso',N'Critica'),
      (@Cliente1UsuarioId,DATEADD(HOUR,-3,@Ahora),N'Comunicaciones',N'Crear',CONVERT(NVARCHAR(100),@HiloCliente),N'Exitoso',N'Consulta de cliente.'),
      (@GerenteId,DATEADD(DAY,-1,@Ahora),N'Integraciones',N'Procesar',N'DEMO-SEED-V1',N'Exitoso',N'Webhook simulado.');

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

PRINT N'Datos ficticios integrales DEMO-SEED-V1 instalados correctamente.';
GO

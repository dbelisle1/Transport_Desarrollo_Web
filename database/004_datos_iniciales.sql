USE [TransPortDB];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    MERGE dbo.Rol AS destino
    USING (VALUES
        (N'AdministradorGeneral',N'Acceso global de administración.'),
        (N'Gerente',N'Gestión de giros y sedes asignados.'),
        (N'Empleado',N'Acceso interno estándar.'),
        (N'Operativo',N'Acceso a operaciones asignadas.'),
        (N'Vendedor',N'Acceso comercial asignado.'),
        (N'Cliente',N'Acceso a empresas cliente asociadas.')
    ) AS fuente(Nombre,Descripcion) ON destino.Nombre=fuente.Nombre
    WHEN MATCHED THEN UPDATE SET Descripcion=fuente.Descripcion,EsActivo=1,Eliminado=0,FechaModificacion=SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT(Nombre,Descripcion) VALUES(fuente.Nombre,fuente.Descripcion);

    MERGE dbo.GiroNegocio AS destino
    USING (VALUES
        (N'Extracción minera',N'Extracción de materia prima mineral.'),
        (N'Procesamiento de materia prima',N'Producción de pisos cerámicos y materiales de construcción.'),
        (N'Venta y alquiler de maquinaria',N'Maquinaria para proyectos de construcción.'),
        (N'Transporte de materia prima',N'Transporte de materia prima para empresas.'),
        (N'Transporte nacional e internacional',N'Transporte entre puertos, fronteras y bodegas.'),
        (N'Servicios de construcción',N'Construcción de puentes, carreteras y edificios.')
    ) AS fuente(Nombre,Descripcion) ON destino.Nombre=fuente.Nombre
    WHEN MATCHED THEN UPDATE SET Descripcion=fuente.Descripcion,EsActivo=1,Eliminado=0,FechaModificacion=SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT(Nombre,Descripcion) VALUES(fuente.Nombre,fuente.Descripcion);

    MERGE dbo.CatalogoOferta AS destino
    USING
    (
        SELECT g.GiroNegocioId,v.Codigo,v.Tipo,v.Nombre,v.Descripcion,v.UnidadMedida,v.PrecioBase
        FROM (VALUES
            (N'Extracción minera',N'MIN-CALIZA-TON',N'Producto',N'Piedra caliza seleccionada',N'Materia prima mineral clasificada para procesos industriales.',N'Tonelada',CAST(425.00 AS DECIMAL(18,2))),
            (N'Procesamiento de materia prima',N'PRO-PISO-45',N'Producto',N'Piso cerámico 45 x 45 cm',N'Caja de piso cerámico para interiores, disponible bajo pedido.',N'Caja',CAST(189.00 AS DECIMAL(18,2))),
            (N'Venta y alquiler de maquinaria',N'MAQ-EXC-DIA',N'Servicio',N'Alquiler diario de excavadora',N'Excavadora con horómetro y mantenimiento vigente; transporte no incluido.',N'Día',CAST(2850.00 AS DECIMAL(18,2))),
            (N'Transporte de materia prima',N'TMP-VIAJE-LOCAL',N'Servicio',N'Transporte local de materia prima',N'Viaje programado de materia prima entre planta y centro de procesamiento.',N'Viaje',CAST(1650.00 AS DECIMAL(18,2))),
            (N'Transporte nacional e internacional',N'TNI-CARGA-NAC',N'Servicio',N'Transporte nacional de carga',N'Traslado terrestre entre bodegas, puertos o fronteras dentro de Guatemala.',N'Viaje',CAST(3200.00 AS DECIMAL(18,2))),
            (N'Servicios de construcción',N'CON-EVAL-TEC',N'Servicio',N'Evaluación técnica de obra',N'Visita inicial y diagnóstico para proyectos de infraestructura.',N'Visita',CAST(1200.00 AS DECIMAL(18,2)))
        ) v(GiroNombre,Codigo,Tipo,Nombre,Descripcion,UnidadMedida,PrecioBase)
        INNER JOIN dbo.GiroNegocio g ON g.Nombre=v.GiroNombre AND g.Eliminado=0
    ) AS fuente
    ON destino.Codigo=fuente.Codigo
    WHEN MATCHED THEN UPDATE SET GiroNegocioId=fuente.GiroNegocioId,Tipo=fuente.Tipo,Nombre=fuente.Nombre,
        Descripcion=fuente.Descripcion,UnidadMedida=fuente.UnidadMedida,PrecioBase=fuente.PrecioBase,
        EsPublico=1,EsActivo=1,Eliminado=0,FechaModificacion=SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT(GiroNegocioId,Codigo,Tipo,Nombre,Descripcion,UnidadMedida,PrecioBase,EsPublico,EsActivo)
        VALUES(fuente.GiroNegocioId,fuente.Codigo,fuente.Tipo,fuente.Nombre,fuente.Descripcion,fuente.UnidadMedida,fuente.PrecioBase,1,1);

    MERGE dbo.Sede AS destino
    USING (VALUES
        (N'Sede central',N'Edificio Sixtino, zona 10, Ciudad de Guatemala.'),
        (N'Cobán - Extracción',N'Planta de extracción minera en Cobán.'),
        (N'El Progreso - Extracción',N'Planta de extracción minera en El Progreso.'),
        (N'Quetzaltenango - Extracción',N'Planta de extracción minera en Quetzaltenango.'),
        (N'Petén - Extracción',N'Planta de extracción minera en Petén.'),
        (N'Zacapa - Procesamiento',N'Planta de procesamiento en Zacapa.'),
        (N'Huehuetenango - Procesamiento',N'Planta de procesamiento en Huehuetenango.'),
        (N'Petén - Procesamiento',N'Planta de procesamiento en Petén.'),
        (N'Guatemala - Maquinaria',N'Sucursal de maquinaria en Guatemala.'),
        (N'Quetzaltenango - Maquinaria',N'Sucursal de maquinaria en Quetzaltenango (Xela).'),
        (N'Zacapa - Maquinaria',N'Sucursal de maquinaria en Zacapa.'),
        (N'Petén - Maquinaria',N'Sucursal de maquinaria en Petén.')
    ) AS fuente(Nombre,Descripcion) ON destino.Nombre=fuente.Nombre
    WHEN MATCHED THEN UPDATE SET Descripcion=fuente.Descripcion,EsActivo=1,Eliminado=0,FechaModificacion=SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT(Nombre,Descripcion) VALUES(fuente.Nombre,fuente.Descripcion);

    MERGE dbo.Usuario AS destino
    USING (VALUES
        (N'admin.demo',N'Administrador',N'General',N'admin.demo@transport.local',N'TransPortAdmin2026!'),
        (N'empleado.demo',N'Empleado',N'Demostración',N'empleado.demo@transport.local',N'TransPortEmpleado2026!'),
        (N'cliente.demo',N'Cliente',N'Demostración',N'cliente.demo@transport.local',N'TransPortCliente2026!')
    ) AS fuente(NombreUsuario,Nombre,Apellido,Correo,Clave) ON destino.NombreUsuario=fuente.NombreUsuario
    WHEN MATCHED THEN UPDATE SET Nombre=fuente.Nombre,Apellido=fuente.Apellido,Correo=fuente.Correo,
        Clave=fuente.Clave,EsActivo=1,Eliminado=0,FechaModificacion=SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT(NombreUsuario,Nombre,Apellido,Correo,Clave) VALUES(fuente.NombreUsuario,fuente.Nombre,fuente.Apellido,fuente.Correo,fuente.Clave);

    MERGE dbo.Cliente AS destino
    USING (VALUES (N'Empresa cliente de demostración',N'CF-DEMO',N'contacto.demo@transport.local')) AS fuente(Nombre,Nit,CorreoContacto)
    ON destino.Nit=fuente.Nit
    WHEN MATCHED THEN UPDATE SET Nombre=fuente.Nombre,CorreoContacto=fuente.CorreoContacto,EsActivo=1,Eliminado=0,FechaModificacion=SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT(Nombre,Nit,CorreoContacto) VALUES(fuente.Nombre,fuente.Nit,fuente.CorreoContacto);

    DECLARE @AdminId INT=(SELECT UsuarioId FROM dbo.Usuario WHERE NombreUsuario=N'admin.demo' AND Eliminado=0);
    DECLARE @EmpleadoId INT=(SELECT UsuarioId FROM dbo.Usuario WHERE NombreUsuario=N'empleado.demo' AND Eliminado=0);
    DECLARE @ClienteUsuarioId INT=(SELECT UsuarioId FROM dbo.Usuario WHERE NombreUsuario=N'cliente.demo' AND Eliminado=0);
    DECLARE @RolAdminId INT=(SELECT RolId FROM dbo.Rol WHERE Nombre=N'AdministradorGeneral' AND Eliminado=0);
    DECLARE @RolEmpleadoId INT=(SELECT RolId FROM dbo.Rol WHERE Nombre=N'Empleado' AND Eliminado=0);
    DECLARE @RolClienteId INT=(SELECT RolId FROM dbo.Rol WHERE Nombre=N'Cliente' AND Eliminado=0);
    DECLARE @ExtraccionId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Extracción minera' AND Eliminado=0);
    DECLARE @TransporteId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Transporte nacional e internacional' AND Eliminado=0);
    DECLARE @SedeCobánId INT=(SELECT SedeId FROM dbo.Sede WHERE Nombre=N'Cobán - Extracción' AND Eliminado=0);
    DECLARE @ClienteId INT=(SELECT ClienteId FROM dbo.Cliente WHERE Nit=N'CF-DEMO' AND Eliminado=0);

    MERGE dbo.UsuarioRol AS d USING (VALUES(@AdminId,@RolAdminId),(@EmpleadoId,@RolEmpleadoId),(@ClienteUsuarioId,@RolClienteId)) s(UsuarioId,RolId)
    ON d.UsuarioId=s.UsuarioId AND d.RolId=s.RolId WHEN MATCHED THEN UPDATE SET Eliminado=0,FechaModificacion=SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT(UsuarioId,RolId) VALUES(s.UsuarioId,s.RolId);

    MERGE dbo.UsuarioGiroNegocio AS d USING (VALUES(@EmpleadoId,@ExtraccionId)) s(UsuarioId,GiroNegocioId)
    ON d.UsuarioId=s.UsuarioId AND d.GiroNegocioId=s.GiroNegocioId WHEN MATCHED THEN UPDATE SET Eliminado=0,FechaModificacion=SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT(UsuarioId,GiroNegocioId) VALUES(s.UsuarioId,s.GiroNegocioId);

    MERGE dbo.UsuarioSede AS d USING (VALUES(@EmpleadoId,@SedeCobánId)) s(UsuarioId,SedeId)
    ON d.UsuarioId=s.UsuarioId AND d.SedeId=s.SedeId WHEN MATCHED THEN UPDATE SET Eliminado=0,FechaModificacion=SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT(UsuarioId,SedeId) VALUES(s.UsuarioId,s.SedeId);

    MERGE dbo.ClienteUsuario AS d USING (VALUES(@ClienteId,@ClienteUsuarioId)) s(ClienteId,UsuarioId)
    ON d.ClienteId=s.ClienteId AND d.UsuarioId=s.UsuarioId WHEN MATCHED THEN UPDATE SET Eliminado=0,FechaModificacion=SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT(ClienteId,UsuarioId) VALUES(s.ClienteId,s.UsuarioId);

    MERGE dbo.ClienteGiroNegocio AS d USING (VALUES(@ClienteId,@TransporteId)) s(ClienteId,GiroNegocioId)
    ON d.ClienteId=s.ClienteId AND d.GiroNegocioId=s.GiroNegocioId WHEN MATCHED THEN UPDATE SET Eliminado=0,FechaModificacion=SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT(ClienteId,GiroNegocioId) VALUES(s.ClienteId,s.GiroNegocioId);

    /* Vincula cada sede conocida con su giro; la sede central opera transversalmente. */
    INSERT dbo.SedeGiroNegocio(SedeId,GiroNegocioId)
    SELECT s.SedeId,g.GiroNegocioId FROM dbo.Sede s CROSS JOIN dbo.GiroNegocio g
    WHERE s.Nombre=N'Sede central' AND s.Eliminado=0 AND g.Eliminado=0
      AND NOT EXISTS(SELECT 1 FROM dbo.SedeGiroNegocio x WHERE x.SedeId=s.SedeId AND x.GiroNegocioId=g.GiroNegocioId AND x.Eliminado=0);

    INSERT dbo.SedeGiroNegocio(SedeId,GiroNegocioId)
    SELECT s.SedeId,@ExtraccionId FROM dbo.Sede s
    WHERE s.Nombre LIKE N'% - Extracción' AND s.Eliminado=0
      AND NOT EXISTS(SELECT 1 FROM dbo.SedeGiroNegocio x WHERE x.SedeId=s.SedeId AND x.GiroNegocioId=@ExtraccionId AND x.Eliminado=0);

    DECLARE @ProcesoId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Procesamiento de materia prima' AND Eliminado=0);
    INSERT dbo.SedeGiroNegocio(SedeId,GiroNegocioId)
    SELECT s.SedeId,@ProcesoId FROM dbo.Sede s WHERE s.Nombre LIKE N'% - Procesamiento' AND s.Eliminado=0
      AND NOT EXISTS(SELECT 1 FROM dbo.SedeGiroNegocio x WHERE x.SedeId=s.SedeId AND x.GiroNegocioId=@ProcesoId AND x.Eliminado=0);

    DECLARE @MaquinariaId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Venta y alquiler de maquinaria' AND Eliminado=0);
    INSERT dbo.SedeGiroNegocio(SedeId,GiroNegocioId)
    SELECT s.SedeId,@MaquinariaId FROM dbo.Sede s WHERE s.Nombre LIKE N'% - Maquinaria' AND s.Eliminado=0
      AND NOT EXISTS(SELECT 1 FROM dbo.SedeGiroNegocio x WHERE x.SedeId=s.SedeId AND x.GiroNegocioId=@MaquinariaId AND x.Eliminado=0);

    /* Artículo funcional para probar la recepción externa simulada de M25. */
    MERGE dbo.InventarioArticulo AS d
    USING (VALUES(@ExtraccionId,N'MP-EXT-DEMO',N'Materia prima externa de demostración',N'Materia prima',N't',CONVERT(DECIMAL(18,3),10)))
      AS s(GiroNegocioId,Codigo,Nombre,Categoria,UnidadMedida,StockMinimo)
    ON d.Codigo=s.Codigo
    WHEN MATCHED THEN UPDATE SET GiroNegocioId=s.GiroNegocioId,Nombre=s.Nombre,Categoria=s.Categoria,
      UnidadMedida=s.UnidadMedida,StockMinimo=s.StockMinimo,EsActivo=1,Eliminado=0,FechaModificacion=SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT(GiroNegocioId,Codigo,Nombre,Categoria,UnidadMedida,StockMinimo)
      VALUES(s.GiroNegocioId,s.Codigo,s.Nombre,s.Categoria,s.UnidadMedida,s.StockMinimo);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

PRINT N'Datos iniciales creados o actualizados. Contraseñas solo para desarrollo; consulte README.md.';
GO

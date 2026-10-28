USE [TransPortDB];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_auditoria_crear_evento
    @UsuarioId INT = NULL,
    @Modulo NVARCHAR(80),
    @TipoOperacion NVARCHAR(80),
    @IdentificadorRegistro NVARCHAR(100) = NULL,
    @Resultado NVARCHAR(40),
    @Detalle NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT dbo.Auditoria (UsuarioId, Modulo, TipoOperacion, IdentificadorRegistro, Resultado, Detalle)
    VALUES (@UsuarioId, @Modulo, @TipoOperacion, @IdentificadorRegistro, @Resultado, @Detalle);
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_auditoria_leer_listado
    @Busqueda NVARCHAR(200) = NULL,
    @FechaDesdeUtc DATETIME2(0) = NULL,
    @FechaHastaUtc DATETIME2(0) = NULL,
    @Modulo NVARCHAR(80) = NULL,
    @TipoOperacion NVARCHAR(80) = NULL,
    @NombreUsuario NVARCHAR(80) = NULL,
    @Resultado NVARCHAR(40) = NULL,
    @Pagina INT = 1,
    @TamanoPagina INT = 25
AS
BEGIN
    SET NOCOUNT ON;

    SET @Busqueda = NULLIF(LTRIM(RTRIM(@Busqueda)), N'');
    SET @Modulo = NULLIF(LTRIM(RTRIM(@Modulo)), N'');
    SET @TipoOperacion = NULLIF(LTRIM(RTRIM(@TipoOperacion)), N'');
    SET @NombreUsuario = NULLIF(LTRIM(RTRIM(@NombreUsuario)), N'');
    SET @Resultado = NULLIF(LTRIM(RTRIM(@Resultado)), N'');
    SET @Pagina = CASE WHEN @Pagina < 1 THEN 1 ELSE @Pagina END;
    SET @TamanoPagina = CASE WHEN @TamanoPagina < 10 THEN 10 WHEN @TamanoPagina > 100 THEN 100 ELSE @TamanoPagina END;

    SELECT COUNT_BIG(*) AS TotalRegistros
    FROM dbo.Auditoria a
    LEFT JOIN dbo.Usuario u ON u.UsuarioId = a.UsuarioId
    WHERE (@FechaDesdeUtc IS NULL OR a.Fecha >= @FechaDesdeUtc)
      AND (@FechaHastaUtc IS NULL OR a.Fecha < @FechaHastaUtc)
      AND (@Modulo IS NULL OR a.Modulo = @Modulo)
      AND (@TipoOperacion IS NULL OR a.TipoOperacion = @TipoOperacion)
      AND (@NombreUsuario IS NULL OR u.NombreUsuario LIKE N'%' + @NombreUsuario + N'%')
      AND (@Resultado IS NULL OR a.Resultado = @Resultado)
      AND (@Busqueda IS NULL OR
           a.Modulo LIKE N'%' + @Busqueda + N'%' OR
           a.TipoOperacion LIKE N'%' + @Busqueda + N'%' OR
           a.IdentificadorRegistro LIKE N'%' + @Busqueda + N'%' OR
           a.Resultado LIKE N'%' + @Busqueda + N'%' OR
           a.Detalle LIKE N'%' + @Busqueda + N'%' OR
           u.NombreUsuario LIKE N'%' + @Busqueda + N'%')
    OPTION (RECOMPILE);

    SELECT a.AuditoriaId, a.UsuarioId, u.NombreUsuario, a.Fecha, a.Modulo,
           a.TipoOperacion, a.IdentificadorRegistro, a.Resultado, a.Detalle
    FROM dbo.Auditoria a
    LEFT JOIN dbo.Usuario u ON u.UsuarioId = a.UsuarioId
    WHERE (@FechaDesdeUtc IS NULL OR a.Fecha >= @FechaDesdeUtc)
      AND (@FechaHastaUtc IS NULL OR a.Fecha < @FechaHastaUtc)
      AND (@Modulo IS NULL OR a.Modulo = @Modulo)
      AND (@TipoOperacion IS NULL OR a.TipoOperacion = @TipoOperacion)
      AND (@NombreUsuario IS NULL OR u.NombreUsuario LIKE N'%' + @NombreUsuario + N'%')
      AND (@Resultado IS NULL OR a.Resultado = @Resultado)
      AND (@Busqueda IS NULL OR
           a.Modulo LIKE N'%' + @Busqueda + N'%' OR
           a.TipoOperacion LIKE N'%' + @Busqueda + N'%' OR
           a.IdentificadorRegistro LIKE N'%' + @Busqueda + N'%' OR
           a.Resultado LIKE N'%' + @Busqueda + N'%' OR
           a.Detalle LIKE N'%' + @Busqueda + N'%' OR
           u.NombreUsuario LIKE N'%' + @Busqueda + N'%')
    ORDER BY a.Fecha DESC, a.AuditoriaId DESC
    OFFSET (@Pagina - 1) * @TamanoPagina ROWS
    FETCH NEXT @TamanoPagina ROWS ONLY
    OPTION (RECOMPILE);
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_usuario_validar_credenciales
    @NombreUsuario NVARCHAR(80), @Clave NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    /* Prototipo académico: reemplazar esta comparación por un verificador de hash en producción. */
    SELECT UsuarioId, NombreUsuario, Nombre, Apellido, Correo, EsActivo
    FROM dbo.Usuario
    WHERE NombreUsuario = @NombreUsuario AND Clave = @Clave AND EsActivo = 1 AND Eliminado = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_usuario_crear_registro
    @NombreUsuario NVARCHAR(80), @Nombre NVARCHAR(100), @Apellido NVARCHAR(100),
    @Correo NVARCHAR(200), @Clave NVARCHAR(200), @EsActivo BIT = 1,
    @UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM dbo.Usuario WHERE Eliminado = 0 AND (NombreUsuario = @NombreUsuario OR Correo = @Correo))
            THROW 50001, N'El nombre de usuario o correo ya está registrado.', 1;
        INSERT dbo.Usuario (NombreUsuario, Nombre, Apellido, Correo, Clave, EsActivo)
        VALUES (@NombreUsuario, @Nombre, @Apellido, @Correo, @Clave, @EsActivo);
        DECLARE @Id INT = CONVERT(INT, SCOPE_IDENTITY());
        INSERT dbo.Auditoria (UsuarioId, Modulo, TipoOperacion, IdentificadorRegistro, Resultado)
        VALUES (@UsuarioResponsableId, N'Usuarios', N'Crear', CONVERT(NVARCHAR(100), @Id), N'Exitoso');
        COMMIT TRANSACTION;
        SELECT @Id;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_usuario_leer_por_id @UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT UsuarioId, NombreUsuario, Nombre, Apellido, Correo, EsActivo, FechaCreacion, FechaModificacion
    FROM dbo.Usuario WHERE UsuarioId = @UsuarioId AND Eliminado = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_usuario_leer_listado
    @Busqueda NVARCHAR(200) = NULL, @EsActivo BIT = NULL, @RolId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.UsuarioId, u.NombreUsuario, u.Nombre, u.Apellido, u.Correo, u.EsActivo, u.FechaCreacion,
           COALESCE(STRING_AGG(CONVERT(NVARCHAR(MAX), r.Nombre), N', '), N'') AS Roles
    FROM dbo.Usuario u
    LEFT JOIN dbo.UsuarioRol ur ON ur.UsuarioId = u.UsuarioId AND ur.Eliminado = 0
    LEFT JOIN dbo.Rol r ON r.RolId = ur.RolId AND r.Eliminado = 0
    WHERE u.Eliminado = 0
      AND (@EsActivo IS NULL OR u.EsActivo = @EsActivo)
      AND (@Busqueda IS NULL OR u.NombreUsuario LIKE N'%' + @Busqueda + N'%'
           OR u.Nombre LIKE N'%' + @Busqueda + N'%' OR u.Apellido LIKE N'%' + @Busqueda + N'%'
           OR u.Correo LIKE N'%' + @Busqueda + N'%')
      AND (@RolId IS NULL OR EXISTS (SELECT 1 FROM dbo.UsuarioRol f WHERE f.UsuarioId = u.UsuarioId AND f.RolId = @RolId AND f.Eliminado = 0))
    GROUP BY u.UsuarioId, u.NombreUsuario, u.Nombre, u.Apellido, u.Correo, u.EsActivo, u.FechaCreacion
    ORDER BY u.Nombre, u.Apellido;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_usuario_actualizar_datos
    @UsuarioId INT, @NombreUsuario NVARCHAR(80), @Nombre NVARCHAR(100), @Apellido NVARCHAR(100),
    @Correo NVARCHAR(200), @EsActivo BIT, @UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM dbo.Usuario WHERE UsuarioId <> @UsuarioId AND Eliminado = 0 AND (NombreUsuario = @NombreUsuario OR Correo = @Correo))
            THROW 50001, N'El nombre de usuario o correo ya está registrado.', 1;
        UPDATE dbo.Usuario SET NombreUsuario = @NombreUsuario, Nombre = @Nombre, Apellido = @Apellido,
            Correo = @Correo, EsActivo = @EsActivo, FechaModificacion = SYSUTCDATETIME()
        WHERE UsuarioId = @UsuarioId AND Eliminado = 0;
        DECLARE @Filas INT = @@ROWCOUNT;
        IF @Filas > 0 INSERT dbo.Auditoria (UsuarioId, Modulo, TipoOperacion, IdentificadorRegistro, Resultado)
            VALUES (@UsuarioResponsableId, N'Usuarios', N'Actualizar', CONVERT(NVARCHAR(100), @UsuarioId), N'Exitoso');
        COMMIT TRANSACTION;
        SELECT @Filas;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_usuario_eliminar_logico @UsuarioId INT, @UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE dbo.Usuario SET Eliminado = 1, EsActivo = 0, FechaModificacion = SYSUTCDATETIME()
        WHERE UsuarioId = @UsuarioId AND Eliminado = 0;
        DECLARE @Filas INT = @@ROWCOUNT;
        IF @Filas > 0
        BEGIN
            UPDATE dbo.UsuarioRol SET Eliminado = 1, FechaModificacion = SYSUTCDATETIME() WHERE UsuarioId = @UsuarioId AND Eliminado = 0;
            UPDATE dbo.UsuarioGiroNegocio SET Eliminado = 1, FechaModificacion = SYSUTCDATETIME() WHERE UsuarioId = @UsuarioId AND Eliminado = 0;
            UPDATE dbo.UsuarioSede SET Eliminado = 1, FechaModificacion = SYSUTCDATETIME() WHERE UsuarioId = @UsuarioId AND Eliminado = 0;
            UPDATE dbo.ClienteUsuario SET Eliminado = 1, FechaModificacion = SYSUTCDATETIME() WHERE UsuarioId = @UsuarioId AND Eliminado = 0;
            INSERT dbo.Auditoria (UsuarioId, Modulo, TipoOperacion, IdentificadorRegistro, Resultado)
            VALUES (@UsuarioResponsableId, N'Usuarios', N'EliminarLogico', CONVERT(NVARCHAR(100), @UsuarioId), N'Exitoso');
        END;
        COMMIT TRANSACTION;
        SELECT @Filas;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_usuario_leer_roles @UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT r.RolId AS Id, r.Nombre FROM dbo.UsuarioRol ur
    INNER JOIN dbo.Rol r ON r.RolId = ur.RolId
    WHERE ur.UsuarioId = @UsuarioId AND ur.Eliminado = 0 AND r.Eliminado = 0 AND r.EsActivo = 1 ORDER BY r.Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_usuario_leer_giros @UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT g.GiroNegocioId AS Id, g.Nombre FROM dbo.UsuarioGiroNegocio ug
    INNER JOIN dbo.GiroNegocio g ON g.GiroNegocioId = ug.GiroNegocioId
    WHERE ug.UsuarioId = @UsuarioId AND ug.Eliminado = 0 AND g.Eliminado = 0 AND g.EsActivo = 1 ORDER BY g.Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_usuario_leer_sedes @UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT s.SedeId AS Id, s.Nombre FROM dbo.UsuarioSede us
    INNER JOIN dbo.Sede s ON s.SedeId = us.SedeId
    WHERE us.UsuarioId = @UsuarioId AND us.Eliminado = 0 AND s.Eliminado = 0 AND s.EsActivo = 1 ORDER BY s.Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_usuario_leer_clientes @UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.ClienteId AS Id, c.Nombre FROM dbo.ClienteUsuario cu
    INNER JOIN dbo.Cliente c ON c.ClienteId = cu.ClienteId
    WHERE cu.UsuarioId = @UsuarioId AND cu.Eliminado = 0 AND c.Eliminado = 0 AND c.EsActivo = 1 ORDER BY c.Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_dashboard_leer_resumen
AS
BEGIN
    SET NOCOUNT ON;
    SELECT (SELECT COUNT(*) FROM dbo.Usuario WHERE Eliminado = 0) AS Usuarios,
           (SELECT COUNT(*) FROM dbo.Cliente WHERE Eliminado = 0) AS Clientes,
           (SELECT COUNT(*) FROM dbo.GiroNegocio WHERE Eliminado = 0) AS Giros,
           (SELECT COUNT(*) FROM dbo.Sede WHERE Eliminado = 0) AS Sedes;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_rol_crear_registro
    @Nombre NVARCHAR(120), @Descripcion NVARCHAR(500) = NULL, @EsActivo BIT = 1, @UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM dbo.Rol WHERE Nombre = @Nombre AND Eliminado = 0) THROW 50001, N'El rol ya existe.', 1;
        INSERT dbo.Rol (Nombre, Descripcion, EsActivo) VALUES (@Nombre, @Descripcion, @EsActivo);
        DECLARE @Id INT = CONVERT(INT, SCOPE_IDENTITY());
        INSERT dbo.Auditoria (UsuarioId, Modulo, TipoOperacion, IdentificadorRegistro, Resultado)
        VALUES (@UsuarioResponsableId, N'Roles', N'Crear', CONVERT(NVARCHAR(100), @Id), N'Exitoso');
        COMMIT TRANSACTION; SELECT @Id;
    END TRY BEGIN CATCH IF XACT_STATE() <> 0 ROLLBACK TRANSACTION; THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_rol_leer_por_id @RolId INT
AS BEGIN SET NOCOUNT ON; SELECT RolId, Nombre, Descripcion, EsActivo, FechaCreacion FROM dbo.Rol WHERE RolId = @RolId AND Eliminado = 0; END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_rol_leer_listado
AS BEGIN SET NOCOUNT ON; SELECT RolId, Nombre, Descripcion, EsActivo, FechaCreacion FROM dbo.Rol WHERE Eliminado = 0 ORDER BY Nombre; END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_rol_actualizar_datos
    @RolId INT, @Nombre NVARCHAR(120), @Descripcion NVARCHAR(500) = NULL, @EsActivo BIT, @UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM dbo.Rol WHERE RolId <> @RolId AND Nombre = @Nombre AND Eliminado = 0) THROW 50001, N'El rol ya existe.', 1;
        UPDATE dbo.Rol SET Nombre=@Nombre, Descripcion=@Descripcion, EsActivo=@EsActivo, FechaModificacion=SYSUTCDATETIME() WHERE RolId=@RolId AND Eliminado=0;
        DECLARE @Filas INT=@@ROWCOUNT;
        IF @Filas>0 INSERT dbo.Auditoria (UsuarioId,Modulo,TipoOperacion,IdentificadorRegistro,Resultado) VALUES (@UsuarioResponsableId,N'Roles',N'Actualizar',CONVERT(NVARCHAR(100),@RolId),N'Exitoso');
        COMMIT TRANSACTION; SELECT @Filas;
    END TRY BEGIN CATCH IF XACT_STATE() <> 0 ROLLBACK TRANSACTION; THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_rol_eliminar_logico @RolId INT, @UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE dbo.Rol SET Eliminado=1,EsActivo=0,FechaModificacion=SYSUTCDATETIME() WHERE RolId=@RolId AND Eliminado=0;
        DECLARE @Filas INT=@@ROWCOUNT;
        IF @Filas>0 BEGIN
            UPDATE dbo.UsuarioRol SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE RolId=@RolId AND Eliminado=0;
            INSERT dbo.Auditoria (UsuarioId,Modulo,TipoOperacion,IdentificadorRegistro,Resultado) VALUES (@UsuarioResponsableId,N'Roles',N'EliminarLogico',CONVERT(NVARCHAR(100),@RolId),N'Exitoso');
        END;
        COMMIT TRANSACTION; SELECT @Filas;
    END TRY BEGIN CATCH IF XACT_STATE() <> 0 ROLLBACK TRANSACTION; THROW; END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_gironegocio_crear_registro
    @Nombre NVARCHAR(120), @Descripcion NVARCHAR(500) = NULL, @EsActivo BIT = 1, @UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM dbo.GiroNegocio WHERE Nombre=@Nombre AND Eliminado=0) THROW 50001, N'El giro de negocio ya existe.', 1;
        INSERT dbo.GiroNegocio (Nombre,Descripcion,EsActivo) VALUES (@Nombre,@Descripcion,@EsActivo);
        DECLARE @Id INT=CONVERT(INT,SCOPE_IDENTITY());
        INSERT dbo.Auditoria (UsuarioId,Modulo,TipoOperacion,IdentificadorRegistro,Resultado) VALUES (@UsuarioResponsableId,N'Giros',N'Crear',CONVERT(NVARCHAR(100),@Id),N'Exitoso');
        COMMIT TRANSACTION; SELECT @Id;
    END TRY BEGIN CATCH IF XACT_STATE() <> 0 ROLLBACK TRANSACTION; THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_gironegocio_leer_por_id @GiroNegocioId INT
AS BEGIN SET NOCOUNT ON; SELECT GiroNegocioId,Nombre,Descripcion,EsActivo,FechaCreacion FROM dbo.GiroNegocio WHERE GiroNegocioId=@GiroNegocioId AND Eliminado=0; END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_gironegocio_leer_listado
AS BEGIN SET NOCOUNT ON; SELECT GiroNegocioId,Nombre,Descripcion,EsActivo,FechaCreacion FROM dbo.GiroNegocio WHERE Eliminado=0 ORDER BY Nombre; END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_gironegocio_actualizar_datos
    @GiroNegocioId INT,@Nombre NVARCHAR(120),@Descripcion NVARCHAR(500)=NULL,@EsActivo BIT,@UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS(SELECT 1 FROM dbo.GiroNegocio WHERE GiroNegocioId<>@GiroNegocioId AND Nombre=@Nombre AND Eliminado=0) THROW 50001,N'El giro de negocio ya existe.',1;
        UPDATE dbo.GiroNegocio SET Nombre=@Nombre,Descripcion=@Descripcion,EsActivo=@EsActivo,FechaModificacion=SYSUTCDATETIME() WHERE GiroNegocioId=@GiroNegocioId AND Eliminado=0;
        DECLARE @Filas INT=@@ROWCOUNT;
        IF @Filas>0 INSERT dbo.Auditoria (UsuarioId,Modulo,TipoOperacion,IdentificadorRegistro,Resultado) VALUES (@UsuarioResponsableId,N'Giros',N'Actualizar',CONVERT(NVARCHAR(100),@GiroNegocioId),N'Exitoso');
        COMMIT TRANSACTION; SELECT @Filas;
    END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_gironegocio_eliminar_logico @GiroNegocioId INT,@UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE dbo.GiroNegocio SET Eliminado=1,EsActivo=0,FechaModificacion=SYSUTCDATETIME() WHERE GiroNegocioId=@GiroNegocioId AND Eliminado=0;
        DECLARE @Filas INT=@@ROWCOUNT;
        IF @Filas>0 BEGIN
            UPDATE dbo.UsuarioGiroNegocio SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE GiroNegocioId=@GiroNegocioId AND Eliminado=0;
            UPDATE dbo.SedeGiroNegocio SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE GiroNegocioId=@GiroNegocioId AND Eliminado=0;
            UPDATE dbo.ClienteGiroNegocio SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE GiroNegocioId=@GiroNegocioId AND Eliminado=0;
            INSERT dbo.Auditoria (UsuarioId,Modulo,TipoOperacion,IdentificadorRegistro,Resultado) VALUES (@UsuarioResponsableId,N'Giros',N'EliminarLogico',CONVERT(NVARCHAR(100),@GiroNegocioId),N'Exitoso');
        END;
        COMMIT TRANSACTION; SELECT @Filas;
    END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_sede_crear_registro
    @Nombre NVARCHAR(120),@Descripcion NVARCHAR(500)=NULL,@EsActivo BIT=1,@UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS(SELECT 1 FROM dbo.Sede WHERE Nombre=@Nombre AND Eliminado=0) THROW 50001,N'La sede ya existe.',1;
        INSERT dbo.Sede(Nombre,Descripcion,EsActivo) VALUES(@Nombre,@Descripcion,@EsActivo);
        DECLARE @Id INT=CONVERT(INT,SCOPE_IDENTITY());
        INSERT dbo.Auditoria(UsuarioId,Modulo,TipoOperacion,IdentificadorRegistro,Resultado) VALUES(@UsuarioResponsableId,N'Sedes',N'Crear',CONVERT(NVARCHAR(100),@Id),N'Exitoso');
        COMMIT TRANSACTION; SELECT @Id;
    END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_sede_leer_por_id @SedeId INT
AS BEGIN SET NOCOUNT ON; SELECT SedeId,Nombre,Descripcion,EsActivo,FechaCreacion FROM dbo.Sede WHERE SedeId=@SedeId AND Eliminado=0; END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_sede_leer_listado
AS BEGIN SET NOCOUNT ON; SELECT SedeId,Nombre,Descripcion,EsActivo,FechaCreacion FROM dbo.Sede WHERE Eliminado=0 ORDER BY Nombre; END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_sede_actualizar_datos
    @SedeId INT,@Nombre NVARCHAR(120),@Descripcion NVARCHAR(500)=NULL,@EsActivo BIT,@UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS(SELECT 1 FROM dbo.Sede WHERE SedeId<>@SedeId AND Nombre=@Nombre AND Eliminado=0) THROW 50001,N'La sede ya existe.',1;
        UPDATE dbo.Sede SET Nombre=@Nombre,Descripcion=@Descripcion,EsActivo=@EsActivo,FechaModificacion=SYSUTCDATETIME() WHERE SedeId=@SedeId AND Eliminado=0;
        DECLARE @Filas INT=@@ROWCOUNT;
        IF @Filas>0 INSERT dbo.Auditoria(UsuarioId,Modulo,TipoOperacion,IdentificadorRegistro,Resultado) VALUES(@UsuarioResponsableId,N'Sedes',N'Actualizar',CONVERT(NVARCHAR(100),@SedeId),N'Exitoso');
        COMMIT TRANSACTION; SELECT @Filas;
    END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_sede_eliminar_logico @SedeId INT,@UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE dbo.Sede SET Eliminado=1,EsActivo=0,FechaModificacion=SYSUTCDATETIME() WHERE SedeId=@SedeId AND Eliminado=0;
        DECLARE @Filas INT=@@ROWCOUNT;
        IF @Filas>0 BEGIN
            UPDATE dbo.UsuarioSede SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE SedeId=@SedeId AND Eliminado=0;
            UPDATE dbo.SedeGiroNegocio SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE SedeId=@SedeId AND Eliminado=0;
            INSERT dbo.Auditoria(UsuarioId,Modulo,TipoOperacion,IdentificadorRegistro,Resultado) VALUES(@UsuarioResponsableId,N'Sedes',N'EliminarLogico',CONVERT(NVARCHAR(100),@SedeId),N'Exitoso');
        END;
        COMMIT TRANSACTION; SELECT @Filas;
    END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_usuariorol_crear_asignacion @UsuarioId INT,@RolId INT,@UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM dbo.UsuarioRol WHERE UsuarioId=@UsuarioId AND RolId=@RolId)
        UPDATE dbo.UsuarioRol SET Eliminado=0,FechaModificacion=SYSUTCDATETIME() WHERE UsuarioId=@UsuarioId AND RolId=@RolId;
    ELSE INSERT dbo.UsuarioRol(UsuarioId,RolId) VALUES(@UsuarioId,@RolId);
    EXEC dbo.sp_auditoria_crear_evento @UsuarioResponsableId,N'Usuarios',N'AsignarRol',@UsuarioId,N'Exitoso',NULL;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_usuariorol_eliminar_asignacion @UsuarioId INT,@RolId INT,@UsuarioResponsableId INT
AS
BEGIN SET NOCOUNT ON; UPDATE dbo.UsuarioRol SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE UsuarioId=@UsuarioId AND RolId=@RolId AND Eliminado=0;
    EXEC dbo.sp_auditoria_crear_evento @UsuarioResponsableId,N'Usuarios',N'RetirarRol',@UsuarioId,N'Exitoso',NULL; END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_usuariogironegocio_crear_asignacion @UsuarioId INT,@GiroNegocioId INT,@UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroNegocioId)
        UPDATE dbo.UsuarioGiroNegocio SET Eliminado=0,FechaModificacion=SYSUTCDATETIME() WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroNegocioId;
    ELSE INSERT dbo.UsuarioGiroNegocio(UsuarioId,GiroNegocioId) VALUES(@UsuarioId,@GiroNegocioId);
    EXEC dbo.sp_auditoria_crear_evento @UsuarioResponsableId,N'Usuarios',N'AsignarGiro',@UsuarioId,N'Exitoso',NULL;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_usuariogironegocio_eliminar_asignacion @UsuarioId INT,@GiroNegocioId INT,@UsuarioResponsableId INT
AS
BEGIN SET NOCOUNT ON; UPDATE dbo.UsuarioGiroNegocio SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroNegocioId AND Eliminado=0;
    EXEC dbo.sp_auditoria_crear_evento @UsuarioResponsableId,N'Usuarios',N'RetirarGiro',@UsuarioId,N'Exitoso',NULL; END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_usuariosede_crear_asignacion @UsuarioId INT,@SedeId INT,@UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId)
        UPDATE dbo.UsuarioSede SET Eliminado=0,FechaModificacion=SYSUTCDATETIME() WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId;
    ELSE INSERT dbo.UsuarioSede(UsuarioId,SedeId) VALUES(@UsuarioId,@SedeId);
    EXEC dbo.sp_auditoria_crear_evento @UsuarioResponsableId,N'Usuarios',N'AsignarSede',@UsuarioId,N'Exitoso',NULL;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_usuariosede_eliminar_asignacion @UsuarioId INT,@SedeId INT,@UsuarioResponsableId INT
AS
BEGIN SET NOCOUNT ON; UPDATE dbo.UsuarioSede SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0;
    EXEC dbo.sp_auditoria_crear_evento @UsuarioResponsableId,N'Usuarios',N'RetirarSede',@UsuarioId,N'Exitoso',NULL; END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_sedegironegocio_crear_asignacion @SedeId INT,@GiroNegocioId INT,@UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM dbo.SedeGiroNegocio WHERE SedeId=@SedeId AND GiroNegocioId=@GiroNegocioId)
        UPDATE dbo.SedeGiroNegocio SET Eliminado=0,FechaModificacion=SYSUTCDATETIME() WHERE SedeId=@SedeId AND GiroNegocioId=@GiroNegocioId;
    ELSE INSERT dbo.SedeGiroNegocio(SedeId,GiroNegocioId) VALUES(@SedeId,@GiroNegocioId);
    EXEC dbo.sp_auditoria_crear_evento @UsuarioResponsableId,N'Organizacion',N'AsignarSedeGiro',@SedeId,N'Exitoso',NULL;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_sedegironegocio_eliminar_asignacion @SedeId INT,@GiroNegocioId INT,@UsuarioResponsableId INT
AS
BEGIN SET NOCOUNT ON; UPDATE dbo.SedeGiroNegocio SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE SedeId=@SedeId AND GiroNegocioId=@GiroNegocioId AND Eliminado=0;
    EXEC dbo.sp_auditoria_crear_evento @UsuarioResponsableId,N'Organizacion',N'RetirarSedeGiro',@SedeId,N'Exitoso',NULL; END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_cliente_leer_usuarios @ClienteId INT
AS BEGIN SET NOCOUNT ON; SELECT u.UsuarioId AS Id,u.NombreUsuario AS Nombre FROM dbo.ClienteUsuario cu INNER JOIN dbo.Usuario u ON u.UsuarioId=cu.UsuarioId WHERE cu.ClienteId=@ClienteId AND cu.Eliminado=0 AND u.Eliminado=0; END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_cliente_leer_giros @ClienteId INT
AS BEGIN SET NOCOUNT ON; SELECT g.GiroNegocioId AS Id,g.Nombre FROM dbo.ClienteGiroNegocio cg INNER JOIN dbo.GiroNegocio g ON g.GiroNegocioId=cg.GiroNegocioId WHERE cg.ClienteId=@ClienteId AND cg.Eliminado=0 AND g.Eliminado=0; END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_cliente_crear_registro
    @Nombre NVARCHAR(200),
    @Nit NVARCHAR(30) = NULL,
    @CorreoContacto NVARCHAR(200) = NULL,
    @EsActivo BIT = 1,
    @UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @TransaccionPropia BIT=0;
    BEGIN TRY
        IF @@TRANCOUNT=0
        BEGIN
            BEGIN TRANSACTION;
            SET @TransaccionPropia=1;
        END;
        IF @Nit IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.Cliente WHERE Nit=@Nit AND Eliminado=0)
            THROW 50001, N'Ya existe un cliente con el NIT indicado.', 1;

        INSERT dbo.Cliente (Nombre,Nit,CorreoContacto,EsActivo)
        VALUES (@Nombre,@Nit,@CorreoContacto,@EsActivo);

        DECLARE @Id INT=CONVERT(INT,SCOPE_IDENTITY());
        INSERT dbo.Auditoria (UsuarioId,Modulo,TipoOperacion,IdentificadorRegistro,Resultado)
        VALUES (@UsuarioResponsableId,N'Clientes',N'Crear',CONVERT(NVARCHAR(100),@Id),N'Exitoso');
        IF @TransaccionPropia=1 COMMIT TRANSACTION;
        SELECT @Id;
    END TRY
    BEGIN CATCH
        IF @TransaccionPropia=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_cliente_leer_por_id @ClienteId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ClienteId,Nombre,Nit,CorreoContacto,EsActivo,FechaCreacion,FechaModificacion
    FROM dbo.Cliente
    WHERE ClienteId=@ClienteId AND Eliminado=0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_cliente_leer_listado
    @Busqueda NVARCHAR(200) = NULL,
    @EsActivo BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        c.ClienteId,c.Nombre,c.Nit,c.CorreoContacto,c.EsActivo,c.FechaCreacion,
        COALESCE((
            SELECT STRING_AGG(CONVERT(NVARCHAR(MAX),u.NombreUsuario),N', ') WITHIN GROUP (ORDER BY u.NombreUsuario)
            FROM dbo.ClienteUsuario cu
            INNER JOIN dbo.Usuario u ON u.UsuarioId=cu.UsuarioId
            WHERE cu.ClienteId=c.ClienteId AND cu.Eliminado=0 AND u.Eliminado=0
        ),N'') AS Usuarios,
        COALESCE((
            SELECT STRING_AGG(CONVERT(NVARCHAR(MAX),g.Nombre),N', ') WITHIN GROUP (ORDER BY g.Nombre)
            FROM dbo.ClienteGiroNegocio cg
            INNER JOIN dbo.GiroNegocio g ON g.GiroNegocioId=cg.GiroNegocioId
            WHERE cg.ClienteId=c.ClienteId AND cg.Eliminado=0 AND g.Eliminado=0
        ),N'') AS Giros
    FROM dbo.Cliente c
    WHERE c.Eliminado=0
      AND (@EsActivo IS NULL OR c.EsActivo=@EsActivo)
      AND (@Busqueda IS NULL OR c.Nombre LIKE N'%'+@Busqueda+N'%'
           OR c.Nit LIKE N'%'+@Busqueda+N'%'
           OR c.CorreoContacto LIKE N'%'+@Busqueda+N'%')
    ORDER BY c.Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_cliente_actualizar_datos
    @ClienteId INT,
    @Nombre NVARCHAR(200),
    @Nit NVARCHAR(30) = NULL,
    @CorreoContacto NVARCHAR(200) = NULL,
    @EsActivo BIT,
    @UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @TransaccionPropia BIT=0;
    BEGIN TRY
        IF @@TRANCOUNT=0
        BEGIN
            BEGIN TRANSACTION;
            SET @TransaccionPropia=1;
        END;
        IF @Nit IS NOT NULL AND EXISTS (
            SELECT 1 FROM dbo.Cliente WHERE ClienteId<>@ClienteId AND Nit=@Nit AND Eliminado=0)
            THROW 50001, N'Ya existe un cliente con el NIT indicado.', 1;

        UPDATE dbo.Cliente
        SET Nombre=@Nombre,Nit=@Nit,CorreoContacto=@CorreoContacto,EsActivo=@EsActivo,
            FechaModificacion=SYSUTCDATETIME()
        WHERE ClienteId=@ClienteId AND Eliminado=0;

        DECLARE @Filas INT=@@ROWCOUNT;
        IF @Filas>0
            INSERT dbo.Auditoria (UsuarioId,Modulo,TipoOperacion,IdentificadorRegistro,Resultado)
            VALUES (@UsuarioResponsableId,N'Clientes',N'Actualizar',CONVERT(NVARCHAR(100),@ClienteId),N'Exitoso');
        IF @TransaccionPropia=1 COMMIT TRANSACTION;
        SELECT @Filas;
    END TRY
    BEGIN CATCH
        IF @TransaccionPropia=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_cliente_eliminar_logico
    @ClienteId INT,
    @UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE dbo.Cliente
        SET Eliminado=1,EsActivo=0,FechaModificacion=SYSUTCDATETIME()
        WHERE ClienteId=@ClienteId AND Eliminado=0;

        DECLARE @Filas INT=@@ROWCOUNT;
        IF @Filas>0
        BEGIN
            UPDATE dbo.ClienteUsuario SET Eliminado=1,FechaModificacion=SYSUTCDATETIME()
            WHERE ClienteId=@ClienteId AND Eliminado=0;
            UPDATE dbo.ClienteGiroNegocio SET Eliminado=1,FechaModificacion=SYSUTCDATETIME()
            WHERE ClienteId=@ClienteId AND Eliminado=0;
            INSERT dbo.Auditoria (UsuarioId,Modulo,TipoOperacion,IdentificadorRegistro,Resultado)
            VALUES (@UsuarioResponsableId,N'Clientes',N'EliminarLogico',CONVERT(NVARCHAR(100),@ClienteId),N'Exitoso');
        END;
        COMMIT TRANSACTION;
        SELECT @Filas;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_clienteusuario_crear_asignacion
    @ClienteId INT,@UsuarioId INT,@UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM dbo.Cliente WHERE ClienteId=@ClienteId AND Eliminado=0)
        THROW 50002,N'El cliente no existe.',1;
    IF NOT EXISTS(SELECT 1 FROM dbo.Usuario WHERE UsuarioId=@UsuarioId AND Eliminado=0)
        THROW 50002,N'El usuario no existe.',1;
    IF EXISTS(SELECT 1 FROM dbo.ClienteUsuario WHERE ClienteId=@ClienteId AND UsuarioId=@UsuarioId)
        UPDATE dbo.ClienteUsuario SET Eliminado=0,FechaModificacion=SYSUTCDATETIME()
        WHERE ClienteId=@ClienteId AND UsuarioId=@UsuarioId;
    ELSE
        INSERT dbo.ClienteUsuario(ClienteId,UsuarioId) VALUES(@ClienteId,@UsuarioId);
    EXEC dbo.sp_auditoria_crear_evento @UsuarioResponsableId,N'Clientes',N'AsignarUsuario',@ClienteId,N'Exitoso',NULL;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_clienteusuario_eliminar_asignacion
    @ClienteId INT,@UsuarioId INT,@UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.ClienteUsuario SET Eliminado=1,FechaModificacion=SYSUTCDATETIME()
    WHERE ClienteId=@ClienteId AND UsuarioId=@UsuarioId AND Eliminado=0;
    IF @@ROWCOUNT>0
        EXEC dbo.sp_auditoria_crear_evento @UsuarioResponsableId,N'Clientes',N'RetirarUsuario',@ClienteId,N'Exitoso',NULL;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_clientegironegocio_crear_asignacion
    @ClienteId INT,@GiroNegocioId INT,@UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM dbo.Cliente WHERE ClienteId=@ClienteId AND Eliminado=0)
        THROW 50002,N'El cliente no existe.',1;
    IF NOT EXISTS(SELECT 1 FROM dbo.GiroNegocio WHERE GiroNegocioId=@GiroNegocioId AND Eliminado=0)
        THROW 50002,N'El giro de negocio no existe.',1;
    IF EXISTS(SELECT 1 FROM dbo.ClienteGiroNegocio WHERE ClienteId=@ClienteId AND GiroNegocioId=@GiroNegocioId)
        UPDATE dbo.ClienteGiroNegocio SET Eliminado=0,FechaModificacion=SYSUTCDATETIME()
        WHERE ClienteId=@ClienteId AND GiroNegocioId=@GiroNegocioId;
    ELSE
        INSERT dbo.ClienteGiroNegocio(ClienteId,GiroNegocioId) VALUES(@ClienteId,@GiroNegocioId);
    EXEC dbo.sp_auditoria_crear_evento @UsuarioResponsableId,N'Clientes',N'AsignarGiro',@ClienteId,N'Exitoso',NULL;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_clientegironegocio_eliminar_asignacion
    @ClienteId INT,@GiroNegocioId INT,@UsuarioResponsableId INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.ClienteGiroNegocio SET Eliminado=1,FechaModificacion=SYSUTCDATETIME()
    WHERE ClienteId=@ClienteId AND GiroNegocioId=@GiroNegocioId AND Eliminado=0;
    IF @@ROWCOUNT>0
        EXEC dbo.sp_auditoria_crear_evento @UsuarioResponsableId,N'Clientes',N'RetirarGiro',@ClienteId,N'Exitoso',NULL;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_pedido_leer_listado
    @UsuarioId INT,
    @EsAdministrador BIT,
    @EsCliente BIT,
    @Busqueda NVARCHAR(200) = NULL,
    @Estado NVARCHAR(30) = NULL,
    @ClienteId INT = NULL,
    @GiroNegocioId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Busqueda = NULLIF(LTRIM(RTRIM(@Busqueda)), N'');
    SET @Estado = NULLIF(LTRIM(RTRIM(@Estado)), N'');

    SELECT p.PedidoId, p.ClienteId, c.Nombre AS Cliente, p.GiroNegocioId, g.Nombre AS Giro,
           p.TipoSolicitud, p.Titulo, p.Estado, p.FechaRequerida, p.MontoCotizado,
           p.VendedorUsuarioId,
           CASE WHEN v.UsuarioId IS NULL THEN NULL ELSE CONCAT(v.Nombre, N' ', v.Apellido) END AS Vendedor,
           p.FechaCreacion, p.FechaModificacion
    FROM dbo.Pedido p
    INNER JOIN dbo.Cliente c ON c.ClienteId=p.ClienteId
    INNER JOIN dbo.GiroNegocio g ON g.GiroNegocioId=p.GiroNegocioId
    LEFT JOIN dbo.Usuario v ON v.UsuarioId=p.VendedorUsuarioId
    WHERE p.Eliminado=0
      AND (@Estado IS NULL OR p.Estado=@Estado)
      AND (@ClienteId IS NULL OR p.ClienteId=@ClienteId)
      AND (@GiroNegocioId IS NULL OR p.GiroNegocioId=@GiroNegocioId)
      AND (@Busqueda IS NULL OR p.Titulo LIKE N'%' + @Busqueda + N'%' OR
           p.Descripcion LIKE N'%' + @Busqueda + N'%' OR c.Nombre LIKE N'%' + @Busqueda + N'%' OR
           g.Nombre LIKE N'%' + @Busqueda + N'%')
      AND (
          @EsAdministrador=1 OR
          (@EsCliente=1 AND EXISTS(
              SELECT 1 FROM dbo.ClienteUsuario cu
              WHERE cu.ClienteId=p.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0)) OR
          (@EsCliente=0 AND (p.VendedorUsuarioId=@UsuarioId OR EXISTS(
              SELECT 1 FROM dbo.UsuarioGiroNegocio ug
              WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=p.GiroNegocioId AND ug.Eliminado=0)))
      )
    ORDER BY p.FechaCreacion DESC, p.PedidoId DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_pedido_leer_por_id
    @PedidoId BIGINT,
    @UsuarioId INT,
    @EsAdministrador BIT,
    @EsCliente BIT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT p.PedidoId, p.ClienteId, c.Nombre AS Cliente, p.GiroNegocioId, g.Nombre AS Giro,
           p.SolicitanteUsuarioId, s.NombreUsuario AS Solicitante, p.VendedorUsuarioId,
           CASE WHEN v.UsuarioId IS NULL THEN NULL ELSE CONCAT(v.Nombre, N' ', v.Apellido) END AS Vendedor,
           p.TipoSolicitud, p.Titulo, p.Descripcion, p.Estado, p.FechaRequerida,
           p.MontoCotizado, p.FechaReunionUtc, p.EnlaceReunion, p.FechaCreacion, p.FechaModificacion
    FROM dbo.Pedido p
    INNER JOIN dbo.Cliente c ON c.ClienteId=p.ClienteId
    INNER JOIN dbo.GiroNegocio g ON g.GiroNegocioId=p.GiroNegocioId
    INNER JOIN dbo.Usuario s ON s.UsuarioId=p.SolicitanteUsuarioId
    LEFT JOIN dbo.Usuario v ON v.UsuarioId=p.VendedorUsuarioId
    WHERE p.PedidoId=@PedidoId AND p.Eliminado=0
      AND (
          @EsAdministrador=1 OR
          (@EsCliente=1 AND EXISTS(SELECT 1 FROM dbo.ClienteUsuario cu WHERE cu.ClienteId=p.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0)) OR
          (@EsCliente=0 AND (p.VendedorUsuarioId=@UsuarioId OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=p.GiroNegocioId AND ug.Eliminado=0)))
      );

    SELECT h.PedidoHistorialId, h.UsuarioId, u.NombreUsuario, h.EstadoAnterior, h.EstadoNuevo, h.Comentario, h.Fecha
    FROM dbo.PedidoHistorial h
    INNER JOIN dbo.Usuario u ON u.UsuarioId=h.UsuarioId
    INNER JOIN dbo.Pedido p ON p.PedidoId=h.PedidoId
    WHERE h.PedidoId=@PedidoId AND p.Eliminado=0
      AND (@EsAdministrador=1 OR
           (@EsCliente=1 AND EXISTS(SELECT 1 FROM dbo.ClienteUsuario cu WHERE cu.ClienteId=p.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0)) OR
           (@EsCliente=0 AND (p.VendedorUsuarioId=@UsuarioId OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=p.GiroNegocioId AND ug.Eliminado=0))))
    ORDER BY h.Fecha DESC, h.PedidoHistorialId DESC;

    SELECT d.PedidoDocumentoId, d.UsuarioId, u.NombreUsuario, d.Nombre, d.TipoDocumento, d.Url, d.FechaCreacion
    FROM dbo.PedidoDocumento d
    INNER JOIN dbo.Usuario u ON u.UsuarioId=d.UsuarioId
    INNER JOIN dbo.Pedido p ON p.PedidoId=d.PedidoId
    WHERE d.PedidoId=@PedidoId AND d.Eliminado=0 AND p.Eliminado=0
      AND (@EsAdministrador=1 OR
           (@EsCliente=1 AND EXISTS(SELECT 1 FROM dbo.ClienteUsuario cu WHERE cu.ClienteId=p.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0)) OR
           (@EsCliente=0 AND (p.VendedorUsuarioId=@UsuarioId OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=p.GiroNegocioId AND ug.Eliminado=0))))
    ORDER BY d.FechaCreacion DESC, d.PedidoDocumentoId DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_pedido_leer_opciones
    @UsuarioId INT,
    @EsAdministrador BIT,
    @EsCliente BIT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT DISTINCT c.ClienteId AS Id, c.Nombre
    FROM dbo.Cliente c
    WHERE c.Eliminado=0 AND c.EsActivo=1
      AND (@EsAdministrador=1 OR @EsCliente=0 OR EXISTS(
          SELECT 1 FROM dbo.ClienteUsuario cu WHERE cu.ClienteId=c.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0))
    ORDER BY c.Nombre;

    SELECT DISTINCT g.GiroNegocioId AS Id, g.Nombre
    FROM dbo.GiroNegocio g
    WHERE g.Eliminado=0 AND g.EsActivo=1
      AND (@EsAdministrador=1 OR
           (@EsCliente=1 AND EXISTS(
               SELECT 1 FROM dbo.ClienteGiroNegocio cg
               INNER JOIN dbo.ClienteUsuario cu ON cu.ClienteId=cg.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0
               WHERE cg.GiroNegocioId=g.GiroNegocioId AND cg.Eliminado=0)) OR
           (@EsCliente=0 AND EXISTS(
               SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.GiroNegocioId=g.GiroNegocioId AND ug.UsuarioId=@UsuarioId AND ug.Eliminado=0)))
    ORDER BY g.Nombre;

    SELECT DISTINCT u.UsuarioId AS Id, CONCAT(u.Nombre, N' ', u.Apellido) AS Nombre
    FROM dbo.Usuario u
    INNER JOIN dbo.UsuarioRol ur ON ur.UsuarioId=u.UsuarioId AND ur.Eliminado=0
    INNER JOIN dbo.Rol r ON r.RolId=ur.RolId AND r.Eliminado=0 AND r.EsActivo=1
    WHERE u.Eliminado=0 AND u.EsActivo=1 AND r.Nombre IN(N'Vendedor',N'AdministradorGeneral')
    ORDER BY Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_pedido_crear_registro
    @ClienteId INT,
    @GiroNegocioId INT,
    @TipoSolicitud NVARCHAR(30),
    @Titulo NVARCHAR(180),
    @Descripcion NVARCHAR(2000),
    @FechaRequerida DATE = NULL,
    @FechaReunionUtc DATETIME2(0) = NULL,
    @UsuarioId INT,
    @EsAdministrador BIT,
    @EsCliente BIT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @TipoSolicitud NOT IN(N'Pedido',N'Cotizacion',N'Reunion') THROW 50002,N'Tipo de solicitud inválido.',1;
        IF NOT EXISTS(SELECT 1 FROM dbo.Cliente WHERE ClienteId=@ClienteId AND Eliminado=0 AND EsActivo=1) THROW 50002,N'El cliente no está disponible.',1;
        IF NOT EXISTS(SELECT 1 FROM dbo.ClienteGiroNegocio WHERE ClienteId=@ClienteId AND GiroNegocioId=@GiroNegocioId AND Eliminado=0) THROW 50002,N'El giro no está contratado por el cliente.',1;
        IF @EsCliente=1 AND NOT EXISTS(SELECT 1 FROM dbo.ClienteUsuario WHERE ClienteId=@ClienteId AND UsuarioId=@UsuarioId AND Eliminado=0) THROW 50002,N'El usuario no pertenece al cliente.',1;
        IF @EsCliente=0 AND @EsAdministrador=0 AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroNegocioId AND Eliminado=0) THROW 50002,N'El usuario no tiene acceso al giro.',1;

        INSERT dbo.Pedido(ClienteId,GiroNegocioId,SolicitanteUsuarioId,TipoSolicitud,Titulo,Descripcion,FechaRequerida,FechaReunionUtc)
        VALUES(@ClienteId,@GiroNegocioId,@UsuarioId,@TipoSolicitud,LTRIM(RTRIM(@Titulo)),LTRIM(RTRIM(@Descripcion)),@FechaRequerida,@FechaReunionUtc);
        DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());
        INSERT dbo.PedidoHistorial(PedidoId,UsuarioId,EstadoAnterior,EstadoNuevo,Comentario)
        VALUES(@Id,@UsuarioId,NULL,N'Solicitado',N'Solicitud creada.');
        EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Pedidos',N'Crear',@Id,N'Exitoso',@TipoSolicitud;
        COMMIT TRANSACTION;
        SELECT @Id;
    END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_pedido_actualizar_gestion
    @PedidoId BIGINT,
    @Estado NVARCHAR(30),
    @VendedorUsuarioId INT = NULL,
    @MontoCotizado DECIMAL(18,2) = NULL,
    @FechaReunionUtc DATETIME2(0) = NULL,
    @EnlaceReunion NVARCHAR(500) = NULL,
    @Comentario NVARCHAR(1000) = NULL,
    @UsuarioId INT,
    @EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @Estado NOT IN(N'Solicitado',N'EnRevision',N'Cotizado',N'Aprobado',N'EnProceso',N'Completado',N'Rechazado',N'Cancelado') THROW 50002,N'Estado inválido.',1;
        DECLARE @Anterior NVARCHAR(30),@GiroNegocioId INT;
        SELECT @Anterior=Estado,@GiroNegocioId=GiroNegocioId FROM dbo.Pedido WHERE PedidoId=@PedidoId AND Eliminado=0;
        IF @Anterior IS NULL THROW 50002,N'El pedido no existe.',1;
        IF @EsAdministrador=0 AND NOT EXISTS(
            SELECT 1 FROM dbo.Pedido p WHERE p.PedidoId=@PedidoId AND
            (p.VendedorUsuarioId=@UsuarioId OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=p.GiroNegocioId AND ug.Eliminado=0)))
            THROW 50002,N'El usuario no puede gestionar este pedido.',1;
        IF @VendedorUsuarioId IS NOT NULL AND NOT EXISTS(
            SELECT 1 FROM dbo.Usuario u INNER JOIN dbo.UsuarioRol ur ON ur.UsuarioId=u.UsuarioId AND ur.Eliminado=0
            INNER JOIN dbo.Rol r ON r.RolId=ur.RolId AND r.Eliminado=0
            WHERE u.UsuarioId=@VendedorUsuarioId AND u.Eliminado=0 AND u.EsActivo=1 AND r.Nombre IN(N'Vendedor',N'AdministradorGeneral'))
            THROW 50002,N'El vendedor seleccionado no es válido.',1;

        UPDATE dbo.Pedido SET Estado=@Estado,VendedorUsuarioId=@VendedorUsuarioId,MontoCotizado=@MontoCotizado,
            FechaReunionUtc=@FechaReunionUtc,EnlaceReunion=NULLIF(LTRIM(RTRIM(@EnlaceReunion)),N''),FechaModificacion=SYSUTCDATETIME()
        WHERE PedidoId=@PedidoId;
        INSERT dbo.PedidoHistorial(PedidoId,UsuarioId,EstadoAnterior,EstadoNuevo,Comentario)
        VALUES(@PedidoId,@UsuarioId,@Anterior,@Estado,NULLIF(LTRIM(RTRIM(@Comentario)),N''));
        EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Pedidos',N'ActualizarGestion',@PedidoId,N'Exitoso',@Estado;
        COMMIT TRANSACTION;
        SELECT 1;
    END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_pedido_agregar_comentario
    @PedidoId BIGINT,@Comentario NVARCHAR(1000),@UsuarioId INT,@EsAdministrador BIT,@EsCliente BIT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Estado NVARCHAR(30),@Permitido BIT=0;
    SELECT @Estado=p.Estado,@Permitido=CASE WHEN @EsAdministrador=1 OR
        (@EsCliente=1 AND EXISTS(SELECT 1 FROM dbo.ClienteUsuario cu WHERE cu.ClienteId=p.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0)) OR
        (@EsCliente=0 AND (p.VendedorUsuarioId=@UsuarioId OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=p.GiroNegocioId AND ug.Eliminado=0))) THEN 1 ELSE 0 END
    FROM dbo.Pedido p WHERE p.PedidoId=@PedidoId AND p.Eliminado=0;
    IF @Estado IS NULL OR @Permitido=0 THROW 50002,N'El pedido no está disponible.',1;
    INSERT dbo.PedidoHistorial(PedidoId,UsuarioId,EstadoAnterior,EstadoNuevo,Comentario)
    VALUES(@PedidoId,@UsuarioId,@Estado,@Estado,LTRIM(RTRIM(@Comentario)));
    EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Pedidos',N'Comentar',@PedidoId,N'Exitoso',NULL;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_pedido_agregar_documento
    @PedidoId BIGINT,@Nombre NVARCHAR(200),@TipoDocumento NVARCHAR(60),@Url NVARCHAR(1000),
    @UsuarioId INT,@EsAdministrador BIT,@EsCliente BIT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF NOT EXISTS(SELECT 1 FROM dbo.Pedido p WHERE p.PedidoId=@PedidoId AND p.Eliminado=0 AND
        (@EsAdministrador=1 OR
         (@EsCliente=1 AND EXISTS(SELECT 1 FROM dbo.ClienteUsuario cu WHERE cu.ClienteId=p.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0)) OR
         (@EsCliente=0 AND (p.VendedorUsuarioId=@UsuarioId OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=p.GiroNegocioId AND ug.Eliminado=0)))))
        THROW 50002,N'El pedido no está disponible.',1;
    INSERT dbo.PedidoDocumento(PedidoId,UsuarioId,Nombre,TipoDocumento,Url)
    VALUES(@PedidoId,@UsuarioId,LTRIM(RTRIM(@Nombre)),LTRIM(RTRIM(@TipoDocumento)),LTRIM(RTRIM(@Url)));
    DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());
    EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Pedidos',N'AgregarDocumento',@PedidoId,N'Exitoso',@Nombre;
    SELECT @Id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_pedido_eliminar_logico
    @PedidoId BIGINT,@UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    UPDATE dbo.Pedido SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE PedidoId=@PedidoId AND Eliminado=0;
    DECLARE @Filas INT=@@ROWCOUNT;
    IF @Filas>0 EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Pedidos',N'EliminarLogico',@PedidoId,N'Exitoso',NULL;
    SELECT @Filas;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_portalcliente_leer_resumen
    @UsuarioId INT,
    @EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT c.ClienteId, c.Nombre, c.Nit, c.CorreoContacto,
           g.GiroNegocioId, g.Nombre AS Giro
    FROM dbo.Cliente c
    LEFT JOIN dbo.ClienteGiroNegocio cg ON cg.ClienteId=c.ClienteId AND cg.Eliminado=0
    LEFT JOIN dbo.GiroNegocio g ON g.GiroNegocioId=cg.GiroNegocioId AND g.Eliminado=0 AND g.EsActivo=1
    WHERE c.Eliminado=0 AND c.EsActivo=1
      AND (@EsAdministrador=1 OR EXISTS(
          SELECT 1 FROM dbo.ClienteUsuario cu
          WHERE cu.ClienteId=c.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0))
    ORDER BY c.Nombre, g.Nombre;

    SELECT COUNT_BIG(*) AS TotalSolicitudes,
           COALESCE(SUM(CASE WHEN p.Estado=N'Solicitado' THEN 1 ELSE 0 END),0) AS Solicitadas,
           COALESCE(SUM(CASE WHEN p.Estado IN(N'EnRevision',N'Cotizado',N'Aprobado',N'EnProceso') THEN 1 ELSE 0 END),0) AS EnGestion,
           COALESCE(SUM(CASE WHEN p.Estado=N'Completado' THEN 1 ELSE 0 END),0) AS Completadas,
           (SELECT COUNT_BIG(*)
            FROM dbo.PedidoDocumento d
            INNER JOIN dbo.Pedido pd ON pd.PedidoId=d.PedidoId AND pd.Eliminado=0
            WHERE d.Eliminado=0 AND (@EsAdministrador=1 OR EXISTS(
                SELECT 1 FROM dbo.ClienteUsuario cu
                WHERE cu.ClienteId=pd.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0))) AS Documentos
    FROM dbo.Pedido p
    WHERE p.Eliminado=0 AND (@EsAdministrador=1 OR EXISTS(
        SELECT 1 FROM dbo.ClienteUsuario cu
        WHERE cu.ClienteId=p.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0));

    SELECT TOP (5) p.PedidoId, p.ClienteId, c.Nombre AS Cliente, p.GiroNegocioId, g.Nombre AS Giro,
           p.TipoSolicitud, p.Titulo, p.Estado, p.FechaRequerida, p.MontoCotizado,
           p.VendedorUsuarioId,
           CASE WHEN v.UsuarioId IS NULL THEN NULL ELSE CONCAT(v.Nombre,N' ',v.Apellido) END AS Vendedor,
           p.FechaCreacion, p.FechaModificacion
    FROM dbo.Pedido p
    INNER JOIN dbo.Cliente c ON c.ClienteId=p.ClienteId
    INNER JOIN dbo.GiroNegocio g ON g.GiroNegocioId=p.GiroNegocioId
    LEFT JOIN dbo.Usuario v ON v.UsuarioId=p.VendedorUsuarioId
    WHERE p.Eliminado=0 AND (@EsAdministrador=1 OR EXISTS(
        SELECT 1 FROM dbo.ClienteUsuario cu
        WHERE cu.ClienteId=p.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0))
    ORDER BY p.FechaCreacion DESC, p.PedidoId DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_inventario_leer_listado
    @UsuarioId INT,@EsAdministrador BIT,@Busqueda NVARCHAR(200)=NULL,
    @GiroNegocioId INT=NULL,@SedeId INT=NULL,@SoloBajoMinimo BIT=0
AS
BEGIN
    SET NOCOUNT ON;
    SET @Busqueda=NULLIF(LTRIM(RTRIM(@Busqueda)),N'');
    SELECT a.InventarioArticuloId,a.Codigo,a.Nombre,a.Categoria,a.UnidadMedida,
           a.GiroNegocioId,g.Nombre AS Giro,a.StockMinimo,e.SedeId,s.Nombre AS Sede,
           COALESCE(e.Cantidad,0) AS Cantidad,COALESCE(e.CantidadReservada,0) AS CantidadReservada,
           COALESCE(e.Cantidad,0)-COALESCE(e.CantidadReservada,0) AS CantidadDisponible,
           CONVERT(BIT,CASE WHEN COALESCE(e.Cantidad,0)<a.StockMinimo THEN 1 ELSE 0 END) AS BajoMinimo
    FROM dbo.InventarioArticulo a
    INNER JOIN dbo.GiroNegocio g ON g.GiroNegocioId=a.GiroNegocioId
    LEFT JOIN dbo.InventarioExistencia e ON e.InventarioArticuloId=a.InventarioArticuloId
    LEFT JOIN dbo.Sede s ON s.SedeId=e.SedeId
    WHERE a.Eliminado=0 AND a.EsActivo=1
      AND (@Busqueda IS NULL OR a.Codigo LIKE N'%'+@Busqueda+N'%' OR a.Nombre LIKE N'%'+@Busqueda+N'%' OR a.Categoria LIKE N'%'+@Busqueda+N'%')
      AND (@GiroNegocioId IS NULL OR a.GiroNegocioId=@GiroNegocioId)
      AND (@SedeId IS NULL OR e.SedeId=@SedeId)
      AND (@SoloBajoMinimo=0 OR COALESCE(e.Cantidad,0)<a.StockMinimo)
      AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=a.GiroNegocioId AND ug.Eliminado=0))
      AND (e.SedeId IS NULL OR @EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=e.SedeId AND us.Eliminado=0))
    ORDER BY a.Nombre,s.Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_inventario_leer_movimientos
    @UsuarioId INT,@EsAdministrador BIT,@InventarioArticuloId INT=NULL,@Limite INT=100
AS
BEGIN
    SET NOCOUNT ON;
    SET @Limite=CASE WHEN @Limite<1 THEN 1 WHEN @Limite>500 THEN 500 ELSE @Limite END;
    SELECT TOP (@Limite) m.InventarioMovimientoId,m.InventarioArticuloId,a.Codigo,a.Nombre AS Articulo,
           m.Tipo,m.SedeOrigenId,so.Nombre AS SedeOrigen,m.SedeDestinoId,sd.Nombre AS SedeDestino,
           m.Cantidad,a.UnidadMedida,m.Referencia,m.Observacion,m.UsuarioId,u.NombreUsuario,m.Fecha
    FROM dbo.InventarioMovimiento m
    INNER JOIN dbo.InventarioArticulo a ON a.InventarioArticuloId=m.InventarioArticuloId
    INNER JOIN dbo.Usuario u ON u.UsuarioId=m.UsuarioId
    LEFT JOIN dbo.Sede so ON so.SedeId=m.SedeOrigenId
    LEFT JOIN dbo.Sede sd ON sd.SedeId=m.SedeDestinoId
    WHERE a.Eliminado=0 AND (@InventarioArticuloId IS NULL OR m.InventarioArticuloId=@InventarioArticuloId)
      AND (@EsAdministrador=1 OR
           (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=a.GiroNegocioId AND ug.Eliminado=0)
            AND (m.SedeOrigenId IS NULL OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=m.SedeOrigenId AND us.Eliminado=0))
            AND (m.SedeDestinoId IS NULL OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=m.SedeDestinoId AND us.Eliminado=0))))
    ORDER BY m.Fecha DESC,m.InventarioMovimientoId DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_inventario_leer_opciones
    @UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT g.GiroNegocioId AS Id,g.Nombre FROM dbo.GiroNegocio g
    WHERE g.Eliminado=0 AND g.EsActivo=1 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=g.GiroNegocioId AND ug.Eliminado=0)) ORDER BY g.Nombre;
    SELECT s.SedeId AS Id,s.Nombre FROM dbo.Sede s
    WHERE s.Eliminado=0 AND s.EsActivo=1 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=s.SedeId AND us.Eliminado=0)) ORDER BY s.Nombre;
    SELECT a.InventarioArticuloId AS Id,CONCAT(a.Codigo,N' · ',a.Nombre) AS Nombre FROM dbo.InventarioArticulo a
    WHERE a.Eliminado=0 AND a.EsActivo=1 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=a.GiroNegocioId AND ug.Eliminado=0)) ORDER BY a.Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_inventario_crear_articulo
    @GiroNegocioId INT,@Codigo NVARCHAR(50),@Nombre NVARCHAR(180),@Categoria NVARCHAR(80),
    @UnidadMedida NVARCHAR(30),@StockMinimo DECIMAL(18,3),@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;SET XACT_ABORT ON;
    IF @StockMinimo<0 THROW 50002,N'El stock mínimo no puede ser negativo.',1;
    IF @EsAdministrador=0 AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroNegocioId AND Eliminado=0) THROW 50002,N'El usuario no tiene acceso al giro.',1;
    INSERT dbo.InventarioArticulo(GiroNegocioId,Codigo,Nombre,Categoria,UnidadMedida,StockMinimo)
    VALUES(@GiroNegocioId,UPPER(LTRIM(RTRIM(@Codigo))),LTRIM(RTRIM(@Nombre)),LTRIM(RTRIM(@Categoria)),LTRIM(RTRIM(@UnidadMedida)),@StockMinimo);
    DECLARE @Id INT=CONVERT(INT,SCOPE_IDENTITY());
    EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Inventario',N'CrearArticulo',@Id,N'Exitoso',@Codigo;
    SELECT @Id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_inventario_registrar_movimiento
    @InventarioArticuloId INT,@Tipo NVARCHAR(30),@SedeOrigenId INT=NULL,@SedeDestinoId INT=NULL,
    @Cantidad DECIMAL(18,3),@Referencia NVARCHAR(120)=NULL,@Observacion NVARCHAR(500)=NULL,
    @UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @Tipo NOT IN(N'Entrada',N'Salida',N'Transferencia',N'Reserva',N'Liberacion') THROW 50002,N'Tipo de movimiento inválido.',1;
        IF @Cantidad<=0 THROW 50002,N'La cantidad debe ser mayor que cero.',1;
        DECLARE @GiroId INT=(SELECT GiroNegocioId FROM dbo.InventarioArticulo WHERE InventarioArticuloId=@InventarioArticuloId AND Eliminado=0 AND EsActivo=1);
        IF @GiroId IS NULL THROW 50002,N'El artículo no está disponible.',1;
        IF @Tipo=N'Entrada' AND @SedeDestinoId IS NULL THROW 50002,N'La entrada requiere sede destino.',1;
        IF @Tipo IN(N'Salida',N'Reserva',N'Liberacion') AND @SedeOrigenId IS NULL THROW 50002,N'El movimiento requiere sede origen.',1;
        IF @Tipo=N'Transferencia' AND (@SedeOrigenId IS NULL OR @SedeDestinoId IS NULL OR @SedeOrigenId=@SedeDestinoId) THROW 50002,N'La transferencia requiere sedes distintas.',1;
        IF @EsAdministrador=0 AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroId AND Eliminado=0) THROW 50002,N'El usuario no tiene acceso al giro.',1;
        IF @SedeOrigenId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.SedeGiroNegocio WHERE SedeId=@SedeOrigenId AND GiroNegocioId=@GiroId AND Eliminado=0) THROW 50002,N'La sede origen no opera el giro del artículo.',1;
        IF @SedeDestinoId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.SedeGiroNegocio WHERE SedeId=@SedeDestinoId AND GiroNegocioId=@GiroId AND Eliminado=0) THROW 50002,N'La sede destino no opera el giro del artículo.',1;
        IF @EsAdministrador=0 AND @SedeOrigenId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeOrigenId AND Eliminado=0) THROW 50002,N'El usuario no tiene acceso a la sede origen.',1;
        IF @EsAdministrador=0 AND @SedeDestinoId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeDestinoId AND Eliminado=0) THROW 50002,N'El usuario no tiene acceso a la sede destino.',1;

        IF @SedeOrigenId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.InventarioExistencia WHERE InventarioArticuloId=@InventarioArticuloId AND SedeId=@SedeOrigenId)
            INSERT dbo.InventarioExistencia(InventarioArticuloId,SedeId) VALUES(@InventarioArticuloId,@SedeOrigenId);
        IF @SedeDestinoId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.InventarioExistencia WHERE InventarioArticuloId=@InventarioArticuloId AND SedeId=@SedeDestinoId)
            INSERT dbo.InventarioExistencia(InventarioArticuloId,SedeId) VALUES(@InventarioArticuloId,@SedeDestinoId);

        DECLARE @Actual DECIMAL(18,3),@Reservada DECIMAL(18,3);
        IF @SedeOrigenId IS NOT NULL SELECT @Actual=Cantidad,@Reservada=CantidadReservada FROM dbo.InventarioExistencia WITH(UPDLOCK,HOLDLOCK) WHERE InventarioArticuloId=@InventarioArticuloId AND SedeId=@SedeOrigenId;
        IF @Tipo IN(N'Salida',N'Transferencia',N'Reserva') AND @Actual-@Reservada<@Cantidad THROW 50002,N'No existe cantidad disponible suficiente.',1;
        IF @Tipo=N'Liberacion' AND @Reservada<@Cantidad THROW 50002,N'No existe cantidad reservada suficiente.',1;

        IF @Tipo=N'Entrada' UPDATE dbo.InventarioExistencia SET Cantidad=Cantidad+@Cantidad,FechaModificacion=SYSUTCDATETIME() WHERE InventarioArticuloId=@InventarioArticuloId AND SedeId=@SedeDestinoId;
        IF @Tipo=N'Salida' UPDATE dbo.InventarioExistencia SET Cantidad=Cantidad-@Cantidad,FechaModificacion=SYSUTCDATETIME() WHERE InventarioArticuloId=@InventarioArticuloId AND SedeId=@SedeOrigenId;
        IF @Tipo=N'Transferencia'
        BEGIN
            UPDATE dbo.InventarioExistencia SET Cantidad=Cantidad-@Cantidad,FechaModificacion=SYSUTCDATETIME() WHERE InventarioArticuloId=@InventarioArticuloId AND SedeId=@SedeOrigenId;
            UPDATE dbo.InventarioExistencia SET Cantidad=Cantidad+@Cantidad,FechaModificacion=SYSUTCDATETIME() WHERE InventarioArticuloId=@InventarioArticuloId AND SedeId=@SedeDestinoId;
        END;
        IF @Tipo=N'Reserva' UPDATE dbo.InventarioExistencia SET CantidadReservada=CantidadReservada+@Cantidad,FechaModificacion=SYSUTCDATETIME() WHERE InventarioArticuloId=@InventarioArticuloId AND SedeId=@SedeOrigenId;
        IF @Tipo=N'Liberacion' UPDATE dbo.InventarioExistencia SET CantidadReservada=CantidadReservada-@Cantidad,FechaModificacion=SYSUTCDATETIME() WHERE InventarioArticuloId=@InventarioArticuloId AND SedeId=@SedeOrigenId;

        INSERT dbo.InventarioMovimiento(InventarioArticuloId,Tipo,SedeOrigenId,SedeDestinoId,Cantidad,Referencia,Observacion,UsuarioId)
        VALUES(@InventarioArticuloId,@Tipo,@SedeOrigenId,@SedeDestinoId,@Cantidad,NULLIF(LTRIM(RTRIM(@Referencia)),N''),NULLIF(LTRIM(RTRIM(@Observacion)),N''),@UsuarioId);
        DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());
        EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Inventario',@Tipo,@Id,N'Exitoso',@Referencia;
        COMMIT TRANSACTION;SELECT @Id;
    END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION;THROW;END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_inventario_eliminar_articulo
    @InventarioArticuloId INT,@UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.InventarioArticulo SET Eliminado=1,EsActivo=0,FechaModificacion=SYSUTCDATETIME()
    WHERE InventarioArticuloId=@InventarioArticuloId AND Eliminado=0;
    DECLARE @Filas INT=@@ROWCOUNT;
    IF @Filas>0 EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Inventario',N'EliminarArticulo',@InventarioArticuloId,N'Exitoso',NULL;
    SELECT @Filas;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_abastecimiento_leer_listado
    @UsuarioId INT,@EsAdministrador BIT,@Estado NVARCHAR(30)=NULL,@Busqueda NVARCHAR(200)=NULL
AS
BEGIN
 SET NOCOUNT ON;SET @Estado=NULLIF(LTRIM(RTRIM(@Estado)),N'');SET @Busqueda=NULLIF(LTRIM(RTRIM(@Busqueda)),N'');
 SELECT a.AbastecimientoSolicitudId,a.Estado,a.FechaNecesaria,a.Motivo,a.GiroSolicitanteId,gs.Nombre GiroSolicitante,a.SedeSolicitanteId,ss.Nombre SedeSolicitante,
        a.GiroProveedorId,gp.Nombre GiroProveedor,a.SedeProveedorId,sp.Nombre SedeProveedor,u.NombreUsuario Solicitante,a.FechaCreacion,a.FechaModificacion,
        (SELECT COUNT(*) FROM dbo.AbastecimientoDetalle d WHERE d.AbastecimientoSolicitudId=a.AbastecimientoSolicitudId) Lineas
 FROM dbo.AbastecimientoSolicitud a JOIN dbo.GiroNegocio gs ON gs.GiroNegocioId=a.GiroSolicitanteId JOIN dbo.GiroNegocio gp ON gp.GiroNegocioId=a.GiroProveedorId
 JOIN dbo.Sede ss ON ss.SedeId=a.SedeSolicitanteId JOIN dbo.Sede sp ON sp.SedeId=a.SedeProveedorId JOIN dbo.Usuario u ON u.UsuarioId=a.SolicitanteUsuarioId
 WHERE a.Eliminado=0 AND (@Estado IS NULL OR a.Estado=@Estado) AND (@Busqueda IS NULL OR a.Motivo LIKE N'%'+@Busqueda+N'%' OR gs.Nombre LIKE N'%'+@Busqueda+N'%' OR gp.Nombre LIKE N'%'+@Busqueda+N'%')
 AND (@EsAdministrador=1 OR
   (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio x WHERE x.UsuarioId=@UsuarioId AND x.GiroNegocioId=a.GiroSolicitanteId AND x.Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=a.SedeSolicitanteId AND x.Eliminado=0)) OR
   (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio x WHERE x.UsuarioId=@UsuarioId AND x.GiroNegocioId=a.GiroProveedorId AND x.Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=a.SedeProveedorId AND x.Eliminado=0)))
 ORDER BY a.FechaCreacion DESC,a.AbastecimientoSolicitudId DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_abastecimiento_leer_por_id @Id BIGINT,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT a.AbastecimientoSolicitudId,a.Estado,a.FechaNecesaria,a.Motivo,a.GiroSolicitanteId,gs.Nombre GiroSolicitante,a.SedeSolicitanteId,ss.Nombre SedeSolicitante,a.GiroProveedorId,gp.Nombre GiroProveedor,a.SedeProveedorId,sp.Nombre SedeProveedor,a.SolicitanteUsuarioId,u.NombreUsuario Solicitante,a.FechaCreacion,a.FechaModificacion
 FROM dbo.AbastecimientoSolicitud a JOIN dbo.GiroNegocio gs ON gs.GiroNegocioId=a.GiroSolicitanteId JOIN dbo.GiroNegocio gp ON gp.GiroNegocioId=a.GiroProveedorId JOIN dbo.Sede ss ON ss.SedeId=a.SedeSolicitanteId JOIN dbo.Sede sp ON sp.SedeId=a.SedeProveedorId JOIN dbo.Usuario u ON u.UsuarioId=a.SolicitanteUsuarioId
 WHERE a.AbastecimientoSolicitudId=@Id AND a.Eliminado=0 AND (@EsAdministrador=1 OR
   (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio x WHERE x.UsuarioId=@UsuarioId AND x.GiroNegocioId=a.GiroSolicitanteId AND x.Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=a.SedeSolicitanteId AND x.Eliminado=0)) OR
   (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio x WHERE x.UsuarioId=@UsuarioId AND x.GiroNegocioId=a.GiroProveedorId AND x.Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=a.SedeProveedorId AND x.Eliminado=0)));
 SELECT d.AbastecimientoDetalleId,d.ArticuloProveedorId,ap.Codigo CodigoProveedor,ap.Nombre ArticuloProveedor,d.ArticuloDestinoId,ad.Codigo CodigoDestino,ad.Nombre ArticuloDestino,d.Cantidad,ap.UnidadMedida
 FROM dbo.AbastecimientoDetalle d JOIN dbo.InventarioArticulo ap ON ap.InventarioArticuloId=d.ArticuloProveedorId JOIN dbo.InventarioArticulo ad ON ad.InventarioArticuloId=d.ArticuloDestinoId WHERE d.AbastecimientoSolicitudId=@Id ORDER BY d.AbastecimientoDetalleId;
 SELECT h.AbastecimientoHistorialId,h.UsuarioId,u.NombreUsuario,h.EstadoAnterior,h.EstadoNuevo,h.Comentario,h.Fecha FROM dbo.AbastecimientoHistorial h JOIN dbo.Usuario u ON u.UsuarioId=h.UsuarioId WHERE h.AbastecimientoSolicitudId=@Id ORDER BY h.Fecha DESC,h.AbastecimientoHistorialId DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_abastecimiento_leer_opciones @UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT g.GiroNegocioId Id,g.Nombre FROM dbo.GiroNegocio g WHERE g.Eliminado=0 AND g.EsActivo=1 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio x WHERE x.UsuarioId=@UsuarioId AND x.GiroNegocioId=g.GiroNegocioId AND x.Eliminado=0)) ORDER BY g.Nombre;
 SELECT s.SedeId Id,s.Nombre FROM dbo.Sede s WHERE s.Eliminado=0 AND s.EsActivo=1 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=s.SedeId AND x.Eliminado=0)) ORDER BY s.Nombre;
 SELECT g.GiroNegocioId Id,g.Nombre FROM dbo.GiroNegocio g WHERE g.Eliminado=0 AND g.EsActivo=1 ORDER BY g.Nombre;
 SELECT s.SedeId Id,s.Nombre FROM dbo.Sede s WHERE s.Eliminado=0 AND s.EsActivo=1 ORDER BY s.Nombre;
 SELECT a.InventarioArticuloId Id,CONCAT(a.Codigo,N' · ',a.Nombre,N' [',g.Nombre,N']') Nombre FROM dbo.InventarioArticulo a JOIN dbo.GiroNegocio g ON g.GiroNegocioId=a.GiroNegocioId WHERE a.Eliminado=0 AND a.EsActivo=1 ORDER BY g.Nombre,a.Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_abastecimiento_crear
 @GiroSolicitanteId INT,@SedeSolicitanteId INT,@GiroProveedorId INT,@SedeProveedorId INT,@FechaNecesaria DATE,@Motivo NVARCHAR(500),@Detalles NVARCHAR(MAX),@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;BEGIN TRY BEGIN TRANSACTION;
 IF @GiroSolicitanteId=@GiroProveedorId THROW 50002,N'Los giros deben ser diferentes.',1;
 IF @FechaNecesaria<CONVERT(DATE,SYSUTCDATETIME()) THROW 50002,N'La fecha necesaria no puede estar en el pasado.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.SedeGiroNegocio WHERE SedeId=@SedeSolicitanteId AND GiroNegocioId=@GiroSolicitanteId AND Eliminado=0) THROW 50002,N'La sede solicitante no corresponde al giro.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.SedeGiroNegocio WHERE SedeId=@SedeProveedorId AND GiroNegocioId=@GiroProveedorId AND Eliminado=0) THROW 50002,N'La sede proveedora no corresponde al giro.',1;
 IF @EsAdministrador=0 AND (NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroSolicitanteId AND Eliminado=0) OR NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeSolicitanteId AND Eliminado=0)) THROW 50002,N'El usuario no puede solicitar para ese giro y sede.',1;
 DECLARE @Lineas TABLE(ArticuloProveedorId INT,ArticuloDestinoId INT,Cantidad DECIMAL(18,3));
 INSERT @Lineas SELECT ArticuloProveedorId,ArticuloDestinoId,SUM(Cantidad) FROM OPENJSON(@Detalles) WITH(ArticuloProveedorId INT '$.articuloProveedorId',ArticuloDestinoId INT '$.articuloDestinoId',Cantidad DECIMAL(18,3) '$.cantidad') GROUP BY ArticuloProveedorId,ArticuloDestinoId;
 IF NOT EXISTS(SELECT 1 FROM @Lineas) OR EXISTS(SELECT 1 FROM @Lineas WHERE Cantidad<=0) THROW 50002,N'Debe agregar cantidades válidas.',1;
 IF EXISTS(SELECT 1 FROM @Lineas l LEFT JOIN dbo.InventarioArticulo a ON a.InventarioArticuloId=l.ArticuloProveedorId AND a.GiroNegocioId=@GiroProveedorId AND a.Eliminado=0 WHERE a.InventarioArticuloId IS NULL) THROW 50002,N'Un artículo proveedor no corresponde al giro.',1;
 IF EXISTS(SELECT 1 FROM @Lineas l LEFT JOIN dbo.InventarioArticulo a ON a.InventarioArticuloId=l.ArticuloDestinoId AND a.GiroNegocioId=@GiroSolicitanteId AND a.Eliminado=0 WHERE a.InventarioArticuloId IS NULL) THROW 50002,N'Un artículo destino no corresponde al giro solicitante.',1;
 INSERT dbo.AbastecimientoSolicitud(GiroSolicitanteId,SedeSolicitanteId,GiroProveedorId,SedeProveedorId,SolicitanteUsuarioId,FechaNecesaria,Motivo) VALUES(@GiroSolicitanteId,@SedeSolicitanteId,@GiroProveedorId,@SedeProveedorId,@UsuarioId,@FechaNecesaria,LTRIM(RTRIM(@Motivo)));
 DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());INSERT dbo.AbastecimientoDetalle(AbastecimientoSolicitudId,ArticuloProveedorId,ArticuloDestinoId,Cantidad) SELECT @Id,ArticuloProveedorId,ArticuloDestinoId,Cantidad FROM @Lineas;
 INSERT dbo.AbastecimientoHistorial(AbastecimientoSolicitudId,UsuarioId,EstadoNuevo,Comentario) VALUES(@Id,@UsuarioId,N'Solicitado',N'Solicitud creada.');EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Abastecimiento',N'Crear',@Id,N'Exitoso',@Motivo;
 COMMIT TRANSACTION;SELECT @Id;END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION;THROW;END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_abastecimiento_actualizar_estado @Id BIGINT,@Estado NVARCHAR(30),@Comentario NVARCHAR(1000)=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;BEGIN TRY BEGIN TRANSACTION;
 DECLARE @Anterior NVARCHAR(30),@Gs INT,@Ss INT,@Gp INT,@Sp INT;SELECT @Anterior=Estado,@Gs=GiroSolicitanteId,@Ss=SedeSolicitanteId,@Gp=GiroProveedorId,@Sp=SedeProveedorId FROM dbo.AbastecimientoSolicitud WITH(UPDLOCK) WHERE AbastecimientoSolicitudId=@Id AND Eliminado=0;
 IF @Anterior IS NULL THROW 50002,N'La solicitud no existe.',1;
 IF NOT ((@Anterior=N'Solicitado' AND @Estado IN(N'Aprobado',N'Rechazado',N'Cancelado')) OR (@Anterior=N'Aprobado' AND @Estado IN(N'Preparacion',N'Cancelado')) OR (@Anterior=N'Preparacion' AND @Estado IN(N'Despachado',N'Cancelado')) OR (@Anterior=N'Despachado' AND @Estado=N'Recibido')) THROW 50002,N'Transición de estado inválida.',1;
 DECLARE @Proveedor BIT=CASE WHEN @EsAdministrador=1 OR (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@Gp AND Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@Sp AND Eliminado=0)) THEN 1 ELSE 0 END;
 DECLARE @Solicitante BIT=CASE WHEN @EsAdministrador=1 OR (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@Gs AND Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@Ss AND Eliminado=0)) THEN 1 ELSE 0 END;
 IF @Estado IN(N'Aprobado',N'Rechazado',N'Preparacion',N'Despachado') AND @Proveedor=0 THROW 50002,N'Solo el giro proveedor puede realizar esta acción.',1;
 IF @Estado=N'Recibido' AND @Solicitante=0 THROW 50002,N'Solo el giro solicitante puede recibir.',1;
 IF @Estado=N'Cancelado' AND @Proveedor=0 AND @Solicitante=0 THROW 50002,N'El usuario no puede cancelar.',1;
 IF @Estado=N'Aprobado'
 BEGIN
   IF EXISTS(SELECT 1 FROM dbo.AbastecimientoDetalle d LEFT JOIN dbo.InventarioExistencia e ON e.InventarioArticuloId=d.ArticuloProveedorId AND e.SedeId=@Sp WHERE d.AbastecimientoSolicitudId=@Id AND COALESCE(e.Cantidad-e.CantidadReservada,0)<d.Cantidad) THROW 50002,N'Inventario insuficiente para aprobar.',1;
   UPDATE e SET CantidadReservada=e.CantidadReservada+d.Cantidad,FechaModificacion=SYSUTCDATETIME() FROM dbo.InventarioExistencia e JOIN dbo.AbastecimientoDetalle d ON d.ArticuloProveedorId=e.InventarioArticuloId AND d.AbastecimientoSolicitudId=@Id WHERE e.SedeId=@Sp;
   INSERT dbo.InventarioMovimiento(InventarioArticuloId,Tipo,SedeOrigenId,Cantidad,Referencia,Observacion,UsuarioId) SELECT d.ArticuloProveedorId,N'Reserva',@Sp,d.Cantidad,CONCAT(N'AB-',@Id),N'Reserva de abastecimiento',@UsuarioId FROM dbo.AbastecimientoDetalle d WHERE d.AbastecimientoSolicitudId=@Id;
 END;
 IF @Estado IN(N'Rechazado',N'Cancelado') AND @Anterior IN(N'Aprobado',N'Preparacion')
 BEGIN
   UPDATE e SET CantidadReservada=e.CantidadReservada-d.Cantidad,FechaModificacion=SYSUTCDATETIME() FROM dbo.InventarioExistencia e JOIN dbo.AbastecimientoDetalle d ON d.ArticuloProveedorId=e.InventarioArticuloId AND d.AbastecimientoSolicitudId=@Id WHERE e.SedeId=@Sp;
   INSERT dbo.InventarioMovimiento(InventarioArticuloId,Tipo,SedeOrigenId,Cantidad,Referencia,Observacion,UsuarioId) SELECT d.ArticuloProveedorId,N'Liberacion',@Sp,d.Cantidad,CONCAT(N'AB-',@Id),N'Liberación de abastecimiento',@UsuarioId FROM dbo.AbastecimientoDetalle d WHERE d.AbastecimientoSolicitudId=@Id;
 END;
 IF @Estado=N'Despachado'
 BEGIN
   IF EXISTS(SELECT 1 FROM dbo.AbastecimientoDetalle d JOIN dbo.InventarioExistencia e ON e.InventarioArticuloId=d.ArticuloProveedorId AND e.SedeId=@Sp WHERE d.AbastecimientoSolicitudId=@Id AND e.CantidadReservada<d.Cantidad) THROW 50002,N'La reserva de inventario no está disponible.',1;
   UPDATE e SET Cantidad=e.Cantidad-d.Cantidad,CantidadReservada=e.CantidadReservada-d.Cantidad,FechaModificacion=SYSUTCDATETIME() FROM dbo.InventarioExistencia e JOIN dbo.AbastecimientoDetalle d ON d.ArticuloProveedorId=e.InventarioArticuloId AND d.AbastecimientoSolicitudId=@Id WHERE e.SedeId=@Sp;
   INSERT dbo.InventarioMovimiento(InventarioArticuloId,Tipo,SedeOrigenId,Cantidad,Referencia,Observacion,UsuarioId) SELECT d.ArticuloProveedorId,N'Salida',@Sp,d.Cantidad,CONCAT(N'AB-',@Id),N'Despacho de abastecimiento',@UsuarioId FROM dbo.AbastecimientoDetalle d WHERE d.AbastecimientoSolicitudId=@Id;
 END;
 IF @Estado=N'Recibido'
 BEGIN
   INSERT dbo.InventarioExistencia(InventarioArticuloId,SedeId) SELECT d.ArticuloDestinoId,@Ss FROM dbo.AbastecimientoDetalle d WHERE d.AbastecimientoSolicitudId=@Id AND NOT EXISTS(SELECT 1 FROM dbo.InventarioExistencia e WHERE e.InventarioArticuloId=d.ArticuloDestinoId AND e.SedeId=@Ss);
   UPDATE e SET Cantidad=e.Cantidad+d.Cantidad,FechaModificacion=SYSUTCDATETIME() FROM dbo.InventarioExistencia e JOIN dbo.AbastecimientoDetalle d ON d.ArticuloDestinoId=e.InventarioArticuloId AND d.AbastecimientoSolicitudId=@Id WHERE e.SedeId=@Ss;
   INSERT dbo.InventarioMovimiento(InventarioArticuloId,Tipo,SedeDestinoId,Cantidad,Referencia,Observacion,UsuarioId) SELECT d.ArticuloDestinoId,N'Entrada',@Ss,d.Cantidad,CONCAT(N'AB-',@Id),N'Recepción de abastecimiento',@UsuarioId FROM dbo.AbastecimientoDetalle d WHERE d.AbastecimientoSolicitudId=@Id;
 END;
 UPDATE dbo.AbastecimientoSolicitud SET Estado=@Estado,FechaModificacion=SYSUTCDATETIME() WHERE AbastecimientoSolicitudId=@Id;
 INSERT dbo.AbastecimientoHistorial(AbastecimientoSolicitudId,UsuarioId,EstadoAnterior,EstadoNuevo,Comentario) VALUES(@Id,@UsuarioId,@Anterior,@Estado,NULLIF(LTRIM(RTRIM(@Comentario)),N''));EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Abastecimiento',N'CambiarEstado',@Id,N'Exitoso',@Estado;
 COMMIT TRANSACTION;SELECT 1;END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION;THROW;END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_abastecimiento_comentar @Id BIGINT,@Comentario NVARCHAR(1000),@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
 SET NOCOUNT ON;DECLARE @Estado NVARCHAR(30);SELECT @Estado=a.Estado FROM dbo.AbastecimientoSolicitud a WHERE a.AbastecimientoSolicitudId=@Id AND a.Eliminado=0 AND (@EsAdministrador=1 OR
 (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio x WHERE x.UsuarioId=@UsuarioId AND x.GiroNegocioId=a.GiroSolicitanteId AND x.Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=a.SedeSolicitanteId AND x.Eliminado=0)) OR
 (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio x WHERE x.UsuarioId=@UsuarioId AND x.GiroNegocioId=a.GiroProveedorId AND x.Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=a.SedeProveedorId AND x.Eliminado=0)));
 IF @Estado IS NULL THROW 50002,N'La solicitud no está disponible.',1;INSERT dbo.AbastecimientoHistorial(AbastecimientoSolicitudId,UsuarioId,EstadoAnterior,EstadoNuevo,Comentario) VALUES(@Id,@UsuarioId,@Estado,@Estado,LTRIM(RTRIM(@Comentario)));EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Abastecimiento',N'Comentar',@Id,N'Exitoso',NULL;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_abastecimiento_eliminar @Id BIGINT,@UsuarioId INT
AS
BEGIN
 SET NOCOUNT ON;IF EXISTS(SELECT 1 FROM dbo.AbastecimientoSolicitud WHERE AbastecimientoSolicitudId=@Id AND Estado IN(N'Aprobado',N'Preparacion',N'Despachado') AND Eliminado=0) THROW 50002,N'No puede eliminar una solicitud activa.',1;UPDATE dbo.AbastecimientoSolicitud SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE AbastecimientoSolicitudId=@Id AND Eliminado=0;DECLARE @F INT=@@ROWCOUNT;IF @F>0 EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Abastecimiento',N'Eliminar',@Id,N'Exitoso',NULL;SELECT @F;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_extraccion_leer_listado @UsuarioId INT,@EsAdministrador BIT,@Estado NVARCHAR(30)=NULL,@SedeId INT=NULL,@FechaDesde DATE=NULL,@FechaHasta DATE=NULL
AS
BEGIN
 SET NOCOUNT ON;DECLARE @GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Extracción minera' AND Eliminado=0);
 SELECT e.ExtraccionJornadaId,e.SedeId,s.Nombre Sede,e.InventarioArticuloId,a.Codigo,a.Nombre Articulo,a.UnidadMedida,e.FechaOperacion,e.Turno,e.FrenteExtraccion,e.CantidadExtraida,e.CantidadRechazada,e.CantidadAprovechable,e.DestinoTipo,e.DestinoDescripcion,e.Estado,u.NombreUsuario Responsable,e.FechaCreacion
 FROM dbo.ExtraccionJornada e JOIN dbo.Sede s ON s.SedeId=e.SedeId JOIN dbo.InventarioArticulo a ON a.InventarioArticuloId=e.InventarioArticuloId JOIN dbo.Usuario u ON u.UsuarioId=e.ResponsableUsuarioId
 WHERE e.Eliminado=0 AND (@Estado IS NULL OR e.Estado=@Estado) AND (@SedeId IS NULL OR e.SedeId=@SedeId) AND (@FechaDesde IS NULL OR e.FechaOperacion>=@FechaDesde) AND (@FechaHasta IS NULL OR e.FechaOperacion<=@FechaHasta)
 AND (@EsAdministrador=1 OR (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio x WHERE x.UsuarioId=@UsuarioId AND x.GiroNegocioId=@GiroId AND x.Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=e.SedeId AND x.Eliminado=0)))
 ORDER BY e.FechaOperacion DESC,e.ExtraccionJornadaId DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_extraccion_leer_por_id @Id BIGINT,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
 SET NOCOUNT ON;DECLARE @GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Extracción minera' AND Eliminado=0);
 SELECT e.ExtraccionJornadaId,e.SedeId,s.Nombre Sede,e.InventarioArticuloId,a.Codigo,a.Nombre Articulo,a.UnidadMedida,e.FechaOperacion,e.Turno,e.FrenteExtraccion,e.CantidadExtraida,e.CantidadRechazada,e.CantidadAprovechable,e.DestinoTipo,e.DestinoDescripcion,e.Estado,e.ResponsableUsuarioId,u.NombreUsuario Responsable,e.Observacion,e.FechaCreacion,e.FechaModificacion
 FROM dbo.ExtraccionJornada e JOIN dbo.Sede s ON s.SedeId=e.SedeId JOIN dbo.InventarioArticulo a ON a.InventarioArticuloId=e.InventarioArticuloId JOIN dbo.Usuario u ON u.UsuarioId=e.ResponsableUsuarioId
 WHERE e.ExtraccionJornadaId=@Id AND e.Eliminado=0 AND (@EsAdministrador=1 OR (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio x WHERE x.UsuarioId=@UsuarioId AND x.GiroNegocioId=@GiroId AND x.Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=e.SedeId AND x.Eliminado=0)));
 SELECT h.ExtraccionHistorialId,h.UsuarioId,u.NombreUsuario,h.EstadoAnterior,h.EstadoNuevo,h.Comentario,h.Fecha FROM dbo.ExtraccionHistorial h JOIN dbo.Usuario u ON u.UsuarioId=h.UsuarioId WHERE h.ExtraccionJornadaId=@Id ORDER BY h.Fecha DESC,h.ExtraccionHistorialId DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_extraccion_leer_opciones @UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
 SET NOCOUNT ON;DECLARE @GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Extracción minera' AND Eliminado=0);
 SELECT s.SedeId Id,s.Nombre FROM dbo.Sede s JOIN dbo.SedeGiroNegocio sg ON sg.SedeId=s.SedeId AND sg.GiroNegocioId=@GiroId AND sg.Eliminado=0 WHERE s.Eliminado=0 AND s.EsActivo=1 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=s.SedeId AND x.Eliminado=0)) ORDER BY s.Nombre;
 SELECT a.InventarioArticuloId Id,CONCAT(a.Codigo,N' · ',a.Nombre) Nombre FROM dbo.InventarioArticulo a WHERE a.GiroNegocioId=@GiroId AND a.Eliminado=0 AND a.EsActivo=1 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio x WHERE x.UsuarioId=@UsuarioId AND x.GiroNegocioId=@GiroId AND x.Eliminado=0)) ORDER BY a.Nombre;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_extraccion_crear @SedeId INT,@InventarioArticuloId INT,@FechaOperacion DATE,@Turno NVARCHAR(30),@FrenteExtraccion NVARCHAR(120),@CantidadExtraida DECIMAL(18,3),@CantidadRechazada DECIMAL(18,3),@DestinoTipo NVARCHAR(30),@DestinoDescripcion NVARCHAR(200)=NULL,@Observacion NVARCHAR(500)=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;BEGIN TRY BEGIN TRANSACTION;DECLARE @GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Extracción minera' AND Eliminado=0);
 IF @DestinoTipo NOT IN(N'Inventario',N'Procesamiento',N'Transporte',N'Tercero') THROW 50002,N'Destino inválido.',1;IF @CantidadExtraida<=0 OR @CantidadRechazada<0 OR @CantidadRechazada>=@CantidadExtraida THROW 50002,N'Cantidades inválidas.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.InventarioArticulo WHERE InventarioArticuloId=@InventarioArticuloId AND GiroNegocioId=@GiroId AND Eliminado=0 AND EsActivo=1) THROW 50002,N'El artículo no corresponde a extracción.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.SedeGiroNegocio WHERE SedeId=@SedeId AND GiroNegocioId=@GiroId AND Eliminado=0) THROW 50002,N'La sede no corresponde a extracción.',1;
 IF @EsAdministrador=0 AND (NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroId AND Eliminado=0) OR NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0)) THROW 50002,N'El usuario no tiene acceso a la planta.',1;
 INSERT dbo.ExtraccionJornada(SedeId,InventarioArticuloId,FechaOperacion,Turno,FrenteExtraccion,CantidadExtraida,CantidadRechazada,DestinoTipo,DestinoDescripcion,ResponsableUsuarioId,Observacion) VALUES(@SedeId,@InventarioArticuloId,@FechaOperacion,LTRIM(RTRIM(@Turno)),LTRIM(RTRIM(@FrenteExtraccion)),@CantidadExtraida,@CantidadRechazada,@DestinoTipo,NULLIF(LTRIM(RTRIM(@DestinoDescripcion)),N''),@UsuarioId,NULLIF(LTRIM(RTRIM(@Observacion)),N''));
 DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());INSERT dbo.ExtraccionHistorial(ExtraccionJornadaId,UsuarioId,EstadoNuevo,Comentario) VALUES(@Id,@UsuarioId,N'Registrada',N'Jornada registrada.');EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Extraccion',N'Crear',@Id,N'Exitoso',@DestinoTipo;COMMIT;SELECT @Id;END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_extraccion_actualizar_estado @Id BIGINT,@Estado NVARCHAR(30),@Comentario NVARCHAR(500)=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;BEGIN TRY BEGIN TRANSACTION;DECLARE @Anterior NVARCHAR(30),@SedeId INT,@ArticuloId INT,@Cantidad DECIMAL(18,3),@GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Extracción minera' AND Eliminado=0);SELECT @Anterior=Estado,@SedeId=SedeId,@ArticuloId=InventarioArticuloId,@Cantidad=CantidadAprovechable FROM dbo.ExtraccionJornada WITH(UPDLOCK) WHERE ExtraccionJornadaId=@Id AND Eliminado=0;
 IF @Anterior IS NULL THROW 50002,N'La jornada no existe.',1;IF NOT((@Anterior=N'Registrada' AND @Estado IN(N'Confirmada',N'Cancelada')) OR (@Anterior=N'Confirmada' AND @Estado=N'Entregada')) THROW 50002,N'Transición inválida.',1;
 IF @EsAdministrador=0 AND (NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroId AND Eliminado=0) OR NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0)) THROW 50002,N'El usuario no tiene acceso a la planta.',1;
 IF @Estado=N'Confirmada' BEGIN IF NOT EXISTS(SELECT 1 FROM dbo.InventarioExistencia WHERE InventarioArticuloId=@ArticuloId AND SedeId=@SedeId) INSERT dbo.InventarioExistencia(InventarioArticuloId,SedeId) VALUES(@ArticuloId,@SedeId);UPDATE dbo.InventarioExistencia SET Cantidad=Cantidad+@Cantidad,FechaModificacion=SYSUTCDATETIME() WHERE InventarioArticuloId=@ArticuloId AND SedeId=@SedeId;INSERT dbo.InventarioMovimiento(InventarioArticuloId,Tipo,SedeDestinoId,Cantidad,Referencia,Observacion,UsuarioId) VALUES(@ArticuloId,N'Entrada',@SedeId,@Cantidad,CONCAT(N'EXT-',@Id),N'Producción de extracción',@UsuarioId);END;
 IF @Estado=N'Entregada' BEGIN IF NOT EXISTS(SELECT 1 FROM dbo.InventarioExistencia WHERE InventarioArticuloId=@ArticuloId AND SedeId=@SedeId AND Cantidad-CantidadReservada>=@Cantidad) THROW 50002,N'La cantidad aprovechable ya no está disponible.',1;UPDATE dbo.InventarioExistencia SET Cantidad=Cantidad-@Cantidad,FechaModificacion=SYSUTCDATETIME() WHERE InventarioArticuloId=@ArticuloId AND SedeId=@SedeId;INSERT dbo.InventarioMovimiento(InventarioArticuloId,Tipo,SedeOrigenId,Cantidad,Referencia,Observacion,UsuarioId) VALUES(@ArticuloId,N'Salida',@SedeId,@Cantidad,CONCAT(N'EXT-',@Id),N'Entrega de extracción',@UsuarioId);END;
 UPDATE dbo.ExtraccionJornada SET Estado=@Estado,FechaModificacion=SYSUTCDATETIME() WHERE ExtraccionJornadaId=@Id;INSERT dbo.ExtraccionHistorial(ExtraccionJornadaId,UsuarioId,EstadoAnterior,EstadoNuevo,Comentario) VALUES(@Id,@UsuarioId,@Anterior,@Estado,NULLIF(LTRIM(RTRIM(@Comentario)),N''));EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Extraccion',N'CambiarEstado',@Id,N'Exitoso',@Estado;COMMIT;SELECT 1;END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_extraccion_eliminar @Id BIGINT,@UsuarioId INT
AS
BEGIN SET NOCOUNT ON;UPDATE dbo.ExtraccionJornada SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE ExtraccionJornadaId=@Id AND Eliminado=0 AND Estado IN(N'Entregada',N'Cancelada');DECLARE @F INT=@@ROWCOUNT;IF @F>0 EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Extraccion',N'Eliminar',@Id,N'Exitoso',NULL;SELECT @F;END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_produccion_leer_listado @UsuarioId INT,@EsAdministrador BIT,@Estado NVARCHAR(30)=NULL,@SedeId INT=NULL,@FechaDesde DATE=NULL,@FechaHasta DATE=NULL
AS
BEGIN
 SET NOCOUNT ON;DECLARE @GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Procesamiento de materia prima' AND Eliminado=0);
 SELECT o.ProduccionOrdenId,o.SedeId,s.Nombre Sede,o.ArticuloEntradaId,ae.Codigo CodigoEntrada,ae.Nombre ArticuloEntrada,ae.UnidadMedida UnidadEntrada,o.ArticuloSalidaId,asal.Codigo CodigoSalida,asal.Nombre ArticuloSalida,asal.UnidadMedida UnidadSalida,o.FechaPlanificada,o.CantidadEntrada,o.CantidadSalidaPlanificada,o.CantidadSalidaReal,o.CantidadMerma,o.CostoUnitario,o.Estado,u.NombreUsuario Responsable,o.FechaCreacion,
 (SELECT TOP(1) e.Nombre FROM dbo.ProduccionEtapa e WHERE e.ProduccionOrdenId=o.ProduccionOrdenId AND e.Estado=N'EnProceso' ORDER BY e.Secuencia) EtapaActual
 FROM dbo.ProduccionOrden o JOIN dbo.Sede s ON s.SedeId=o.SedeId JOIN dbo.InventarioArticulo ae ON ae.InventarioArticuloId=o.ArticuloEntradaId JOIN dbo.InventarioArticulo asal ON asal.InventarioArticuloId=o.ArticuloSalidaId JOIN dbo.Usuario u ON u.UsuarioId=o.ResponsableUsuarioId
 WHERE o.Eliminado=0 AND (@Estado IS NULL OR o.Estado=@Estado) AND (@SedeId IS NULL OR o.SedeId=@SedeId) AND (@FechaDesde IS NULL OR o.FechaPlanificada>=@FechaDesde) AND (@FechaHasta IS NULL OR o.FechaPlanificada<=@FechaHasta)
 AND (@EsAdministrador=1 OR (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio x WHERE x.UsuarioId=@UsuarioId AND x.GiroNegocioId=@GiroId AND x.Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=o.SedeId AND x.Eliminado=0)))
 ORDER BY o.FechaPlanificada DESC,o.ProduccionOrdenId DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_produccion_leer_por_id @Id BIGINT,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
 SET NOCOUNT ON;DECLARE @GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Procesamiento de materia prima' AND Eliminado=0);
 SELECT o.ProduccionOrdenId,o.SedeId,s.Nombre Sede,o.ArticuloEntradaId,ae.Codigo CodigoEntrada,ae.Nombre ArticuloEntrada,ae.UnidadMedida UnidadEntrada,o.ArticuloSalidaId,asal.Codigo CodigoSalida,asal.Nombre ArticuloSalida,asal.UnidadMedida UnidadSalida,o.FechaPlanificada,o.CantidadEntrada,o.CantidadSalidaPlanificada,o.CantidadSalidaReal,o.CantidadMerma,o.CostoUnitario,o.Estado,o.ResponsableUsuarioId,u.NombreUsuario Responsable,o.Observacion,o.FechaCreacion,o.FechaModificacion
 FROM dbo.ProduccionOrden o JOIN dbo.Sede s ON s.SedeId=o.SedeId JOIN dbo.InventarioArticulo ae ON ae.InventarioArticuloId=o.ArticuloEntradaId JOIN dbo.InventarioArticulo asal ON asal.InventarioArticuloId=o.ArticuloSalidaId JOIN dbo.Usuario u ON u.UsuarioId=o.ResponsableUsuarioId
 WHERE o.ProduccionOrdenId=@Id AND o.Eliminado=0 AND (@EsAdministrador=1 OR (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio x WHERE x.UsuarioId=@UsuarioId AND x.GiroNegocioId=@GiroId AND x.Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=o.SedeId AND x.Eliminado=0)));
 SELECT ProduccionEtapaId,Secuencia,Nombre,Estado,FechaInicio,FechaFin,Observacion FROM dbo.ProduccionEtapa WHERE ProduccionOrdenId=@Id ORDER BY Secuencia;
 SELECT h.ProduccionHistorialId,h.UsuarioId,u.NombreUsuario,h.EstadoAnterior,h.EstadoNuevo,h.Comentario,h.Fecha FROM dbo.ProduccionHistorial h JOIN dbo.Usuario u ON u.UsuarioId=h.UsuarioId WHERE h.ProduccionOrdenId=@Id ORDER BY h.Fecha DESC,h.ProduccionHistorialId DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_produccion_leer_opciones @UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
 SET NOCOUNT ON;DECLARE @GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Procesamiento de materia prima' AND Eliminado=0);
 SELECT s.SedeId Id,s.Nombre FROM dbo.Sede s JOIN dbo.SedeGiroNegocio sg ON sg.SedeId=s.SedeId AND sg.GiroNegocioId=@GiroId AND sg.Eliminado=0 WHERE s.Eliminado=0 AND s.EsActivo=1 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=s.SedeId AND x.Eliminado=0)) ORDER BY s.Nombre;
 SELECT a.InventarioArticuloId Id,CONCAT(a.Codigo,N' · ',a.Nombre) Nombre FROM dbo.InventarioArticulo a WHERE a.GiroNegocioId=@GiroId AND a.Eliminado=0 AND a.EsActivo=1 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio x WHERE x.UsuarioId=@UsuarioId AND x.GiroNegocioId=@GiroId AND x.Eliminado=0)) ORDER BY a.Nombre;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_produccion_crear @SedeId INT,@ArticuloEntradaId INT,@ArticuloSalidaId INT,@FechaPlanificada DATE,@CantidadEntrada DECIMAL(18,3),@CantidadSalidaPlanificada DECIMAL(18,3),@Observacion NVARCHAR(500)=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;BEGIN TRY BEGIN TRANSACTION;DECLARE @GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Procesamiento de materia prima' AND Eliminado=0);
 IF @CantidadEntrada<=0 OR @CantidadSalidaPlanificada<=0 OR @ArticuloEntradaId=@ArticuloSalidaId THROW 50002,N'Datos de producción inválidos.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.SedeGiroNegocio WHERE SedeId=@SedeId AND GiroNegocioId=@GiroId AND Eliminado=0) THROW 50002,N'La sede no corresponde a procesamiento.',1;
 IF (SELECT COUNT(*) FROM dbo.InventarioArticulo WHERE InventarioArticuloId IN(@ArticuloEntradaId,@ArticuloSalidaId) AND GiroNegocioId=@GiroId AND Eliminado=0 AND EsActivo=1)<>2 THROW 50002,N'Los artículos deben pertenecer a procesamiento.',1;
 IF @EsAdministrador=0 AND (NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroId AND Eliminado=0) OR NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0)) THROW 50002,N'El usuario no tiene acceso a la planta.',1;
 INSERT dbo.ProduccionOrden(SedeId,ArticuloEntradaId,ArticuloSalidaId,FechaPlanificada,CantidadEntrada,CantidadSalidaPlanificada,ResponsableUsuarioId,Observacion) VALUES(@SedeId,@ArticuloEntradaId,@ArticuloSalidaId,@FechaPlanificada,@CantidadEntrada,@CantidadSalidaPlanificada,@UsuarioId,NULLIF(LTRIM(RTRIM(@Observacion)),N''));DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());
 INSERT dbo.ProduccionEtapa(ProduccionOrdenId,Secuencia,Nombre) VALUES(@Id,1,N'Preparación'),(@Id,2,N'Transformación'),(@Id,3,N'Control de calidad');INSERT dbo.ProduccionHistorial(ProduccionOrdenId,UsuarioId,EstadoNuevo,Comentario) VALUES(@Id,@UsuarioId,N'Planificada',N'Orden creada.');EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Produccion',N'Crear',@Id,N'Exitoso',NULL;COMMIT;SELECT @Id;END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_produccion_actualizar_estado @Id BIGINT,@Estado NVARCHAR(30),@CantidadSalidaReal DECIMAL(18,3)=NULL,@CantidadMerma DECIMAL(18,3)=NULL,@CostoUnitario DECIMAL(18,2)=NULL,@Comentario NVARCHAR(500)=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;BEGIN TRY BEGIN TRANSACTION;DECLARE @Anterior NVARCHAR(30),@SedeId INT,@EntradaId INT,@SalidaId INT,@CantidadEntrada DECIMAL(18,3),@GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Procesamiento de materia prima' AND Eliminado=0);SELECT @Anterior=Estado,@SedeId=SedeId,@EntradaId=ArticuloEntradaId,@SalidaId=ArticuloSalidaId,@CantidadEntrada=CantidadEntrada FROM dbo.ProduccionOrden WITH(UPDLOCK) WHERE ProduccionOrdenId=@Id AND Eliminado=0;
 IF @Anterior IS NULL THROW 50002,N'La orden no existe.',1;IF NOT((@Anterior=N'Planificada' AND @Estado IN(N'EnProceso',N'Cancelada')) OR (@Anterior=N'EnProceso' AND @Estado=N'Completada')) THROW 50002,N'Transición inválida.',1;
 IF @EsAdministrador=0 AND (NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroId AND Eliminado=0) OR NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0)) THROW 50002,N'El usuario no tiene acceso a la planta.',1;
 IF @Estado=N'EnProceso' BEGIN IF NOT EXISTS(SELECT 1 FROM dbo.InventarioExistencia WHERE InventarioArticuloId=@EntradaId AND SedeId=@SedeId AND Cantidad-CantidadReservada>=@CantidadEntrada) THROW 50002,N'Materia prima insuficiente.',1;UPDATE dbo.InventarioExistencia SET Cantidad=Cantidad-@CantidadEntrada,FechaModificacion=SYSUTCDATETIME() WHERE InventarioArticuloId=@EntradaId AND SedeId=@SedeId;INSERT dbo.InventarioMovimiento(InventarioArticuloId,Tipo,SedeOrigenId,Cantidad,Referencia,Observacion,UsuarioId) VALUES(@EntradaId,N'Salida',@SedeId,@CantidadEntrada,CONCAT(N'PROD-',@Id,N'-IN'),N'Consumo de producción',@UsuarioId);UPDATE dbo.ProduccionEtapa SET Estado=N'EnProceso',FechaInicio=SYSUTCDATETIME() WHERE ProduccionOrdenId=@Id AND Secuencia=1;END;
 IF @Estado=N'Completada' BEGIN IF @CantidadSalidaReal IS NULL OR @CantidadSalidaReal<=0 OR @CantidadMerma IS NULL OR @CantidadMerma<0 OR @CostoUnitario IS NULL OR @CostoUnitario<0 THROW 50002,N'Resultados de producción inválidos.',1;IF EXISTS(SELECT 1 FROM dbo.ProduccionEtapa WHERE ProduccionOrdenId=@Id AND Estado<>N'Completada') THROW 50002,N'Debe completar todas las etapas.',1;IF NOT EXISTS(SELECT 1 FROM dbo.InventarioExistencia WHERE InventarioArticuloId=@SalidaId AND SedeId=@SedeId) INSERT dbo.InventarioExistencia(InventarioArticuloId,SedeId) VALUES(@SalidaId,@SedeId);UPDATE dbo.InventarioExistencia SET Cantidad=Cantidad+@CantidadSalidaReal,FechaModificacion=SYSUTCDATETIME() WHERE InventarioArticuloId=@SalidaId AND SedeId=@SedeId;INSERT dbo.InventarioMovimiento(InventarioArticuloId,Tipo,SedeDestinoId,Cantidad,Referencia,Observacion,UsuarioId) VALUES(@SalidaId,N'Entrada',@SedeId,@CantidadSalidaReal,CONCAT(N'PROD-',@Id,N'-OUT'),N'Producto terminado',@UsuarioId);END;
 UPDATE dbo.ProduccionOrden SET Estado=@Estado,CantidadSalidaReal=CASE WHEN @Estado=N'Completada' THEN @CantidadSalidaReal ELSE CantidadSalidaReal END,CantidadMerma=CASE WHEN @Estado=N'Completada' THEN @CantidadMerma ELSE CantidadMerma END,CostoUnitario=CASE WHEN @Estado=N'Completada' THEN @CostoUnitario ELSE CostoUnitario END,FechaModificacion=SYSUTCDATETIME() WHERE ProduccionOrdenId=@Id;INSERT dbo.ProduccionHistorial(ProduccionOrdenId,UsuarioId,EstadoAnterior,EstadoNuevo,Comentario) VALUES(@Id,@UsuarioId,@Anterior,@Estado,NULLIF(LTRIM(RTRIM(@Comentario)),N''));EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Produccion',N'CambiarEstado',@Id,N'Exitoso',@Estado;COMMIT;SELECT 1;END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_produccion_completar_etapa @Id BIGINT,@EtapaId BIGINT,@Observacion NVARCHAR(500)=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;BEGIN TRY BEGIN TRANSACTION;DECLARE @SedeId INT,@GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Procesamiento de materia prima' AND Eliminado=0);SELECT @SedeId=SedeId FROM dbo.ProduccionOrden WITH(UPDLOCK) WHERE ProduccionOrdenId=@Id AND Estado=N'EnProceso' AND Eliminado=0;IF @SedeId IS NULL THROW 50002,N'La orden no está en proceso.',1;
 IF @EsAdministrador=0 AND (NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroId AND Eliminado=0) OR NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0)) THROW 50002,N'El usuario no tiene acceso a la planta.',1;
 DECLARE @Secuencia INT;SELECT @Secuencia=Secuencia FROM dbo.ProduccionEtapa WITH(UPDLOCK) WHERE ProduccionEtapaId=@EtapaId AND ProduccionOrdenId=@Id AND Estado=N'EnProceso';IF @Secuencia IS NULL THROW 50002,N'La etapa no es la etapa activa.',1;UPDATE dbo.ProduccionEtapa SET Estado=N'Completada',FechaFin=SYSUTCDATETIME(),Observacion=NULLIF(LTRIM(RTRIM(@Observacion)),N'') WHERE ProduccionEtapaId=@EtapaId;UPDATE dbo.ProduccionEtapa SET Estado=N'EnProceso',FechaInicio=SYSUTCDATETIME() WHERE ProduccionOrdenId=@Id AND Secuencia=@Secuencia+1 AND Estado=N'Pendiente';DECLARE @Detalle NVARCHAR(30)=CONVERT(NVARCHAR(30),@EtapaId);EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Produccion',N'CompletarEtapa',@Id,N'Exitoso',@Detalle;COMMIT;SELECT 1;END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_produccion_eliminar @Id BIGINT,@UsuarioId INT
AS
BEGIN SET NOCOUNT ON;UPDATE dbo.ProduccionOrden SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE ProduccionOrdenId=@Id AND Eliminado=0 AND Estado IN(N'Completada',N'Cancelada');DECLARE @F INT=@@ROWCOUNT;IF @F>0 EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Produccion',N'Eliminar',@Id,N'Exitoso',NULL;SELECT @F;END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_maquinaria_leer_listado @UsuarioId INT,@EsAdministrador BIT,@Estado NVARCHAR(30)=NULL,@SedeId INT=NULL,@Busqueda NVARCHAR(120)=NULL
AS
BEGIN SET NOCOUNT ON;DECLARE @GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Venta y alquiler de maquinaria' AND Eliminado=0);SELECT e.MaquinariaEquipoId,e.SedeId,s.Nombre Sede,e.Codigo,e.Tipo,e.Marca,e.Modelo,e.Anio,e.Estado,e.PrecioVenta,e.TarifaDiaria,e.HorasUso,e.Observacion,e.FechaCreacion FROM dbo.MaquinariaEquipo e JOIN dbo.Sede s ON s.SedeId=e.SedeId WHERE e.Eliminado=0 AND (@Estado IS NULL OR e.Estado=@Estado) AND (@SedeId IS NULL OR e.SedeId=@SedeId) AND (@Busqueda IS NULL OR CONCAT(e.Codigo,N' ',e.Tipo,N' ',e.Marca,N' ',e.Modelo) LIKE N'%'+@Busqueda+N'%') AND (@EsAdministrador=1 OR (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio x WHERE x.UsuarioId=@UsuarioId AND x.GiroNegocioId=@GiroId AND x.Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=e.SedeId AND x.Eliminado=0))) ORDER BY e.Codigo;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_maquinaria_leer_por_id @Id INT,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;DECLARE @GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Venta y alquiler de maquinaria' AND Eliminado=0);SELECT e.MaquinariaEquipoId,e.SedeId,s.Nombre Sede,e.Codigo,e.Tipo,e.Marca,e.Modelo,e.Anio,e.Estado,e.PrecioVenta,e.TarifaDiaria,e.HorasUso,e.Observacion,e.FechaCreacion,e.FechaModificacion FROM dbo.MaquinariaEquipo e JOIN dbo.Sede s ON s.SedeId=e.SedeId WHERE e.MaquinariaEquipoId=@Id AND e.Eliminado=0 AND (@EsAdministrador=1 OR (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio x WHERE x.UsuarioId=@UsuarioId AND x.GiroNegocioId=@GiroId AND x.Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=e.SedeId AND x.Eliminado=0)));
 SELECT c.MaquinariaContratoId,c.ClienteId,cl.Nombre Cliente,c.Tipo,c.FechaInicio,c.FechaFin,c.MontoTotal,c.Deposito,c.Estado,c.HorasEntrega,c.HorasDevolucion,u.NombreUsuario Responsable,c.Observacion,c.FechaCreacion FROM dbo.MaquinariaContrato c JOIN dbo.Cliente cl ON cl.ClienteId=c.ClienteId JOIN dbo.Usuario u ON u.UsuarioId=c.ResponsableUsuarioId WHERE c.MaquinariaEquipoId=@Id AND c.Eliminado=0 ORDER BY c.FechaCreacion DESC;
 SELECT m.MaquinariaMantenimientoId,m.Tipo,m.FechaProgramada,m.FechaCompletada,m.Costo,m.Estado,u.NombreUsuario Responsable,m.Observacion,m.FechaCreacion FROM dbo.MaquinariaMantenimiento m JOIN dbo.Usuario u ON u.UsuarioId=m.ResponsableUsuarioId WHERE m.MaquinariaEquipoId=@Id ORDER BY m.FechaCreacion DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_maquinaria_leer_opciones @UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;DECLARE @GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Venta y alquiler de maquinaria' AND Eliminado=0);SELECT s.SedeId Id,s.Nombre FROM dbo.Sede s JOIN dbo.SedeGiroNegocio sg ON sg.SedeId=s.SedeId AND sg.GiroNegocioId=@GiroId AND sg.Eliminado=0 WHERE s.Eliminado=0 AND s.EsActivo=1 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=s.SedeId AND x.Eliminado=0)) ORDER BY s.Nombre;SELECT ClienteId Id,Nombre FROM dbo.Cliente WHERE Eliminado=0 AND EsActivo=1 ORDER BY Nombre;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_maquinaria_crear_equipo @SedeId INT,@Codigo NVARCHAR(50),@Tipo NVARCHAR(80),@Marca NVARCHAR(80),@Modelo NVARCHAR(80),@Anio SMALLINT=NULL,@PrecioVenta DECIMAL(18,2)=NULL,@TarifaDiaria DECIMAL(18,2)=NULL,@HorasUso DECIMAL(18,2)=0,@Observacion NVARCHAR(500)=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;DECLARE @GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Venta y alquiler de maquinaria' AND Eliminado=0);IF @PrecioVenta IS NULL AND @TarifaDiaria IS NULL THROW 50002,N'Indique precio de venta o tarifa diaria.',1;IF NOT EXISTS(SELECT 1 FROM dbo.SedeGiroNegocio WHERE SedeId=@SedeId AND GiroNegocioId=@GiroId AND Eliminado=0) THROW 50002,N'La sede no opera maquinaria.',1;IF @EsAdministrador=0 AND (NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroId AND Eliminado=0) OR NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0)) THROW 50002,N'El usuario no tiene acceso a la sede.',1;INSERT dbo.MaquinariaEquipo(SedeId,Codigo,Tipo,Marca,Modelo,Anio,PrecioVenta,TarifaDiaria,HorasUso,Observacion) VALUES(@SedeId,UPPER(LTRIM(RTRIM(@Codigo))),LTRIM(RTRIM(@Tipo)),LTRIM(RTRIM(@Marca)),LTRIM(RTRIM(@Modelo)),@Anio,@PrecioVenta,@TarifaDiaria,@HorasUso,NULLIF(LTRIM(RTRIM(@Observacion)),N''));DECLARE @Id INT=CONVERT(INT,SCOPE_IDENTITY());EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Maquinaria',N'CrearEquipo',@Id,N'Exitoso',NULL;SELECT @Id;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_maquinaria_crear_contrato @EquipoId INT,@ClienteId INT,@Tipo NVARCHAR(20),@FechaInicio DATE,@FechaFin DATE=NULL,@MontoTotal DECIMAL(18,2),@Deposito DECIMAL(18,2)=0,@Observacion NVARCHAR(500)=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;SET XACT_ABORT ON;BEGIN TRY BEGIN TRANSACTION;DECLARE @SedeId INT,@Estado NVARCHAR(30),@GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Venta y alquiler de maquinaria' AND Eliminado=0);SELECT @SedeId=SedeId,@Estado=Estado FROM dbo.MaquinariaEquipo WITH(UPDLOCK) WHERE MaquinariaEquipoId=@EquipoId AND Eliminado=0;IF @Estado<>N'Disponible' THROW 50002,N'El equipo no está disponible.',1;IF @Tipo NOT IN(N'Venta',N'Alquiler') OR @MontoTotal<0 OR @Deposito<0 OR (@Tipo=N'Alquiler' AND (@FechaFin IS NULL OR @FechaFin<@FechaInicio)) THROW 50002,N'Datos de contrato inválidos.',1;IF NOT EXISTS(SELECT 1 FROM dbo.Cliente WHERE ClienteId=@ClienteId AND Eliminado=0 AND EsActivo=1) THROW 50002,N'Cliente inválido.',1;IF @EsAdministrador=0 AND (NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroId AND Eliminado=0) OR NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0)) THROW 50002,N'Sin acceso al equipo.',1;INSERT dbo.MaquinariaContrato(MaquinariaEquipoId,ClienteId,Tipo,FechaInicio,FechaFin,MontoTotal,Deposito,HorasEntrega,ResponsableUsuarioId,Observacion) SELECT @EquipoId,@ClienteId,@Tipo,@FechaInicio,@FechaFin,@MontoTotal,@Deposito,HorasUso,@UsuarioId,NULLIF(LTRIM(RTRIM(@Observacion)),N'') FROM dbo.MaquinariaEquipo WHERE MaquinariaEquipoId=@EquipoId;DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());UPDATE dbo.MaquinariaEquipo SET Estado=N'Reservada',FechaModificacion=SYSUTCDATETIME() WHERE MaquinariaEquipoId=@EquipoId;EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Maquinaria',N'CrearContrato',@Id,N'Exitoso',@Tipo;COMMIT;SELECT @Id;END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_maquinaria_actualizar_contrato @Id BIGINT,@Estado NVARCHAR(20),@HorasDevolucion DECIMAL(18,2)=NULL,@Observacion NVARCHAR(500)=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;SET XACT_ABORT ON;BEGIN TRY BEGIN TRANSACTION;DECLARE @Anterior NVARCHAR(20),@Tipo NVARCHAR(20),@EquipoId INT,@SedeId INT,@HorasEntrega DECIMAL(18,2),@GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Venta y alquiler de maquinaria' AND Eliminado=0);SELECT @Anterior=c.Estado,@Tipo=c.Tipo,@EquipoId=c.MaquinariaEquipoId,@SedeId=e.SedeId,@HorasEntrega=c.HorasEntrega FROM dbo.MaquinariaContrato c WITH(UPDLOCK) JOIN dbo.MaquinariaEquipo e ON e.MaquinariaEquipoId=c.MaquinariaEquipoId WHERE c.MaquinariaContratoId=@Id AND c.Eliminado=0;IF @Anterior IS NULL THROW 50002,N'Contrato inexistente.',1;IF NOT((@Anterior=N'Reservado' AND @Estado IN(N'Activo',N'Cancelado')) OR (@Anterior=N'Activo' AND @Estado IN(N'Finalizado',N'Cancelado'))) THROW 50002,N'Transición inválida.',1;IF @EsAdministrador=0 AND (NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroId AND Eliminado=0) OR NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0)) THROW 50002,N'Sin acceso al equipo.',1;IF @Estado=N'Activo' UPDATE dbo.MaquinariaEquipo SET Estado=CASE WHEN @Tipo=N'Alquiler' THEN N'Alquilada' ELSE N'Reservada' END,FechaModificacion=SYSUTCDATETIME() WHERE MaquinariaEquipoId=@EquipoId;IF @Estado=N'Finalizado' BEGIN IF @Tipo=N'Alquiler' AND (@HorasDevolucion IS NULL OR @HorasDevolucion<@HorasEntrega) THROW 50002,N'Lectura de devolución inválida.',1;UPDATE dbo.MaquinariaEquipo SET Estado=CASE WHEN @Tipo=N'Venta' THEN N'Vendida' ELSE N'Disponible' END,HorasUso=CASE WHEN @Tipo=N'Alquiler' THEN @HorasDevolucion ELSE HorasUso END,FechaModificacion=SYSUTCDATETIME() WHERE MaquinariaEquipoId=@EquipoId;END;IF @Estado=N'Cancelado' UPDATE dbo.MaquinariaEquipo SET Estado=N'Disponible',FechaModificacion=SYSUTCDATETIME() WHERE MaquinariaEquipoId=@EquipoId;UPDATE dbo.MaquinariaContrato SET Estado=@Estado,HorasDevolucion=CASE WHEN @Estado=N'Finalizado' THEN @HorasDevolucion ELSE HorasDevolucion END,Observacion=COALESCE(NULLIF(LTRIM(RTRIM(@Observacion)),N''),Observacion),FechaModificacion=SYSUTCDATETIME() WHERE MaquinariaContratoId=@Id;EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Maquinaria',N'EstadoContrato',@Id,N'Exitoso',@Estado;COMMIT;SELECT 1;END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_maquinaria_crear_mantenimiento @EquipoId INT,@Tipo NVARCHAR(80),@FechaProgramada DATE,@Costo DECIMAL(18,2),@Observacion NVARCHAR(500)=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;DECLARE @SedeId INT,@Estado NVARCHAR(30),@GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Venta y alquiler de maquinaria' AND Eliminado=0);SELECT @SedeId=SedeId,@Estado=Estado FROM dbo.MaquinariaEquipo WHERE MaquinariaEquipoId=@EquipoId AND Eliminado=0;IF @Estado<>N'Disponible' THROW 50002,N'El equipo no está disponible para mantenimiento.',1;IF @Costo<0 THROW 50002,N'Costo inválido.',1;IF @EsAdministrador=0 AND (NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroId AND Eliminado=0) OR NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0)) THROW 50002,N'Sin acceso al equipo.',1;INSERT dbo.MaquinariaMantenimiento(MaquinariaEquipoId,Tipo,FechaProgramada,Costo,ResponsableUsuarioId,Observacion) VALUES(@EquipoId,LTRIM(RTRIM(@Tipo)),@FechaProgramada,@Costo,@UsuarioId,NULLIF(LTRIM(RTRIM(@Observacion)),N''));DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Maquinaria',N'CrearMantenimiento',@Id,N'Exitoso',NULL;SELECT @Id;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_maquinaria_actualizar_mantenimiento @Id BIGINT,@Estado NVARCHAR(20),@Observacion NVARCHAR(500)=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;SET XACT_ABORT ON;BEGIN TRY BEGIN TRANSACTION;DECLARE @Anterior NVARCHAR(20),@EquipoId INT,@SedeId INT,@EquipoEstado NVARCHAR(30),@GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Venta y alquiler de maquinaria' AND Eliminado=0);SELECT @Anterior=m.Estado,@EquipoId=m.MaquinariaEquipoId,@SedeId=e.SedeId,@EquipoEstado=e.Estado FROM dbo.MaquinariaMantenimiento m WITH(UPDLOCK) JOIN dbo.MaquinariaEquipo e ON e.MaquinariaEquipoId=m.MaquinariaEquipoId WHERE m.MaquinariaMantenimientoId=@Id;IF @Anterior IS NULL OR NOT((@Anterior=N'Programado' AND @Estado IN(N'EnProceso',N'Cancelado')) OR (@Anterior=N'EnProceso' AND @Estado IN(N'Completado',N'Cancelado'))) THROW 50002,N'Transición inválida.',1;IF @EsAdministrador=0 AND (NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroId AND Eliminado=0) OR NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0)) THROW 50002,N'Sin acceso al equipo.',1;IF @Estado=N'EnProceso' BEGIN IF @EquipoEstado<>N'Disponible' THROW 50002,N'El equipo ya no está disponible.',1;UPDATE dbo.MaquinariaEquipo SET Estado=N'Mantenimiento',FechaModificacion=SYSUTCDATETIME() WHERE MaquinariaEquipoId=@EquipoId;END;IF @Estado IN(N'Completado',N'Cancelado') AND @Anterior=N'EnProceso' UPDATE dbo.MaquinariaEquipo SET Estado=N'Disponible',FechaModificacion=SYSUTCDATETIME() WHERE MaquinariaEquipoId=@EquipoId;UPDATE dbo.MaquinariaMantenimiento SET Estado=@Estado,FechaCompletada=CASE WHEN @Estado=N'Completado' THEN CONVERT(DATE,SYSUTCDATETIME()) ELSE FechaCompletada END,Observacion=COALESCE(NULLIF(LTRIM(RTRIM(@Observacion)),N''),Observacion) WHERE MaquinariaMantenimientoId=@Id;EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Maquinaria',N'EstadoMantenimiento',@Id,N'Exitoso',@Estado;COMMIT;SELECT 1;END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_maquinaria_eliminar_equipo @Id INT,@UsuarioId INT
AS
BEGIN SET NOCOUNT ON;IF EXISTS(SELECT 1 FROM dbo.MaquinariaContrato WHERE MaquinariaEquipoId=@Id AND Estado IN(N'Reservado',N'Activo') AND Eliminado=0) OR EXISTS(SELECT 1 FROM dbo.MaquinariaMantenimiento WHERE MaquinariaEquipoId=@Id AND Estado IN(N'Programado',N'EnProceso')) THROW 50002,N'El equipo tiene operaciones activas.',1;UPDATE dbo.MaquinariaEquipo SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE MaquinariaEquipoId=@Id AND Eliminado=0;DECLARE @F INT=@@ROWCOUNT;IF @F>0 EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Maquinaria',N'EliminarEquipo',@Id,N'Exitoso',NULL;SELECT @F;END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_transporte_leer_listado @UsuarioId INT,@EsAdministrador BIT,@Estado NVARCHAR(20)=NULL,@Tipo NVARCHAR(30)=NULL,@SedeId INT=NULL
AS
BEGIN SET NOCOUNT ON;SELECT v.TransporteViajeId,v.SedeId,s.Nombre Sede,v.Tipo,v.Origen,v.Destino,v.DescripcionCarga,v.PesoCarga,v.FechaSalidaPlanificada,v.FechaSalidaReal,v.FechaEntrega,v.Estado,vh.Placa,c.Nombre Conductor,cl.Nombre Cliente,u.NombreUsuario Responsable,(SELECT COUNT(*) FROM dbo.TransporteIncidencia i WHERE i.TransporteViajeId=v.TransporteViajeId AND i.Resuelta=0) IncidenciasAbiertas FROM dbo.TransporteViaje v JOIN dbo.Sede s ON s.SedeId=v.SedeId JOIN dbo.TransporteVehiculo vh ON vh.TransporteVehiculoId=v.TransporteVehiculoId JOIN dbo.TransporteConductor c ON c.TransporteConductorId=v.TransporteConductorId LEFT JOIN dbo.Cliente cl ON cl.ClienteId=v.ClienteId JOIN dbo.Usuario u ON u.UsuarioId=v.ResponsableUsuarioId WHERE v.Eliminado=0 AND (@Estado IS NULL OR v.Estado=@Estado) AND (@Tipo IS NULL OR v.Tipo=@Tipo) AND (@SedeId IS NULL OR v.SedeId=@SedeId) AND (@EsAdministrador=1 OR (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug JOIN dbo.GiroNegocio g ON g.GiroNegocioId=ug.GiroNegocioId WHERE ug.UsuarioId=@UsuarioId AND ug.Eliminado=0 AND g.Nombre IN(N'Transporte de materia prima',N'Transporte nacional e internacional') AND g.Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=v.SedeId AND us.Eliminado=0))) ORDER BY v.FechaSalidaPlanificada DESC;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_transporte_leer_por_id @Id BIGINT,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;SELECT v.TransporteViajeId,v.SedeId,s.Nombre Sede,v.TransporteVehiculoId,vh.Placa,vh.Tipo TipoVehiculo,v.TransporteConductorId,c.Nombre Conductor,c.Licencia,v.ClienteId,cl.Nombre Cliente,v.Tipo,v.Origen,v.Destino,v.DescripcionCarga,v.PesoCarga,v.FechaSalidaPlanificada,v.FechaSalidaReal,v.FechaEntrega,v.Estado,u.NombreUsuario Responsable,v.Observacion,v.FechaCreacion FROM dbo.TransporteViaje v JOIN dbo.Sede s ON s.SedeId=v.SedeId JOIN dbo.TransporteVehiculo vh ON vh.TransporteVehiculoId=v.TransporteVehiculoId JOIN dbo.TransporteConductor c ON c.TransporteConductorId=v.TransporteConductorId LEFT JOIN dbo.Cliente cl ON cl.ClienteId=v.ClienteId JOIN dbo.Usuario u ON u.UsuarioId=v.ResponsableUsuarioId WHERE v.TransporteViajeId=@Id AND v.Eliminado=0 AND (@EsAdministrador=1 OR (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug JOIN dbo.GiroNegocio g ON g.GiroNegocioId=ug.GiroNegocioId WHERE ug.UsuarioId=@UsuarioId AND ug.Eliminado=0 AND g.Nombre IN(N'Transporte de materia prima',N'Transporte nacional e internacional') AND g.Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=v.SedeId AND us.Eliminado=0)));SELECT i.TransporteIncidenciaId,i.Tipo,i.Severidad,i.Descripcion,i.Resuelta,i.Resolucion,u.NombreUsuario,i.Fecha,i.FechaResolucion FROM dbo.TransporteIncidencia i JOIN dbo.Usuario u ON u.UsuarioId=i.UsuarioId WHERE i.TransporteViajeId=@Id ORDER BY i.Fecha DESC;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_transporte_leer_opciones @UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;SELECT DISTINCT s.SedeId Id,s.Nombre FROM dbo.Sede s JOIN dbo.SedeGiroNegocio sg ON sg.SedeId=s.SedeId JOIN dbo.GiroNegocio g ON g.GiroNegocioId=sg.GiroNegocioId WHERE g.Nombre IN(N'Transporte de materia prima',N'Transporte nacional e internacional') AND s.Eliminado=0 AND s.EsActivo=1 AND sg.Eliminado=0 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=s.SedeId AND x.Eliminado=0)) ORDER BY s.Nombre;SELECT TransporteVehiculoId Id,CONCAT(Placa,N' · ',Tipo,N' · ',Estado) Nombre FROM dbo.TransporteVehiculo WHERE Eliminado=0 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=TransporteVehiculo.SedeId AND x.Eliminado=0)) ORDER BY Placa;SELECT TransporteConductorId Id,CONCAT(Nombre,N' · ',Licencia,N' · ',Estado) Nombre FROM dbo.TransporteConductor WHERE Eliminado=0 ORDER BY Nombre;SELECT ClienteId Id,Nombre FROM dbo.Cliente WHERE Eliminado=0 AND EsActivo=1 ORDER BY Nombre;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_transporte_crear_vehiculo @SedeId INT,@Placa NVARCHAR(20),@Tipo NVARCHAR(60),@Marca NVARCHAR(60),@Modelo NVARCHAR(60),@Capacidad DECIMAL(18,3),@UnidadCapacidad NVARCHAR(20),@EsInternacional BIT,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;IF @Capacidad<=0 THROW 50002,N'Capacidad inválida.',1;IF NOT EXISTS(SELECT 1 FROM dbo.SedeGiroNegocio sg JOIN dbo.GiroNegocio g ON g.GiroNegocioId=sg.GiroNegocioId WHERE sg.SedeId=@SedeId AND sg.Eliminado=0 AND g.Nombre IN(N'Transporte de materia prima',N'Transporte nacional e internacional') AND g.Eliminado=0) THROW 50002,N'La sede no opera transporte.',1;IF @EsAdministrador=0 AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0) THROW 50002,N'Sin acceso a la sede.',1;INSERT dbo.TransporteVehiculo(SedeId,Placa,Tipo,Marca,Modelo,Capacidad,UnidadCapacidad,EsInternacional) VALUES(@SedeId,UPPER(LTRIM(RTRIM(@Placa))),LTRIM(RTRIM(@Tipo)),LTRIM(RTRIM(@Marca)),LTRIM(RTRIM(@Modelo)),@Capacidad,LTRIM(RTRIM(@UnidadCapacidad)),@EsInternacional);DECLARE @Id INT=CONVERT(INT,SCOPE_IDENTITY());EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Transporte',N'CrearVehiculo',@Id,N'Exitoso',NULL;SELECT @Id;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_transporte_crear_conductor @Nombre NVARCHAR(160),@Licencia NVARCHAR(50),@Categoria NVARCHAR(20),@FechaVencimiento DATE,@Telefono NVARCHAR(30)=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;IF @FechaVencimiento<CONVERT(DATE,SYSUTCDATETIME()) THROW 50002,N'La licencia está vencida.',1;IF @EsAdministrador=0 AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug JOIN dbo.GiroNegocio g ON g.GiroNegocioId=ug.GiroNegocioId WHERE ug.UsuarioId=@UsuarioId AND ug.Eliminado=0 AND g.Nombre IN(N'Transporte de materia prima',N'Transporte nacional e internacional') AND g.Eliminado=0) THROW 50002,N'Sin acceso al giro de transporte.',1;INSERT dbo.TransporteConductor(Nombre,Licencia,Categoria,FechaVencimiento,Telefono) VALUES(LTRIM(RTRIM(@Nombre)),UPPER(LTRIM(RTRIM(@Licencia))),LTRIM(RTRIM(@Categoria)),@FechaVencimiento,NULLIF(LTRIM(RTRIM(@Telefono)),N''));DECLARE @Id INT=CONVERT(INT,SCOPE_IDENTITY());EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Transporte',N'CrearConductor',@Id,N'Exitoso',NULL;SELECT @Id;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_transporte_crear_viaje @SedeId INT,@VehiculoId INT,@ConductorId INT,@ClienteId INT=NULL,@Tipo NVARCHAR(30),@Origen NVARCHAR(200),@Destino NVARCHAR(200),@DescripcionCarga NVARCHAR(300),@PesoCarga DECIMAL(18,3),@FechaSalidaPlanificada DATETIME2(0),@Observacion NVARCHAR(500)=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;SET XACT_ABORT ON;BEGIN TRY BEGIN TRANSACTION;DECLARE @Capacidad DECIMAL(18,3),@VehiculoEstado NVARCHAR(20),@Internacional BIT;SELECT @Capacidad=Capacidad,@VehiculoEstado=Estado,@Internacional=EsInternacional FROM dbo.TransporteVehiculo WITH(UPDLOCK) WHERE TransporteVehiculoId=@VehiculoId AND SedeId=@SedeId AND Eliminado=0;IF @VehiculoEstado<>N'Disponible' OR @PesoCarga<=0 OR @PesoCarga>@Capacidad THROW 50002,N'Vehículo o carga no disponibles.',1;IF @Tipo NOT IN(N'MateriaPrima',N'Nacional',N'Internacional') OR (@Tipo=N'Internacional' AND @Internacional=0) THROW 50002,N'Tipo de viaje inválido para el vehículo.',1;IF NOT EXISTS(SELECT 1 FROM dbo.TransporteConductor WITH(UPDLOCK) WHERE TransporteConductorId=@ConductorId AND Estado=N'Disponible' AND Eliminado=0 AND FechaVencimiento>=CONVERT(DATE,@FechaSalidaPlanificada)) THROW 50002,N'Conductor no disponible o licencia vencida.',1;IF @EsAdministrador=0 AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0) THROW 50002,N'Sin acceso a la sede.',1;INSERT dbo.TransporteViaje(SedeId,TransporteVehiculoId,TransporteConductorId,ClienteId,Tipo,Origen,Destino,DescripcionCarga,PesoCarga,FechaSalidaPlanificada,ResponsableUsuarioId,Observacion) VALUES(@SedeId,@VehiculoId,@ConductorId,@ClienteId,@Tipo,LTRIM(RTRIM(@Origen)),LTRIM(RTRIM(@Destino)),LTRIM(RTRIM(@DescripcionCarga)),@PesoCarga,@FechaSalidaPlanificada,@UsuarioId,NULLIF(LTRIM(RTRIM(@Observacion)),N''));DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());UPDATE dbo.TransporteVehiculo SET Estado=N'Asignado' WHERE TransporteVehiculoId=@VehiculoId;UPDATE dbo.TransporteConductor SET Estado=N'Asignado' WHERE TransporteConductorId=@ConductorId;EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Transporte',N'CrearViaje',@Id,N'Exitoso',@Tipo;COMMIT;SELECT @Id;END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_transporte_actualizar_estado @Id BIGINT,@Estado NVARCHAR(20),@Observacion NVARCHAR(500)=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;SET XACT_ABORT ON;BEGIN TRY BEGIN TRANSACTION;DECLARE @Anterior NVARCHAR(20),@VehiculoId INT,@ConductorId INT,@SedeId INT;SELECT @Anterior=Estado,@VehiculoId=TransporteVehiculoId,@ConductorId=TransporteConductorId,@SedeId=SedeId FROM dbo.TransporteViaje WITH(UPDLOCK) WHERE TransporteViajeId=@Id AND Eliminado=0;IF NOT((@Anterior=N'Programado' AND @Estado IN(N'EnRuta',N'Cancelado')) OR (@Anterior=N'EnRuta' AND @Estado IN(N'Entregado',N'Cancelado'))) THROW 50002,N'Transición inválida.',1;IF @EsAdministrador=0 AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0) THROW 50002,N'Sin acceso al viaje.',1;UPDATE dbo.TransporteViaje SET Estado=@Estado,FechaSalidaReal=CASE WHEN @Estado=N'EnRuta' THEN SYSUTCDATETIME() ELSE FechaSalidaReal END,FechaEntrega=CASE WHEN @Estado=N'Entregado' THEN SYSUTCDATETIME() ELSE FechaEntrega END,Observacion=COALESCE(NULLIF(LTRIM(RTRIM(@Observacion)),N''),Observacion),FechaModificacion=SYSUTCDATETIME() WHERE TransporteViajeId=@Id;IF @Estado IN(N'Entregado',N'Cancelado') BEGIN UPDATE dbo.TransporteVehiculo SET Estado=N'Disponible' WHERE TransporteVehiculoId=@VehiculoId;UPDATE dbo.TransporteConductor SET Estado=N'Disponible' WHERE TransporteConductorId=@ConductorId;END;EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Transporte',N'EstadoViaje',@Id,N'Exitoso',@Estado;COMMIT;SELECT 1;END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_transporte_crear_incidencia @ViajeId BIGINT,@Tipo NVARCHAR(80),@Severidad NVARCHAR(20),@Descripcion NVARCHAR(500),@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;IF @Severidad NOT IN(N'Baja',N'Media',N'Alta',N'Critica') THROW 50002,N'Severidad inválida.',1;DECLARE @SedeId INT=(SELECT SedeId FROM dbo.TransporteViaje WHERE TransporteViajeId=@ViajeId AND Eliminado=0);IF @SedeId IS NULL THROW 50002,N'Viaje inexistente.',1;IF @EsAdministrador=0 AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0) THROW 50002,N'Sin acceso al viaje.',1;INSERT dbo.TransporteIncidencia(TransporteViajeId,Tipo,Severidad,Descripcion,UsuarioId) VALUES(@ViajeId,LTRIM(RTRIM(@Tipo)),@Severidad,LTRIM(RTRIM(@Descripcion)),@UsuarioId);DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Transporte',N'CrearIncidencia',@Id,N'Exitoso',@Severidad;SELECT @Id;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_transporte_resolver_incidencia @Id BIGINT,@Resolucion NVARCHAR(500),@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;DECLARE @SedeId INT=(SELECT v.SedeId FROM dbo.TransporteIncidencia i JOIN dbo.TransporteViaje v ON v.TransporteViajeId=i.TransporteViajeId WHERE i.TransporteIncidenciaId=@Id);IF @EsAdministrador=0 AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0) THROW 50002,N'Sin acceso a la incidencia.',1;UPDATE dbo.TransporteIncidencia SET Resuelta=1,Resolucion=LTRIM(RTRIM(@Resolucion)),FechaResolucion=SYSUTCDATETIME() WHERE TransporteIncidenciaId=@Id AND Resuelta=0;DECLARE @F INT=@@ROWCOUNT;IF @F>0 EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Transporte',N'ResolverIncidencia',@Id,N'Exitoso',NULL;SELECT @F;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_transporte_eliminar_viaje @Id BIGINT,@UsuarioId INT
AS
BEGIN SET NOCOUNT ON;UPDATE dbo.TransporteViaje SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE TransporteViajeId=@Id AND Eliminado=0 AND Estado IN(N'Entregado',N'Cancelado');DECLARE @F INT=@@ROWCOUNT;IF @F>0 EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Transporte',N'EliminarViaje',@Id,N'Exitoso',NULL;SELECT @F;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_transporte_eliminar_recurso @Tipo NVARCHAR(20),@Id INT,@UsuarioId INT
AS
BEGIN SET NOCOUNT ON;DECLARE @F INT=0;IF @Tipo=N'Vehiculo' BEGIN IF EXISTS(SELECT 1 FROM dbo.TransporteViaje WHERE TransporteVehiculoId=@Id AND Estado IN(N'Programado',N'EnRuta') AND Eliminado=0) THROW 50002,N'Vehículo asignado.',1;UPDATE dbo.TransporteVehiculo SET Eliminado=1 WHERE TransporteVehiculoId=@Id AND Eliminado=0;SET @F=@@ROWCOUNT;END ELSE IF @Tipo=N'Conductor' BEGIN IF EXISTS(SELECT 1 FROM dbo.TransporteViaje WHERE TransporteConductorId=@Id AND Estado IN(N'Programado',N'EnRuta') AND Eliminado=0) THROW 50002,N'Conductor asignado.',1;UPDATE dbo.TransporteConductor SET Eliminado=1 WHERE TransporteConductorId=@Id AND Eliminado=0;SET @F=@@ROWCOUNT;END ELSE THROW 50002,N'Recurso inválido.',1;IF @F>0 EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Transporte',N'EliminarRecurso',@Id,N'Exitoso',@Tipo;SELECT @F;END;
GO

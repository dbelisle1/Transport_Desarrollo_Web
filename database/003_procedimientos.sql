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

CREATE OR ALTER PROCEDURE dbo.sp_catalogocomercial_leer_publico
    @GiroNegocioId INT = NULL,
    @Tipo NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT o.CatalogoOfertaId,o.GiroNegocioId,g.Nombre AS Giro,o.Codigo,o.Tipo,o.Nombre,
           o.Descripcion,o.UnidadMedida,o.PrecioBase,o.EsPublico,o.EsActivo,
           o.FechaCreacion,o.FechaModificacion
    FROM dbo.CatalogoOferta o
    INNER JOIN dbo.GiroNegocio g ON g.GiroNegocioId=o.GiroNegocioId
    WHERE o.Eliminado=0 AND o.EsActivo=1 AND o.EsPublico=1
      AND g.Eliminado=0 AND g.EsActivo=1
      AND (@GiroNegocioId IS NULL OR o.GiroNegocioId=@GiroNegocioId)
      AND (@Tipo IS NULL OR o.Tipo=@Tipo)
    ORDER BY g.Nombre,o.Tipo,o.Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_catalogocomercial_leer_listado
    @UsuarioId INT,@EsAdministrador BIT,@Busqueda NVARCHAR(200)=NULL,
    @GiroNegocioId INT=NULL,@Tipo NVARCHAR(20)=NULL,@EsActivo BIT=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Busqueda=NULLIF(LTRIM(RTRIM(@Busqueda)),N'');
    SELECT o.CatalogoOfertaId,o.GiroNegocioId,g.Nombre AS Giro,o.Codigo,o.Tipo,o.Nombre,
           o.Descripcion,o.UnidadMedida,o.PrecioBase,o.EsPublico,o.EsActivo,
           o.FechaCreacion,o.FechaModificacion
    FROM dbo.CatalogoOferta o
    INNER JOIN dbo.GiroNegocio g ON g.GiroNegocioId=o.GiroNegocioId
    WHERE o.Eliminado=0
      AND (@Busqueda IS NULL OR o.Codigo LIKE N'%'+@Busqueda+N'%' OR o.Nombre LIKE N'%'+@Busqueda+N'%' OR o.Descripcion LIKE N'%'+@Busqueda+N'%')
      AND (@GiroNegocioId IS NULL OR o.GiroNegocioId=@GiroNegocioId)
      AND (@Tipo IS NULL OR o.Tipo=@Tipo)
      AND (@EsActivo IS NULL OR o.EsActivo=@EsActivo)
      AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=o.GiroNegocioId AND ug.Eliminado=0))
    ORDER BY g.Nombre,o.Tipo,o.Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_catalogocomercial_leer_opciones @UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT g.GiroNegocioId AS Id,g.Nombre
    FROM dbo.GiroNegocio g
    WHERE g.Eliminado=0 AND g.EsActivo=1
      AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=g.GiroNegocioId AND ug.Eliminado=0))
    ORDER BY g.Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_catalogocomercial_crear
    @GiroNegocioId INT,@Codigo NVARCHAR(50),@Tipo NVARCHAR(20),@Nombre NVARCHAR(180),
    @Descripcion NVARCHAR(1000),@UnidadMedida NVARCHAR(40),@PrecioBase DECIMAL(18,2),
    @EsPublico BIT,@EsActivo BIT,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;
    IF @Tipo NOT IN(N'Producto',N'Servicio') OR @PrecioBase<0 OR
       NULLIF(LTRIM(RTRIM(@Codigo)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@Nombre)),N'') IS NULL OR
       NULLIF(LTRIM(RTRIM(@Descripcion)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@UnidadMedida)),N'') IS NULL
        THROW 50002,N'Datos de oferta inválidos.',1;
    IF NOT EXISTS(SELECT 1 FROM dbo.GiroNegocio g WHERE g.GiroNegocioId=@GiroNegocioId AND g.Eliminado=0 AND g.EsActivo=1) OR
       (@EsAdministrador=0 AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=@GiroNegocioId AND ug.Eliminado=0))
        THROW 50002,N'Sin acceso al giro seleccionado.',1;
    IF EXISTS(SELECT 1 FROM dbo.CatalogoOferta WHERE Codigo=LTRIM(RTRIM(@Codigo)) AND Eliminado=0)
        THROW 50002,N'El código de oferta ya existe.',1;
    INSERT dbo.CatalogoOferta(GiroNegocioId,Codigo,Tipo,Nombre,Descripcion,UnidadMedida,PrecioBase,EsPublico,EsActivo)
    VALUES(@GiroNegocioId,LTRIM(RTRIM(@Codigo)),@Tipo,LTRIM(RTRIM(@Nombre)),LTRIM(RTRIM(@Descripcion)),LTRIM(RTRIM(@UnidadMedida)),@PrecioBase,@EsPublico,@EsActivo);
    DECLARE @Id INT=CONVERT(INT,SCOPE_IDENTITY());
    EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'CatalogoComercial',N'Crear',@Id,N'Exitoso',@Codigo;
    SELECT @Id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_catalogocomercial_actualizar
    @CatalogoOfertaId INT,@GiroNegocioId INT,@Codigo NVARCHAR(50),@Tipo NVARCHAR(20),@Nombre NVARCHAR(180),
    @Descripcion NVARCHAR(1000),@UnidadMedida NVARCHAR(40),@PrecioBase DECIMAL(18,2),
    @EsPublico BIT,@EsActivo BIT,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;
    IF @Tipo NOT IN(N'Producto',N'Servicio') OR @PrecioBase<0 OR
       NULLIF(LTRIM(RTRIM(@Codigo)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@Nombre)),N'') IS NULL OR
       NULLIF(LTRIM(RTRIM(@Descripcion)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@UnidadMedida)),N'') IS NULL
        THROW 50002,N'Datos de oferta inválidos.',1;
    IF NOT EXISTS(SELECT 1 FROM dbo.CatalogoOferta o WHERE o.CatalogoOfertaId=@CatalogoOfertaId AND o.Eliminado=0 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=o.GiroNegocioId AND ug.Eliminado=0))) OR
       NOT EXISTS(SELECT 1 FROM dbo.GiroNegocio g WHERE g.GiroNegocioId=@GiroNegocioId AND g.Eliminado=0 AND g.EsActivo=1) OR
       (@EsAdministrador=0 AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=@GiroNegocioId AND ug.Eliminado=0))
        THROW 50002,N'Oferta inexistente o fuera de alcance.',1;
    IF EXISTS(SELECT 1 FROM dbo.CatalogoOferta WHERE Codigo=LTRIM(RTRIM(@Codigo)) AND CatalogoOfertaId<>@CatalogoOfertaId AND Eliminado=0)
        THROW 50002,N'El código de oferta ya existe.',1;
    UPDATE dbo.CatalogoOferta SET GiroNegocioId=@GiroNegocioId,Codigo=LTRIM(RTRIM(@Codigo)),Tipo=@Tipo,
        Nombre=LTRIM(RTRIM(@Nombre)),Descripcion=LTRIM(RTRIM(@Descripcion)),UnidadMedida=LTRIM(RTRIM(@UnidadMedida)),
        PrecioBase=@PrecioBase,EsPublico=@EsPublico,EsActivo=@EsActivo,FechaModificacion=SYSUTCDATETIME()
    WHERE CatalogoOfertaId=@CatalogoOfertaId;
    EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'CatalogoComercial',N'Actualizar',@CatalogoOfertaId,N'Exitoso',@Codigo;
    SELECT 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_catalogocomercial_eliminar @CatalogoOfertaId INT,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE o SET Eliminado=1,EsActivo=0,FechaModificacion=SYSUTCDATETIME()
    FROM dbo.CatalogoOferta o
    WHERE o.CatalogoOfertaId=@CatalogoOfertaId AND o.Eliminado=0
      AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=o.GiroNegocioId AND ug.Eliminado=0));
    DECLARE @Filas INT=@@ROWCOUNT;
    IF @Filas>0 EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'CatalogoComercial',N'Eliminar',@CatalogoOfertaId,N'Exitoso',NULL;
    SELECT @Filas;
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

    SELECT l.PedidoLineaId,l.CatalogoOfertaId,l.Codigo,l.Tipo,l.Nombre,l.UnidadMedida,l.Cantidad,
           l.PrecioUnitarioBase,l.PrecioUnitarioCotizado,
           CONVERT(DECIMAL(18,2),l.Cantidad*l.PrecioUnitarioBase) AS SubtotalBase,
           CASE WHEN l.PrecioUnitarioCotizado IS NULL THEN NULL ELSE CONVERT(DECIMAL(18,2),l.Cantidad*l.PrecioUnitarioCotizado) END AS SubtotalCotizado
    FROM dbo.PedidoLinea l
    INNER JOIN dbo.Pedido p ON p.PedidoId=l.PedidoId
    WHERE l.PedidoId=@PedidoId AND p.Eliminado=0
      AND (@EsAdministrador=1 OR
           (@EsCliente=1 AND EXISTS(SELECT 1 FROM dbo.ClienteUsuario cu WHERE cu.ClienteId=p.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0)) OR
           (@EsCliente=0 AND (p.VendedorUsuarioId=@UsuarioId OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=p.GiroNegocioId AND ug.Eliminado=0))))
    ORDER BY l.PedidoLineaId;
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

    SELECT DISTINCT o.CatalogoOfertaId,o.GiroNegocioId,g.Nombre AS Giro,o.Codigo,o.Tipo,o.Nombre,
           o.Descripcion,o.UnidadMedida,o.PrecioBase,o.EsPublico,o.EsActivo,o.FechaCreacion,o.FechaModificacion
    FROM dbo.CatalogoOferta o
    INNER JOIN dbo.GiroNegocio g ON g.GiroNegocioId=o.GiroNegocioId
    WHERE o.Eliminado=0 AND o.EsActivo=1
      AND (@EsCliente=0 OR o.EsPublico=1)
      AND (@EsAdministrador=1 OR
           (@EsCliente=1 AND EXISTS(
               SELECT 1 FROM dbo.ClienteGiroNegocio cg
               INNER JOIN dbo.ClienteUsuario cu ON cu.ClienteId=cg.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0
               WHERE cg.GiroNegocioId=o.GiroNegocioId AND cg.Eliminado=0)) OR
           (@EsCliente=0 AND EXISTS(
               SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.GiroNegocioId=o.GiroNegocioId AND ug.UsuarioId=@UsuarioId AND ug.Eliminado=0)))
    ORDER BY g.Nombre,o.Tipo,o.Nombre;
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
    @LineasJson NVARCHAR(MAX) = NULL,
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

        DECLARE @Lineas TABLE(CatalogoOfertaId INT NULL,Cantidad DECIMAL(18,3) NULL);
        IF NULLIF(LTRIM(RTRIM(@LineasJson)),N'') IS NOT NULL
        BEGIN
            IF ISJSON(@LineasJson)<>1 THROW 50002,N'Las líneas del pedido no tienen un formato válido.',1;
            INSERT @Lineas(CatalogoOfertaId,Cantidad)
            SELECT CatalogoOfertaId,Cantidad
            FROM OPENJSON(@LineasJson) WITH(CatalogoOfertaId INT N'$.catalogoOfertaId',Cantidad DECIMAL(18,3) N'$.cantidad');
            IF (SELECT COUNT(*) FROM @Lineas)>20 OR EXISTS(SELECT 1 FROM @Lineas WHERE CatalogoOfertaId IS NULL OR Cantidad<=0) OR
               EXISTS(SELECT CatalogoOfertaId FROM @Lineas GROUP BY CatalogoOfertaId HAVING COUNT(*)>1)
                THROW 50002,N'Las líneas del pedido son inválidas o están duplicadas.',1;
            IF EXISTS(SELECT 1 FROM @Lineas l LEFT JOIN dbo.CatalogoOferta o ON o.CatalogoOfertaId=l.CatalogoOfertaId AND o.Eliminado=0 AND o.EsActivo=1 WHERE o.CatalogoOfertaId IS NULL OR o.GiroNegocioId<>@GiroNegocioId OR (@EsCliente=1 AND o.EsPublico=0))
                THROW 50002,N'Una oferta no está disponible para el giro seleccionado.',1;
        END;

        INSERT dbo.Pedido(ClienteId,GiroNegocioId,SolicitanteUsuarioId,TipoSolicitud,Titulo,Descripcion,FechaRequerida,FechaReunionUtc)
        VALUES(@ClienteId,@GiroNegocioId,@UsuarioId,@TipoSolicitud,LTRIM(RTRIM(@Titulo)),LTRIM(RTRIM(@Descripcion)),@FechaRequerida,@FechaReunionUtc);
        DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());
        INSERT dbo.PedidoLinea(PedidoId,CatalogoOfertaId,Codigo,Tipo,Nombre,UnidadMedida,Cantidad,PrecioUnitarioBase)
        SELECT @Id,o.CatalogoOfertaId,o.Codigo,o.Tipo,o.Nombre,o.UnidadMedida,l.Cantidad,o.PrecioBase
        FROM @Lineas l INNER JOIN dbo.CatalogoOferta o ON o.CatalogoOfertaId=l.CatalogoOfertaId;
        INSERT dbo.PedidoHistorial(PedidoId,UsuarioId,EstadoAnterior,EstadoNuevo,Comentario)
        VALUES(@Id,@UsuarioId,NULL,N'Solicitado',N'Solicitud creada.');
        EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Pedidos',N'Crear',@Id,N'Exitoso',@TipoSolicitud;
        COMMIT TRANSACTION;
        SELECT @Id;
    END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_pedido_actualizar_cotizacion_linea
    @PedidoId BIGINT,@PedidoLineaId BIGINT,@PrecioUnitario DECIMAL(18,2),
    @UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @PrecioUnitario<0 THROW 50002,N'El precio cotizado no puede ser negativo.',1;
        IF NOT EXISTS(
            SELECT 1 FROM dbo.Pedido p
            WHERE p.PedidoId=@PedidoId AND p.Eliminado=0
              AND (@EsAdministrador=1 OR p.VendedorUsuarioId=@UsuarioId OR EXISTS(
                  SELECT 1 FROM dbo.UsuarioGiroNegocio ug
                  WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=p.GiroNegocioId AND ug.Eliminado=0)))
            THROW 50002,N'El usuario no puede cotizar este pedido.',1;
        UPDATE dbo.PedidoLinea SET PrecioUnitarioCotizado=@PrecioUnitario,FechaModificacion=SYSUTCDATETIME()
        WHERE PedidoLineaId=@PedidoLineaId AND PedidoId=@PedidoId;
        IF @@ROWCOUNT=0 THROW 50002,N'La línea no pertenece al pedido.',1;
        DECLARE @Estado NVARCHAR(30)=(SELECT Estado FROM dbo.Pedido WHERE PedidoId=@PedidoId);
        DECLARE @Total DECIMAL(18,2)=(SELECT CONVERT(DECIMAL(18,2),SUM(Cantidad*COALESCE(PrecioUnitarioCotizado,PrecioUnitarioBase))) FROM dbo.PedidoLinea WHERE PedidoId=@PedidoId);
        UPDATE dbo.Pedido SET MontoCotizado=@Total,FechaModificacion=SYSUTCDATETIME() WHERE PedidoId=@PedidoId;
        INSERT dbo.PedidoHistorial(PedidoId,UsuarioId,EstadoAnterior,EstadoNuevo,Comentario)
        VALUES(@PedidoId,@UsuarioId,@Estado,@Estado,N'Cotización de línea actualizada.');
        DECLARE @DetalleAuditoria NVARCHAR(60)=CONVERT(NVARCHAR(60),@PrecioUnitario);
        EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Pedidos',N'CotizarLinea',@PedidoLineaId,N'Exitoso',@DetalleAuditoria;
        COMMIT TRANSACTION;
        SELECT 1;
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

CREATE OR ALTER PROCEDURE dbo.sp_gps_leer_resumen @UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT d.GpsDispositivoId,d.IdentificadorExterno,d.NombreActivo,d.TransporteVehiculoId,v.Placa,d.MaquinariaEquipoId,m.Codigo MaquinariaCodigo,d.Proveedor,d.VelocidadMaxima,d.EsActivo,d.UltimaSincronizacion,p.FechaEvento,p.Latitud,p.Longitud,p.Velocidad,p.HorasUso,p.Kilometraje,p.Evento,
 (SELECT COUNT(*) FROM dbo.GpsAlerta a WHERE a.GpsDispositivoId=d.GpsDispositivoId AND a.Atendida=0) AlertasAbiertas
 FROM dbo.GpsDispositivo d LEFT JOIN dbo.TransporteVehiculo v ON v.TransporteVehiculoId=d.TransporteVehiculoId LEFT JOIN dbo.MaquinariaEquipo m ON m.MaquinariaEquipoId=d.MaquinariaEquipoId
 OUTER APPLY(SELECT TOP(1) x.FechaEvento,x.Latitud,x.Longitud,x.Velocidad,x.HorasUso,x.Kilometraje,x.Evento FROM dbo.GpsPosicion x WHERE x.GpsDispositivoId=d.GpsDispositivoId ORDER BY x.FechaEvento DESC,x.GpsPosicionId DESC)p
 WHERE d.Eliminado=0 AND (@EsAdministrador=1 OR (d.TransporteVehiculoId IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=v.SedeId AND us.Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug JOIN dbo.GiroNegocio g ON g.GiroNegocioId=ug.GiroNegocioId WHERE ug.UsuarioId=@UsuarioId AND ug.Eliminado=0 AND g.Nombre IN(N'Transporte de materia prima',N'Transporte nacional e internacional') AND g.Eliminado=0)) OR (d.MaquinariaEquipoId IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=m.SedeId AND us.Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug JOIN dbo.GiroNegocio g ON g.GiroNegocioId=ug.GiroNegocioId WHERE ug.UsuarioId=@UsuarioId AND ug.Eliminado=0 AND g.Nombre=N'Venta y alquiler de maquinaria' AND g.Eliminado=0))) ORDER BY d.NombreActivo;
 SELECT a.GpsAlertaId,a.GpsDispositivoId,d.NombreActivo,a.Tipo,a.Severidad,a.Mensaje,a.Atendida,a.Fecha,a.FechaAtencion,u.NombreUsuario AtendidaPor FROM dbo.GpsAlerta a JOIN dbo.GpsDispositivo d ON d.GpsDispositivoId=a.GpsDispositivoId LEFT JOIN dbo.Usuario u ON u.UsuarioId=a.AtendidaPorUsuarioId LEFT JOIN dbo.TransporteVehiculo v ON v.TransporteVehiculoId=d.TransporteVehiculoId LEFT JOIN dbo.MaquinariaEquipo m ON m.MaquinariaEquipoId=d.MaquinariaEquipoId WHERE d.Eliminado=0 AND (@EsAdministrador=1 OR (d.TransporteVehiculoId IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=v.SedeId AND us.Eliminado=0)) OR (d.MaquinariaEquipoId IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=m.SedeId AND us.Eliminado=0))) ORDER BY a.Atendida,a.Fecha DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_gps_leer_recorrido @Id INT,@UsuarioId INT,@EsAdministrador BIT,@FechaDesde DATETIME2(0)=NULL,@FechaHasta DATETIME2(0)=NULL
AS
BEGIN SET NOCOUNT ON;DECLARE @Permitido BIT=0;SELECT @Permitido=CASE WHEN @EsAdministrador=1 OR (d.TransporteVehiculoId IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.UsuarioSede us JOIN dbo.TransporteVehiculo v ON v.SedeId=us.SedeId WHERE us.UsuarioId=@UsuarioId AND v.TransporteVehiculoId=d.TransporteVehiculoId AND us.Eliminado=0)) OR (d.MaquinariaEquipoId IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.UsuarioSede us JOIN dbo.MaquinariaEquipo m ON m.SedeId=us.SedeId WHERE us.UsuarioId=@UsuarioId AND m.MaquinariaEquipoId=d.MaquinariaEquipoId AND us.Eliminado=0)) THEN 1 ELSE 0 END FROM dbo.GpsDispositivo d WHERE d.GpsDispositivoId=@Id AND d.Eliminado=0;IF @Permitido=0 THROW 50002,N'Dispositivo no disponible.',1;SELECT GpsPosicionId,GpsDispositivoId,FechaEvento,Latitud,Longitud,Velocidad,HorasUso,Kilometraje,Evento,OrigenDato,DatosFuente,Recibido FROM dbo.GpsPosicion WHERE GpsDispositivoId=@Id AND (@FechaDesde IS NULL OR FechaEvento>=@FechaDesde) AND (@FechaHasta IS NULL OR FechaEvento<=@FechaHasta) ORDER BY FechaEvento DESC,GpsPosicionId DESC;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_gps_leer_opciones @UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;SELECT v.TransporteVehiculoId Id,CONCAT(v.Placa,N' · ',v.Tipo) Nombre FROM dbo.TransporteVehiculo v WHERE v.Eliminado=0 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=v.SedeId AND x.Eliminado=0)) ORDER BY v.Placa;SELECT m.MaquinariaEquipoId Id,CONCAT(m.Codigo,N' · ',m.Tipo) Nombre FROM dbo.MaquinariaEquipo m WHERE m.Eliminado=0 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=m.SedeId AND x.Eliminado=0)) ORDER BY m.Codigo;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_gps_crear_dispositivo @IdentificadorExterno NVARCHAR(100),@NombreActivo NVARCHAR(160),@VehiculoId INT=NULL,@MaquinariaId INT=NULL,@Proveedor NVARCHAR(80),@VelocidadMaxima DECIMAL(8,2),@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;IF @VehiculoId IS NOT NULL AND @MaquinariaId IS NOT NULL THROW 50002,N'Asocie solamente un activo.',1;IF @VehiculoId IS NULL AND @MaquinariaId IS NULL AND @EsAdministrador=0 THROW 50002,N'Solo administración puede registrar un activo externo sin asociación.',1;IF @VehiculoId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.TransporteVehiculo v WHERE v.TransporteVehiculoId=@VehiculoId AND v.Eliminado=0 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=v.SedeId AND x.Eliminado=0))) THROW 50002,N'Vehículo no disponible.',1;IF @MaquinariaId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.MaquinariaEquipo m WHERE m.MaquinariaEquipoId=@MaquinariaId AND m.Eliminado=0 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=m.SedeId AND x.Eliminado=0))) THROW 50002,N'Maquinaria no disponible.',1;INSERT dbo.GpsDispositivo(IdentificadorExterno,NombreActivo,TransporteVehiculoId,MaquinariaEquipoId,Proveedor,VelocidadMaxima) VALUES(UPPER(LTRIM(RTRIM(@IdentificadorExterno))),LTRIM(RTRIM(@NombreActivo)),@VehiculoId,@MaquinariaId,LTRIM(RTRIM(@Proveedor)),@VelocidadMaxima);DECLARE @Id INT=CONVERT(INT,SCOPE_IDENTITY());EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'GPS',N'CrearDispositivo',@Id,N'Exitoso',@Proveedor;SELECT @Id;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_gps_simular_evento @DispositivoId INT,@FechaEvento DATETIME2(0),@Latitud DECIMAL(9,6),@Longitud DECIMAL(9,6),@Velocidad DECIMAL(8,2),@HorasUso DECIMAL(18,2)=NULL,@Kilometraje DECIMAL(18,2)=NULL,@Evento NVARCHAR(80)=NULL,@DatosFuente NVARCHAR(2000)=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;SET XACT_ABORT ON;BEGIN TRY BEGIN TRANSACTION;DECLARE @Max DECIMAL(8,2),@VehiculoId INT,@MaquinariaId INT;SELECT @Max=VelocidadMaxima,@VehiculoId=TransporteVehiculoId,@MaquinariaId=MaquinariaEquipoId FROM dbo.GpsDispositivo WITH(UPDLOCK) WHERE GpsDispositivoId=@DispositivoId AND Eliminado=0 AND EsActivo=1;IF @Max IS NULL THROW 50002,N'Dispositivo no disponible.',1;IF @EsAdministrador=0 AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede us LEFT JOIN dbo.TransporteVehiculo v ON v.SedeId=us.SedeId LEFT JOIN dbo.MaquinariaEquipo m ON m.SedeId=us.SedeId WHERE us.UsuarioId=@UsuarioId AND us.Eliminado=0 AND (v.TransporteVehiculoId=@VehiculoId OR m.MaquinariaEquipoId=@MaquinariaId)) THROW 50002,N'Sin acceso al dispositivo.',1;INSERT dbo.GpsPosicion(GpsDispositivoId,FechaEvento,Latitud,Longitud,Velocidad,HorasUso,Kilometraje,Evento,OrigenDato,DatosFuente) VALUES(@DispositivoId,@FechaEvento,@Latitud,@Longitud,@Velocidad,@HorasUso,@Kilometraje,NULLIF(LTRIM(RTRIM(@Evento)),N''),N'Simulación externa',NULLIF(@DatosFuente,N''));DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());UPDATE dbo.GpsDispositivo SET UltimaSincronizacion=SYSUTCDATETIME() WHERE GpsDispositivoId=@DispositivoId;IF @Velocidad>@Max INSERT dbo.GpsAlerta(GpsDispositivoId,GpsPosicionId,Tipo,Severidad,Mensaje) VALUES(@DispositivoId,@Id,N'ExcesoVelocidad',CASE WHEN @Velocidad>@Max+30 THEN N'Critica' ELSE N'Alta' END,CONCAT(N'Velocidad ',CONVERT(NVARCHAR(30),@Velocidad),N' km/h supera el máximo ',CONVERT(NVARCHAR(30),@Max),N' km/h.'));IF UPPER(ISNULL(@Evento,N'')) IN(N'SOS',N'DESCONEXION') INSERT dbo.GpsAlerta(GpsDispositivoId,GpsPosicionId,Tipo,Severidad,Mensaje) VALUES(@DispositivoId,@Id,@Evento,N'Critica',CONCAT(N'Evento crítico recibido: ',@Evento,N'.'));EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'GPS',N'SimularEvento',@Id,N'Exitoso',N'Simulación externa';COMMIT;SELECT @Id;END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_gps_atender_alerta @Id BIGINT,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;DECLARE @DispositivoId INT,@VehiculoId INT,@MaquinariaId INT;SELECT @DispositivoId=d.GpsDispositivoId,@VehiculoId=d.TransporteVehiculoId,@MaquinariaId=d.MaquinariaEquipoId FROM dbo.GpsAlerta a JOIN dbo.GpsDispositivo d ON d.GpsDispositivoId=a.GpsDispositivoId WHERE a.GpsAlertaId=@Id AND d.Eliminado=0;IF @DispositivoId IS NULL THROW 50002,N'Alerta inexistente.',1;IF @EsAdministrador=0 AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede us LEFT JOIN dbo.TransporteVehiculo v ON v.SedeId=us.SedeId LEFT JOIN dbo.MaquinariaEquipo m ON m.SedeId=us.SedeId WHERE us.UsuarioId=@UsuarioId AND us.Eliminado=0 AND (v.TransporteVehiculoId=@VehiculoId OR m.MaquinariaEquipoId=@MaquinariaId)) THROW 50002,N'Sin acceso a la alerta.',1;UPDATE dbo.GpsAlerta SET Atendida=1,AtendidaPorUsuarioId=@UsuarioId,FechaAtencion=SYSUTCDATETIME() WHERE GpsAlertaId=@Id AND Atendida=0;DECLARE @F INT=@@ROWCOUNT;IF @F>0 EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'GPS',N'AtenderAlerta',@Id,N'Exitoso',NULL;SELECT @F;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_gps_eliminar_dispositivo @Id INT,@UsuarioId INT
AS
BEGIN SET NOCOUNT ON;UPDATE dbo.GpsDispositivo SET Eliminado=1,EsActivo=0 WHERE GpsDispositivoId=@Id AND Eliminado=0;DECLARE @F INT=@@ROWCOUNT;IF @F>0 EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'GPS',N'EliminarDispositivo',@Id,N'Exitoso',NULL;SELECT @F;END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_construccion_leer_listado @UsuarioId INT,@EsAdministrador BIT,@Estado NVARCHAR(30)=NULL,@SedeId INT=NULL,@Busqueda NVARCHAR(150)=NULL
AS
BEGIN SET NOCOUNT ON;DECLARE @GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Servicios de construcción' AND Eliminado=0);SELECT p.ConstruccionProyectoId,p.SedeId,s.Nombre Sede,p.ClienteId,c.Nombre Cliente,p.Nombre,p.TipoObra,p.Ubicacion,p.FechaInicioPlanificada,p.FechaFinPlanificada,p.Presupuesto,p.Estado,u.NombreUsuario Responsable,p.FechaCreacion,COALESCE((SELECT AVG(a.PorcentajeAvance) FROM dbo.ConstruccionActividad a WHERE a.ConstruccionProyectoId=p.ConstruccionProyectoId),0) PorcentajeAvance,COALESCE((SELECT SUM(r.Cantidad*r.CostoUnitario) FROM dbo.ConstruccionRecurso r WHERE r.ConstruccionProyectoId=p.ConstruccionProyectoId),0) CostoReal FROM dbo.ConstruccionProyecto p JOIN dbo.Sede s ON s.SedeId=p.SedeId LEFT JOIN dbo.Cliente c ON c.ClienteId=p.ClienteId JOIN dbo.Usuario u ON u.UsuarioId=p.ResponsableUsuarioId WHERE p.Eliminado=0 AND (@Estado IS NULL OR p.Estado=@Estado) AND (@SedeId IS NULL OR p.SedeId=@SedeId) AND (@Busqueda IS NULL OR CONCAT(p.Nombre,N' ',p.Ubicacion,N' ',p.TipoObra,N' ',c.Nombre) LIKE N'%'+@Busqueda+N'%') AND (@EsAdministrador=1 OR (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio x WHERE x.UsuarioId=@UsuarioId AND x.GiroNegocioId=@GiroId AND x.Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=p.SedeId AND x.Eliminado=0))) ORDER BY p.FechaInicioPlanificada DESC,p.ConstruccionProyectoId DESC;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_construccion_leer_por_id @Id BIGINT,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;DECLARE @GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Servicios de construcción' AND Eliminado=0);IF NOT EXISTS(SELECT 1 FROM dbo.ConstruccionProyecto p WHERE p.ConstruccionProyectoId=@Id AND p.Eliminado=0 AND (@EsAdministrador=1 OR (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio x WHERE x.UsuarioId=@UsuarioId AND x.GiroNegocioId=@GiroId AND x.Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=p.SedeId AND x.Eliminado=0)))) RETURN;SELECT p.ConstruccionProyectoId,p.SedeId,s.Nombre Sede,p.ClienteId,c.Nombre Cliente,p.Nombre,p.TipoObra,p.Ubicacion,p.FechaInicioPlanificada,p.FechaFinPlanificada,p.Presupuesto,p.Estado,p.ResponsableUsuarioId,u.NombreUsuario Responsable,p.Descripcion,p.FechaCreacion,p.FechaModificacion FROM dbo.ConstruccionProyecto p JOIN dbo.Sede s ON s.SedeId=p.SedeId LEFT JOIN dbo.Cliente c ON c.ClienteId=p.ClienteId JOIN dbo.Usuario u ON u.UsuarioId=p.ResponsableUsuarioId WHERE p.ConstruccionProyectoId=@Id;
 SELECT a.ConstruccionActividadId,a.Nombre,a.ResponsableUsuarioId,u.NombreUsuario Responsable,a.FechaInicio,a.FechaFin,a.Presupuesto,a.PorcentajeAvance,a.Estado,a.Observacion,COALESCE((SELECT SUM(r.Cantidad*r.CostoUnitario) FROM dbo.ConstruccionRecurso r WHERE r.ConstruccionActividadId=a.ConstruccionActividadId),0) CostoReal FROM dbo.ConstruccionActividad a JOIN dbo.Usuario u ON u.UsuarioId=a.ResponsableUsuarioId WHERE a.ConstruccionProyectoId=@Id ORDER BY a.FechaInicio,a.ConstruccionActividadId;
 SELECT r.ConstruccionRecursoId,r.ConstruccionActividadId,r.Tipo,r.Descripcion,r.Cantidad,r.Unidad,r.CostoUnitario,r.InventarioArticuloId,ia.Codigo ArticuloCodigo,r.MaquinariaEquipoId,m.Codigo MaquinariaCodigo,u.NombreUsuario,r.Fecha FROM dbo.ConstruccionRecurso r JOIN dbo.Usuario u ON u.UsuarioId=r.UsuarioId LEFT JOIN dbo.InventarioArticulo ia ON ia.InventarioArticuloId=r.InventarioArticuloId LEFT JOIN dbo.MaquinariaEquipo m ON m.MaquinariaEquipoId=r.MaquinariaEquipoId WHERE r.ConstruccionProyectoId=@Id ORDER BY r.Fecha DESC;
 SELECT av.ConstruccionAvanceId,av.ConstruccionActividadId,a.Nombre Actividad,av.PorcentajeAnterior,av.PorcentajeNuevo,av.Comentario,av.EvidenciaUrl,u.NombreUsuario,av.Fecha FROM dbo.ConstruccionAvance av JOIN dbo.ConstruccionActividad a ON a.ConstruccionActividadId=av.ConstruccionActividadId JOIN dbo.Usuario u ON u.UsuarioId=av.UsuarioId WHERE a.ConstruccionProyectoId=@Id ORDER BY av.Fecha DESC;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_construccion_leer_opciones @UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;DECLARE @GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Servicios de construcción' AND Eliminado=0);SELECT DISTINCT s.SedeId Id,s.Nombre FROM dbo.Sede s JOIN dbo.SedeGiroNegocio sg ON sg.SedeId=s.SedeId AND sg.GiroNegocioId=@GiroId AND sg.Eliminado=0 WHERE s.Eliminado=0 AND s.EsActivo=1 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=s.SedeId AND x.Eliminado=0)) ORDER BY s.Nombre;SELECT ClienteId Id,Nombre FROM dbo.Cliente WHERE Eliminado=0 AND EsActivo=1 ORDER BY Nombre;SELECT UsuarioId Id,CONCAT(Nombre,N' ',Apellido,N' (',NombreUsuario,N')') Nombre FROM dbo.Usuario WHERE Eliminado=0 AND EsActivo=1 ORDER BY Nombre,Apellido;SELECT InventarioArticuloId Id,CONCAT(Codigo,N' · ',Nombre) Nombre FROM dbo.InventarioArticulo WHERE Eliminado=0 AND EsActivo=1 ORDER BY Nombre;SELECT MaquinariaEquipoId Id,CONCAT(Codigo,N' · ',Tipo,N' · ',Estado) Nombre FROM dbo.MaquinariaEquipo WHERE Eliminado=0 ORDER BY Codigo;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_construccion_crear_proyecto @SedeId INT,@ClienteId INT=NULL,@Nombre NVARCHAR(180),@TipoObra NVARCHAR(30),@Ubicacion NVARCHAR(250),@FechaInicio DATE,@FechaFin DATE,@Presupuesto DECIMAL(18,2),@ResponsableId INT,@Descripcion NVARCHAR(1000)=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;DECLARE @GiroId INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Servicios de construcción' AND Eliminado=0);IF @TipoObra NOT IN(N'Puente',N'Carretera',N'Edificio',N'Otro') OR @FechaFin<@FechaInicio OR @Presupuesto<0 THROW 50002,N'Datos de proyecto inválidos.',1;IF NOT EXISTS(SELECT 1 FROM dbo.SedeGiroNegocio WHERE SedeId=@SedeId AND GiroNegocioId=@GiroId AND Eliminado=0) THROW 50002,N'La sede no opera construcción.',1;IF @EsAdministrador=0 AND (NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroId AND Eliminado=0) OR NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0)) THROW 50002,N'Sin acceso a la sede.',1;INSERT dbo.ConstruccionProyecto(SedeId,ClienteId,Nombre,TipoObra,Ubicacion,FechaInicioPlanificada,FechaFinPlanificada,Presupuesto,ResponsableUsuarioId,Descripcion) VALUES(@SedeId,@ClienteId,LTRIM(RTRIM(@Nombre)),@TipoObra,LTRIM(RTRIM(@Ubicacion)),@FechaInicio,@FechaFin,@Presupuesto,@ResponsableId,NULLIF(LTRIM(RTRIM(@Descripcion)),N''));DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Construccion',N'CrearProyecto',@Id,N'Exitoso',@TipoObra;SELECT @Id;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_construccion_crear_actividad @ProyectoId BIGINT,@Nombre NVARCHAR(180),@ResponsableId INT,@FechaInicio DATE,@FechaFin DATE,@Presupuesto DECIMAL(18,2),@Observacion NVARCHAR(500)=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;DECLARE @SedeId INT=(SELECT SedeId FROM dbo.ConstruccionProyecto WHERE ConstruccionProyectoId=@ProyectoId AND Eliminado=0);IF @SedeId IS NULL OR @FechaFin<@FechaInicio OR @Presupuesto<0 THROW 50002,N'Datos de actividad inválidos.',1;IF @EsAdministrador=0 AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0) THROW 50002,N'Sin acceso al proyecto.',1;INSERT dbo.ConstruccionActividad(ConstruccionProyectoId,Nombre,ResponsableUsuarioId,FechaInicio,FechaFin,Presupuesto,Observacion) VALUES(@ProyectoId,LTRIM(RTRIM(@Nombre)),@ResponsableId,@FechaInicio,@FechaFin,@Presupuesto,NULLIF(LTRIM(RTRIM(@Observacion)),N''));DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Construccion',N'CrearActividad',@Id,N'Exitoso',NULL;SELECT @Id;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_construccion_registrar_avance @ActividadId BIGINT,@Porcentaje DECIMAL(5,2),@Comentario NVARCHAR(500),@EvidenciaUrl NVARCHAR(500)=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;SET XACT_ABORT ON;BEGIN TRY BEGIN TRANSACTION;DECLARE @Anterior DECIMAL(5,2),@ProyectoId BIGINT,@SedeId INT;SELECT @Anterior=a.PorcentajeAvance,@ProyectoId=a.ConstruccionProyectoId,@SedeId=p.SedeId FROM dbo.ConstruccionActividad a WITH(UPDLOCK) JOIN dbo.ConstruccionProyecto p ON p.ConstruccionProyectoId=a.ConstruccionProyectoId WHERE a.ConstruccionActividadId=@ActividadId AND p.Eliminado=0;IF @Anterior IS NULL OR @Porcentaje<0 OR @Porcentaje>100 THROW 50002,N'Avance inválido.',1;IF @EsAdministrador=0 AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0) THROW 50002,N'Sin acceso a la actividad.',1;UPDATE dbo.ConstruccionActividad SET PorcentajeAvance=@Porcentaje,Estado=CASE WHEN @Porcentaje=100 THEN N'Completada' WHEN @Porcentaje>0 THEN N'EnProceso' ELSE N'Pendiente' END WHERE ConstruccionActividadId=@ActividadId;INSERT dbo.ConstruccionAvance(ConstruccionActividadId,PorcentajeAnterior,PorcentajeNuevo,Comentario,EvidenciaUrl,UsuarioId) VALUES(@ActividadId,@Anterior,@Porcentaje,LTRIM(RTRIM(@Comentario)),NULLIF(LTRIM(RTRIM(@EvidenciaUrl)),N''),@UsuarioId);DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY()),@Detalle NVARCHAR(30)=CONVERT(NVARCHAR(30),@Porcentaje);EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Construccion',N'RegistrarAvance',@Id,N'Exitoso',@Detalle;COMMIT;SELECT @Id;END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_construccion_asignar_recurso @ProyectoId BIGINT,@ActividadId BIGINT=NULL,@Tipo NVARCHAR(20),@Descripcion NVARCHAR(200),@Cantidad DECIMAL(18,3),@Unidad NVARCHAR(30),@CostoUnitario DECIMAL(18,2),@ArticuloId INT=NULL,@MaquinariaId INT=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;SET XACT_ABORT ON;BEGIN TRY BEGIN TRANSACTION;DECLARE @SedeId INT=(SELECT SedeId FROM dbo.ConstruccionProyecto WHERE ConstruccionProyectoId=@ProyectoId AND Eliminado=0);IF @SedeId IS NULL OR @Tipo NOT IN(N'Material',N'Maquinaria',N'Personal',N'Otro') OR @Cantidad<=0 OR @CostoUnitario<0 THROW 50002,N'Recurso inválido.',1;IF @ActividadId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.ConstruccionActividad WHERE ConstruccionActividadId=@ActividadId AND ConstruccionProyectoId=@ProyectoId) THROW 50002,N'La actividad no pertenece al proyecto.',1;IF @EsAdministrador=0 AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0) THROW 50002,N'Sin acceso al proyecto.',1;IF @Tipo=N'Material' BEGIN IF @ArticuloId IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.InventarioExistencia WHERE InventarioArticuloId=@ArticuloId AND SedeId=@SedeId AND Cantidad-CantidadReservada>=@Cantidad) THROW 50002,N'Material insuficiente en la sede.',1;UPDATE dbo.InventarioExistencia SET Cantidad=Cantidad-@Cantidad,FechaModificacion=SYSUTCDATETIME() WHERE InventarioArticuloId=@ArticuloId AND SedeId=@SedeId;INSERT dbo.InventarioMovimiento(InventarioArticuloId,Tipo,SedeOrigenId,Cantidad,Referencia,Observacion,UsuarioId) VALUES(@ArticuloId,N'Salida',@SedeId,@Cantidad,CONCAT(N'OBRA-',@ProyectoId),N'Consumo de construcción',@UsuarioId);END;IF @Tipo=N'Maquinaria' AND (@MaquinariaId IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.MaquinariaEquipo WHERE MaquinariaEquipoId=@MaquinariaId AND Eliminado=0)) THROW 50002,N'Maquinaria inválida.',1;INSERT dbo.ConstruccionRecurso(ConstruccionProyectoId,ConstruccionActividadId,Tipo,Descripcion,Cantidad,Unidad,CostoUnitario,InventarioArticuloId,MaquinariaEquipoId,UsuarioId) VALUES(@ProyectoId,@ActividadId,@Tipo,LTRIM(RTRIM(@Descripcion)),@Cantidad,LTRIM(RTRIM(@Unidad)),@CostoUnitario,@ArticuloId,@MaquinariaId,@UsuarioId);DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Construccion',N'AsignarRecurso',@Id,N'Exitoso',@Tipo;COMMIT;SELECT @Id;END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_construccion_actualizar_estado @Id BIGINT,@Estado NVARCHAR(30),@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;DECLARE @Anterior NVARCHAR(30),@SedeId INT;SELECT @Anterior=Estado,@SedeId=SedeId FROM dbo.ConstruccionProyecto WHERE ConstruccionProyectoId=@Id AND Eliminado=0;IF NOT((@Anterior=N'Planificado' AND @Estado IN(N'EnEjecucion',N'Cancelado')) OR (@Anterior=N'EnEjecucion' AND @Estado IN(N'Suspendido',N'Completado',N'Cancelado')) OR (@Anterior=N'Suspendido' AND @Estado IN(N'EnEjecucion',N'Cancelado'))) THROW 50002,N'Transición inválida.',1;IF @Estado=N'Completado' AND EXISTS(SELECT 1 FROM dbo.ConstruccionActividad WHERE ConstruccionProyectoId=@Id AND PorcentajeAvance<100) THROW 50002,N'Existen actividades incompletas.',1;IF @EsAdministrador=0 AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0) THROW 50002,N'Sin acceso al proyecto.',1;UPDATE dbo.ConstruccionProyecto SET Estado=@Estado,FechaModificacion=SYSUTCDATETIME() WHERE ConstruccionProyectoId=@Id;EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Construccion',N'CambiarEstado',@Id,N'Exitoso',@Estado;SELECT 1;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_construccion_eliminar @Id BIGINT,@UsuarioId INT
AS
BEGIN SET NOCOUNT ON;UPDATE dbo.ConstruccionProyecto SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE ConstruccionProyectoId=@Id AND Eliminado=0 AND Estado IN(N'Completado',N'Cancelado');DECLARE @F INT=@@ROWCOUNT;IF @F>0 EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Construccion',N'Eliminar',@Id,N'Exitoso',NULL;SELECT @F;END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_finanzas_leer_presupuestos @UsuarioId INT,@EsAdministrador BIT,@Anio SMALLINT=NULL,@Mes TINYINT=NULL,@GiroId INT=NULL,@SedeId INT=NULL
AS
BEGIN SET NOCOUNT ON;SELECT p.FinanzaPresupuestoId,p.GiroNegocioId,g.Nombre Giro,p.SedeId,s.Nombre Sede,p.Anio,p.Mes,p.Nombre,p.Monto,p.Estado,COALESCE(SUM(x.Monto),0) GastoReal,p.Monto-COALESCE(SUM(x.Monto),0) Disponible,CAST(CASE WHEN p.Monto=0 THEN 0 ELSE COALESCE(SUM(x.Monto),0)*100.0/p.Monto END AS DECIMAL(7,2)) PorcentajeEjecutado,p.FechaCreacion FROM dbo.FinanzaPresupuesto p JOIN dbo.GiroNegocio g ON g.GiroNegocioId=p.GiroNegocioId JOIN dbo.Sede s ON s.SedeId=p.SedeId LEFT JOIN dbo.FinanzaGasto x ON x.FinanzaPresupuestoId=p.FinanzaPresupuestoId WHERE p.Eliminado=0 AND (@Anio IS NULL OR p.Anio=@Anio) AND (@Mes IS NULL OR p.Mes=@Mes) AND (@GiroId IS NULL OR p.GiroNegocioId=@GiroId) AND (@SedeId IS NULL OR p.SedeId=@SedeId) AND (@EsAdministrador=1 OR (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=p.GiroNegocioId AND ug.Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=p.SedeId AND us.Eliminado=0))) GROUP BY p.FinanzaPresupuestoId,p.GiroNegocioId,g.Nombre,p.SedeId,s.Nombre,p.Anio,p.Mes,p.Nombre,p.Monto,p.Estado,p.FechaCreacion ORDER BY p.Anio DESC,p.Mes DESC,g.Nombre,s.Nombre;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_finanzas_leer_presupuesto @Id BIGINT,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;IF NOT EXISTS(SELECT 1 FROM dbo.FinanzaPresupuesto p WHERE p.FinanzaPresupuestoId=@Id AND p.Eliminado=0 AND (@EsAdministrador=1 OR (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=p.GiroNegocioId AND ug.Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=p.SedeId AND us.Eliminado=0)))) RETURN;SELECT p.FinanzaPresupuestoId,p.GiroNegocioId,g.Nombre Giro,p.SedeId,s.Nombre Sede,p.Anio,p.Mes,p.Nombre,p.Monto,p.Estado,p.Observacion,COALESCE(SUM(x.Monto),0) GastoReal,p.Monto-COALESCE(SUM(x.Monto),0) Disponible,CAST(CASE WHEN p.Monto=0 THEN 0 ELSE COALESCE(SUM(x.Monto),0)*100.0/p.Monto END AS DECIMAL(7,2)) PorcentajeEjecutado,p.FechaCreacion FROM dbo.FinanzaPresupuesto p JOIN dbo.GiroNegocio g ON g.GiroNegocioId=p.GiroNegocioId JOIN dbo.Sede s ON s.SedeId=p.SedeId LEFT JOIN dbo.FinanzaGasto x ON x.FinanzaPresupuestoId=p.FinanzaPresupuestoId WHERE p.FinanzaPresupuestoId=@Id GROUP BY p.FinanzaPresupuestoId,p.GiroNegocioId,g.Nombre,p.SedeId,s.Nombre,p.Anio,p.Mes,p.Nombre,p.Monto,p.Estado,p.Observacion,p.FechaCreacion;SELECT x.FinanzaGastoId,x.Fecha,x.Categoria,x.Concepto,x.Monto,x.OrigenModulo,x.OrigenRegistroId,x.Referencia,u.NombreUsuario,x.FechaCreacion FROM dbo.FinanzaGasto x JOIN dbo.Usuario u ON u.UsuarioId=x.UsuarioId WHERE x.FinanzaPresupuestoId=@Id ORDER BY x.Fecha DESC,x.FinanzaGastoId DESC;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_finanzas_leer_opciones @UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;SELECT g.GiroNegocioId Id,g.Nombre FROM dbo.GiroNegocio g WHERE g.Eliminado=0 AND g.EsActivo=1 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio x WHERE x.UsuarioId=@UsuarioId AND x.GiroNegocioId=g.GiroNegocioId AND x.Eliminado=0)) ORDER BY g.Nombre;SELECT s.SedeId Id,s.Nombre FROM dbo.Sede s WHERE s.Eliminado=0 AND s.EsActivo=1 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=s.SedeId AND x.Eliminado=0)) ORDER BY s.Nombre;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_finanzas_crear_presupuesto @GiroId INT,@SedeId INT,@Anio SMALLINT,@Mes TINYINT,@Nombre NVARCHAR(180),@Monto DECIMAL(18,2),@Observacion NVARCHAR(500)=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;IF @Anio NOT BETWEEN 2000 AND 2100 OR @Mes NOT BETWEEN 1 AND 12 OR @Monto<=0 THROW 50002,N'Datos de presupuesto inválidos.',1;IF NOT EXISTS(SELECT 1 FROM dbo.SedeGiroNegocio WHERE GiroNegocioId=@GiroId AND SedeId=@SedeId AND Eliminado=0) THROW 50002,N'La sede no opera el giro seleccionado.',1;IF @EsAdministrador=0 AND (NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroId AND Eliminado=0) OR NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0)) THROW 50002,N'Sin acceso al giro o sede.',1;INSERT dbo.FinanzaPresupuesto(GiroNegocioId,SedeId,Anio,Mes,Nombre,Monto,CreadoPorUsuarioId,Observacion) VALUES(@GiroId,@SedeId,@Anio,@Mes,LTRIM(RTRIM(@Nombre)),@Monto,@UsuarioId,NULLIF(LTRIM(RTRIM(@Observacion)),N''));DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Finanzas',N'CrearPresupuesto',@Id,N'Exitoso',@Nombre;SELECT @Id;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_finanzas_registrar_gasto @PresupuestoId BIGINT,@Fecha DATE,@Categoria NVARCHAR(30),@Concepto NVARCHAR(250),@Monto DECIMAL(18,2),@OrigenModulo NVARCHAR(30),@OrigenRegistroId BIGINT=NULL,@Referencia NVARCHAR(120)=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;DECLARE @GiroId INT,@SedeId INT,@Estado NVARCHAR(20),@GiroNombre NVARCHAR(150);SELECT @GiroId=p.GiroNegocioId,@SedeId=p.SedeId,@Estado=p.Estado,@GiroNombre=g.Nombre FROM dbo.FinanzaPresupuesto p JOIN dbo.GiroNegocio g ON g.GiroNegocioId=p.GiroNegocioId WHERE p.FinanzaPresupuestoId=@PresupuestoId AND p.Eliminado=0;IF @Estado<>N'Abierto' OR @Monto<=0 OR @Categoria NOT IN(N'Material',N'Personal',N'Transporte',N'Servicios',N'Maquinaria',N'Otro') OR @OrigenModulo NOT IN(N'Manual',N'Pedido',N'Produccion',N'Transporte',N'Construccion') THROW 50002,N'Gasto inválido o presupuesto cerrado.',1;IF (@OrigenModulo=N'Manual' AND @OrigenRegistroId IS NOT NULL) OR (@OrigenModulo<>N'Manual' AND @OrigenRegistroId IS NULL) THROW 50002,N'La referencia de origen no corresponde.',1;IF @EsAdministrador=0 AND (NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroId AND Eliminado=0) OR NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0)) THROW 50002,N'Sin acceso al presupuesto.',1;IF @OrigenModulo=N'Pedido' AND NOT EXISTS(SELECT 1 FROM dbo.Pedido WHERE PedidoId=@OrigenRegistroId AND GiroNegocioId=@GiroId AND Eliminado=0) THROW 50002,N'El pedido no corresponde al giro.',1;IF @OrigenModulo=N'Produccion' AND (@GiroNombre<>N'Procesamiento de materia prima' OR NOT EXISTS(SELECT 1 FROM dbo.ProduccionOrden WHERE ProduccionOrdenId=@OrigenRegistroId AND SedeId=@SedeId AND Eliminado=0)) THROW 50002,N'La orden de producción no corresponde al presupuesto.',1;IF @OrigenModulo=N'Transporte' AND (@GiroNombre NOT IN(N'Transporte de materia prima',N'Transporte nacional e internacional') OR NOT EXISTS(SELECT 1 FROM dbo.TransporteViaje WHERE TransporteViajeId=@OrigenRegistroId AND SedeId=@SedeId AND Eliminado=0)) THROW 50002,N'El viaje no corresponde al presupuesto.',1;IF @OrigenModulo=N'Construccion' AND (@GiroNombre<>N'Servicios de construcción' OR NOT EXISTS(SELECT 1 FROM dbo.ConstruccionProyecto WHERE ConstruccionProyectoId=@OrigenRegistroId AND SedeId=@SedeId AND Eliminado=0)) THROW 50002,N'La obra no corresponde al presupuesto.',1;INSERT dbo.FinanzaGasto(FinanzaPresupuestoId,Fecha,Categoria,Concepto,Monto,OrigenModulo,OrigenRegistroId,Referencia,UsuarioId) VALUES(@PresupuestoId,@Fecha,@Categoria,LTRIM(RTRIM(@Concepto)),@Monto,@OrigenModulo,@OrigenRegistroId,NULLIF(LTRIM(RTRIM(@Referencia)),N''),@UsuarioId);DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Finanzas',N'RegistrarGasto',@Id,N'Exitoso',@OrigenModulo;SELECT @Id;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_finanzas_actualizar_estado @Id BIGINT,@Estado NVARCHAR(20),@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;DECLARE @Anterior NVARCHAR(20),@GiroId INT,@SedeId INT;SELECT @Anterior=Estado,@GiroId=GiroNegocioId,@SedeId=SedeId FROM dbo.FinanzaPresupuesto WHERE FinanzaPresupuestoId=@Id AND Eliminado=0;IF @Anterior<>N'Abierto' OR @Estado NOT IN(N'Cerrado',N'Cancelado') THROW 50002,N'Transición de presupuesto inválida.',1;IF @EsAdministrador=0 AND (NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroId AND Eliminado=0) OR NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0)) THROW 50002,N'Sin acceso al presupuesto.',1;UPDATE dbo.FinanzaPresupuesto SET Estado=@Estado,FechaModificacion=SYSUTCDATETIME() WHERE FinanzaPresupuestoId=@Id;EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Finanzas',N'CerrarPresupuesto',@Id,N'Exitoso',@Estado;SELECT 1;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_finanzas_eliminar_presupuesto @Id BIGINT,@UsuarioId INT
AS
BEGIN SET NOCOUNT ON;UPDATE dbo.FinanzaPresupuesto SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE FinanzaPresupuestoId=@Id AND Eliminado=0 AND Estado IN(N'Cerrado',N'Cancelado');DECLARE @F INT=@@ROWCOUNT;IF @F>0 EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Finanzas',N'EliminarPresupuesto',@Id,N'Exitoso',NULL;SELECT @F;END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_alertas_leer_listado @UsuarioId INT,@EsAdministrador BIT,@Estado NVARCHAR(20)=NULL,@SoloPendientes BIT=0
AS
BEGIN SET NOCOUNT ON;SELECT n.AlertaNotificacionId,n.Tipo,n.Titulo,n.Mensaje,n.Severidad,n.Estado,n.FechaProgramadaUtc,n.FechaVencimientoUtc,r.Nombre Rol,g.Nombre Giro,s.Nombre Sede,u.NombreUsuario UsuarioDestino,n.ModuloOrigen,n.RegistroOrigenId,CAST(CASE WHEN l.AlertaLecturaId IS NULL THEN 0 ELSE 1 END AS BIT) Leida,(SELECT COUNT(*) FROM dbo.AlertaSeguimiento x WHERE x.AlertaNotificacionId=n.AlertaNotificacionId) Seguimientos FROM dbo.AlertaNotificacion n LEFT JOIN dbo.Rol r ON r.RolId=n.RolId LEFT JOIN dbo.GiroNegocio g ON g.GiroNegocioId=n.GiroNegocioId LEFT JOIN dbo.Sede s ON s.SedeId=n.SedeId LEFT JOIN dbo.Usuario u ON u.UsuarioId=n.UsuarioDestinoId LEFT JOIN dbo.AlertaLectura l ON l.AlertaNotificacionId=n.AlertaNotificacionId AND l.UsuarioId=@UsuarioId WHERE n.Eliminado=0 AND (@Estado IS NULL OR n.Estado=@Estado) AND (@SoloPendientes=0 OR l.AlertaLecturaId IS NULL OR n.Estado=N'Activa') AND (@EsAdministrador=1 OR ((n.UsuarioDestinoId IS NULL OR n.UsuarioDestinoId=@UsuarioId) AND (n.RolId IS NULL OR EXISTS(SELECT 1 FROM dbo.UsuarioRol ur WHERE ur.UsuarioId=@UsuarioId AND ur.RolId=n.RolId AND ur.Eliminado=0)) AND (n.GiroNegocioId IS NULL OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=n.GiroNegocioId AND ug.Eliminado=0)) AND (n.SedeId IS NULL OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=n.SedeId AND us.Eliminado=0)))) ORDER BY CASE n.Severidad WHEN N'Critica' THEN 1 WHEN N'Advertencia' THEN 2 ELSE 3 END,n.FechaProgramadaUtc DESC;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_alertas_leer_por_id @Id BIGINT,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;IF NOT EXISTS(SELECT 1 FROM dbo.AlertaNotificacion n WHERE n.AlertaNotificacionId=@Id AND n.Eliminado=0 AND (@EsAdministrador=1 OR ((n.UsuarioDestinoId IS NULL OR n.UsuarioDestinoId=@UsuarioId) AND (n.RolId IS NULL OR EXISTS(SELECT 1 FROM dbo.UsuarioRol ur WHERE ur.UsuarioId=@UsuarioId AND ur.RolId=n.RolId AND ur.Eliminado=0)) AND (n.GiroNegocioId IS NULL OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=n.GiroNegocioId AND ug.Eliminado=0)) AND (n.SedeId IS NULL OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=n.SedeId AND us.Eliminado=0))))) RETURN;SELECT n.AlertaNotificacionId,n.Tipo,n.Titulo,n.Mensaje,n.Severidad,n.Estado,n.FechaProgramadaUtc,n.FechaVencimientoUtc,n.RolId,r.Nombre Rol,n.GiroNegocioId,g.Nombre Giro,n.SedeId,s.Nombre Sede,n.UsuarioDestinoId,u.NombreUsuario UsuarioDestino,n.ModuloOrigen,n.RegistroOrigenId,c.NombreUsuario CreadoPor,n.FechaCreacion,CAST(CASE WHEN l.AlertaLecturaId IS NULL THEN 0 ELSE 1 END AS BIT) Leida,l.FechaLectura FROM dbo.AlertaNotificacion n LEFT JOIN dbo.Rol r ON r.RolId=n.RolId LEFT JOIN dbo.GiroNegocio g ON g.GiroNegocioId=n.GiroNegocioId LEFT JOIN dbo.Sede s ON s.SedeId=n.SedeId LEFT JOIN dbo.Usuario u ON u.UsuarioId=n.UsuarioDestinoId JOIN dbo.Usuario c ON c.UsuarioId=n.CreadoPorUsuarioId LEFT JOIN dbo.AlertaLectura l ON l.AlertaNotificacionId=n.AlertaNotificacionId AND l.UsuarioId=@UsuarioId WHERE n.AlertaNotificacionId=@Id;SELECT x.AlertaSeguimientoId,x.Comentario,u.NombreUsuario,x.Fecha FROM dbo.AlertaSeguimiento x JOIN dbo.Usuario u ON u.UsuarioId=x.UsuarioId WHERE x.AlertaNotificacionId=@Id ORDER BY x.Fecha DESC;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_alertas_leer_opciones @UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;SELECT RolId Id,Nombre FROM dbo.Rol WHERE Eliminado=0 AND EsActivo=1 AND Nombre<>N'Cliente' ORDER BY Nombre;SELECT g.GiroNegocioId Id,g.Nombre FROM dbo.GiroNegocio g WHERE g.Eliminado=0 AND g.EsActivo=1 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio x WHERE x.UsuarioId=@UsuarioId AND x.GiroNegocioId=g.GiroNegocioId AND x.Eliminado=0)) ORDER BY g.Nombre;SELECT s.SedeId Id,s.Nombre FROM dbo.Sede s WHERE s.Eliminado=0 AND s.EsActivo=1 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede x WHERE x.UsuarioId=@UsuarioId AND x.SedeId=s.SedeId AND x.Eliminado=0)) ORDER BY s.Nombre;SELECT u.UsuarioId Id,CONCAT(u.Nombre,N' ',u.Apellido,N' (',u.NombreUsuario,N')') Nombre FROM dbo.Usuario u WHERE u.Eliminado=0 AND u.EsActivo=1 AND EXISTS(SELECT 1 FROM dbo.UsuarioRol ur JOIN dbo.Rol r ON r.RolId=ur.RolId WHERE ur.UsuarioId=u.UsuarioId AND ur.Eliminado=0 AND r.Eliminado=0 AND r.EsActivo=1 AND r.Nombre<>N'Cliente') AND (@EsAdministrador=1 OR u.UsuarioId=@UsuarioId OR (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio a JOIN dbo.UsuarioGiroNegocio b ON b.GiroNegocioId=a.GiroNegocioId AND b.UsuarioId=u.UsuarioId AND b.Eliminado=0 WHERE a.UsuarioId=@UsuarioId AND a.Eliminado=0) AND EXISTS(SELECT 1 FROM dbo.UsuarioSede a JOIN dbo.UsuarioSede b ON b.SedeId=a.SedeId AND b.UsuarioId=u.UsuarioId AND b.Eliminado=0 WHERE a.UsuarioId=@UsuarioId AND a.Eliminado=0))) ORDER BY u.Nombre,u.Apellido;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_alertas_crear @Tipo NVARCHAR(20),@Titulo NVARCHAR(180),@Mensaje NVARCHAR(1500),@Severidad NVARCHAR(20),@RolId INT=NULL,@GiroId INT=NULL,@SedeId INT=NULL,@UsuarioDestinoId INT=NULL,@FechaProgramadaUtc DATETIME2(0),@FechaVencimientoUtc DATETIME2(0)=NULL,@ModuloOrigen NVARCHAR(50)=NULL,@RegistroOrigenId BIGINT=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;IF @Tipo NOT IN(N'Alerta',N'Recordatorio') OR @Severidad NOT IN(N'Informativa',N'Advertencia',N'Critica') OR NULLIF(LTRIM(RTRIM(@Titulo)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@Mensaje)),N'') IS NULL OR (@FechaVencimientoUtc IS NOT NULL AND @FechaVencimientoUtc<@FechaProgramadaUtc) THROW 50002,N'Datos de alerta inválidos.',1;IF @RolId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.Rol WHERE RolId=@RolId AND Eliminado=0 AND EsActivo=1 AND Nombre<>N'Cliente') THROW 50002,N'Rol destino inválido.',1;IF @EsAdministrador=0 AND @GiroId IS NULL AND @SedeId IS NULL THROW 50002,N'El gerente debe delimitar la alerta por giro o sede.',1;IF @EsAdministrador=0 AND ((@GiroId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroId AND Eliminado=0)) OR (@SedeId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0))) THROW 50002,N'Sin acceso al alcance seleccionado.',1;IF @UsuarioDestinoId IS NOT NULL AND (NOT EXISTS(SELECT 1 FROM dbo.Usuario u JOIN dbo.UsuarioRol ur ON ur.UsuarioId=u.UsuarioId AND ur.Eliminado=0 JOIN dbo.Rol r ON r.RolId=ur.RolId AND r.Eliminado=0 AND r.EsActivo=1 AND r.Nombre<>N'Cliente' WHERE u.UsuarioId=@UsuarioDestinoId AND u.Eliminado=0 AND u.EsActivo=1) OR (@EsAdministrador=0 AND ((@GiroId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioDestinoId AND GiroNegocioId=@GiroId AND Eliminado=0)) OR (@SedeId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioDestinoId AND SedeId=@SedeId AND Eliminado=0))))) THROW 50002,N'Usuario destino inválido para el alcance.',1;INSERT dbo.AlertaNotificacion(Tipo,Titulo,Mensaje,Severidad,RolId,GiroNegocioId,SedeId,UsuarioDestinoId,FechaProgramadaUtc,FechaVencimientoUtc,ModuloOrigen,RegistroOrigenId,CreadoPorUsuarioId) VALUES(@Tipo,LTRIM(RTRIM(@Titulo)),LTRIM(RTRIM(@Mensaje)),@Severidad,@RolId,@GiroId,@SedeId,@UsuarioDestinoId,@FechaProgramadaUtc,@FechaVencimientoUtc,NULLIF(LTRIM(RTRIM(@ModuloOrigen)),N''),@RegistroOrigenId,@UsuarioId);DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Alertas',N'Crear',@Id,N'Exitoso',@Severidad;SELECT @Id;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_alertas_marcar_leida @Id BIGINT,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;IF NOT EXISTS(SELECT 1 FROM dbo.AlertaNotificacion n WHERE n.AlertaNotificacionId=@Id AND n.Eliminado=0 AND (@EsAdministrador=1 OR ((n.UsuarioDestinoId IS NULL OR n.UsuarioDestinoId=@UsuarioId) AND (n.RolId IS NULL OR EXISTS(SELECT 1 FROM dbo.UsuarioRol ur WHERE ur.UsuarioId=@UsuarioId AND ur.RolId=n.RolId AND ur.Eliminado=0)) AND (n.GiroNegocioId IS NULL OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=n.GiroNegocioId AND ug.Eliminado=0)) AND (n.SedeId IS NULL OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=n.SedeId AND us.Eliminado=0))))) THROW 50002,N'Alerta no disponible.',1;IF NOT EXISTS(SELECT 1 FROM dbo.AlertaLectura WHERE AlertaNotificacionId=@Id AND UsuarioId=@UsuarioId) INSERT dbo.AlertaLectura(AlertaNotificacionId,UsuarioId) VALUES(@Id,@UsuarioId);SELECT 1;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_alertas_agregar_seguimiento @Id BIGINT,@Comentario NVARCHAR(1000),@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;IF NOT EXISTS(SELECT 1 FROM dbo.AlertaNotificacion n WHERE n.AlertaNotificacionId=@Id AND n.Eliminado=0 AND n.Estado=N'Activa' AND (@EsAdministrador=1 OR ((n.UsuarioDestinoId IS NULL OR n.UsuarioDestinoId=@UsuarioId) AND (n.RolId IS NULL OR EXISTS(SELECT 1 FROM dbo.UsuarioRol ur WHERE ur.UsuarioId=@UsuarioId AND ur.RolId=n.RolId AND ur.Eliminado=0)) AND (n.GiroNegocioId IS NULL OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=n.GiroNegocioId AND ug.Eliminado=0)) AND (n.SedeId IS NULL OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=n.SedeId AND us.Eliminado=0))))) THROW 50002,N'Alerta no disponible para seguimiento.',1;INSERT dbo.AlertaSeguimiento(AlertaNotificacionId,UsuarioId,Comentario) VALUES(@Id,@UsuarioId,LTRIM(RTRIM(@Comentario)));DECLARE @SeguimientoId BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Alertas',N'Seguimiento',@SeguimientoId,N'Exitoso',NULL;SELECT @SeguimientoId;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_alertas_actualizar_estado @Id BIGINT,@Estado NVARCHAR(20),@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN SET NOCOUNT ON;DECLARE @Severidad NVARCHAR(20);SELECT @Severidad=Severidad FROM dbo.AlertaNotificacion WHERE AlertaNotificacionId=@Id AND Eliminado=0 AND Estado=N'Activa';IF @Severidad IS NULL OR @Estado NOT IN(N'Resuelta',N'Cancelada') THROW 50002,N'Transición de alerta inválida.',1;IF @EsAdministrador=0 AND NOT EXISTS(SELECT 1 FROM dbo.AlertaNotificacion n WHERE n.AlertaNotificacionId=@Id AND (n.GiroNegocioId IS NOT NULL OR n.SedeId IS NOT NULL) AND (n.GiroNegocioId IS NULL OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=n.GiroNegocioId AND ug.Eliminado=0)) AND (n.SedeId IS NULL OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=n.SedeId AND us.Eliminado=0))) THROW 50002,N'Sin acceso a la alerta.',1;IF @Estado=N'Resuelta' AND @Severidad=N'Critica' AND NOT EXISTS(SELECT 1 FROM dbo.AlertaSeguimiento WHERE AlertaNotificacionId=@Id) THROW 50002,N'Una alerta crítica requiere seguimiento antes de resolverse.',1;UPDATE dbo.AlertaNotificacion SET Estado=@Estado,FechaModificacion=SYSUTCDATETIME() WHERE AlertaNotificacionId=@Id;EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Alertas',N'CambiarEstado',@Id,N'Exitoso',@Estado;SELECT 1;END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_alertas_eliminar @Id BIGINT,@UsuarioId INT
AS
BEGIN SET NOCOUNT ON;UPDATE dbo.AlertaNotificacion SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE AlertaNotificacionId=@Id AND Eliminado=0 AND Estado IN(N'Resuelta',N'Cancelada');DECLARE @F INT=@@ROWCOUNT;IF @F>0 EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Alertas',N'Eliminar',@Id,N'Exitoso',NULL;SELECT @F;END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_comunicaciones_leer_listado
    @UsuarioId INT,@EsAdministrador BIT,@EsCliente BIT,@Estado NVARCHAR(20)=NULL,
    @Tipo NVARCHAR(20)=NULL,@Busqueda NVARCHAR(200)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Busqueda=NULLIF(LTRIM(RTRIM(@Busqueda)),N'');
    SELECT h.ComunicacionHiloId,h.Tipo,h.Asunto,h.Estado,h.ClienteId,c.Nombre AS Cliente,
           h.GiroNegocioId,g.Nombre AS Giro,h.PedidoId,h.ResponsableUsuarioId,
           CASE WHEN r.UsuarioId IS NULL THEN NULL ELSE CONCAT(r.Nombre,N' ',r.Apellido) END AS Responsable,
           h.ModuloOrigen,h.RegistroOrigenId,h.UltimaActividad,h.FechaCreacion,
           (SELECT COUNT(*) FROM dbo.ComunicacionMensaje m WHERE m.ComunicacionHiloId=h.ComunicacionHiloId AND (@EsCliente=0 OR m.EsInterno=0)) AS Mensajes
    FROM dbo.ComunicacionHilo h
    LEFT JOIN dbo.Cliente c ON c.ClienteId=h.ClienteId
    LEFT JOIN dbo.GiroNegocio g ON g.GiroNegocioId=h.GiroNegocioId
    LEFT JOIN dbo.Usuario r ON r.UsuarioId=h.ResponsableUsuarioId
    WHERE h.Eliminado=0 AND (@Estado IS NULL OR h.Estado=@Estado) AND (@Tipo IS NULL OR h.Tipo=@Tipo)
      AND (@Busqueda IS NULL OR h.Asunto LIKE N'%'+@Busqueda+N'%' OR c.Nombre LIKE N'%'+@Busqueda+N'%' OR g.Nombre LIKE N'%'+@Busqueda+N'%')
      AND (@EsAdministrador=1 OR
           (@EsCliente=1 AND h.Tipo=N'Cliente' AND EXISTS(SELECT 1 FROM dbo.ClienteUsuario cu WHERE cu.ClienteId=h.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0)) OR
           (@EsCliente=0 AND (h.CreadoPorUsuarioId=@UsuarioId OR h.ResponsableUsuarioId=@UsuarioId OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=h.GiroNegocioId AND ug.Eliminado=0))))
    ORDER BY h.UltimaActividad DESC,h.ComunicacionHiloId DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_comunicaciones_leer_por_id
    @Id BIGINT,@UsuarioId INT,@EsAdministrador BIT,@EsCliente BIT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM dbo.ComunicacionHilo h WHERE h.ComunicacionHiloId=@Id AND h.Eliminado=0 AND
       (@EsAdministrador=1 OR (@EsCliente=1 AND h.Tipo=N'Cliente' AND EXISTS(SELECT 1 FROM dbo.ClienteUsuario cu WHERE cu.ClienteId=h.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0)) OR
        (@EsCliente=0 AND (h.CreadoPorUsuarioId=@UsuarioId OR h.ResponsableUsuarioId=@UsuarioId OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=h.GiroNegocioId AND ug.Eliminado=0))))) RETURN;
    SELECT h.ComunicacionHiloId,h.Tipo,h.Asunto,h.Estado,h.ClienteId,c.Nombre AS Cliente,
           h.GiroNegocioId,g.Nombre AS Giro,h.PedidoId,h.ResponsableUsuarioId,
           CASE WHEN r.UsuarioId IS NULL THEN NULL ELSE CONCAT(r.Nombre,N' ',r.Apellido) END AS Responsable,
           h.ModuloOrigen,h.RegistroOrigenId,u.NombreUsuario AS CreadoPor,h.UltimaActividad,h.FechaCreacion,h.FechaModificacion
    FROM dbo.ComunicacionHilo h
    LEFT JOIN dbo.Cliente c ON c.ClienteId=h.ClienteId
    LEFT JOIN dbo.GiroNegocio g ON g.GiroNegocioId=h.GiroNegocioId
    LEFT JOIN dbo.Usuario r ON r.UsuarioId=h.ResponsableUsuarioId
    INNER JOIN dbo.Usuario u ON u.UsuarioId=h.CreadoPorUsuarioId
    WHERE h.ComunicacionHiloId=@Id;
    SELECT m.ComunicacionMensajeId,m.UsuarioId,u.NombreUsuario,m.Mensaje,m.EsInterno,m.Fecha
    FROM dbo.ComunicacionMensaje m INNER JOIN dbo.Usuario u ON u.UsuarioId=m.UsuarioId
    WHERE m.ComunicacionHiloId=@Id AND (@EsCliente=0 OR m.EsInterno=0)
    ORDER BY m.Fecha,m.ComunicacionMensajeId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_comunicaciones_leer_opciones
    @UsuarioId INT,@EsAdministrador BIT,@EsCliente BIT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT DISTINCT c.ClienteId AS Id,c.Nombre FROM dbo.Cliente c
    WHERE c.Eliminado=0 AND c.EsActivo=1 AND
      (@EsAdministrador=1 OR (@EsCliente=1 AND EXISTS(SELECT 1 FROM dbo.ClienteUsuario cu WHERE cu.ClienteId=c.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0)) OR
       (@EsCliente=0 AND EXISTS(SELECT 1 FROM dbo.ClienteGiroNegocio cg INNER JOIN dbo.UsuarioGiroNegocio ug ON ug.GiroNegocioId=cg.GiroNegocioId AND ug.UsuarioId=@UsuarioId AND ug.Eliminado=0 WHERE cg.ClienteId=c.ClienteId AND cg.Eliminado=0))) ORDER BY c.Nombre;
    SELECT DISTINCT g.GiroNegocioId AS Id,g.Nombre FROM dbo.GiroNegocio g
    WHERE g.Eliminado=0 AND g.EsActivo=1 AND
      (@EsAdministrador=1 OR (@EsCliente=1 AND EXISTS(SELECT 1 FROM dbo.ClienteGiroNegocio cg INNER JOIN dbo.ClienteUsuario cu ON cu.ClienteId=cg.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0 WHERE cg.GiroNegocioId=g.GiroNegocioId AND cg.Eliminado=0)) OR
       (@EsCliente=0 AND EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.GiroNegocioId=g.GiroNegocioId AND ug.UsuarioId=@UsuarioId AND ug.Eliminado=0))) ORDER BY g.Nombre;
    SELECT p.PedidoId AS Id,CONCAT(N'#',p.PedidoId,N' · ',p.Titulo) AS Nombre FROM dbo.Pedido p
    WHERE p.Eliminado=0 AND (@EsAdministrador=1 OR
      (@EsCliente=1 AND EXISTS(SELECT 1 FROM dbo.ClienteUsuario cu WHERE cu.ClienteId=p.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0)) OR
      (@EsCliente=0 AND (p.VendedorUsuarioId=@UsuarioId OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=p.GiroNegocioId AND ug.Eliminado=0))))
    ORDER BY p.PedidoId DESC;
    SELECT DISTINCT u.UsuarioId AS Id,CONCAT(u.Nombre,N' ',u.Apellido,N' (',u.NombreUsuario,N')') AS Nombre
    FROM dbo.Usuario u INNER JOIN dbo.UsuarioRol ur ON ur.UsuarioId=u.UsuarioId AND ur.Eliminado=0
    INNER JOIN dbo.Rol r ON r.RolId=ur.RolId AND r.Eliminado=0 AND r.EsActivo=1
    WHERE @EsCliente=0 AND u.Eliminado=0 AND u.EsActivo=1 AND r.Nombre<>N'Cliente' AND
      (@EsAdministrador=1 OR u.UsuarioId=@UsuarioId OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio a INNER JOIN dbo.UsuarioGiroNegocio b ON b.GiroNegocioId=a.GiroNegocioId AND b.UsuarioId=u.UsuarioId AND b.Eliminado=0 WHERE a.UsuarioId=@UsuarioId AND a.Eliminado=0))
    ORDER BY Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_comunicaciones_crear
    @Tipo NVARCHAR(20),@ClienteId INT=NULL,@GiroNegocioId INT=NULL,@PedidoId BIGINT=NULL,
    @Asunto NVARCHAR(180),@MensajeInicial NVARCHAR(2000),@ModuloOrigen NVARCHAR(50)=NULL,
    @RegistroOrigenId BIGINT=NULL,@UsuarioId INT,@EsAdministrador BIT,@EsCliente BIT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @Tipo NOT IN(N'Cliente',N'Interna') OR NULLIF(LTRIM(RTRIM(@Asunto)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@MensajeInicial)),N'') IS NULL THROW 50002,N'Datos de comunicación inválidos.',1;
        IF @EsCliente=1 AND @Tipo<>N'Cliente' THROW 50002,N'El cliente solo puede iniciar comunicaciones con su empresa.',1;
        IF @Tipo=N'Cliente' AND @ClienteId IS NULL THROW 50002,N'La comunicación requiere una empresa cliente.',1;
        IF @ClienteId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.Cliente WHERE ClienteId=@ClienteId AND Eliminado=0 AND EsActivo=1) THROW 50002,N'Cliente no disponible.',1;
        IF @GiroNegocioId IS NOT NULL AND @ClienteId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.ClienteGiroNegocio WHERE ClienteId=@ClienteId AND GiroNegocioId=@GiroNegocioId AND Eliminado=0) THROW 50002,N'El giro no está contratado por el cliente.',1;
        IF @EsCliente=1 AND NOT EXISTS(SELECT 1 FROM dbo.ClienteUsuario WHERE ClienteId=@ClienteId AND UsuarioId=@UsuarioId AND Eliminado=0) THROW 50002,N'El usuario no pertenece al cliente.',1;
        IF @EsCliente=0 AND @EsAdministrador=0 AND (@GiroNegocioId IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroNegocioId AND Eliminado=0)) THROW 50002,N'Sin acceso al giro de la comunicación.',1;
        IF @PedidoId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.Pedido p WHERE p.PedidoId=@PedidoId AND p.Eliminado=0 AND (@ClienteId IS NULL OR p.ClienteId=@ClienteId) AND (@GiroNegocioId IS NULL OR p.GiroNegocioId=@GiroNegocioId)) THROW 50002,N'El pedido no corresponde con la comunicación.',1;
        INSERT dbo.ComunicacionHilo(Tipo,ClienteId,GiroNegocioId,PedidoId,Asunto,ModuloOrigen,RegistroOrigenId,CreadoPorUsuarioId)
        VALUES(@Tipo,@ClienteId,@GiroNegocioId,@PedidoId,LTRIM(RTRIM(@Asunto)),NULLIF(LTRIM(RTRIM(@ModuloOrigen)),N''),@RegistroOrigenId,@UsuarioId);
        DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());
        INSERT dbo.ComunicacionMensaje(ComunicacionHiloId,UsuarioId,Mensaje,EsInterno) VALUES(@Id,@UsuarioId,LTRIM(RTRIM(@MensajeInicial)),0);
        EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Comunicaciones',N'Crear',@Id,N'Exitoso',@Tipo;
        COMMIT TRANSACTION;
        SELECT @Id;
    END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_comunicaciones_agregar_mensaje
    @Id BIGINT,@Mensaje NVARCHAR(2000),@EsInterno BIT,@UsuarioId INT,@EsAdministrador BIT,@EsCliente BIT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF NULLIF(LTRIM(RTRIM(@Mensaje)),N'') IS NULL OR (@EsCliente=1 AND @EsInterno=1) THROW 50002,N'Mensaje inválido.',1;
    IF NOT EXISTS(SELECT 1 FROM dbo.ComunicacionHilo h WHERE h.ComunicacionHiloId=@Id AND h.Eliminado=0 AND h.Estado=N'Abierta' AND
      (@EsAdministrador=1 OR (@EsCliente=1 AND h.Tipo=N'Cliente' AND EXISTS(SELECT 1 FROM dbo.ClienteUsuario cu WHERE cu.ClienteId=h.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0)) OR
       (@EsCliente=0 AND (h.CreadoPorUsuarioId=@UsuarioId OR h.ResponsableUsuarioId=@UsuarioId OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=h.GiroNegocioId AND ug.Eliminado=0))))) THROW 50002,N'Comunicación no disponible.',1;
    INSERT dbo.ComunicacionMensaje(ComunicacionHiloId,UsuarioId,Mensaje,EsInterno) VALUES(@Id,@UsuarioId,LTRIM(RTRIM(@Mensaje)),@EsInterno);
    DECLARE @MensajeId BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());
    UPDATE dbo.ComunicacionHilo SET UltimaActividad=SYSUTCDATETIME(),FechaModificacion=SYSUTCDATETIME() WHERE ComunicacionHiloId=@Id;
    EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Comunicaciones',N'Mensaje',@MensajeId,N'Exitoso',NULL;
    SELECT @MensajeId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_comunicaciones_actualizar_gestion
    @Id BIGINT,@Estado NVARCHAR(20),@ResponsableUsuarioId INT=NULL,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;
    IF @Estado NOT IN(N'Abierta',N'Cerrada') THROW 50002,N'Estado de comunicación inválido.',1;
    IF NOT EXISTS(SELECT 1 FROM dbo.ComunicacionHilo h WHERE h.ComunicacionHiloId=@Id AND h.Eliminado=0 AND
      (@EsAdministrador=1 OR h.ResponsableUsuarioId=@UsuarioId OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=h.GiroNegocioId AND ug.Eliminado=0))) THROW 50002,N'Sin acceso a la comunicación.',1;
    IF @ResponsableUsuarioId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.Usuario u INNER JOIN dbo.UsuarioRol ur ON ur.UsuarioId=u.UsuarioId AND ur.Eliminado=0 INNER JOIN dbo.Rol r ON r.RolId=ur.RolId AND r.Eliminado=0 AND r.Nombre<>N'Cliente' WHERE u.UsuarioId=@ResponsableUsuarioId AND u.Eliminado=0 AND u.EsActivo=1) THROW 50002,N'Responsable inválido.',1;
    UPDATE dbo.ComunicacionHilo SET Estado=@Estado,ResponsableUsuarioId=@ResponsableUsuarioId,FechaModificacion=SYSUTCDATETIME(),UltimaActividad=SYSUTCDATETIME() WHERE ComunicacionHiloId=@Id;
    EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Comunicaciones',N'Gestionar',@Id,N'Exitoso',@Estado;
    SELECT 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_comunicaciones_eliminar @Id BIGINT,@UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.ComunicacionHilo SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE ComunicacionHiloId=@Id AND Eliminado=0 AND Estado=N'Cerrada';
    DECLARE @Filas INT=@@ROWCOUNT;
    IF @Filas>0 EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Comunicaciones',N'Eliminar',@Id,N'Exitoso',NULL;
    SELECT @Filas;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_portalcliente_leer_operaciones
    @UsuarioId INT,@EsAdministrador BIT,@ClienteId INT=NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
      (SELECT COUNT_BIG(*) FROM dbo.TransporteViaje v
       INNER JOIN dbo.Cliente c ON c.ClienteId=v.ClienteId AND c.Eliminado=0 AND c.EsActivo=1
       WHERE v.Eliminado=0 AND v.Estado IN(N'Programado',N'EnRuta')
         AND (@ClienteId IS NULL OR v.ClienteId=@ClienteId)
         AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.ClienteUsuario cu WHERE cu.ClienteId=v.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0))) AS ViajesActivos,
      (SELECT COUNT_BIG(*) FROM dbo.MaquinariaContrato mc
       INNER JOIN dbo.Cliente c ON c.ClienteId=mc.ClienteId AND c.Eliminado=0 AND c.EsActivo=1
       WHERE mc.Eliminado=0 AND mc.Estado IN(N'Reservado',N'Activo')
         AND (@ClienteId IS NULL OR mc.ClienteId=@ClienteId)
         AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.ClienteUsuario cu WHERE cu.ClienteId=mc.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0))) AS ContratosActivos,
      (SELECT COUNT_BIG(*) FROM dbo.ConstruccionProyecto p
       INNER JOIN dbo.Cliente c ON c.ClienteId=p.ClienteId AND c.Eliminado=0 AND c.EsActivo=1
       WHERE p.Eliminado=0 AND p.Estado IN(N'Planificado',N'EnEjecucion',N'Suspendido')
         AND (@ClienteId IS NULL OR p.ClienteId=@ClienteId)
         AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.ClienteUsuario cu WHERE cu.ClienteId=p.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0))) AS ProyectosActivos;

    SELECT TOP (100) v.TransporteViajeId,v.ClienteId,c.Nombre AS Cliente,v.Tipo,
           v.Origen,v.Destino,v.DescripcionCarga,v.FechaSalidaPlanificada,
           v.FechaSalidaReal,v.FechaEntrega,v.Estado,ve.Placa,co.Nombre AS Conductor,
           (SELECT COUNT(*) FROM dbo.TransporteIncidencia i
            WHERE i.TransporteViajeId=v.TransporteViajeId AND i.Resuelta=0) AS IncidenciasAbiertas
    FROM dbo.TransporteViaje v
    INNER JOIN dbo.Cliente c ON c.ClienteId=v.ClienteId AND c.Eliminado=0 AND c.EsActivo=1
    INNER JOIN dbo.TransporteVehiculo ve ON ve.TransporteVehiculoId=v.TransporteVehiculoId
    INNER JOIN dbo.TransporteConductor co ON co.TransporteConductorId=v.TransporteConductorId
    WHERE v.Eliminado=0 AND (@ClienteId IS NULL OR v.ClienteId=@ClienteId)
      AND (@EsAdministrador=1 OR EXISTS(
          SELECT 1 FROM dbo.ClienteUsuario cu
          WHERE cu.ClienteId=v.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0))
    ORDER BY v.FechaSalidaPlanificada DESC,v.TransporteViajeId DESC;

    SELECT TOP (100) mc.MaquinariaContratoId,mc.ClienteId,c.Nombre AS Cliente,
           e.MaquinariaEquipoId,e.Codigo,CONCAT(e.Tipo,N' ',e.Marca,N' ',e.Modelo) AS Equipo,
           mc.Tipo,mc.FechaInicio,mc.FechaFin,mc.MontoTotal,mc.Estado,
           mc.HorasEntrega,mc.HorasDevolucion
    FROM dbo.MaquinariaContrato mc
    INNER JOIN dbo.Cliente c ON c.ClienteId=mc.ClienteId AND c.Eliminado=0 AND c.EsActivo=1
    INNER JOIN dbo.MaquinariaEquipo e ON e.MaquinariaEquipoId=mc.MaquinariaEquipoId
    WHERE mc.Eliminado=0 AND (@ClienteId IS NULL OR mc.ClienteId=@ClienteId)
      AND (@EsAdministrador=1 OR EXISTS(
          SELECT 1 FROM dbo.ClienteUsuario cu
          WHERE cu.ClienteId=mc.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0))
    ORDER BY mc.FechaInicio DESC,mc.MaquinariaContratoId DESC;

    SELECT TOP (100) p.ConstruccionProyectoId,p.ClienteId,c.Nombre AS Cliente,
           p.Nombre,p.TipoObra,p.Ubicacion,p.FechaInicioPlanificada,p.FechaFinPlanificada,
           p.Presupuesto,p.Estado,
           CONVERT(DECIMAL(5,2),COALESCE((SELECT AVG(a.PorcentajeAvance)
               FROM dbo.ConstruccionActividad a WHERE a.ConstruccionProyectoId=p.ConstruccionProyectoId),0)) AS PorcentajeAvance,
           CONVERT(DECIMAL(18,2),COALESCE((SELECT SUM(r.Cantidad*r.CostoUnitario)
               FROM dbo.ConstruccionRecurso r WHERE r.ConstruccionProyectoId=p.ConstruccionProyectoId),0)) AS CostoReal
    FROM dbo.ConstruccionProyecto p
    INNER JOIN dbo.Cliente c ON c.ClienteId=p.ClienteId AND c.Eliminado=0 AND c.EsActivo=1
    WHERE p.Eliminado=0 AND (@ClienteId IS NULL OR p.ClienteId=@ClienteId)
      AND (@EsAdministrador=1 OR EXISTS(
          SELECT 1 FROM dbo.ClienteUsuario cu
          WHERE cu.ClienteId=p.ClienteId AND cu.UsuarioId=@UsuarioId AND cu.Eliminado=0))
    ORDER BY p.FechaInicioPlanificada DESC,p.ConstruccionProyectoId DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_integraciones_leer_listado
    @UsuarioId INT,@EsAdministrador BIT,@Estado NVARCHAR(20)=NULL,
    @Canal NVARCHAR(20)=NULL,@Busqueda NVARCHAR(200)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Estado=NULLIF(LTRIM(RTRIM(@Estado)),N'');SET @Canal=NULLIF(LTRIM(RTRIM(@Canal)),N'');SET @Busqueda=NULLIF(LTRIM(RTRIM(@Busqueda)),N'');
    SELECT e.IntegracionEventoId,e.Canal,e.Direccion,e.SocioTipo,e.SocioNombre,e.Operacion,
           e.ClaveIdempotencia,e.DocumentoExterno,e.Estado,e.Intentos,e.Error,
           e.InventarioArticuloId,a.Codigo AS ArticuloCodigo,a.Nombre AS Articulo,
           e.SedeId,s.Nombre AS Sede,e.Cantidad,e.InventarioMovimientoId,
           u.NombreUsuario,e.FechaProcesamiento,e.FechaCreacion
    FROM dbo.IntegracionEvento e
    INNER JOIN dbo.Usuario u ON u.UsuarioId=e.UsuarioId
    LEFT JOIN dbo.InventarioArticulo a ON a.InventarioArticuloId=e.InventarioArticuloId
    LEFT JOIN dbo.Sede s ON s.SedeId=e.SedeId
    WHERE e.Eliminado=0 AND (@Estado IS NULL OR e.Estado=@Estado) AND (@Canal IS NULL OR e.Canal=@Canal)
      AND (@Busqueda IS NULL OR e.SocioNombre LIKE N'%'+@Busqueda+N'%' OR e.ClaveIdempotencia LIKE N'%'+@Busqueda+N'%' OR e.DocumentoExterno LIKE N'%'+@Busqueda+N'%')
      AND (@EsAdministrador=1 OR e.UsuarioId=@UsuarioId OR
          (e.InventarioArticuloId IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=a.GiroNegocioId AND ug.Eliminado=0)
           AND e.SedeId IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=e.SedeId AND us.Eliminado=0)))
    ORDER BY e.FechaCreacion DESC,e.IntegracionEventoId DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_integraciones_leer_por_id
    @Id BIGINT,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT e.IntegracionEventoId,e.Canal,e.Direccion,e.SocioTipo,e.SocioNombre,e.Operacion,
           e.ClaveIdempotencia,e.DocumentoExterno,e.Contenido,e.Estado,e.Intentos,e.Error,
           e.InventarioArticuloId,a.Codigo AS ArticuloCodigo,a.Nombre AS Articulo,a.UnidadMedida,
           e.SedeId,s.Nombre AS Sede,e.Cantidad,e.InventarioMovimientoId,
           u.NombreUsuario,e.FechaProcesamiento,e.FechaCreacion,e.FechaModificacion
    FROM dbo.IntegracionEvento e
    INNER JOIN dbo.Usuario u ON u.UsuarioId=e.UsuarioId
    LEFT JOIN dbo.InventarioArticulo a ON a.InventarioArticuloId=e.InventarioArticuloId
    LEFT JOIN dbo.Sede s ON s.SedeId=e.SedeId
    WHERE e.IntegracionEventoId=@Id AND e.Eliminado=0 AND
      (@EsAdministrador=1 OR e.UsuarioId=@UsuarioId OR
       (e.InventarioArticuloId IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=a.GiroNegocioId AND ug.Eliminado=0)
        AND e.SedeId IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=e.SedeId AND us.Eliminado=0)));
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_integraciones_leer_opciones @UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT a.InventarioArticuloId AS Id,CONCAT(a.Codigo,N' · ',a.Nombre,N' (',a.UnidadMedida,N')') AS Nombre
    FROM dbo.InventarioArticulo a WHERE a.Eliminado=0 AND a.EsActivo=1 AND
      (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=a.GiroNegocioId AND ug.Eliminado=0))
    ORDER BY a.Codigo;
    SELECT s.SedeId AS Id,s.Nombre FROM dbo.Sede s WHERE s.Eliminado=0 AND s.EsActivo=1 AND
      (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=s.SedeId AND us.Eliminado=0))
    ORDER BY CASE WHEN s.Nombre=N'Sede central' THEN 0 ELSE 1 END,s.Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_integraciones_procesar @Id BIGINT,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;SET XACT_ABORT ON;
    UPDATE dbo.IntegracionEvento SET Intentos=Intentos+1,Estado=N'Recibido',Error=NULL,FechaModificacion=SYSUTCDATETIME()
    WHERE IntegracionEventoId=@Id AND Eliminado=0 AND Estado IN(N'Recibido',N'Error');
    IF @@ROWCOUNT=0 THROW 50002,N'El evento no está disponible para procesamiento.',1;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @Operacion NVARCHAR(40),@Direccion NVARCHAR(20),@Canal NVARCHAR(20),@Socio NVARCHAR(180),
                @Documento NVARCHAR(120),@ArticuloId INT,@SedeId INT,@Cantidad DECIMAL(18,3),@GiroId INT,@MovimientoId BIGINT;
        SELECT @Operacion=Operacion,@Direccion=Direccion,@Canal=Canal,@Socio=SocioNombre,@Documento=DocumentoExterno,
               @ArticuloId=InventarioArticuloId,@SedeId=SedeId,@Cantidad=Cantidad
        FROM dbo.IntegracionEvento WITH(UPDLOCK,HOLDLOCK) WHERE IntegracionEventoId=@Id;
        IF @Operacion=N'RecepcionMateriaPrima'
        BEGIN
            IF @Direccion<>N'Entrada' OR @ArticuloId IS NULL OR @SedeId IS NULL OR @Cantidad IS NULL OR @Cantidad<=0
                THROW 50002,N'La recepción requiere dirección Entrada, artículo, sede y cantidad positiva.',1;
            SELECT @GiroId=GiroNegocioId FROM dbo.InventarioArticulo WHERE InventarioArticuloId=@ArticuloId AND Eliminado=0 AND EsActivo=1;
            IF @GiroId IS NULL THROW 50002,N'El artículo recibido no está disponible.',1;
            IF NOT EXISTS(SELECT 1 FROM dbo.SedeGiroNegocio WHERE SedeId=@SedeId AND GiroNegocioId=@GiroId AND Eliminado=0)
                THROW 50002,N'La sede destino no opera el giro del artículo.',1;
            IF @EsAdministrador=0 AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroId AND Eliminado=0)
                THROW 50002,N'El usuario no tiene acceso al giro.',1;
            IF @EsAdministrador=0 AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0)
                THROW 50002,N'El usuario no tiene acceso a la sede destino.',1;
            IF NOT EXISTS(SELECT 1 FROM dbo.InventarioExistencia WHERE InventarioArticuloId=@ArticuloId AND SedeId=@SedeId)
                INSERT dbo.InventarioExistencia(InventarioArticuloId,SedeId) VALUES(@ArticuloId,@SedeId);
            UPDATE dbo.InventarioExistencia SET Cantidad=Cantidad+@Cantidad,FechaModificacion=SYSUTCDATETIME()
            WHERE InventarioArticuloId=@ArticuloId AND SedeId=@SedeId;
            INSERT dbo.InventarioMovimiento(InventarioArticuloId,Tipo,SedeDestinoId,Cantidad,Referencia,Observacion,UsuarioId)
            VALUES(@ArticuloId,N'Entrada',@SedeId,@Cantidad,COALESCE(NULLIF(@Documento,N''),CONCAT(N'Integración #',@Id)),
                   CONCAT(N'Recepción externa simulada vía ',@Canal,N' desde ',@Socio,N'.'),@UsuarioId);
            SET @MovimientoId=CONVERT(BIGINT,SCOPE_IDENTITY());
        END;
        UPDATE dbo.IntegracionEvento SET Estado=N'Procesado',Error=NULL,InventarioMovimientoId=@MovimientoId,
               FechaProcesamiento=SYSUTCDATETIME(),FechaModificacion=SYSUTCDATETIME() WHERE IntegracionEventoId=@Id;
        EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Integraciones',N'Procesar',@Id,N'Exitoso',@Operacion;
        COMMIT TRANSACTION;
        SELECT @Id;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        DECLARE @Error NVARCHAR(1000)=ERROR_MESSAGE();
        UPDATE dbo.IntegracionEvento SET Estado=N'Error',Error=@Error,FechaModificacion=SYSUTCDATETIME() WHERE IntegracionEventoId=@Id;
        EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Integraciones',N'Procesar',@Id,N'Error',@Error;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_integraciones_simular
    @Canal NVARCHAR(20),@Direccion NVARCHAR(20),@SocioTipo NVARCHAR(20),@SocioNombre NVARCHAR(180),
    @Operacion NVARCHAR(40),@ClaveIdempotencia NVARCHAR(120),@DocumentoExterno NVARCHAR(120)=NULL,
    @Contenido NVARCHAR(MAX),@InventarioArticuloId INT=NULL,@SedeId INT=NULL,@Cantidad DECIMAL(18,3)=NULL,
    @UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Existente BIGINT=(SELECT IntegracionEventoId FROM dbo.IntegracionEvento WHERE ClaveIdempotencia=@ClaveIdempotencia AND Eliminado=0);
    IF @Existente IS NOT NULL BEGIN SELECT @Existente;RETURN;END;
    INSERT dbo.IntegracionEvento(Canal,Direccion,SocioTipo,SocioNombre,Operacion,ClaveIdempotencia,DocumentoExterno,Contenido,InventarioArticuloId,SedeId,Cantidad,UsuarioId)
    VALUES(@Canal,@Direccion,@SocioTipo,LTRIM(RTRIM(@SocioNombre)),@Operacion,LTRIM(RTRIM(@ClaveIdempotencia)),NULLIF(LTRIM(RTRIM(@DocumentoExterno)),N''),@Contenido,@InventarioArticuloId,@SedeId,@Cantidad,@UsuarioId);
    DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());
    EXEC dbo.sp_integraciones_procesar @Id,@UsuarioId,@EsAdministrador;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_integraciones_reintentar @Id BIGINT,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM dbo.IntegracionEvento e LEFT JOIN dbo.InventarioArticulo a ON a.InventarioArticuloId=e.InventarioArticuloId
       WHERE e.IntegracionEventoId=@Id AND e.Eliminado=0 AND e.Estado=N'Error' AND
       (@EsAdministrador=1 OR e.UsuarioId=@UsuarioId OR (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=a.GiroNegocioId AND ug.Eliminado=0)
        AND EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=e.SedeId AND us.Eliminado=0))))
       THROW 50002,N'El evento con error no está disponible para reintento.',1;
    EXEC dbo.sp_integraciones_procesar @Id,@UsuarioId,@EsAdministrador;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_integraciones_eliminar @Id BIGINT,@UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.IntegracionEvento SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE IntegracionEventoId=@Id AND Eliminado=0;
    DECLARE @Filas INT=@@ROWCOUNT;
    IF @Filas>0 EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Integraciones',N'Eliminar',@Id,N'Exitoso',NULL;
    SELECT @Filas;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_finanzas_ingresos_leer_listado
    @UsuarioId INT,@EsAdministrador BIT,@Anio SMALLINT=NULL,@Mes TINYINT=NULL,@GiroId INT=NULL,@SedeId INT=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT i.FinanzaIngresoId,i.GiroNegocioId,g.Nombre AS Giro,i.SedeId,s.Nombre AS Sede,
           i.ClienteId,c.Nombre AS Cliente,i.Fecha,i.Categoria,i.Concepto,i.Monto,i.OrigenModulo,
           i.OrigenRegistroId,i.Referencia,u.NombreUsuario,i.FechaCreacion
    FROM dbo.FinanzaIngreso i
    INNER JOIN dbo.GiroNegocio g ON g.GiroNegocioId=i.GiroNegocioId
    INNER JOIN dbo.Sede s ON s.SedeId=i.SedeId
    INNER JOIN dbo.Usuario u ON u.UsuarioId=i.UsuarioId
    LEFT JOIN dbo.Cliente c ON c.ClienteId=i.ClienteId
    WHERE i.Eliminado=0
      AND (@Anio IS NULL OR YEAR(i.Fecha)=@Anio)
      AND (@Mes IS NULL OR MONTH(i.Fecha)=@Mes)
      AND (@GiroId IS NULL OR i.GiroNegocioId=@GiroId)
      AND (@SedeId IS NULL OR i.SedeId=@SedeId)
      AND (@EsAdministrador=1 OR
           (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=i.GiroNegocioId AND ug.Eliminado=0)
            AND EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=i.SedeId AND us.Eliminado=0)))
    ORDER BY i.Fecha DESC,i.FinanzaIngresoId DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_finanzas_ingresos_leer_por_id @Id BIGINT,@UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT i.FinanzaIngresoId,i.GiroNegocioId,g.Nombre AS Giro,i.SedeId,s.Nombre AS Sede,
           i.ClienteId,c.Nombre AS Cliente,i.Fecha,i.Categoria,i.Concepto,i.Monto,i.OrigenModulo,
           i.OrigenRegistroId,i.Referencia,u.NombreUsuario,i.FechaCreacion
    FROM dbo.FinanzaIngreso i
    INNER JOIN dbo.GiroNegocio g ON g.GiroNegocioId=i.GiroNegocioId
    INNER JOIN dbo.Sede s ON s.SedeId=i.SedeId
    INNER JOIN dbo.Usuario u ON u.UsuarioId=i.UsuarioId
    LEFT JOIN dbo.Cliente c ON c.ClienteId=i.ClienteId
    WHERE i.FinanzaIngresoId=@Id AND i.Eliminado=0
      AND (@EsAdministrador=1 OR
           (EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=i.GiroNegocioId AND ug.Eliminado=0)
            AND EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=i.SedeId AND us.Eliminado=0)));
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_finanzas_ingresos_leer_opciones @UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT g.GiroNegocioId AS Id,g.Nombre FROM dbo.GiroNegocio g
    WHERE g.Eliminado=0 AND g.EsActivo=1 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=g.GiroNegocioId AND ug.Eliminado=0)) ORDER BY g.Nombre;
    SELECT s.SedeId AS Id,s.Nombre FROM dbo.Sede s
    WHERE s.Eliminado=0 AND s.EsActivo=1 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=s.SedeId AND us.Eliminado=0)) ORDER BY s.Nombre;
    SELECT DISTINCT c.ClienteId AS Id,c.Nombre FROM dbo.Cliente c
    INNER JOIN dbo.ClienteGiroNegocio cg ON cg.ClienteId=c.ClienteId AND cg.Eliminado=0
    WHERE c.Eliminado=0 AND c.EsActivo=1 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=cg.GiroNegocioId AND ug.Eliminado=0)) ORDER BY c.Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_finanzas_ingresos_crear
    @GiroId INT,@SedeId INT,@ClienteId INT=NULL,@Fecha DATE,@Categoria NVARCHAR(30),@Concepto NVARCHAR(250),
    @Monto DECIMAL(18,2),@OrigenModulo NVARCHAR(30),@OrigenRegistroId BIGINT=NULL,@Referencia NVARCHAR(120)=NULL,
    @UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;SET XACT_ABORT ON;
    IF @Monto<=0 OR NULLIF(LTRIM(RTRIM(@Concepto)),N'') IS NULL OR @Categoria NOT IN(N'VentaProducto',N'Servicio',N'Alquiler',N'Transporte',N'Construccion',N'Otro')
        THROW 50002,N'Los datos del ingreso no son válidos.',1;
    IF @OrigenModulo NOT IN(N'Manual',N'Pedido',N'Maquinaria',N'Transporte',N'Construccion') OR
       (@OrigenModulo=N'Manual' AND @OrigenRegistroId IS NOT NULL) OR (@OrigenModulo<>N'Manual' AND @OrigenRegistroId IS NULL)
        THROW 50002,N'La referencia de origen no corresponde.',1;
    IF NOT EXISTS(SELECT 1 FROM dbo.SedeGiroNegocio sg INNER JOIN dbo.Sede s ON s.SedeId=sg.SedeId INNER JOIN dbo.GiroNegocio g ON g.GiroNegocioId=sg.GiroNegocioId WHERE sg.SedeId=@SedeId AND sg.GiroNegocioId=@GiroId AND sg.Eliminado=0 AND s.Eliminado=0 AND s.EsActivo=1 AND g.Eliminado=0 AND g.EsActivo=1)
        THROW 50002,N'La sede no opera el giro seleccionado.',1;
    IF @EsAdministrador=0 AND (NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroId AND Eliminado=0) OR NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0))
        THROW 50002,N'El usuario no tiene acceso al giro y sede seleccionados.',1;

    DECLARE @ClienteOrigen INT,@GiroNombre NVARCHAR(150)=(SELECT Nombre FROM dbo.GiroNegocio WHERE GiroNegocioId=@GiroId),@TipoViaje NVARCHAR(30),@OrigenExiste BIT=0;
    IF @OrigenModulo=N'Pedido'
    BEGIN
        SELECT @ClienteOrigen=ClienteId FROM dbo.Pedido WHERE PedidoId=@OrigenRegistroId AND GiroNegocioId=@GiroId AND Eliminado=0;
        IF @ClienteOrigen IS NULL THROW 50002,N'El pedido no corresponde al giro seleccionado.',1;
    END;
    IF @OrigenModulo=N'Maquinaria'
    BEGIN
        SELECT @ClienteOrigen=c.ClienteId FROM dbo.MaquinariaContrato c INNER JOIN dbo.MaquinariaEquipo e ON e.MaquinariaEquipoId=c.MaquinariaEquipoId WHERE c.MaquinariaContratoId=@OrigenRegistroId AND c.Eliminado=0 AND e.Eliminado=0 AND e.SedeId=@SedeId;
        IF @ClienteOrigen IS NULL OR @GiroNombre<>N'Venta y alquiler de maquinaria' THROW 50002,N'El contrato de maquinaria no corresponde al giro y sede seleccionados.',1;
    END;
    IF @OrigenModulo=N'Transporte'
    BEGIN
        SELECT @ClienteOrigen=ClienteId,@TipoViaje=Tipo FROM dbo.TransporteViaje WHERE TransporteViajeId=@OrigenRegistroId AND SedeId=@SedeId AND Eliminado=0;
        IF @TipoViaje IS NULL OR (@TipoViaje=N'MateriaPrima' AND @GiroNombre<>N'Transporte de materia prima') OR (@TipoViaje IN(N'Nacional',N'Internacional') AND @GiroNombre<>N'Transporte nacional e internacional')
            THROW 50002,N'El viaje no corresponde al giro y sede seleccionados.',1;
    END;
    IF @OrigenModulo=N'Construccion'
    BEGIN
        SELECT @ClienteOrigen=ClienteId,@OrigenExiste=1 FROM dbo.ConstruccionProyecto WHERE ConstruccionProyectoId=@OrigenRegistroId AND SedeId=@SedeId AND Eliminado=0;
        IF @OrigenExiste=0 OR @GiroNombre<>N'Servicios de construcción' THROW 50002,N'El proyecto no corresponde al giro y sede seleccionados.',1;
    END;
    IF @OrigenModulo<>N'Manual' AND @ClienteId IS NOT NULL AND (@ClienteOrigen IS NULL OR @ClienteId<>@ClienteOrigen) THROW 50002,N'El cliente no corresponde al registro de origen.',1;
    SET @ClienteId=COALESCE(@ClienteId,@ClienteOrigen);
    IF @ClienteId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.Cliente c INNER JOIN dbo.ClienteGiroNegocio cg ON cg.ClienteId=c.ClienteId WHERE c.ClienteId=@ClienteId AND c.Eliminado=0 AND c.EsActivo=1 AND cg.GiroNegocioId=@GiroId AND cg.Eliminado=0)
        THROW 50002,N'El cliente no está asociado al giro seleccionado.',1;

    INSERT dbo.FinanzaIngreso(GiroNegocioId,SedeId,ClienteId,Fecha,Categoria,Concepto,Monto,OrigenModulo,OrigenRegistroId,Referencia,UsuarioId)
    VALUES(@GiroId,@SedeId,@ClienteId,@Fecha,@Categoria,LTRIM(RTRIM(@Concepto)),@Monto,@OrigenModulo,@OrigenRegistroId,NULLIF(LTRIM(RTRIM(@Referencia)),N''),@UsuarioId);
    DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());
    EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Finanzas',N'RegistrarIngreso',@Id,N'Exitoso',@OrigenModulo;
    SELECT @Id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_finanzas_ingresos_eliminar @Id BIGINT,@UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.FinanzaIngreso SET Eliminado=1,FechaModificacion=SYSUTCDATETIME() WHERE FinanzaIngresoId=@Id AND Eliminado=0;
    DECLARE @Filas INT=@@ROWCOUNT;
    IF @Filas>0 EXEC dbo.sp_auditoria_crear_evento @UsuarioId,N'Finanzas',N'EliminarIngreso',@Id,N'Exitoso',NULL;
    SELECT @Filas;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_reportes_leer_opciones @UsuarioId INT,@EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT g.GiroNegocioId AS Id,g.Nombre FROM dbo.GiroNegocio g
    WHERE g.Eliminado=0 AND g.EsActivo=1 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=g.GiroNegocioId AND ug.Eliminado=0)) ORDER BY g.Nombre;
    SELECT s.SedeId AS Id,s.Nombre FROM dbo.Sede s
    WHERE s.Eliminado=0 AND s.EsActivo=1 AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=s.SedeId AND us.Eliminado=0)) ORDER BY s.Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_reportes_leer_interno
    @UsuarioId INT,@EsAdministrador BIT,@Desde DATE=NULL,@Hasta DATE=NULL,@GiroId INT=NULL,@SedeId INT=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Desde=COALESCE(@Desde,DATEFROMPARTS(YEAR(GETDATE()),1,1));
    SET @Hasta=COALESCE(@Hasta,CONVERT(DATE,GETDATE()));
    IF @Hasta<@Desde OR DATEDIFF(MONTH,@Desde,@Hasta)>60 THROW 50002,N'El período del reporte no es válido o excede cinco años.',1;
    IF @EsAdministrador=0 AND @GiroId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId AND GiroNegocioId=@GiroId AND Eliminado=0) THROW 50002,N'El usuario no tiene acceso al giro solicitado.',1;
    IF @EsAdministrador=0 AND @SedeId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId AND SedeId=@SedeId AND Eliminado=0) THROW 50002,N'El usuario no tiene acceso a la sede solicitada.',1;

    DECLARE @Giros TABLE(GiroNegocioId INT PRIMARY KEY,Giro NVARCHAR(150),Operaciones BIGINT DEFAULT(0),Completadas BIGINT DEFAULT(0),Indicador NVARCHAR(120),ValorIndicador DECIMAL(18,3) DEFAULT(0),UnidadIndicador NVARCHAR(40),Presupuesto DECIMAL(18,2) DEFAULT(0),Gastos DECIMAL(18,2) DEFAULT(0),Ingresos DECIMAL(18,2) DEFAULT(0));
    INSERT @Giros(GiroNegocioId,Giro,Indicador,UnidadIndicador)
    SELECT g.GiroNegocioId,g.Nombre,
           CASE g.Nombre WHEN N'Extracción minera' THEN N'Material aprovechable' WHEN N'Procesamiento de materia prima' THEN N'Producción terminada' WHEN N'Venta y alquiler de maquinaria' THEN N'Monto contratado' WHEN N'Transporte de materia prima' THEN N'Peso transportado' WHEN N'Transporte nacional e internacional' THEN N'Peso transportado' WHEN N'Servicios de construcción' THEN N'Avance físico promedio' ELSE N'Operación registrada' END,
           CASE g.Nombre WHEN N'Venta y alquiler de maquinaria' THEN N'Q' WHEN N'Servicios de construcción' THEN N'%' WHEN N'Transporte de materia prima' THEN N't' WHEN N'Transporte nacional e internacional' THEN N't' ELSE N'unidades' END
    FROM dbo.GiroNegocio g WHERE g.Eliminado=0 AND g.EsActivo=1 AND (@GiroId IS NULL OR g.GiroNegocioId=@GiroId)
      AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioGiroNegocio ug WHERE ug.UsuarioId=@UsuarioId AND ug.GiroNegocioId=g.GiroNegocioId AND ug.Eliminado=0));

    DECLARE @Extraccion INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Extracción minera' AND Eliminado=0),
            @Produccion INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Procesamiento de materia prima' AND Eliminado=0),
            @Maquinaria INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Venta y alquiler de maquinaria' AND Eliminado=0),
            @TransporteMateria INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Transporte de materia prima' AND Eliminado=0),
            @TransporteServicio INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Transporte nacional e internacional' AND Eliminado=0),
            @Construccion INT=(SELECT GiroNegocioId FROM dbo.GiroNegocio WHERE Nombre=N'Servicios de construcción' AND Eliminado=0);

    UPDATE g SET Operaciones=(SELECT COUNT_BIG(*) FROM dbo.ExtraccionJornada x WHERE x.Eliminado=0 AND x.FechaOperacion BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR x.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=x.SedeId AND us.Eliminado=0))),Completadas=(SELECT COUNT_BIG(*) FROM dbo.ExtraccionJornada x WHERE x.Eliminado=0 AND x.Estado=N'Entregada' AND x.FechaOperacion BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR x.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=x.SedeId AND us.Eliminado=0))),ValorIndicador=COALESCE((SELECT SUM(x.CantidadAprovechable) FROM dbo.ExtraccionJornada x WHERE x.Eliminado=0 AND x.Estado<>N'Cancelada' AND x.FechaOperacion BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR x.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=x.SedeId AND us.Eliminado=0))),0) FROM @Giros g WHERE g.GiroNegocioId=@Extraccion;
    UPDATE g SET Operaciones=(SELECT COUNT_BIG(*) FROM dbo.ProduccionOrden x WHERE x.Eliminado=0 AND x.FechaPlanificada BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR x.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=x.SedeId AND us.Eliminado=0))),Completadas=(SELECT COUNT_BIG(*) FROM dbo.ProduccionOrden x WHERE x.Eliminado=0 AND x.Estado=N'Completada' AND x.FechaPlanificada BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR x.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=x.SedeId AND us.Eliminado=0))),ValorIndicador=COALESCE((SELECT SUM(x.CantidadSalidaReal) FROM dbo.ProduccionOrden x WHERE x.Eliminado=0 AND x.Estado=N'Completada' AND x.FechaPlanificada BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR x.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=x.SedeId AND us.Eliminado=0))),0) FROM @Giros g WHERE g.GiroNegocioId=@Produccion;
    UPDATE g SET Operaciones=(SELECT COUNT_BIG(*) FROM dbo.MaquinariaContrato x INNER JOIN dbo.MaquinariaEquipo e ON e.MaquinariaEquipoId=x.MaquinariaEquipoId WHERE x.Eliminado=0 AND e.Eliminado=0 AND x.FechaInicio BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR e.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=e.SedeId AND us.Eliminado=0))),Completadas=(SELECT COUNT_BIG(*) FROM dbo.MaquinariaContrato x INNER JOIN dbo.MaquinariaEquipo e ON e.MaquinariaEquipoId=x.MaquinariaEquipoId WHERE x.Eliminado=0 AND e.Eliminado=0 AND x.Estado=N'Finalizado' AND x.FechaInicio BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR e.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=e.SedeId AND us.Eliminado=0))),ValorIndicador=COALESCE((SELECT SUM(x.MontoTotal) FROM dbo.MaquinariaContrato x INNER JOIN dbo.MaquinariaEquipo e ON e.MaquinariaEquipoId=x.MaquinariaEquipoId WHERE x.Eliminado=0 AND e.Eliminado=0 AND x.Estado<>N'Cancelado' AND x.FechaInicio BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR e.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=e.SedeId AND us.Eliminado=0))),0) FROM @Giros g WHERE g.GiroNegocioId=@Maquinaria;
    UPDATE g SET Operaciones=(SELECT COUNT_BIG(*) FROM dbo.TransporteViaje x WHERE x.Eliminado=0 AND x.Tipo=N'MateriaPrima' AND CONVERT(DATE,x.FechaSalidaPlanificada) BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR x.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=x.SedeId AND us.Eliminado=0))),Completadas=(SELECT COUNT_BIG(*) FROM dbo.TransporteViaje x WHERE x.Eliminado=0 AND x.Tipo=N'MateriaPrima' AND x.Estado=N'Entregado' AND CONVERT(DATE,x.FechaSalidaPlanificada) BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR x.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=x.SedeId AND us.Eliminado=0))),ValorIndicador=COALESCE((SELECT SUM(x.PesoCarga) FROM dbo.TransporteViaje x WHERE x.Eliminado=0 AND x.Tipo=N'MateriaPrima' AND x.Estado<>N'Cancelado' AND CONVERT(DATE,x.FechaSalidaPlanificada) BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR x.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=x.SedeId AND us.Eliminado=0))),0) FROM @Giros g WHERE g.GiroNegocioId=@TransporteMateria;
    UPDATE g SET Operaciones=(SELECT COUNT_BIG(*) FROM dbo.TransporteViaje x WHERE x.Eliminado=0 AND x.Tipo IN(N'Nacional',N'Internacional') AND CONVERT(DATE,x.FechaSalidaPlanificada) BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR x.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=x.SedeId AND us.Eliminado=0))),Completadas=(SELECT COUNT_BIG(*) FROM dbo.TransporteViaje x WHERE x.Eliminado=0 AND x.Tipo IN(N'Nacional',N'Internacional') AND x.Estado=N'Entregado' AND CONVERT(DATE,x.FechaSalidaPlanificada) BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR x.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=x.SedeId AND us.Eliminado=0))),ValorIndicador=COALESCE((SELECT SUM(x.PesoCarga) FROM dbo.TransporteViaje x WHERE x.Eliminado=0 AND x.Tipo IN(N'Nacional',N'Internacional') AND x.Estado<>N'Cancelado' AND CONVERT(DATE,x.FechaSalidaPlanificada) BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR x.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=x.SedeId AND us.Eliminado=0))),0) FROM @Giros g WHERE g.GiroNegocioId=@TransporteServicio;
    UPDATE g SET Operaciones=(SELECT COUNT_BIG(*) FROM dbo.ConstruccionProyecto x WHERE x.Eliminado=0 AND x.FechaInicioPlanificada BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR x.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=x.SedeId AND us.Eliminado=0))),Completadas=(SELECT COUNT_BIG(*) FROM dbo.ConstruccionProyecto x WHERE x.Eliminado=0 AND x.Estado=N'Completado' AND x.FechaInicioPlanificada BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR x.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=x.SedeId AND us.Eliminado=0))),ValorIndicador=COALESCE((SELECT AVG(CONVERT(DECIMAL(18,3),a.PorcentajeAvance)) FROM dbo.ConstruccionProyecto x INNER JOIN dbo.ConstruccionActividad a ON a.ConstruccionProyectoId=x.ConstruccionProyectoId WHERE x.Eliminado=0 AND x.FechaInicioPlanificada BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR x.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=x.SedeId AND us.Eliminado=0))),0) FROM @Giros g WHERE g.GiroNegocioId=@Construccion;

    UPDATE g SET Presupuesto=COALESCE((SELECT SUM(p.Monto) FROM dbo.FinanzaPresupuesto p WHERE p.Eliminado=0 AND p.Estado<>N'Cancelado' AND p.GiroNegocioId=g.GiroNegocioId AND DATEFROMPARTS(p.Anio,p.Mes,1) BETWEEN DATEFROMPARTS(YEAR(@Desde),MONTH(@Desde),1) AND DATEFROMPARTS(YEAR(@Hasta),MONTH(@Hasta),1) AND (@SedeId IS NULL OR p.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=p.SedeId AND us.Eliminado=0))),0),Gastos=COALESCE((SELECT SUM(x.Monto) FROM dbo.FinanzaGasto x INNER JOIN dbo.FinanzaPresupuesto p ON p.FinanzaPresupuestoId=x.FinanzaPresupuestoId WHERE p.Eliminado=0 AND p.GiroNegocioId=g.GiroNegocioId AND x.Fecha BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR p.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=p.SedeId AND us.Eliminado=0))),0),Ingresos=COALESCE((SELECT SUM(i.Monto) FROM dbo.FinanzaIngreso i WHERE i.Eliminado=0 AND i.GiroNegocioId=g.GiroNegocioId AND i.Fecha BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR i.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=i.SedeId AND us.Eliminado=0))),0) FROM @Giros g;

    SELECT @Desde AS Desde,@Hasta AS Hasta,CONVERT(INT,(SELECT COUNT(*) FROM @Giros)) AS Giros,
           CONVERT(INT,(SELECT COUNT(DISTINCT sg.SedeId) FROM dbo.SedeGiroNegocio sg INNER JOIN @Giros g ON g.GiroNegocioId=sg.GiroNegocioId WHERE sg.Eliminado=0 AND (@SedeId IS NULL OR sg.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=sg.SedeId AND us.Eliminado=0)))) AS Sedes,
           COALESCE(SUM(Operaciones),0) AS Operaciones,COALESCE(SUM(Completadas),0) AS Completadas,COALESCE(SUM(Presupuesto),0) AS Presupuesto,COALESCE(SUM(Gastos),0) AS Gastos,COALESCE(SUM(Ingresos),0) AS Ingresos,COALESCE(SUM(Ingresos-Gastos),0) AS Resultado FROM @Giros;
    SELECT GiroNegocioId,Giro,Operaciones,Completadas,Indicador,ValorIndicador,UnidadIndicador,Presupuesto,Gastos,Ingresos,Ingresos-Gastos AS Resultado FROM @Giros ORDER BY Giro;

    ;WITH Meses AS(SELECT DATEFROMPARTS(YEAR(@Desde),MONTH(@Desde),1) Inicio UNION ALL SELECT DATEADD(MONTH,1,Inicio) FROM Meses WHERE DATEADD(MONTH,1,Inicio)<=DATEFROMPARTS(YEAR(@Hasta),MONTH(@Hasta),1))
    SELECT CONVERT(SMALLINT,YEAR(m.Inicio)) AS Anio,CONVERT(TINYINT,MONTH(m.Inicio)) AS Mes,CONVERT(CHAR(7),m.Inicio,120) AS Periodo,COALESCE(p.Monto,0) AS Presupuesto,COALESCE(x.Monto,0) AS Gastos,COALESCE(i.Monto,0) AS Ingresos,COALESCE(i.Monto,0)-COALESCE(x.Monto,0) AS Resultado
    FROM Meses m
    OUTER APPLY(SELECT SUM(p.Monto) Monto FROM dbo.FinanzaPresupuesto p INNER JOIN @Giros g ON g.GiroNegocioId=p.GiroNegocioId WHERE p.Eliminado=0 AND p.Estado<>N'Cancelado' AND p.Anio=YEAR(m.Inicio) AND p.Mes=MONTH(m.Inicio) AND (@SedeId IS NULL OR p.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=p.SedeId AND us.Eliminado=0))) p
    OUTER APPLY(SELECT SUM(x.Monto) Monto FROM dbo.FinanzaGasto x INNER JOIN dbo.FinanzaPresupuesto p ON p.FinanzaPresupuestoId=x.FinanzaPresupuestoId INNER JOIN @Giros g ON g.GiroNegocioId=p.GiroNegocioId WHERE p.Eliminado=0 AND YEAR(x.Fecha)=YEAR(m.Inicio) AND MONTH(x.Fecha)=MONTH(m.Inicio) AND x.Fecha BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR p.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=p.SedeId AND us.Eliminado=0))) x
    OUTER APPLY(SELECT SUM(i.Monto) Monto FROM dbo.FinanzaIngreso i INNER JOIN @Giros g ON g.GiroNegocioId=i.GiroNegocioId WHERE i.Eliminado=0 AND YEAR(i.Fecha)=YEAR(m.Inicio) AND MONTH(i.Fecha)=MONTH(m.Inicio) AND i.Fecha BETWEEN @Desde AND @Hasta AND (@SedeId IS NULL OR i.SedeId=@SedeId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.UsuarioSede us WHERE us.UsuarioId=@UsuarioId AND us.SedeId=i.SedeId AND us.Eliminado=0))) i
    ORDER BY m.Inicio OPTION(MAXRECURSION 60);
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_reportes_leer_cliente @UsuarioId INT,@EsAdministrador BIT,@ClienteId INT=NULL,@Desde DATE=NULL,@Hasta DATE=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Desde=COALESCE(@Desde,DATEFROMPARTS(YEAR(GETDATE()),1,1));SET @Hasta=COALESCE(@Hasta,CONVERT(DATE,GETDATE()));
    IF @Hasta<@Desde OR DATEDIFF(MONTH,@Desde,@Hasta)>60 THROW 50002,N'El período del reporte no es válido o excede cinco años.',1;
    DECLARE @Clientes TABLE(ClienteId INT PRIMARY KEY,Cliente NVARCHAR(180));
    INSERT @Clientes SELECT c.ClienteId,c.Nombre FROM dbo.Cliente c WHERE c.Eliminado=0 AND c.EsActivo=1 AND (@ClienteId IS NULL OR c.ClienteId=@ClienteId) AND (@EsAdministrador=1 OR EXISTS(SELECT 1 FROM dbo.ClienteUsuario cu WHERE cu.UsuarioId=@UsuarioId AND cu.ClienteId=c.ClienteId AND cu.Eliminado=0));
    DECLARE @Empresas TABLE(ClienteId INT PRIMARY KEY,Cliente NVARCHAR(180),Pedidos BIGINT DEFAULT(0),Completados BIGINT DEFAULT(0),MontoCotizado DECIMAL(18,2) DEFAULT(0),Viajes BIGINT DEFAULT(0),Entregados BIGINT DEFAULT(0),PesoTransportado DECIMAL(18,3) DEFAULT(0),Contratos BIGINT DEFAULT(0),MontoContratos DECIMAL(18,2) DEFAULT(0),Proyectos BIGINT DEFAULT(0),PresupuestoObras DECIMAL(18,2) DEFAULT(0),AvancePromedio DECIMAL(5,2) DEFAULT(0),IngresosRegistrados DECIMAL(18,2) DEFAULT(0));
    INSERT @Empresas(ClienteId,Cliente) SELECT ClienteId,Cliente FROM @Clientes;
    UPDATE e SET Pedidos=(SELECT COUNT_BIG(*) FROM dbo.Pedido p WHERE p.ClienteId=e.ClienteId AND p.Eliminado=0 AND CONVERT(DATE,p.FechaCreacion) BETWEEN @Desde AND @Hasta),Completados=(SELECT COUNT_BIG(*) FROM dbo.Pedido p WHERE p.ClienteId=e.ClienteId AND p.Eliminado=0 AND p.Estado=N'Completado' AND CONVERT(DATE,p.FechaCreacion) BETWEEN @Desde AND @Hasta),MontoCotizado=COALESCE((SELECT SUM(p.MontoCotizado) FROM dbo.Pedido p WHERE p.ClienteId=e.ClienteId AND p.Eliminado=0 AND p.Estado<>N'Cancelado' AND CONVERT(DATE,p.FechaCreacion) BETWEEN @Desde AND @Hasta),0),Viajes=(SELECT COUNT_BIG(*) FROM dbo.TransporteViaje v WHERE v.ClienteId=e.ClienteId AND v.Eliminado=0 AND CONVERT(DATE,v.FechaSalidaPlanificada) BETWEEN @Desde AND @Hasta),Entregados=(SELECT COUNT_BIG(*) FROM dbo.TransporteViaje v WHERE v.ClienteId=e.ClienteId AND v.Eliminado=0 AND v.Estado=N'Entregado' AND CONVERT(DATE,v.FechaSalidaPlanificada) BETWEEN @Desde AND @Hasta),PesoTransportado=COALESCE((SELECT SUM(v.PesoCarga) FROM dbo.TransporteViaje v WHERE v.ClienteId=e.ClienteId AND v.Eliminado=0 AND v.Estado<>N'Cancelado' AND CONVERT(DATE,v.FechaSalidaPlanificada) BETWEEN @Desde AND @Hasta),0),Contratos=(SELECT COUNT_BIG(*) FROM dbo.MaquinariaContrato m WHERE m.ClienteId=e.ClienteId AND m.Eliminado=0 AND m.FechaInicio BETWEEN @Desde AND @Hasta),MontoContratos=COALESCE((SELECT SUM(m.MontoTotal) FROM dbo.MaquinariaContrato m WHERE m.ClienteId=e.ClienteId AND m.Eliminado=0 AND m.Estado<>N'Cancelado' AND m.FechaInicio BETWEEN @Desde AND @Hasta),0),Proyectos=(SELECT COUNT_BIG(*) FROM dbo.ConstruccionProyecto p WHERE p.ClienteId=e.ClienteId AND p.Eliminado=0 AND p.FechaInicioPlanificada BETWEEN @Desde AND @Hasta),PresupuestoObras=COALESCE((SELECT SUM(p.Presupuesto) FROM dbo.ConstruccionProyecto p WHERE p.ClienteId=e.ClienteId AND p.Eliminado=0 AND p.Estado<>N'Cancelado' AND p.FechaInicioPlanificada BETWEEN @Desde AND @Hasta),0),AvancePromedio=COALESCE((SELECT AVG(CONVERT(DECIMAL(5,2),a.PorcentajeAvance)) FROM dbo.ConstruccionProyecto p INNER JOIN dbo.ConstruccionActividad a ON a.ConstruccionProyectoId=p.ConstruccionProyectoId WHERE p.ClienteId=e.ClienteId AND p.Eliminado=0 AND p.FechaInicioPlanificada BETWEEN @Desde AND @Hasta),0),IngresosRegistrados=COALESCE((SELECT SUM(i.Monto) FROM dbo.FinanzaIngreso i WHERE i.ClienteId=e.ClienteId AND i.Eliminado=0 AND i.Fecha BETWEEN @Desde AND @Hasta),0) FROM @Empresas e;
    SELECT @Desde Desde,@Hasta Hasta,CONVERT(INT,(SELECT COUNT(*) FROM @Empresas)) Empresas,COALESCE(SUM(Pedidos),0) Pedidos,COALESCE(SUM(Completados),0) Completados,COALESCE(SUM(MontoCotizado),0) MontoCotizado,COALESCE(SUM(Viajes),0) Viajes,COALESCE(SUM(Entregados),0) Entregados,COALESCE(SUM(PesoTransportado),0) PesoTransportado,COALESCE(SUM(Contratos),0) Contratos,COALESCE(SUM(MontoContratos),0) MontoContratos,COALESCE(SUM(Proyectos),0) Proyectos,COALESCE(SUM(PresupuestoObras),0) PresupuestoObras,CONVERT(DECIMAL(5,2),COALESCE(AVG(NULLIF(AvancePromedio,0)),0)) AvancePromedio,COALESCE(SUM(IngresosRegistrados),0) IngresosRegistrados FROM @Empresas;
    SELECT ClienteId,Cliente,Pedidos,Completados,MontoCotizado,Viajes,Entregados,PesoTransportado,Contratos,MontoContratos,Proyectos,PresupuestoObras,AvancePromedio,IngresosRegistrados FROM @Empresas ORDER BY Cliente;
    ;WITH Meses AS(SELECT DATEFROMPARTS(YEAR(@Desde),MONTH(@Desde),1) Inicio UNION ALL SELECT DATEADD(MONTH,1,Inicio) FROM Meses WHERE DATEADD(MONTH,1,Inicio)<=DATEFROMPARTS(YEAR(@Hasta),MONTH(@Hasta),1))
    SELECT CONVERT(SMALLINT,YEAR(m.Inicio)) Anio,CONVERT(TINYINT,MONTH(m.Inicio)) Mes,CONVERT(CHAR(7),m.Inicio,120) Periodo,
           (SELECT COUNT_BIG(*) FROM dbo.Pedido p INNER JOIN @Clientes c ON c.ClienteId=p.ClienteId WHERE p.Eliminado=0 AND YEAR(p.FechaCreacion)=YEAR(m.Inicio) AND MONTH(p.FechaCreacion)=MONTH(m.Inicio) AND CONVERT(DATE,p.FechaCreacion) BETWEEN @Desde AND @Hasta) Pedidos,
           ((SELECT COUNT_BIG(*) FROM dbo.TransporteViaje v INNER JOIN @Clientes c ON c.ClienteId=v.ClienteId WHERE v.Eliminado=0 AND YEAR(v.FechaSalidaPlanificada)=YEAR(m.Inicio) AND MONTH(v.FechaSalidaPlanificada)=MONTH(m.Inicio) AND CONVERT(DATE,v.FechaSalidaPlanificada) BETWEEN @Desde AND @Hasta)+(SELECT COUNT_BIG(*) FROM dbo.MaquinariaContrato x INNER JOIN @Clientes c ON c.ClienteId=x.ClienteId WHERE x.Eliminado=0 AND YEAR(x.FechaInicio)=YEAR(m.Inicio) AND MONTH(x.FechaInicio)=MONTH(m.Inicio) AND x.FechaInicio BETWEEN @Desde AND @Hasta)+(SELECT COUNT_BIG(*) FROM dbo.ConstruccionProyecto p INNER JOIN @Clientes c ON c.ClienteId=p.ClienteId WHERE p.Eliminado=0 AND YEAR(p.FechaInicioPlanificada)=YEAR(m.Inicio) AND MONTH(p.FechaInicioPlanificada)=MONTH(m.Inicio) AND p.FechaInicioPlanificada BETWEEN @Desde AND @Hasta)) Operaciones,
           COALESCE((SELECT SUM(i.Monto) FROM dbo.FinanzaIngreso i INNER JOIN @Clientes c ON c.ClienteId=i.ClienteId WHERE i.Eliminado=0 AND YEAR(i.Fecha)=YEAR(m.Inicio) AND MONTH(i.Fecha)=MONTH(m.Inicio) AND i.Fecha BETWEEN @Desde AND @Hasta),0) IngresosRegistrados
    FROM Meses m ORDER BY m.Inicio OPTION(MAXRECURSION 60);
END;
GO

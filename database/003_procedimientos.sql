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

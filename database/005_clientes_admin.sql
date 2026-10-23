USE TransPortDB;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* 1 */
CREATE OR ALTER PROCEDURE dbo.sp_cliente_crear_registro
    @Nombre NVARCHAR(200), @Nit NVARCHAR(50)=NULL, @CorreoContacto NVARCHAR(150)=NULL,
    @EsActivo BIT=1, @UsuarioResponsableId INT=NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF @Nombre IS NULL OR LTRIM(RTRIM(@Nombre))=''
        THROW 50001, 'El nombre del cliente es obligatorio.', 1;
    IF @Nit IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.Cliente WHERE Nit=@Nit AND Eliminado=0)
        THROW 50002, 'Ya existe un cliente activo con ese NIT.', 1;
    BEGIN TRANSACTION;
    INSERT INTO dbo.Cliente(Nombre,Nit,CorreoContacto,EsActivo,Eliminado)
    VALUES(@Nombre,@Nit,@CorreoContacto,@EsActivo,0);
    DECLARE @Id INT=CAST(SCOPE_IDENTITY() AS INT);
    EXEC dbo.sp_auditoria_crear_evento @UsuarioId=@UsuarioResponsableId,@Modulo='Clientes',
         @TipoOperacion='Crear',@IdentificadorRegistro=CAST(@Id AS NVARCHAR(100)),
         @Resultado='Exitoso',@Detalle='Cliente creado';
    COMMIT TRANSACTION;
    SELECT @Id AS ClienteId;
END;
GO

/* 2 */
CREATE OR ALTER PROCEDURE dbo.sp_cliente_actualizar_datos
    @ClienteId INT, @Nombre NVARCHAR(200), @Nit NVARCHAR(50)=NULL,
    @CorreoContacto NVARCHAR(150)=NULL, @EsActivo BIT, @UsuarioResponsableId INT=NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE ClienteId=@ClienteId AND Eliminado=0)
        THROW 50001, 'El cliente no existe o fue eliminado.', 1;
    IF @Nombre IS NULL OR LTRIM(RTRIM(@Nombre))=''
        THROW 50001, 'El nombre del cliente es obligatorio.', 1;
    IF @Nit IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.Cliente
        WHERE Nit=@Nit AND Eliminado=0 AND ClienteId<>@ClienteId)
        THROW 50002, 'Otro cliente activo ya usa ese NIT.', 1;
    BEGIN TRANSACTION;
    UPDATE dbo.Cliente SET Nombre=@Nombre,Nit=@Nit,CorreoContacto=@CorreoContacto,
           EsActivo=@EsActivo,FechaModificacion=SYSUTCDATETIME()
     WHERE ClienteId=@ClienteId AND Eliminado=0;
    DECLARE @F INT=@@ROWCOUNT;
    EXEC dbo.sp_auditoria_crear_evento @UsuarioId=@UsuarioResponsableId,@Modulo='Clientes',
         @TipoOperacion='Actualizar',@IdentificadorRegistro=CAST(@ClienteId AS NVARCHAR(100)),
         @Resultado='Exitoso',@Detalle='Cliente actualizado';
    COMMIT TRANSACTION;
    SELECT @F AS Filas;
END;
GO

/* 3 */
CREATE OR ALTER PROCEDURE dbo.sp_cliente_eliminar_logico
    @ClienteId INT, @UsuarioResponsableId INT=NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE ClienteId=@ClienteId AND Eliminado=0)
        THROW 50001, 'El cliente no existe o ya fue eliminado.', 1;
    BEGIN TRANSACTION;
    UPDATE dbo.Cliente SET Eliminado=1,EsActivo=0,FechaModificacion=SYSUTCDATETIME() WHERE ClienteId=@ClienteId;
    UPDATE dbo.ClienteUsuario SET Eliminado=1,FechaModificacion=SYSUTCDATETIME()
     WHERE ClienteId=@ClienteId AND Eliminado=0;
    UPDATE dbo.ClienteGiroNegocio SET Eliminado=1,FechaModificacion=SYSUTCDATETIME()
     WHERE ClienteId=@ClienteId AND Eliminado=0;
    EXEC dbo.sp_auditoria_crear_evento @UsuarioId=@UsuarioResponsableId,@Modulo='Clientes',
         @TipoOperacion='EliminarLogico',@IdentificadorRegistro=CAST(@ClienteId AS NVARCHAR(100)),
         @Resultado='Exitoso',@Detalle='Cliente eliminado lógicamente';
    COMMIT TRANSACTION;
    SELECT 1 AS Filas;
END;
GO

/* 4 */
CREATE OR ALTER PROCEDURE dbo.sp_cliente_leer_por_id @ClienteId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ClienteId,Nombre,Nit,CorreoContacto,EsActivo,FechaModificacion
      FROM dbo.Cliente WHERE ClienteId=@ClienteId AND Eliminado=0;
END;
GO

/* 5 */
CREATE OR ALTER PROCEDURE dbo.sp_cliente_leer_listado
    @Busqueda NVARCHAR(200)=NULL, @EsActivo BIT=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ClienteId,Nombre,Nit,CorreoContacto,EsActivo,FechaModificacion
      FROM dbo.Cliente
     WHERE Eliminado=0
       AND (@EsActivo IS NULL OR EsActivo=@EsActivo)
       AND (@Busqueda IS NULL OR @Busqueda=''
            OR Nombre LIKE '%'+@Busqueda+'%'
            OR Nit LIKE '%'+@Busqueda+'%'
            OR CorreoContacto LIKE '%'+@Busqueda+'%')
     ORDER BY Nombre;
END;
GO

/* 6 */
CREATE OR ALTER PROCEDURE dbo.sp_cliente_leer_usuarios @ClienteId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.UsuarioId, u.NombreUsuario+' — '+u.Nombre+' '+u.Apellido AS Nombre
      FROM dbo.ClienteUsuario cu
      JOIN dbo.Usuario u ON u.UsuarioId=cu.UsuarioId
     WHERE cu.ClienteId=@ClienteId AND cu.Eliminado=0 AND u.Eliminado=0
     ORDER BY u.Nombre;
END;
GO

/* 7 */
CREATE OR ALTER PROCEDURE dbo.sp_cliente_leer_giros @ClienteId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT g.GiroNegocioId, g.Nombre
      FROM dbo.ClienteGiroNegocio cg
      JOIN dbo.GiroNegocio g ON g.GiroNegocioId=cg.GiroNegocioId
     WHERE cg.ClienteId=@ClienteId AND cg.Eliminado=0 AND g.Eliminado=0
     ORDER BY g.Nombre;
END;
GO

/* 8 */
CREATE OR ALTER PROCEDURE dbo.sp_clienteusuario_crear_asignacion
    @ClienteId INT, @UsuarioId INT, @UsuarioResponsableId INT=NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE ClienteId=@ClienteId AND Eliminado=0)
        THROW 50001, 'Cliente no existe o fue eliminado.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE UsuarioId=@UsuarioId AND Eliminado=0)
        THROW 50001, 'Usuario no existe o fue eliminado.', 1;
    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM dbo.ClienteUsuario
               WHERE ClienteId=@ClienteId AND UsuarioId=@UsuarioId AND Eliminado=1)
        UPDATE dbo.ClienteUsuario SET Eliminado=0,FechaModificacion=SYSUTCDATETIME()
         WHERE ClienteId=@ClienteId AND UsuarioId=@UsuarioId;
    ELSE IF NOT EXISTS (SELECT 1 FROM dbo.ClienteUsuario
                        WHERE ClienteId=@ClienteId AND UsuarioId=@UsuarioId)
        INSERT INTO dbo.ClienteUsuario(ClienteId,UsuarioId,Eliminado)
        VALUES(@ClienteId,@UsuarioId,0);
    EXEC dbo.sp_auditoria_crear_evento @UsuarioId=@UsuarioResponsableId,@Modulo='Clientes',
         @TipoOperacion='AsignarUsuario',@IdentificadorRegistro=CAST(@ClienteId AS NVARCHAR(100)),
         @Resultado='Exitoso',@Detalle='Usuario asignado al cliente';
    COMMIT TRANSACTION;
END;
GO

/* 9 */
CREATE OR ALTER PROCEDURE dbo.sp_clienteusuario_eliminar_asignacion
    @ClienteId INT, @UsuarioId INT, @UsuarioResponsableId INT=NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRANSACTION;
    UPDATE dbo.ClienteUsuario SET Eliminado=1,FechaModificacion=SYSUTCDATETIME()
     WHERE ClienteId=@ClienteId AND UsuarioId=@UsuarioId AND Eliminado=0;
    EXEC dbo.sp_auditoria_crear_evento @UsuarioId=@UsuarioResponsableId,@Modulo='Clientes',
         @TipoOperacion='QuitarUsuario',@IdentificadorRegistro=CAST(@ClienteId AS NVARCHAR(100)),
         @Resultado='Exitoso',@Detalle='Usuario desasociado del cliente';
    COMMIT TRANSACTION;
END;
GO

/* 10 */
CREATE OR ALTER PROCEDURE dbo.sp_clientegironegocio_crear_asignacion
    @ClienteId INT, @GiroNegocioId INT, @UsuarioResponsableId INT=NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE ClienteId=@ClienteId AND Eliminado=0)
        THROW 50001, 'Cliente no existe o fue eliminado.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.GiroNegocio WHERE GiroNegocioId=@GiroNegocioId AND Eliminado=0)
        THROW 50001, 'Giro de negocio no existe o fue eliminado.', 1;
    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM dbo.ClienteGiroNegocio
               WHERE ClienteId=@ClienteId AND GiroNegocioId=@GiroNegocioId AND Eliminado=1)
        UPDATE dbo.ClienteGiroNegocio SET Eliminado=0,FechaModificacion=SYSUTCDATETIME()
         WHERE ClienteId=@ClienteId AND GiroNegocioId=@GiroNegocioId;
    ELSE IF NOT EXISTS (SELECT 1 FROM dbo.ClienteGiroNegocio
                        WHERE ClienteId=@ClienteId AND GiroNegocioId=@GiroNegocioId)
        INSERT INTO dbo.ClienteGiroNegocio(ClienteId,GiroNegocioId,Eliminado)
        VALUES(@ClienteId,@GiroNegocioId,0);
    EXEC dbo.sp_auditoria_crear_evento @UsuarioId=@UsuarioResponsableId,@Modulo='Clientes',
         @TipoOperacion='AsignarGiro',@IdentificadorRegistro=CAST(@ClienteId AS NVARCHAR(100)),
         @Resultado='Exitoso',@Detalle='Giro asignado al cliente';
    COMMIT TRANSACTION;
END;
GO

/* 11 */
CREATE OR ALTER PROCEDURE dbo.sp_clientegironegocio_eliminar_asignacion
    @ClienteId INT, @GiroNegocioId INT, @UsuarioResponsableId INT=NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRANSACTION;
    UPDATE dbo.ClienteGiroNegocio SET Eliminado=1,FechaModificacion=SYSUTCDATETIME()
     WHERE ClienteId=@ClienteId AND GiroNegocioId=@GiroNegocioId AND Eliminado=0;
    EXEC dbo.sp_auditoria_crear_evento @UsuarioId=@UsuarioResponsableId,@Modulo='Clientes',
         @TipoOperacion='QuitarGiro',@IdentificadorRegistro=CAST(@ClienteId AS NVARCHAR(100)),
         @Resultado='Exitoso',@Detalle='Giro desasociado del cliente';
    COMMIT TRANSACTION;
END;
GO
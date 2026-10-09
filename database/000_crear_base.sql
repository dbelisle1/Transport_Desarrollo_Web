/* Ejecutar con permisos para crear bases. Seguro para múltiples ejecuciones. */
USE [master];
GO
IF DB_ID(N'TransPortDB') IS NULL
BEGIN
    CREATE DATABASE [TransPortDB];
END;
GO
ALTER DATABASE [TransPortDB] SET RECOVERY SIMPLE;
GO

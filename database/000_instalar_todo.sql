/*
  Instalador para SQLCMD. Ejecútelo desde la carpeta database:
  sqlcmd -S localhost -E -C -i 000_instalar_todo.sql
*/
:ON ERROR EXIT
:r .\000_crear_base.sql
:r .\001_tablas.sql
:r .\002_indices_relaciones.sql
:r .\003_procedimientos.sql
:r .\004_datos_iniciales.sql
PRINT N'Instalación de TransPortDB finalizada.';
GO

using System.Data;
using Microsoft.Data.SqlClient;
using TransPort.Api.Configuration;
using TransPort.Api.Modules.Seguridad.DTOs;
using TransPort.Api.Modules.Shared.DTOs;
using TransPort.Api.Modules.Shared.Repositories;

namespace TransPort.Api.Modules.Seguridad.Repositories;

public sealed class UsuarioRepository(ISqlConnectionFactory connections) : IUsuarioRepository
{
    public async Task<CredencialUsuarioDto?> ValidarCredencialesAsync(
        string nombreUsuario, string clave, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_usuario_validar_credenciales");
        command.Parameters.Add("@NombreUsuario", SqlDbType.NVarChar, 80).Value = nombreUsuario;
        command.Parameters.Add("@Clave", SqlDbType.NVarChar, 200).Value = clave;
        await using var reader = await command.ExecuteReaderAsync(ct);
        if (!await reader.ReadAsync(ct)) return null;
        return new CredencialUsuarioDto(
            reader.Int32("UsuarioId"), reader.Text("NombreUsuario"), reader.Text("Nombre"),
            reader.Text("Apellido"), reader.Text("Correo"), reader.Bool("EsActivo"));
    }

    public async Task<IReadOnlyList<UsuarioListadoDto>> ListarAsync(
        string? busqueda, bool? esActivo, int? rolId, CancellationToken ct)
    {
        var result = new List<UsuarioListadoDto>();
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_usuario_leer_listado");
        command.Parameters.Add("@Busqueda", SqlDbType.NVarChar, 200).Value = Db(busqueda);
        command.Parameters.Add("@EsActivo", SqlDbType.Bit).Value = Db(esActivo);
        command.Parameters.Add("@RolId", SqlDbType.Int).Value = Db(rolId);
        await using var reader = await command.ExecuteReaderAsync(ct);
        while (await reader.ReadAsync(ct))
        {
            result.Add(new UsuarioListadoDto(
                reader.Int32("UsuarioId"), reader.Text("NombreUsuario"), reader.Text("Nombre"),
                reader.Text("Apellido"), reader.Text("Correo"), reader.Bool("EsActivo"),
                reader.Date("FechaCreacion"), reader.Text("Roles")));
        }
        return result;
    }

    public async Task<UsuarioDetalleDto?> ObtenerAsync(int id, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_usuario_leer_por_id");
        command.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = id;
        await using var reader = await command.ExecuteReaderAsync(ct);
        if (!await reader.ReadAsync(ct)) return null;
        var usuario = new UsuarioDetalleDto(
            reader.Int32("UsuarioId"), reader.Text("NombreUsuario"), reader.Text("Nombre"),
            reader.Text("Apellido"), reader.Text("Correo"), reader.Bool("EsActivo"),
            reader.Date("FechaCreacion"), reader.NullableDate("FechaModificacion"), [], [], []);
        await reader.CloseAsync();
        var roles = await LeerCatalogoAsync(connection, "sp_usuario_leer_roles", id, ct);
        var giros = await LeerCatalogoAsync(connection, "sp_usuario_leer_giros", id, ct);
        var sedes = await LeerCatalogoAsync(connection, "sp_usuario_leer_sedes", id, ct);
        return usuario with { Roles = roles, Giros = giros, Sedes = sedes };
    }

    public async Task<int> CrearAsync(CrearUsuarioRequest request, int responsableId, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_usuario_crear_registro");
        command.Parameters.Add("@NombreUsuario", SqlDbType.NVarChar, 80).Value = request.NombreUsuario.Trim();
        command.Parameters.Add("@Nombre", SqlDbType.NVarChar, 100).Value = request.Nombre.Trim();
        command.Parameters.Add("@Apellido", SqlDbType.NVarChar, 100).Value = request.Apellido.Trim();
        command.Parameters.Add("@Correo", SqlDbType.NVarChar, 200).Value = request.Correo.Trim();
        command.Parameters.Add("@Clave", SqlDbType.NVarChar, 200).Value = request.Clave;
        command.Parameters.Add("@EsActivo", SqlDbType.Bit).Value = request.EsActivo;
        command.Parameters.Add("@UsuarioResponsableId", SqlDbType.Int).Value = responsableId;
        return Convert.ToInt32(await command.ExecuteScalarAsync(ct));
    }

    public async Task<bool> ActualizarAsync(
        int id, ActualizarUsuarioRequest request, int responsableId, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_usuario_actualizar_datos");
        command.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = id;
        command.Parameters.Add("@NombreUsuario", SqlDbType.NVarChar, 80).Value = request.NombreUsuario.Trim();
        command.Parameters.Add("@Nombre", SqlDbType.NVarChar, 100).Value = request.Nombre.Trim();
        command.Parameters.Add("@Apellido", SqlDbType.NVarChar, 100).Value = request.Apellido.Trim();
        command.Parameters.Add("@Correo", SqlDbType.NVarChar, 200).Value = request.Correo.Trim();
        command.Parameters.Add("@EsActivo", SqlDbType.Bit).Value = request.EsActivo;
        command.Parameters.Add("@UsuarioResponsableId", SqlDbType.Int).Value = responsableId;
        return Convert.ToInt32(await command.ExecuteScalarAsync(ct)) > 0;
    }

    public async Task<bool> EliminarAsync(int id, int responsableId, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_usuario_eliminar_logico");
        command.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = id;
        command.Parameters.Add("@UsuarioResponsableId", SqlDbType.Int).Value = responsableId;
        return Convert.ToInt32(await command.ExecuteScalarAsync(ct)) > 0;
    }

    public Task<IReadOnlyList<CatalogoDto>> LeerRolesAsync(int id, CancellationToken ct) =>
        LeerCatalogoConConexionAsync("sp_usuario_leer_roles", id, ct);
    public Task<IReadOnlyList<CatalogoDto>> LeerGirosAsync(int id, CancellationToken ct) =>
        LeerCatalogoConConexionAsync("sp_usuario_leer_giros", id, ct);
    public Task<IReadOnlyList<CatalogoDto>> LeerSedesAsync(int id, CancellationToken ct) =>
        LeerCatalogoConConexionAsync("sp_usuario_leer_sedes", id, ct);
    public Task<IReadOnlyList<CatalogoDto>> LeerClientesAsync(int id, CancellationToken ct) =>
        LeerCatalogoConConexionAsync("sp_usuario_leer_clientes", id, ct);

    public async Task ActualizarAsignacionesAsync(
        int usuarioId, AsignacionesUsuarioRequest request, int responsableId, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var transaction = (SqlTransaction)await connection.BeginTransactionAsync(ct);
        try
        {
            await SincronizarAsync(connection, transaction, usuarioId,
                await LeerCatalogoAsync(connection, "sp_usuario_leer_roles", usuarioId, ct, transaction),
                request.Roles, "sp_usuariorol_crear_asignacion", "sp_usuariorol_eliminar_asignacion", "@RolId", responsableId, ct);
            await SincronizarAsync(connection, transaction, usuarioId,
                await LeerCatalogoAsync(connection, "sp_usuario_leer_giros", usuarioId, ct, transaction),
                request.Giros, "sp_usuariogironegocio_crear_asignacion", "sp_usuariogironegocio_eliminar_asignacion", "@GiroNegocioId", responsableId, ct);
            await SincronizarAsync(connection, transaction, usuarioId,
                await LeerCatalogoAsync(connection, "sp_usuario_leer_sedes", usuarioId, ct, transaction),
                request.Sedes, "sp_usuariosede_crear_asignacion", "sp_usuariosede_eliminar_asignacion", "@SedeId", responsableId, ct);
            await transaction.CommitAsync(ct);
        }
        catch
        {
            await transaction.RollbackAsync(ct);
            throw;
        }
    }

    private async Task<IReadOnlyList<CatalogoDto>> LeerCatalogoConConexionAsync(
        string procedure, int usuarioId, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        return await LeerCatalogoAsync(connection, procedure, usuarioId, ct);
    }

    private static async Task<IReadOnlyList<CatalogoDto>> LeerCatalogoAsync(
        SqlConnection connection, string procedure, int usuarioId, CancellationToken ct,
        SqlTransaction? transaction = null)
    {
        var result = new List<CatalogoDto>();
        await using var command = Procedure(connection, procedure, transaction);
        command.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = usuarioId;
        await using var reader = await command.ExecuteReaderAsync(ct);
        while (await reader.ReadAsync(ct)) result.Add(new CatalogoDto(reader.Int32("Id"), reader.Text("Nombre")));
        return result;
    }

    private static async Task SincronizarAsync(
        SqlConnection connection, SqlTransaction transaction, int usuarioId,
        IReadOnlyList<CatalogoDto> actuales, IReadOnlyList<int> solicitados,
        string crear, string eliminar, string parametro, int responsableId, CancellationToken ct)
    {
        var nuevos = solicitados.Where(x => x > 0).Distinct().ToHashSet();
        foreach (var actual in actuales.Where(x => !nuevos.Contains(x.Id)))
            await EjecutarAsignacionAsync(connection, transaction, eliminar, usuarioId, parametro, actual.Id, responsableId, ct);
        foreach (var nuevo in nuevos.Where(x => actuales.All(a => a.Id != x)))
            await EjecutarAsignacionAsync(connection, transaction, crear, usuarioId, parametro, nuevo, responsableId, ct);
    }

    private static async Task EjecutarAsignacionAsync(
        SqlConnection connection, SqlTransaction transaction, string procedure, int usuarioId,
        string parametro, int valor, int responsableId, CancellationToken ct)
    {
        await using var command = Procedure(connection, procedure, transaction);
        command.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = usuarioId;
        command.Parameters.Add(parametro, SqlDbType.Int).Value = valor;
        command.Parameters.Add("@UsuarioResponsableId", SqlDbType.Int).Value = responsableId;
        await command.ExecuteNonQueryAsync(ct);
    }

    private static SqlCommand Procedure(SqlConnection connection, string name, SqlTransaction? transaction = null) =>
        new(name, connection, transaction) { CommandType = CommandType.StoredProcedure };

    private static object Db(object? value) => value ?? DBNull.Value;
}

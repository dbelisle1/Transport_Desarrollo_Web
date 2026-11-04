using System.Data;
using Microsoft.Data.SqlClient;
using TransPort.Api.Configuration;
using TransPort.Api.Modules.Clientes.DTOs;
using TransPort.Api.Modules.Shared.DTOs;
using TransPort.Api.Modules.Shared.Repositories;

namespace TransPort.Api.Modules.Clientes.Repositories;

public sealed class ClienteRepository(ISqlConnectionFactory connections) : IClienteRepository
{
    public async Task<IReadOnlyList<ClienteListadoDto>> ListarAsync(
        string? busqueda, bool? esActivo, CancellationToken ct)
    {
        var result = new List<ClienteListadoDto>();
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_cliente_leer_listado");
        command.Parameters.Add("@Busqueda", SqlDbType.NVarChar, 200).Value = Db(Limpiar(busqueda));
        command.Parameters.Add("@EsActivo", SqlDbType.Bit).Value = Db(esActivo);
        await using var reader = await command.ExecuteReaderAsync(ct);
        while (await reader.ReadAsync(ct))
        {
            result.Add(new ClienteListadoDto(
                reader.Int32("ClienteId"), reader.Text("Nombre"), reader.NullableText("Nit"),
                reader.NullableText("CorreoContacto"), reader.Bool("EsActivo"),
                reader.Date("FechaCreacion"), reader.Text("Usuarios"), reader.Text("Giros")));
        }
        return result;
    }

    public async Task<ClienteDetalleDto?> ObtenerAsync(int id, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_cliente_leer_por_id");
        command.Parameters.Add("@ClienteId", SqlDbType.Int).Value = id;
        await using var reader = await command.ExecuteReaderAsync(ct);
        if (!await reader.ReadAsync(ct)) return null;
        var cliente = new ClienteDetalleDto(
            reader.Int32("ClienteId"), reader.Text("Nombre"), reader.NullableText("Nit"),
            reader.NullableText("CorreoContacto"), reader.Bool("EsActivo"),
            reader.Date("FechaCreacion"), reader.NullableDate("FechaModificacion"), [], []);
        await reader.CloseAsync();
        var usuarios = await LeerAsignacionesAsync(connection, "sp_cliente_leer_usuarios", id, ct);
        var giros = await LeerAsignacionesAsync(connection, "sp_cliente_leer_giros", id, ct);
        return cliente with { Usuarios = usuarios, Giros = giros };
    }

    public async Task<int> CrearAsync(CrearClienteRequest request, int responsableId, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var transaction = (SqlTransaction)await connection.BeginTransactionAsync(ct);
        try
        {
            await using var command = Procedure(connection, "sp_cliente_crear_registro", transaction);
            AgregarDatos(command, request.Nombre, request.Nit, request.CorreoContacto, request.EsActivo, responsableId);
            var id = Convert.ToInt32(await command.ExecuteScalarAsync(ct));
            await SincronizarAsync(connection, transaction, id, [], request.Usuarios,
                "sp_clienteusuario_crear_asignacion", "sp_clienteusuario_eliminar_asignacion",
                "@UsuarioId", responsableId, ct);
            await SincronizarAsync(connection, transaction, id, [], request.Giros,
                "sp_clientegironegocio_crear_asignacion", "sp_clientegironegocio_eliminar_asignacion",
                "@GiroNegocioId", responsableId, ct);
            await transaction.CommitAsync(ct);
            return id;
        }
        catch
        {
            await transaction.RollbackAsync(ct);
            throw;
        }
    }

    public async Task<bool> ActualizarAsync(
        int id, ActualizarClienteRequest request, int responsableId, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var transaction = (SqlTransaction)await connection.BeginTransactionAsync(ct);
        try
        {
            await using var command = Procedure(connection, "sp_cliente_actualizar_datos", transaction);
            command.Parameters.Add("@ClienteId", SqlDbType.Int).Value = id;
            AgregarDatos(command, request.Nombre, request.Nit, request.CorreoContacto, request.EsActivo, responsableId);
            var actualizado = Convert.ToInt32(await command.ExecuteScalarAsync(ct)) > 0;
            if (actualizado)
            {
                await SincronizarAsync(connection, transaction, id,
                    await LeerAsignacionesAsync(connection, "sp_cliente_leer_usuarios", id, ct, transaction),
                    request.Usuarios, "sp_clienteusuario_crear_asignacion",
                    "sp_clienteusuario_eliminar_asignacion", "@UsuarioId", responsableId, ct);
                await SincronizarAsync(connection, transaction, id,
                    await LeerAsignacionesAsync(connection, "sp_cliente_leer_giros", id, ct, transaction),
                    request.Giros, "sp_clientegironegocio_crear_asignacion",
                    "sp_clientegironegocio_eliminar_asignacion", "@GiroNegocioId", responsableId, ct);
            }
            await transaction.CommitAsync(ct);
            return actualizado;
        }
        catch
        {
            await transaction.RollbackAsync(ct);
            throw;
        }
    }

    public async Task<bool> EliminarAsync(int id, int responsableId, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_cliente_eliminar_logico");
        command.Parameters.Add("@ClienteId", SqlDbType.Int).Value = id;
        command.Parameters.Add("@UsuarioResponsableId", SqlDbType.Int).Value = responsableId;
        return Convert.ToInt32(await command.ExecuteScalarAsync(ct)) > 0;
    }

    public async Task ActualizarAsignacionesAsync(
        int id, AsignacionesClienteRequest request, int responsableId, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var transaction = (SqlTransaction)await connection.BeginTransactionAsync(ct);
        try
        {
            await SincronizarAsync(connection, transaction, id,
                await LeerAsignacionesAsync(connection, "sp_cliente_leer_usuarios", id, ct, transaction),
                request.Usuarios, "sp_clienteusuario_crear_asignacion",
                "sp_clienteusuario_eliminar_asignacion", "@UsuarioId", responsableId, ct);
            await SincronizarAsync(connection, transaction, id,
                await LeerAsignacionesAsync(connection, "sp_cliente_leer_giros", id, ct, transaction),
                request.Giros, "sp_clientegironegocio_crear_asignacion",
                "sp_clientegironegocio_eliminar_asignacion", "@GiroNegocioId", responsableId, ct);
            await transaction.CommitAsync(ct);
        }
        catch
        {
            await transaction.RollbackAsync(ct);
            throw;
        }
    }

    private static async Task<IReadOnlyList<CatalogoDto>> LeerAsignacionesAsync(
        SqlConnection connection, string procedure, int id, CancellationToken ct,
        SqlTransaction? transaction = null)
    {
        var result = new List<CatalogoDto>();
        await using var command = Procedure(connection, procedure, transaction);
        command.Parameters.Add("@ClienteId", SqlDbType.Int).Value = id;
        await using var reader = await command.ExecuteReaderAsync(ct);
        while (await reader.ReadAsync(ct))
            result.Add(new CatalogoDto(reader.Int32("Id"), reader.Text("Nombre")));
        return result;
    }

    private static async Task SincronizarAsync(
        SqlConnection connection, SqlTransaction transaction, int clienteId,
        IReadOnlyList<CatalogoDto> actuales, IReadOnlyList<int> solicitados,
        string crear, string eliminar, string parametro, int responsableId, CancellationToken ct)
    {
        var nuevos = solicitados.Where(x => x > 0).Distinct().ToHashSet();
        foreach (var actual in actuales.Where(x => !nuevos.Contains(x.Id)))
            await EjecutarAsignacionAsync(connection, transaction, eliminar, clienteId, parametro, actual.Id, responsableId, ct);
        foreach (var nuevo in nuevos.Where(x => actuales.All(a => a.Id != x)))
            await EjecutarAsignacionAsync(connection, transaction, crear, clienteId, parametro, nuevo, responsableId, ct);
    }

    private static async Task EjecutarAsignacionAsync(
        SqlConnection connection, SqlTransaction transaction, string procedure, int clienteId,
        string parametro, int valor, int responsableId, CancellationToken ct)
    {
        await using var command = Procedure(connection, procedure, transaction);
        command.Parameters.Add("@ClienteId", SqlDbType.Int).Value = clienteId;
        command.Parameters.Add(parametro, SqlDbType.Int).Value = valor;
        command.Parameters.Add("@UsuarioResponsableId", SqlDbType.Int).Value = responsableId;
        await command.ExecuteNonQueryAsync(ct);
    }

    private static void AgregarDatos(
        SqlCommand command, string nombre, string? nit, string? correo, bool esActivo, int responsableId)
    {
        command.Parameters.Add("@Nombre", SqlDbType.NVarChar, 200).Value = nombre.Trim();
        command.Parameters.Add("@Nit", SqlDbType.NVarChar, 30).Value = Db(Limpiar(nit));
        command.Parameters.Add("@CorreoContacto", SqlDbType.NVarChar, 200).Value = Db(Limpiar(correo));
        command.Parameters.Add("@EsActivo", SqlDbType.Bit).Value = esActivo;
        command.Parameters.Add("@UsuarioResponsableId", SqlDbType.Int).Value = responsableId;
    }

    private static string? Limpiar(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static SqlCommand Procedure(
        SqlConnection connection, string name, SqlTransaction? transaction = null) =>
        new(name, connection, transaction) { CommandType = CommandType.StoredProcedure };

    private static object Db(object? value) => value ?? DBNull.Value;
}

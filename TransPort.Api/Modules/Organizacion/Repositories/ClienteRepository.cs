using System.Data;
using Microsoft.Data.SqlClient;
using TransPort.Api.Configuration;
using TransPort.Api.Modules.Organizacion.DTOs;
using TransPort.Api.Modules.Shared.DTOs;
using TransPort.Api.Modules.Shared.Repositories;

namespace TransPort.Api.Modules.Organizacion.Repositories;

public sealed class ClienteRepository(ISqlConnectionFactory connections) : IClienteRepository
{
    public async Task<IReadOnlyList<ClienteListadoDto>> ListarAsync(string? busqueda, bool? esActivo, CancellationToken ct)
    {
        var result = new List<ClienteListadoDto>();
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_cliente_leer_listado");
        command.Parameters.Add("@Busqueda", SqlDbType.NVarChar, 200).Value = Db(busqueda);
        command.Parameters.Add("@EsActivo", SqlDbType.Bit).Value = Db(esActivo);
        await using var reader = await command.ExecuteReaderAsync(ct);
        while (await reader.ReadAsync(ct))
        {
            result.Add(new ClienteListadoDto(
                reader.Int32("ClienteId"), reader.Text("Nombre"), reader.NullableText("Nit"),
                reader.NullableText("CorreoContacto"), reader.Bool("EsActivo"), reader.NullableDate("FechaModificacion")));
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
            reader.NullableText("CorreoContacto"), reader.Bool("EsActivo"), reader.NullableDate("FechaModificacion"), [], []);
        await reader.CloseAsync();

        var usuarios = await LeerCatalogoAsync(connection, "sp_cliente_leer_usuarios", id, "UsuarioId", ct);
        var giros = await LeerCatalogoAsync(connection, "sp_cliente_leer_giros", id, "GiroNegocioId", ct);
        return cliente with { Usuarios = usuarios, Giros = giros };
    }

    public async Task<int> CrearAsync(CrearClienteRequest request, int responsableId, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_cliente_crear_registro");
        command.Parameters.Add("@Nombre", SqlDbType.NVarChar, 200).Value = request.Nombre.Trim();
        command.Parameters.Add("@Nit", SqlDbType.NVarChar, 50).Value = Db(request.Nit?.Trim());
        command.Parameters.Add("@CorreoContacto", SqlDbType.NVarChar, 150).Value = Db(request.CorreoContacto?.Trim());
        command.Parameters.Add("@EsActivo", SqlDbType.Bit).Value = request.EsActivo;
        command.Parameters.Add("@UsuarioResponsableId", SqlDbType.Int).Value = responsableId;
        return Convert.ToInt32(await command.ExecuteScalarAsync(ct));
    }

    public async Task<bool> ActualizarAsync(int id, ActualizarClienteRequest request, int responsableId, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_cliente_actualizar_datos");
        command.Parameters.Add("@ClienteId", SqlDbType.Int).Value = id;
        command.Parameters.Add("@Nombre", SqlDbType.NVarChar, 200).Value = request.Nombre.Trim();
        command.Parameters.Add("@Nit", SqlDbType.NVarChar, 50).Value = Db(request.Nit?.Trim());
        command.Parameters.Add("@CorreoContacto", SqlDbType.NVarChar, 150).Value = Db(request.CorreoContacto?.Trim());
        command.Parameters.Add("@EsActivo", SqlDbType.Bit).Value = request.EsActivo;
        command.Parameters.Add("@UsuarioResponsableId", SqlDbType.Int).Value = responsableId;
        return Convert.ToInt32(await command.ExecuteScalarAsync(ct)) > 0;
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

    public async Task ActualizarAsociacionesAsync(int clienteId, AsociacionesClienteRequest request, int responsableId, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var transaction = (SqlTransaction)await connection.BeginTransactionAsync(ct);
        try
        {
            await SincronizarAsync(connection, transaction, clienteId,
                await LeerCatalogoAsync(connection, "sp_cliente_leer_usuarios", clienteId, "UsuarioId", ct, transaction),
                request.Usuarios, "sp_clienteusuario_crear_asignacion", "sp_clienteusuario_eliminar_asignacion", "@UsuarioId", responsableId, ct);

            await SincronizarAsync(connection, transaction, clienteId,
                await LeerCatalogoAsync(connection, "sp_cliente_leer_giros", clienteId, "GiroNegocioId", ct, transaction),
                request.Giros, "sp_clientegironegocio_crear_asignacion", "sp_clientegironegocio_eliminar_asignacion", "@GiroNegocioId", responsableId, ct);

            await transaction.CommitAsync(ct);
        }
        catch { await transaction.RollbackAsync(ct); throw; }
    }

    private static async Task<IReadOnlyList<CatalogoDto>> LeerCatalogoAsync(SqlConnection conn, string sp, int id, string col, CancellationToken ct, SqlTransaction? tx = null)
    {
        var res = new List<CatalogoDto>();
        await using var cmd = Procedure(conn, sp, tx);
        cmd.Parameters.Add("@ClienteId", SqlDbType.Int).Value = id;
        await using var r = await cmd.ExecuteReaderAsync(ct);
        while (await r.ReadAsync(ct)) res.Add(new CatalogoDto(r.Int32(col), r.Text("Nombre")));
        return res;
    }

    private static async Task SincronizarAsync(SqlConnection conn, SqlTransaction tx, int id,
        IReadOnlyList<CatalogoDto> actuales, IReadOnlyList<int> solic, string crear, string elim, string param, int resp, CancellationToken ct)
    {
        var nuevos = solic.Where(x => x > 0).Distinct().ToHashSet();
        foreach (var a in actuales.Where(x => !nuevos.Contains(x.Id)))
            await EjecutarAsigAsync(conn, tx, elim, id, param, a.Id, resp, ct);
        foreach (var n in nuevos.Where(x => actuales.All(a => a.Id != x)))
            await EjecutarAsigAsync(conn, tx, crear, id, param, n, resp, ct);
    }

    private static async Task EjecutarAsigAsync(SqlConnection conn, SqlTransaction tx, string sp, int id, string param, int val, int resp, CancellationToken ct)
    {
        await using var cmd = Procedure(conn, sp, tx);
        cmd.Parameters.Add("@ClienteId", SqlDbType.Int).Value = id;
        cmd.Parameters.Add(param, SqlDbType.Int).Value = val;
        cmd.Parameters.Add("@UsuarioResponsableId", SqlDbType.Int).Value = resp;
        await cmd.ExecuteNonQueryAsync(ct);
    }

    private static SqlCommand Procedure(SqlConnection c, string n, SqlTransaction? t = null) => new(n, c, t) { CommandType = CommandType.StoredProcedure };
    private static object Db(object? v) => v ?? DBNull.Value;
}
using System.Data;
using Microsoft.Data.SqlClient;
using TransPort.Api.Configuration;
using TransPort.Api.Modules.Comercial.DTOs;
using TransPort.Api.Modules.Shared.DTOs;
using TransPort.Api.Modules.Shared.Repositories;

namespace TransPort.Api.Modules.Comercial.Repositories;

public sealed class ComunicacionRepository(ISqlConnectionFactory connections) : IComunicacionRepository
{
    public async Task<IReadOnlyList<ComunicacionListadoDto>> ListarAsync(
        string? estado, string? tipo, string? busqueda, AlcanceComunicacion alcance, CancellationToken ct)
    {
        var result = new List<ComunicacionListadoDto>();
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_comunicaciones_leer_listado");
        Scope(command, alcance);
        Text(command, "@Estado", 20, estado);
        Text(command, "@Tipo", 20, tipo);
        Text(command, "@Busqueda", 200, busqueda);
        await using var reader = await command.ExecuteReaderAsync(ct);
        while (await reader.ReadAsync(ct))
            result.Add(new ComunicacionListadoDto(
                reader.Int64("ComunicacionHiloId"), reader.Text("Tipo"), reader.Text("Asunto"), reader.Text("Estado"),
                reader.NullableInt32("ClienteId"), reader.NullableText("Cliente"), reader.NullableInt32("GiroNegocioId"),
                reader.NullableText("Giro"), Long(reader, "PedidoId"), reader.NullableInt32("ResponsableUsuarioId"),
                reader.NullableText("Responsable"), reader.NullableText("ModuloOrigen"), Long(reader, "RegistroOrigenId"),
                reader.Date("UltimaActividad"), reader.Date("FechaCreacion"), reader.Int32("Mensajes")));
        return result;
    }

    public async Task<ComunicacionDetalleDto?> ObtenerAsync(long id, AlcanceComunicacion alcance, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_comunicaciones_leer_por_id");
        command.Parameters.Add("@Id", SqlDbType.BigInt).Value = id;
        Scope(command, alcance);
        await using var reader = await command.ExecuteReaderAsync(ct);
        if (!await reader.ReadAsync(ct)) return null;
        var detail = new ComunicacionDetalleDto(
            reader.Int64("ComunicacionHiloId"), reader.Text("Tipo"), reader.Text("Asunto"), reader.Text("Estado"),
            reader.NullableInt32("ClienteId"), reader.NullableText("Cliente"), reader.NullableInt32("GiroNegocioId"),
            reader.NullableText("Giro"), Long(reader, "PedidoId"), reader.NullableInt32("ResponsableUsuarioId"),
            reader.NullableText("Responsable"), reader.NullableText("ModuloOrigen"), Long(reader, "RegistroOrigenId"),
            reader.Text("CreadoPor"), reader.Date("UltimaActividad"), reader.Date("FechaCreacion"),
            reader.NullableDate("FechaModificacion"), []);
        var messages = new List<ComunicacionMensajeDto>();
        if (await reader.NextResultAsync(ct))
            while (await reader.ReadAsync(ct))
                messages.Add(new ComunicacionMensajeDto(
                    reader.Int64("ComunicacionMensajeId"), reader.Int32("UsuarioId"), reader.Text("NombreUsuario"),
                    reader.Text("Mensaje"), reader.GetBoolean(reader.GetOrdinal("EsInterno")), reader.Date("Fecha")));
        return detail with { Mensajes = messages };
    }

    public async Task<ComunicacionOpcionesDto> OpcionesAsync(AlcanceComunicacion alcance, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_comunicaciones_leer_opciones");
        Scope(command, alcance);
        await using var reader = await command.ExecuteReaderAsync(ct);
        var clients = await Catalogs(reader, ct);
        var lines = await NextCatalogs(reader, ct);
        var orders = new List<ComunicacionPedidoOpcionDto>();
        if (await reader.NextResultAsync(ct))
            while (await reader.ReadAsync(ct)) orders.Add(new(reader.Int64("Id"), reader.Text("Nombre")));
        var owners = await NextCatalogs(reader, ct);
        return new ComunicacionOpcionesDto(clients, lines, orders, owners);
    }

    public async Task<long> CrearAsync(CrearComunicacionRequest request, AlcanceComunicacion alcance, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_comunicaciones_crear");
        Text(command, "@Tipo", 20, request.Tipo);
        command.Parameters.Add("@ClienteId", SqlDbType.Int).Value = Db(request.ClienteId);
        command.Parameters.Add("@GiroNegocioId", SqlDbType.Int).Value = Db(request.GiroNegocioId);
        command.Parameters.Add("@PedidoId", SqlDbType.BigInt).Value = Db(request.PedidoId);
        Text(command, "@Asunto", 180, request.Asunto);
        Text(command, "@MensajeInicial", 2000, request.MensajeInicial);
        Text(command, "@ModuloOrigen", 50, request.ModuloOrigen);
        command.Parameters.Add("@RegistroOrigenId", SqlDbType.BigInt).Value = Db(request.RegistroOrigenId);
        Scope(command, alcance);
        return Convert.ToInt64(await command.ExecuteScalarAsync(ct));
    }

    public async Task<long> AgregarMensajeAsync(
        long id, CrearMensajeComunicacionRequest request, AlcanceComunicacion alcance, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_comunicaciones_agregar_mensaje");
        command.Parameters.Add("@Id", SqlDbType.BigInt).Value = id;
        Text(command, "@Mensaje", 2000, request.Mensaje);
        command.Parameters.Add("@EsInterno", SqlDbType.Bit).Value = request.EsInterno;
        Scope(command, alcance);
        return Convert.ToInt64(await command.ExecuteScalarAsync(ct));
    }

    public async Task<bool> GestionarAsync(
        long id, GestionComunicacionRequest request, AlcanceComunicacion alcance, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_comunicaciones_actualizar_gestion");
        command.Parameters.Add("@Id", SqlDbType.BigInt).Value = id;
        Text(command, "@Estado", 20, request.Estado);
        command.Parameters.Add("@ResponsableUsuarioId", SqlDbType.Int).Value = Db(request.ResponsableUsuarioId);
        command.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = alcance.UsuarioId;
        command.Parameters.Add("@EsAdministrador", SqlDbType.Bit).Value = alcance.EsAdministrador;
        return Convert.ToInt32(await command.ExecuteScalarAsync(ct)) > 0;
    }

    public async Task<bool> EliminarAsync(long id, int usuarioId, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_comunicaciones_eliminar");
        command.Parameters.Add("@Id", SqlDbType.BigInt).Value = id;
        command.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = usuarioId;
        return Convert.ToInt32(await command.ExecuteScalarAsync(ct)) > 0;
    }

    private static async Task<IReadOnlyList<CatalogoDto>> NextCatalogs(SqlDataReader reader, CancellationToken ct) =>
        await reader.NextResultAsync(ct) ? await Catalogs(reader, ct) : [];
    private static async Task<IReadOnlyList<CatalogoDto>> Catalogs(SqlDataReader reader, CancellationToken ct)
    {
        var result = new List<CatalogoDto>();
        while (await reader.ReadAsync(ct)) result.Add(new(reader.Int32("Id"), reader.Text("Nombre")));
        return result;
    }
    private static void Scope(SqlCommand command, AlcanceComunicacion scope)
    {
        command.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = scope.UsuarioId;
        command.Parameters.Add("@EsAdministrador", SqlDbType.Bit).Value = scope.EsAdministrador;
        command.Parameters.Add("@EsCliente", SqlDbType.Bit).Value = scope.EsCliente;
    }
    private static void Text(SqlCommand command, string name, int size, string? value) =>
        command.Parameters.Add(name, SqlDbType.NVarChar, size).Value = string.IsNullOrWhiteSpace(value) ? DBNull.Value : value.Trim();
    private static object Db(object? value) => value ?? DBNull.Value;
    private static long? Long(SqlDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetInt64(ordinal);
    }
    private static SqlCommand Procedure(SqlConnection connection, string name) =>
        new(name, connection) { CommandType = CommandType.StoredProcedure };
}

using System.Data;
using Microsoft.Data.SqlClient;
using TransPort.Api.Configuration;
using TransPort.Api.Modules.Comercial.DTOs;
using TransPort.Api.Modules.Shared.DTOs;
using TransPort.Api.Modules.Shared.Repositories;

namespace TransPort.Api.Modules.Comercial.Repositories;

public sealed class PedidoRepository(ISqlConnectionFactory connections) : IPedidoRepository
{
    public async Task<IReadOnlyList<PedidoListadoDto>> ListarAsync(
        string? busqueda, string? estado, int? clienteId, int? giroId,
        AlcancePedido alcance, CancellationToken ct)
    {
        var result = new List<PedidoListadoDto>();
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_pedido_leer_listado");
        Alcance(command, alcance);
        command.Parameters.Add("@Busqueda", SqlDbType.NVarChar, 200).Value = Db(Limpiar(busqueda));
        command.Parameters.Add("@Estado", SqlDbType.NVarChar, 30).Value = Db(Limpiar(estado));
        command.Parameters.Add("@ClienteId", SqlDbType.Int).Value = Db(clienteId);
        command.Parameters.Add("@GiroNegocioId", SqlDbType.Int).Value = Db(giroId);
        await using var reader = await command.ExecuteReaderAsync(ct);
        while (await reader.ReadAsync(ct))
            result.Add(new PedidoListadoDto(
                reader.Int64("PedidoId"), reader.Int32("ClienteId"), reader.Text("Cliente"),
                reader.Int32("GiroNegocioId"), reader.Text("Giro"), reader.Text("TipoSolicitud"),
                reader.Text("Titulo"), reader.Text("Estado"), reader.NullableDate("FechaRequerida"),
                Decimal(reader, "MontoCotizado"), reader.NullableInt32("VendedorUsuarioId"),
                reader.NullableText("Vendedor"), reader.Date("FechaCreacion"), reader.NullableDate("FechaModificacion")));
        return result;
    }

    public async Task<PedidoDetalleDto?> ObtenerAsync(long id, AlcancePedido alcance, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_pedido_leer_por_id");
        command.Parameters.Add("@PedidoId", SqlDbType.BigInt).Value = id;
        Alcance(command, alcance);
        await using var reader = await command.ExecuteReaderAsync(ct);
        if (!await reader.ReadAsync(ct)) return null;
        var pedido = new PedidoDetalleDto(
            reader.Int64("PedidoId"), reader.Int32("ClienteId"), reader.Text("Cliente"),
            reader.Int32("GiroNegocioId"), reader.Text("Giro"), reader.Int32("SolicitanteUsuarioId"),
            reader.Text("Solicitante"), reader.NullableInt32("VendedorUsuarioId"), reader.NullableText("Vendedor"),
            reader.Text("TipoSolicitud"), reader.Text("Titulo"), reader.Text("Descripcion"), reader.Text("Estado"),
            reader.NullableDate("FechaRequerida"), Decimal(reader, "MontoCotizado"),
            reader.NullableDate("FechaReunionUtc"), reader.NullableText("EnlaceReunion"),
            reader.Date("FechaCreacion"), reader.NullableDate("FechaModificacion"), [], []);

        var historial = new List<PedidoHistorialDto>();
        if (await reader.NextResultAsync(ct))
            while (await reader.ReadAsync(ct))
                historial.Add(new PedidoHistorialDto(
                    reader.Int64("PedidoHistorialId"), reader.Int32("UsuarioId"), reader.Text("NombreUsuario"),
                    reader.NullableText("EstadoAnterior"), reader.Text("EstadoNuevo"), reader.NullableText("Comentario"), reader.Date("Fecha")));

        var documentos = new List<PedidoDocumentoDto>();
        if (await reader.NextResultAsync(ct))
            while (await reader.ReadAsync(ct))
                documentos.Add(new PedidoDocumentoDto(
                    reader.Int64("PedidoDocumentoId"), reader.Int32("UsuarioId"), reader.Text("NombreUsuario"),
                    reader.Text("Nombre"), reader.Text("TipoDocumento"), reader.Text("Url"), reader.Date("FechaCreacion")));
        return pedido with { Historial = historial, Documentos = documentos };
    }

    public async Task<PedidoOpcionesDto> OpcionesAsync(AlcancePedido alcance, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_pedido_leer_opciones");
        Alcance(command, alcance);
        await using var reader = await command.ExecuteReaderAsync(ct);
        var clientes = await CatalogosAsync(reader, ct);
        var giros = await reader.NextResultAsync(ct) ? await CatalogosAsync(reader, ct) : [];
        var vendedores = await reader.NextResultAsync(ct) ? await CatalogosAsync(reader, ct) : [];
        return new PedidoOpcionesDto(clientes, giros, vendedores);
    }

    public async Task<long> CrearAsync(CrearPedidoRequest request, AlcancePedido alcance, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_pedido_crear_registro");
        command.Parameters.Add("@ClienteId", SqlDbType.Int).Value = request.ClienteId;
        command.Parameters.Add("@GiroNegocioId", SqlDbType.Int).Value = request.GiroNegocioId;
        command.Parameters.Add("@TipoSolicitud", SqlDbType.NVarChar, 30).Value = request.TipoSolicitud.Trim();
        command.Parameters.Add("@Titulo", SqlDbType.NVarChar, 180).Value = request.Titulo.Trim();
        command.Parameters.Add("@Descripcion", SqlDbType.NVarChar, 2000).Value = request.Descripcion.Trim();
        command.Parameters.Add("@FechaRequerida", SqlDbType.Date).Value = Db(request.FechaRequerida?.Date);
        command.Parameters.Add("@FechaReunionUtc", SqlDbType.DateTime2).Value = Db(request.FechaReunionUtc);
        Alcance(command, alcance);
        return Convert.ToInt64(await command.ExecuteScalarAsync(ct));
    }

    public async Task<bool> GestionarAsync(
        long id, GestionPedidoRequest request, AlcancePedido alcance, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_pedido_actualizar_gestion");
        command.Parameters.Add("@PedidoId", SqlDbType.BigInt).Value = id;
        command.Parameters.Add("@Estado", SqlDbType.NVarChar, 30).Value = request.Estado.Trim();
        command.Parameters.Add("@VendedorUsuarioId", SqlDbType.Int).Value = Db(request.VendedorUsuarioId);
        command.Parameters.Add("@MontoCotizado", SqlDbType.Decimal).Value = Db(request.MontoCotizado);
        command.Parameters["@MontoCotizado"].Precision = 18;
        command.Parameters["@MontoCotizado"].Scale = 2;
        command.Parameters.Add("@FechaReunionUtc", SqlDbType.DateTime2).Value = Db(request.FechaReunionUtc);
        command.Parameters.Add("@EnlaceReunion", SqlDbType.NVarChar, 500).Value = Db(Limpiar(request.EnlaceReunion));
        command.Parameters.Add("@Comentario", SqlDbType.NVarChar, 1000).Value = Db(Limpiar(request.Comentario));
        command.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = alcance.UsuarioId;
        command.Parameters.Add("@EsAdministrador", SqlDbType.Bit).Value = alcance.EsAdministrador;
        return Convert.ToInt32(await command.ExecuteScalarAsync(ct)) > 0;
    }

    public Task ComentarAsync(long id, AgregarComentarioPedidoRequest request, AlcancePedido alcance, CancellationToken ct) =>
        EjecutarAccionAsync("sp_pedido_agregar_comentario", id, alcance, ct, command =>
            command.Parameters.Add("@Comentario", SqlDbType.NVarChar, 1000).Value = request.Comentario.Trim());

    public async Task<long> AgregarDocumentoAsync(
        long id, AgregarDocumentoPedidoRequest request, AlcancePedido alcance, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_pedido_agregar_documento");
        command.Parameters.Add("@PedidoId", SqlDbType.BigInt).Value = id;
        command.Parameters.Add("@Nombre", SqlDbType.NVarChar, 200).Value = request.Nombre.Trim();
        command.Parameters.Add("@TipoDocumento", SqlDbType.NVarChar, 60).Value = request.TipoDocumento.Trim();
        command.Parameters.Add("@Url", SqlDbType.NVarChar, 1000).Value = request.Url.Trim();
        Alcance(command, alcance);
        return Convert.ToInt64(await command.ExecuteScalarAsync(ct));
    }

    public async Task<bool> EliminarAsync(long id, int usuarioId, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_pedido_eliminar_logico");
        command.Parameters.Add("@PedidoId", SqlDbType.BigInt).Value = id;
        command.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = usuarioId;
        return Convert.ToInt32(await command.ExecuteScalarAsync(ct)) > 0;
    }

    private async Task EjecutarAccionAsync(
        string procedure, long id, AlcancePedido alcance, CancellationToken ct, Action<SqlCommand> parametros)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, procedure);
        command.Parameters.Add("@PedidoId", SqlDbType.BigInt).Value = id;
        parametros(command);
        Alcance(command, alcance);
        await command.ExecuteNonQueryAsync(ct);
    }

    private static async Task<IReadOnlyList<CatalogoDto>> CatalogosAsync(SqlDataReader reader, CancellationToken ct)
    {
        var result = new List<CatalogoDto>();
        while (await reader.ReadAsync(ct)) result.Add(new CatalogoDto(reader.Int32("Id"), reader.Text("Nombre")));
        return result;
    }

    private static void Alcance(SqlCommand command, AlcancePedido alcance)
    {
        command.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = alcance.UsuarioId;
        command.Parameters.Add("@EsAdministrador", SqlDbType.Bit).Value = alcance.EsAdministrador;
        command.Parameters.Add("@EsCliente", SqlDbType.Bit).Value = alcance.EsCliente;
    }

    private static decimal? Decimal(SqlDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetDecimal(ordinal);
    }

    private static SqlCommand Procedure(SqlConnection connection, string name) =>
        new(name, connection) { CommandType = CommandType.StoredProcedure };
    private static string? Limpiar(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    private static object Db(object? value) => value ?? DBNull.Value;
}

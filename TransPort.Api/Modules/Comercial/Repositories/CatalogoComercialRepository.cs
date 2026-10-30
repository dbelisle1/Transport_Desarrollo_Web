using System.Data;
using Microsoft.Data.SqlClient;
using TransPort.Api.Configuration;
using TransPort.Api.Modules.Comercial.DTOs;
using TransPort.Api.Modules.Shared.DTOs;
using TransPort.Api.Modules.Shared.Repositories;

namespace TransPort.Api.Modules.Comercial.Repositories;

public sealed class CatalogoComercialRepository(ISqlConnectionFactory connections) : ICatalogoComercialRepository
{
    public Task<IReadOnlyList<OfertaCatalogoDto>> ListarPublicoAsync(int? giroId, string? tipo, CancellationToken ct) =>
        ListarConProcedimientoAsync("sp_catalogocomercial_leer_publico", ct, command =>
        {
            command.Parameters.Add("@GiroNegocioId", SqlDbType.Int).Value = Db(giroId);
            Texto(command, "@Tipo", 20, tipo);
        });

    public Task<IReadOnlyList<OfertaCatalogoDto>> ListarAsync(
        string? busqueda, int? giroId, string? tipo, bool? esActivo,
        AlcanceCatalogoComercial alcance, CancellationToken ct) =>
        ListarConProcedimientoAsync("sp_catalogocomercial_leer_listado", ct, command =>
        {
            Alcance(command, alcance);
            Texto(command, "@Busqueda", 200, busqueda);
            command.Parameters.Add("@GiroNegocioId", SqlDbType.Int).Value = Db(giroId);
            Texto(command, "@Tipo", 20, tipo);
            command.Parameters.Add("@EsActivo", SqlDbType.Bit).Value = Db(esActivo);
        });

    public async Task<CatalogoComercialOpcionesDto> OpcionesAsync(
        AlcanceCatalogoComercial alcance, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_catalogocomercial_leer_opciones");
        Alcance(command, alcance);
        await using var reader = await command.ExecuteReaderAsync(ct);
        var giros = new List<CatalogoDto>();
        while (await reader.ReadAsync(ct)) giros.Add(new CatalogoDto(reader.Int32("Id"), reader.Text("Nombre")));
        return new CatalogoComercialOpcionesDto(giros);
    }

    public async Task<int> CrearAsync(
        GuardarOfertaCatalogoRequest request, AlcanceCatalogoComercial alcance, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_catalogocomercial_crear");
        Guardar(command, request);
        Alcance(command, alcance);
        return Convert.ToInt32(await command.ExecuteScalarAsync(ct));
    }

    public async Task<bool> ActualizarAsync(
        int id, GuardarOfertaCatalogoRequest request, AlcanceCatalogoComercial alcance, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_catalogocomercial_actualizar");
        command.Parameters.Add("@CatalogoOfertaId", SqlDbType.Int).Value = id;
        Guardar(command, request);
        Alcance(command, alcance);
        return Convert.ToInt32(await command.ExecuteScalarAsync(ct)) > 0;
    }

    public async Task<bool> EliminarAsync(int id, AlcanceCatalogoComercial alcance, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_catalogocomercial_eliminar");
        command.Parameters.Add("@CatalogoOfertaId", SqlDbType.Int).Value = id;
        Alcance(command, alcance);
        return Convert.ToInt32(await command.ExecuteScalarAsync(ct)) > 0;
    }

    private async Task<IReadOnlyList<OfertaCatalogoDto>> ListarConProcedimientoAsync(
        string procedure, CancellationToken ct, Action<SqlCommand> parameters)
    {
        var result = new List<OfertaCatalogoDto>();
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, procedure);
        parameters(command);
        await using var reader = await command.ExecuteReaderAsync(ct);
        while (await reader.ReadAsync(ct))
            result.Add(new OfertaCatalogoDto(
                reader.Int32("CatalogoOfertaId"), reader.Int32("GiroNegocioId"), reader.Text("Giro"),
                reader.Text("Codigo"), reader.Text("Tipo"), reader.Text("Nombre"), reader.Text("Descripcion"),
                reader.Text("UnidadMedida"), reader.GetDecimal(reader.GetOrdinal("PrecioBase")),
                reader.GetBoolean(reader.GetOrdinal("EsPublico")), reader.GetBoolean(reader.GetOrdinal("EsActivo")),
                reader.Date("FechaCreacion"), reader.NullableDate("FechaModificacion")));
        return result;
    }

    private static void Guardar(SqlCommand command, GuardarOfertaCatalogoRequest request)
    {
        command.Parameters.Add("@GiroNegocioId", SqlDbType.Int).Value = request.GiroNegocioId;
        Texto(command, "@Codigo", 50, request.Codigo);
        Texto(command, "@Tipo", 20, request.Tipo);
        Texto(command, "@Nombre", 180, request.Nombre);
        Texto(command, "@Descripcion", 1000, request.Descripcion);
        Texto(command, "@UnidadMedida", 40, request.UnidadMedida);
        var price = command.Parameters.Add("@PrecioBase", SqlDbType.Decimal);
        price.Precision = 18;
        price.Scale = 2;
        price.Value = request.PrecioBase;
        command.Parameters.Add("@EsPublico", SqlDbType.Bit).Value = request.EsPublico;
        command.Parameters.Add("@EsActivo", SqlDbType.Bit).Value = request.EsActivo;
    }

    private static void Alcance(SqlCommand command, AlcanceCatalogoComercial alcance)
    {
        command.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = alcance.UsuarioId;
        command.Parameters.Add("@EsAdministrador", SqlDbType.Bit).Value = alcance.EsAdministrador;
    }

    private static void Texto(SqlCommand command, string name, int size, string? value) =>
        command.Parameters.Add(name, SqlDbType.NVarChar, size).Value =
            string.IsNullOrWhiteSpace(value) ? DBNull.Value : value.Trim();
    private static object Db(object? value) => value ?? DBNull.Value;
    private static SqlCommand Procedure(SqlConnection connection, string name) =>
        new(name, connection) { CommandType = CommandType.StoredProcedure };
}

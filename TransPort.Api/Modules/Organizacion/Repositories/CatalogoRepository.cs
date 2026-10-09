using System.Data;
using Microsoft.Data.SqlClient;
using TransPort.Api.Configuration;
using TransPort.Api.Modules.Shared.DTOs;
using TransPort.Api.Modules.Shared.Repositories;

namespace TransPort.Api.Modules.Organizacion.Repositories;

public sealed class CatalogoRepository(ISqlConnectionFactory connections) : ICatalogoRepository
{
    private static readonly IReadOnlyDictionary<string, (string Prefijo, string Id)> Tipos =
        new Dictionary<string, (string, string)>(StringComparer.OrdinalIgnoreCase)
        {
            ["roles"] = ("rol", "RolId"),
            ["giros"] = ("gironegocio", "GiroNegocioId"),
            ["sedes"] = ("sede", "SedeId")
        };

    public async Task<IReadOnlyList<EntidadCatalogoDto>> ListarAsync(string tipo, CancellationToken ct)
    {
        var meta = Meta(tipo);
        var result = new List<EntidadCatalogoDto>();
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, $"sp_{meta.Prefijo}_leer_listado");
        await using var reader = await command.ExecuteReaderAsync(ct);
        while (await reader.ReadAsync(ct)) result.Add(Map(reader, meta.Id));
        return result;
    }

    public async Task<EntidadCatalogoDto?> ObtenerAsync(string tipo, int id, CancellationToken ct)
    {
        var meta = Meta(tipo);
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, $"sp_{meta.Prefijo}_leer_por_id");
        command.Parameters.Add($"@{meta.Id}", SqlDbType.Int).Value = id;
        await using var reader = await command.ExecuteReaderAsync(ct);
        return await reader.ReadAsync(ct) ? Map(reader, meta.Id) : null;
    }

    public async Task<int> CrearAsync(string tipo, GuardarCatalogoRequest request, int responsableId, CancellationToken ct)
    {
        var meta = Meta(tipo);
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, $"sp_{meta.Prefijo}_crear_registro");
        AddValues(command, request, responsableId);
        return Convert.ToInt32(await command.ExecuteScalarAsync(ct));
    }

    public async Task<bool> ActualizarAsync(
        string tipo, int id, GuardarCatalogoRequest request, int responsableId, CancellationToken ct)
    {
        var meta = Meta(tipo);
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, $"sp_{meta.Prefijo}_actualizar_datos");
        command.Parameters.Add($"@{meta.Id}", SqlDbType.Int).Value = id;
        AddValues(command, request, responsableId);
        return Convert.ToInt32(await command.ExecuteScalarAsync(ct)) > 0;
    }

    public async Task<bool> EliminarAsync(string tipo, int id, int responsableId, CancellationToken ct)
    {
        var meta = Meta(tipo);
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, $"sp_{meta.Prefijo}_eliminar_logico");
        command.Parameters.Add($"@{meta.Id}", SqlDbType.Int).Value = id;
        command.Parameters.Add("@UsuarioResponsableId", SqlDbType.Int).Value = responsableId;
        return Convert.ToInt32(await command.ExecuteScalarAsync(ct)) > 0;
    }

    private static (string Prefijo, string Id) Meta(string tipo) =>
        Tipos.TryGetValue(tipo, out var value) ? value : throw new ArgumentOutOfRangeException(nameof(tipo));

    private static EntidadCatalogoDto Map(System.Data.Common.DbDataReader reader, string id) =>
        new(reader.Int32(id), reader.Text("Nombre"), reader.NullableText("Descripcion"),
            reader.Bool("EsActivo"), reader.Date("FechaCreacion"));

    private static void AddValues(SqlCommand command, GuardarCatalogoRequest request, int responsableId)
    {
        command.Parameters.Add("@Nombre", SqlDbType.NVarChar, 120).Value = request.Nombre.Trim();
        command.Parameters.Add("@Descripcion", SqlDbType.NVarChar, 500).Value = (object?)request.Descripcion?.Trim() ?? DBNull.Value;
        command.Parameters.Add("@EsActivo", SqlDbType.Bit).Value = request.EsActivo;
        command.Parameters.Add("@UsuarioResponsableId", SqlDbType.Int).Value = responsableId;
    }

    private static SqlCommand Procedure(SqlConnection connection, string name) =>
        new(name, connection) { CommandType = CommandType.StoredProcedure };
}

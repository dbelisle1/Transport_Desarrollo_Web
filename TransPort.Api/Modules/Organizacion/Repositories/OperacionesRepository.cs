using System.Data;
using Microsoft.Data.SqlClient;
using TransPort.Api.Configuration;
using TransPort.Api.Modules.Organizacion.DTOs;
using TransPort.Api.Modules.Shared.Repositories;

namespace TransPort.Api.Modules.Organizacion.Repositories;

public sealed class OperacionesRepository(ISqlConnectionFactory connections) : IOperacionesRepository
{
    public async Task<DashboardDto> ObtenerResumenAsync(CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_dashboard_leer_resumen");
        await using var reader = await command.ExecuteReaderAsync(ct);
        if (!await reader.ReadAsync(ct)) return new DashboardDto(0, 0, 0, 0);
        return new DashboardDto(
            reader.Int32("Usuarios"), reader.Int32("Clientes"), reader.Int32("Giros"), reader.Int32("Sedes"));
    }

    public async Task CrearAuditoriaAsync(CrearAuditoriaDto evento, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_auditoria_crear_evento");
        command.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = Db(evento.UsuarioId);
        command.Parameters.Add("@Modulo", SqlDbType.NVarChar, 80).Value = evento.Modulo;
        command.Parameters.Add("@TipoOperacion", SqlDbType.NVarChar, 80).Value = evento.TipoOperacion;
        command.Parameters.Add("@IdentificadorRegistro", SqlDbType.NVarChar, 100).Value = Db(evento.IdentificadorRegistro);
        command.Parameters.Add("@Resultado", SqlDbType.NVarChar, 40).Value = evento.Resultado;
        command.Parameters.Add("@Detalle", SqlDbType.NVarChar, 1000).Value = Db(evento.Detalle);
        await command.ExecuteNonQueryAsync(ct);
    }

    public async Task<IReadOnlyList<AuditoriaDto>> ListarAuditoriaAsync(int cantidad, CancellationToken ct)
    {
        var result = new List<AuditoriaDto>();
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_auditoria_leer_listado");
        command.Parameters.Add("@Cantidad", SqlDbType.Int).Value = Math.Clamp(cantidad, 1, 500);
        await using var reader = await command.ExecuteReaderAsync(ct);
        while (await reader.ReadAsync(ct))
        {
            result.Add(new AuditoriaDto(
                reader.Int64("AuditoriaId"), reader.NullableInt32("UsuarioId"), reader.NullableText("NombreUsuario"),
                reader.Date("Fecha"), reader.Text("Modulo"), reader.Text("TipoOperacion"),
                reader.NullableText("IdentificadorRegistro"), reader.Text("Resultado"), reader.NullableText("Detalle")));
        }
        return result;
    }

    private static SqlCommand Procedure(SqlConnection connection, string name) =>
        new(name, connection) { CommandType = CommandType.StoredProcedure };
    private static object Db(object? value) => value ?? DBNull.Value;
}

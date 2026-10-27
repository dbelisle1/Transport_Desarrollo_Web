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

    public async Task<AuditoriaPaginaDto> ListarAuditoriaAsync(AuditoriaConsultaDto consulta, CancellationToken ct)
    {
        var pagina = Math.Max(consulta.Pagina, 1);
        var tamanoPagina = Math.Clamp(consulta.TamanoPagina, 10, 100);
        var result = new List<AuditoriaDto>();
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = Procedure(connection, "sp_auditoria_leer_listado");
        command.Parameters.Add("@Busqueda", SqlDbType.NVarChar, 200).Value = Db(Text(consulta.Busqueda));
        command.Parameters.Add("@FechaDesdeUtc", SqlDbType.DateTime2).Value = Db(consulta.FechaDesdeUtc);
        command.Parameters.Add("@FechaHastaUtc", SqlDbType.DateTime2).Value = Db(consulta.FechaHastaUtc);
        command.Parameters.Add("@Modulo", SqlDbType.NVarChar, 80).Value = Db(Text(consulta.Modulo));
        command.Parameters.Add("@TipoOperacion", SqlDbType.NVarChar, 80).Value = Db(Text(consulta.TipoOperacion));
        command.Parameters.Add("@NombreUsuario", SqlDbType.NVarChar, 80).Value = Db(Text(consulta.NombreUsuario));
        command.Parameters.Add("@Resultado", SqlDbType.NVarChar, 40).Value = Db(Text(consulta.Resultado));
        command.Parameters.Add("@Pagina", SqlDbType.Int).Value = pagina;
        command.Parameters.Add("@TamanoPagina", SqlDbType.Int).Value = tamanoPagina;
        await using var reader = await command.ExecuteReaderAsync(ct);
        var totalRegistros = await reader.ReadAsync(ct) ? reader.GetInt64(reader.GetOrdinal("TotalRegistros")) : 0L;
        await reader.NextResultAsync(ct);
        while (await reader.ReadAsync(ct))
        {
            result.Add(new AuditoriaDto(
                reader.Int64("AuditoriaId"), reader.NullableInt32("UsuarioId"), reader.NullableText("NombreUsuario"),
                reader.Date("Fecha"), reader.Text("Modulo"), reader.Text("TipoOperacion"),
                reader.NullableText("IdentificadorRegistro"), reader.Text("Resultado"), reader.NullableText("Detalle")));
        }
        return new AuditoriaPaginaDto(result, totalRegistros, pagina, tamanoPagina);
    }

    private static SqlCommand Procedure(SqlConnection connection, string name) =>
        new(name, connection) { CommandType = CommandType.StoredProcedure };
    private static object Db(object? value) => value ?? DBNull.Value;
    private static string? Text(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}

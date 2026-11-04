using System.Data;
using Microsoft.Data.SqlClient;
using TransPort.Api.Configuration;
using TransPort.Api.Modules.Extraccion.DTOs;
using TransPort.Api.Modules.Shared.DTOs;
using TransPort.Api.Modules.Shared.Repositories;

namespace TransPort.Api.Modules.Extraccion.Repositories;

public sealed class ExtraccionRepository(ISqlConnectionFactory connections) : IExtraccionRepository
{
    public async Task<IReadOnlyList<ExtraccionListadoDto>> ListarAsync(string? estado, int? sedeId, DateTime? fechaDesde, DateTime? fechaHasta, AlcanceExtraccion a, CancellationToken ct)
    {
        var items = new List<ExtraccionListadoDto>();
        await using var cn = connections.Create(); await cn.OpenAsync(ct);
        await using var c = Procedure(cn, "sp_extraccion_leer_listado"); Scope(c, a);
        c.Parameters.Add("@Estado", SqlDbType.NVarChar, 30).Value = Db(Text(estado));
        c.Parameters.Add("@SedeId", SqlDbType.Int).Value = Db(sedeId);
        c.Parameters.Add("@FechaDesde", SqlDbType.Date).Value = Db(fechaDesde?.Date);
        c.Parameters.Add("@FechaHasta", SqlDbType.Date).Value = Db(fechaHasta?.Date);
        await using var r = await c.ExecuteReaderAsync(ct);
        while (await r.ReadAsync(ct)) items.Add(MapListado(r));
        return items;
    }

    public async Task<ExtraccionDetalleDto?> ObtenerAsync(long id, AlcanceExtraccion a, CancellationToken ct)
    {
        await using var cn = connections.Create(); await cn.OpenAsync(ct);
        await using var c = Procedure(cn, "sp_extraccion_leer_por_id");
        c.Parameters.Add("@Id", SqlDbType.BigInt).Value = id; Scope(c, a);
        await using var r = await c.ExecuteReaderAsync(ct);
        if (!await r.ReadAsync(ct)) return null;
        var item = new ExtraccionDetalleDto(r.Int64("ExtraccionJornadaId"), r.Int32("SedeId"), r.Text("Sede"), r.Int32("InventarioArticuloId"), r.Text("Codigo"), r.Text("Articulo"), r.Text("UnidadMedida"), r.Date("FechaOperacion"), r.Text("Turno"), r.Text("FrenteExtraccion"), Decimal(r, "CantidadExtraida"), Decimal(r, "CantidadRechazada"), Decimal(r, "CantidadAprovechable"), r.Text("DestinoTipo"), r.NullableText("DestinoDescripcion"), r.Text("Estado"), r.Int32("ResponsableUsuarioId"), r.Text("Responsable"), r.NullableText("Observacion"), r.Date("FechaCreacion"), r.NullableDate("FechaModificacion"), []);
        var history = new List<ExtraccionHistorialDto>();
        if (await r.NextResultAsync(ct)) while (await r.ReadAsync(ct)) history.Add(new(r.Int64("ExtraccionHistorialId"), r.Int32("UsuarioId"), r.Text("NombreUsuario"), r.NullableText("EstadoAnterior"), r.Text("EstadoNuevo"), r.NullableText("Comentario"), r.Date("Fecha")));
        return item with { Historial = history };
    }

    public async Task<ExtraccionOpcionesDto> OpcionesAsync(AlcanceExtraccion a, CancellationToken ct)
    {
        await using var cn = connections.Create(); await cn.OpenAsync(ct);
        await using var c = Procedure(cn, "sp_extraccion_leer_opciones"); Scope(c, a);
        await using var r = await c.ExecuteReaderAsync(ct);
        var sedes = await Catalogos(r, ct);
        var articulos = await r.NextResultAsync(ct) ? await Catalogos(r, ct) : [];
        return new(sedes, articulos);
    }

    public async Task<long> CrearAsync(CrearExtraccionRequest x, AlcanceExtraccion a, CancellationToken ct)
    {
        await using var cn = connections.Create(); await cn.OpenAsync(ct);
        await using var c = Procedure(cn, "sp_extraccion_crear");
        c.Parameters.Add("@SedeId", SqlDbType.Int).Value = x.SedeId;
        c.Parameters.Add("@InventarioArticuloId", SqlDbType.Int).Value = x.InventarioArticuloId;
        c.Parameters.Add("@FechaOperacion", SqlDbType.Date).Value = x.FechaOperacion.Date;
        c.Parameters.Add("@Turno", SqlDbType.NVarChar, 30).Value = x.Turno.Trim();
        c.Parameters.Add("@FrenteExtraccion", SqlDbType.NVarChar, 120).Value = x.FrenteExtraccion.Trim();
        AddDecimal(c, "@CantidadExtraida", x.CantidadExtraida); AddDecimal(c, "@CantidadRechazada", x.CantidadRechazada);
        c.Parameters.Add("@DestinoTipo", SqlDbType.NVarChar, 30).Value = x.DestinoTipo.Trim();
        c.Parameters.Add("@DestinoDescripcion", SqlDbType.NVarChar, 200).Value = Db(Text(x.DestinoDescripcion));
        c.Parameters.Add("@Observacion", SqlDbType.NVarChar, 500).Value = Db(Text(x.Observacion)); Scope(c, a);
        return Convert.ToInt64(await c.ExecuteScalarAsync(ct));
    }

    public async Task<bool> CambiarEstadoAsync(long id, CambiarEstadoExtraccionRequest x, AlcanceExtraccion a, CancellationToken ct)
    {
        await using var cn = connections.Create(); await cn.OpenAsync(ct);
        await using var c = Procedure(cn, "sp_extraccion_actualizar_estado");
        c.Parameters.Add("@Id", SqlDbType.BigInt).Value = id;
        c.Parameters.Add("@Estado", SqlDbType.NVarChar, 30).Value = x.Estado.Trim();
        c.Parameters.Add("@Comentario", SqlDbType.NVarChar, 500).Value = Db(Text(x.Comentario)); Scope(c, a);
        return Convert.ToInt32(await c.ExecuteScalarAsync(ct)) > 0;
    }

    public async Task<bool> EliminarAsync(long id, int usuarioId, CancellationToken ct)
    {
        await using var cn = connections.Create(); await cn.OpenAsync(ct);
        await using var c = Procedure(cn, "sp_extraccion_eliminar");
        c.Parameters.Add("@Id", SqlDbType.BigInt).Value = id; c.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = usuarioId;
        return Convert.ToInt32(await c.ExecuteScalarAsync(ct)) > 0;
    }

    private static ExtraccionListadoDto MapListado(SqlDataReader r) => new(r.Int64("ExtraccionJornadaId"), r.Int32("SedeId"), r.Text("Sede"), r.Int32("InventarioArticuloId"), r.Text("Codigo"), r.Text("Articulo"), r.Text("UnidadMedida"), r.Date("FechaOperacion"), r.Text("Turno"), r.Text("FrenteExtraccion"), Decimal(r, "CantidadExtraida"), Decimal(r, "CantidadRechazada"), Decimal(r, "CantidadAprovechable"), r.Text("DestinoTipo"), r.NullableText("DestinoDescripcion"), r.Text("Estado"), r.Text("Responsable"), r.Date("FechaCreacion"));
    private static async Task<IReadOnlyList<CatalogoDto>> Catalogos(SqlDataReader r, CancellationToken ct) { var x = new List<CatalogoDto>(); while (await r.ReadAsync(ct)) x.Add(new(r.Int32("Id"), r.Text("Nombre"))); return x; }
    private static void Scope(SqlCommand c, AlcanceExtraccion a) { c.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = a.UsuarioId; c.Parameters.Add("@EsAdministrador", SqlDbType.Bit).Value = a.EsAdministrador; }
    private static void AddDecimal(SqlCommand c, string name, decimal value) { var p = c.Parameters.Add(name, SqlDbType.Decimal); p.Precision = 18; p.Scale = 3; p.Value = value; }
    private static SqlCommand Procedure(SqlConnection c, string name) => new(name, c) { CommandType = CommandType.StoredProcedure };
    private static object Db(object? value) => value ?? DBNull.Value;
    private static string? Text(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    private static decimal Decimal(SqlDataReader r, string name) => r.GetDecimal(r.GetOrdinal(name));
}

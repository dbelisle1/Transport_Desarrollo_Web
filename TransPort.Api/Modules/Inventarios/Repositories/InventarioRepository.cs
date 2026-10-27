using System.Data;
using Microsoft.Data.SqlClient;
using TransPort.Api.Configuration;
using TransPort.Api.Modules.Inventarios.DTOs;
using TransPort.Api.Modules.Shared.DTOs;
using TransPort.Api.Modules.Shared.Repositories;

namespace TransPort.Api.Modules.Inventarios.Repositories;

public sealed class InventarioRepository(ISqlConnectionFactory connections):IInventarioRepository
{
    public async Task<IReadOnlyList<InventarioExistenciaDto>> ListarAsync(string? busqueda,int? giroId,int? sedeId,bool soloBajoMinimo,AlcanceInventario alcance,CancellationToken ct)
    {
        var result=new List<InventarioExistenciaDto>();
        await using var cn=connections.Create();await cn.OpenAsync(ct);
        await using var cmd=Procedure(cn,"sp_inventario_leer_listado");Scope(cmd,alcance);
        cmd.Parameters.Add("@Busqueda",SqlDbType.NVarChar,200).Value=Db(Text(busqueda));
        cmd.Parameters.Add("@GiroNegocioId",SqlDbType.Int).Value=Db(giroId);
        cmd.Parameters.Add("@SedeId",SqlDbType.Int).Value=Db(sedeId);
        cmd.Parameters.Add("@SoloBajoMinimo",SqlDbType.Bit).Value=soloBajoMinimo;
        await using var r=await cmd.ExecuteReaderAsync(ct);
        while(await r.ReadAsync(ct))result.Add(new InventarioExistenciaDto(
            r.Int32("InventarioArticuloId"),r.Text("Codigo"),r.Text("Nombre"),r.Text("Categoria"),r.Text("UnidadMedida"),
            r.Int32("GiroNegocioId"),r.Text("Giro"),Dec(r,"StockMinimo"),r.NullableInt32("SedeId"),r.NullableText("Sede"),
            Dec(r,"Cantidad"),Dec(r,"CantidadReservada"),Dec(r,"CantidadDisponible"),r.Bool("BajoMinimo")));
        return result;
    }

    public async Task<IReadOnlyList<InventarioMovimientoDto>> MovimientosAsync(int? articuloId,int limite,AlcanceInventario alcance,CancellationToken ct)
    {
        var result=new List<InventarioMovimientoDto>();
        await using var cn=connections.Create();await cn.OpenAsync(ct);
        await using var cmd=Procedure(cn,"sp_inventario_leer_movimientos");Scope(cmd,alcance);
        cmd.Parameters.Add("@InventarioArticuloId",SqlDbType.Int).Value=Db(articuloId);
        cmd.Parameters.Add("@Limite",SqlDbType.Int).Value=Math.Clamp(limite,1,500);
        await using var r=await cmd.ExecuteReaderAsync(ct);
        while(await r.ReadAsync(ct))result.Add(new InventarioMovimientoDto(
            r.Int64("InventarioMovimientoId"),r.Int32("InventarioArticuloId"),r.Text("Codigo"),r.Text("Articulo"),r.Text("Tipo"),
            r.NullableInt32("SedeOrigenId"),r.NullableText("SedeOrigen"),r.NullableInt32("SedeDestinoId"),r.NullableText("SedeDestino"),
            Dec(r,"Cantidad"),r.Text("UnidadMedida"),r.NullableText("Referencia"),r.NullableText("Observacion"),r.Int32("UsuarioId"),r.Text("NombreUsuario"),r.Date("Fecha")));
        return result;
    }

    public async Task<InventarioOpcionesDto> OpcionesAsync(AlcanceInventario alcance,CancellationToken ct)
    {
        await using var cn=connections.Create();await cn.OpenAsync(ct);
        await using var cmd=Procedure(cn,"sp_inventario_leer_opciones");Scope(cmd,alcance);
        await using var r=await cmd.ExecuteReaderAsync(ct);
        var giros=await Catalogos(r,ct);var sedes=await r.NextResultAsync(ct)?await Catalogos(r,ct):[];var articulos=await r.NextResultAsync(ct)?await Catalogos(r,ct):[];
        return new InventarioOpcionesDto(giros,sedes,articulos);
    }

    public async Task<int> CrearArticuloAsync(CrearInventarioArticuloRequest x,AlcanceInventario alcance,CancellationToken ct)
    {
        await using var cn=connections.Create();await cn.OpenAsync(ct);await using var cmd=Procedure(cn,"sp_inventario_crear_articulo");
        cmd.Parameters.Add("@GiroNegocioId",SqlDbType.Int).Value=x.GiroNegocioId;
        cmd.Parameters.Add("@Codigo",SqlDbType.NVarChar,50).Value=x.Codigo.Trim();cmd.Parameters.Add("@Nombre",SqlDbType.NVarChar,180).Value=x.Nombre.Trim();
        cmd.Parameters.Add("@Categoria",SqlDbType.NVarChar,80).Value=x.Categoria.Trim();cmd.Parameters.Add("@UnidadMedida",SqlDbType.NVarChar,30).Value=x.UnidadMedida.Trim();
        AddDecimal(cmd,"@StockMinimo",x.StockMinimo);Scope(cmd,alcance);return Convert.ToInt32(await cmd.ExecuteScalarAsync(ct));
    }

    public async Task<long> RegistrarMovimientoAsync(RegistrarInventarioMovimientoRequest x,AlcanceInventario alcance,CancellationToken ct)
    {
        await using var cn=connections.Create();await cn.OpenAsync(ct);await using var cmd=Procedure(cn,"sp_inventario_registrar_movimiento");
        cmd.Parameters.Add("@InventarioArticuloId",SqlDbType.Int).Value=x.InventarioArticuloId;cmd.Parameters.Add("@Tipo",SqlDbType.NVarChar,30).Value=x.Tipo.Trim();
        cmd.Parameters.Add("@SedeOrigenId",SqlDbType.Int).Value=Db(x.SedeOrigenId);cmd.Parameters.Add("@SedeDestinoId",SqlDbType.Int).Value=Db(x.SedeDestinoId);
        AddDecimal(cmd,"@Cantidad",x.Cantidad);cmd.Parameters.Add("@Referencia",SqlDbType.NVarChar,120).Value=Db(Text(x.Referencia));cmd.Parameters.Add("@Observacion",SqlDbType.NVarChar,500).Value=Db(Text(x.Observacion));
        Scope(cmd,alcance);return Convert.ToInt64(await cmd.ExecuteScalarAsync(ct));
    }
    public async Task<bool> EliminarArticuloAsync(int id,int usuarioId,CancellationToken ct){await using var cn=connections.Create();await cn.OpenAsync(ct);await using var cmd=Procedure(cn,"sp_inventario_eliminar_articulo");cmd.Parameters.Add("@InventarioArticuloId",SqlDbType.Int).Value=id;cmd.Parameters.Add("@UsuarioId",SqlDbType.Int).Value=usuarioId;return Convert.ToInt32(await cmd.ExecuteScalarAsync(ct))>0;}

    private static async Task<IReadOnlyList<CatalogoDto>> Catalogos(SqlDataReader r,CancellationToken ct){var x=new List<CatalogoDto>();while(await r.ReadAsync(ct))x.Add(new(r.Int32("Id"),r.Text("Nombre")));return x;}
    private static void Scope(SqlCommand c,AlcanceInventario a){c.Parameters.Add("@UsuarioId",SqlDbType.Int).Value=a.UsuarioId;c.Parameters.Add("@EsAdministrador",SqlDbType.Bit).Value=a.EsAdministrador;}
    private static void AddDecimal(SqlCommand c,string n,decimal v){var p=c.Parameters.Add(n,SqlDbType.Decimal);p.Precision=18;p.Scale=3;p.Value=v;}
    private static decimal Dec(SqlDataReader r,string n)=>r.GetDecimal(r.GetOrdinal(n));
    private static SqlCommand Procedure(SqlConnection c,string n)=>new(n,c){CommandType=CommandType.StoredProcedure};
    private static object Db(object? x)=>x??DBNull.Value;private static string? Text(string? x)=>string.IsNullOrWhiteSpace(x)?null:x.Trim();
}

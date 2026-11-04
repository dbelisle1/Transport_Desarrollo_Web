using System.Data;
using Microsoft.Data.SqlClient;
using TransPort.Api.Configuration;
using TransPort.Api.Modules.Integraciones.DTOs;
using TransPort.Api.Modules.Shared.DTOs;
using TransPort.Api.Modules.Shared.Repositories;

namespace TransPort.Api.Modules.Integraciones.Repositories;

public sealed class IntegracionRepository(ISqlConnectionFactory connections):IIntegracionRepository
{
    public async Task<IReadOnlyList<IntegracionListadoDto>> ListarAsync(string?estado,string?canal,string?busqueda,AlcanceIntegracion alcance,CancellationToken ct)
    {
        var result=new List<IntegracionListadoDto>();await using var cn=connections.Create();await cn.OpenAsync(ct);await using var cmd=Procedure(cn,"sp_integraciones_leer_listado");Scope(cmd,alcance);Text(cmd,"@Estado",20,estado);Text(cmd,"@Canal",20,canal);Text(cmd,"@Busqueda",200,busqueda);await using var r=await cmd.ExecuteReaderAsync(ct);
        while(await r.ReadAsync(ct))result.Add(new(r.Int64("IntegracionEventoId"),r.Text("Canal"),r.Text("Direccion"),r.Text("SocioTipo"),r.Text("SocioNombre"),r.Text("Operacion"),r.Text("ClaveIdempotencia"),r.NullableText("DocumentoExterno"),r.Text("Estado"),r.Int32("Intentos"),r.NullableText("Error"),r.NullableInt32("InventarioArticuloId"),r.NullableText("ArticuloCodigo"),r.NullableText("Articulo"),r.NullableInt32("SedeId"),r.NullableText("Sede"),Decimal(r,"Cantidad"),Long(r,"InventarioMovimientoId"),r.Text("NombreUsuario"),r.NullableDate("FechaProcesamiento"),r.Date("FechaCreacion")));
        return result;
    }
    public async Task<IntegracionDetalleDto?> ObtenerAsync(long id,AlcanceIntegracion alcance,CancellationToken ct)
    {
        await using var cn=connections.Create();await cn.OpenAsync(ct);await using var cmd=Procedure(cn,"sp_integraciones_leer_por_id");cmd.Parameters.Add("@Id",SqlDbType.BigInt).Value=id;Scope(cmd,alcance);await using var r=await cmd.ExecuteReaderAsync(ct);if(!await r.ReadAsync(ct))return null;
        return new(r.Int64("IntegracionEventoId"),r.Text("Canal"),r.Text("Direccion"),r.Text("SocioTipo"),r.Text("SocioNombre"),r.Text("Operacion"),r.Text("ClaveIdempotencia"),r.NullableText("DocumentoExterno"),r.Text("Contenido"),r.Text("Estado"),r.Int32("Intentos"),r.NullableText("Error"),r.NullableInt32("InventarioArticuloId"),r.NullableText("ArticuloCodigo"),r.NullableText("Articulo"),r.NullableText("UnidadMedida"),r.NullableInt32("SedeId"),r.NullableText("Sede"),Decimal(r,"Cantidad"),Long(r,"InventarioMovimientoId"),r.Text("NombreUsuario"),r.NullableDate("FechaProcesamiento"),r.Date("FechaCreacion"),r.NullableDate("FechaModificacion"));
    }
    public async Task<IntegracionOpcionesDto> OpcionesAsync(AlcanceIntegracion alcance,CancellationToken ct)
    {
        await using var cn=connections.Create();await cn.OpenAsync(ct);await using var cmd=Procedure(cn,"sp_integraciones_leer_opciones");Scope(cmd,alcance);await using var r=await cmd.ExecuteReaderAsync(ct);var articles=await Catalogs(r,ct);var sites=await r.NextResultAsync(ct)?await Catalogs(r,ct):[];return new(articles,sites);
    }
    public async Task<long> SimularAsync(SimularIntegracionRequest x,AlcanceIntegracion alcance,CancellationToken ct)
    {
        await using var cn=connections.Create();await cn.OpenAsync(ct);await using var cmd=Procedure(cn,"sp_integraciones_simular");Text(cmd,"@Canal",20,x.Canal);Text(cmd,"@Direccion",20,x.Direccion);Text(cmd,"@SocioTipo",20,x.SocioTipo);Text(cmd,"@SocioNombre",180,x.SocioNombre);Text(cmd,"@Operacion",40,x.Operacion);Text(cmd,"@ClaveIdempotencia",120,x.ClaveIdempotencia);Text(cmd,"@DocumentoExterno",120,x.DocumentoExterno);cmd.Parameters.Add("@Contenido",SqlDbType.NVarChar,-1).Value=x.Contenido;cmd.Parameters.Add("@InventarioArticuloId",SqlDbType.Int).Value=Db(x.InventarioArticuloId);cmd.Parameters.Add("@SedeId",SqlDbType.Int).Value=Db(x.SedeId);var q=cmd.Parameters.Add("@Cantidad",SqlDbType.Decimal);q.Precision=18;q.Scale=3;q.Value=Db(x.Cantidad);Scope(cmd,alcance);return Convert.ToInt64(await cmd.ExecuteScalarAsync(ct));
    }
    public async Task<long> ReintentarAsync(long id,AlcanceIntegracion alcance,CancellationToken ct){await using var cn=connections.Create();await cn.OpenAsync(ct);await using var cmd=Procedure(cn,"sp_integraciones_reintentar");cmd.Parameters.Add("@Id",SqlDbType.BigInt).Value=id;Scope(cmd,alcance);return Convert.ToInt64(await cmd.ExecuteScalarAsync(ct));}
    public async Task<bool> EliminarAsync(long id,int usuarioId,CancellationToken ct){await using var cn=connections.Create();await cn.OpenAsync(ct);await using var cmd=Procedure(cn,"sp_integraciones_eliminar");cmd.Parameters.Add("@Id",SqlDbType.BigInt).Value=id;cmd.Parameters.Add("@UsuarioId",SqlDbType.Int).Value=usuarioId;return Convert.ToInt32(await cmd.ExecuteScalarAsync(ct))>0;}
    private static async Task<IReadOnlyList<CatalogoDto>> Catalogs(SqlDataReader r,CancellationToken ct){var x=new List<CatalogoDto>();while(await r.ReadAsync(ct))x.Add(new(r.Int32("Id"),r.Text("Nombre")));return x;}
    private static void Scope(SqlCommand c,AlcanceIntegracion a){c.Parameters.Add("@UsuarioId",SqlDbType.Int).Value=a.UsuarioId;c.Parameters.Add("@EsAdministrador",SqlDbType.Bit).Value=a.EsAdministrador;}
    private static void Text(SqlCommand c,string n,int s,string? v)=>c.Parameters.Add(n,SqlDbType.NVarChar,s).Value=string.IsNullOrWhiteSpace(v)?DBNull.Value:v.Trim();
    private static object Db(object?x)=>x??DBNull.Value;
    private static decimal? Decimal(SqlDataReader r,string n){var i=r.GetOrdinal(n);return r.IsDBNull(i)?null:r.GetDecimal(i);}
    private static long? Long(SqlDataReader r,string n){var i=r.GetOrdinal(n);return r.IsDBNull(i)?null:r.GetInt64(i);}
    private static SqlCommand Procedure(SqlConnection c,string n)=>new(n,c){CommandType=CommandType.StoredProcedure};
}

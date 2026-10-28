using System.Data;
using Microsoft.Data.SqlClient;
using TransPort.Api.Configuration;
using TransPort.Api.Modules.Finanzas.DTOs;
using TransPort.Api.Modules.Shared.DTOs;
using TransPort.Api.Modules.Shared.Repositories;

namespace TransPort.Api.Modules.Finanzas.Repositories;

public sealed class FinanzaRepository(ISqlConnectionFactory connections):IFinanzaRepository
{
    public async Task<IReadOnlyList<PresupuestoListadoDto>> ListarAsync(short? anio,byte? mes,int? giroId,int? sedeId,AlcanceFinanza a,CancellationToken ct)
    {
        var items=new List<PresupuestoListadoDto>();
        await using var cn=connections.Create();await cn.OpenAsync(ct);
        await using var cmd=Proc(cn,"sp_finanzas_leer_presupuestos");Scope(cmd,a);
        cmd.Parameters.Add("@Anio",SqlDbType.SmallInt).Value=Db(anio);cmd.Parameters.Add("@Mes",SqlDbType.TinyInt).Value=Db(mes);cmd.Parameters.Add("@GiroId",SqlDbType.Int).Value=Db(giroId);cmd.Parameters.Add("@SedeId",SqlDbType.Int).Value=Db(sedeId);
        await using var r=await cmd.ExecuteReaderAsync(ct);
        while(await r.ReadAsync(ct))items.Add(new(r.Int64("FinanzaPresupuestoId"),r.Int32("GiroNegocioId"),r.Text("Giro"),r.Int32("SedeId"),r.Text("Sede"),r.GetInt16(r.GetOrdinal("Anio")),r.GetByte(r.GetOrdinal("Mes")),r.Text("Nombre"),Dec(r,"Monto"),r.Text("Estado"),Dec(r,"GastoReal"),Dec(r,"Disponible"),Dec(r,"PorcentajeEjecutado"),r.Date("FechaCreacion")));
        return items;
    }

    public async Task<PresupuestoDetalleDto?> ObtenerAsync(long id,AlcanceFinanza a,CancellationToken ct)
    {
        await using var cn=connections.Create();await cn.OpenAsync(ct);await using var cmd=Proc(cn,"sp_finanzas_leer_presupuesto");cmd.Parameters.Add("@Id",SqlDbType.BigInt).Value=id;Scope(cmd,a);
        await using var r=await cmd.ExecuteReaderAsync(ct);if(!await r.ReadAsync(ct))return null;
        var dto=new PresupuestoDetalleDto(r.Int64("FinanzaPresupuestoId"),r.Int32("GiroNegocioId"),r.Text("Giro"),r.Int32("SedeId"),r.Text("Sede"),r.GetInt16(r.GetOrdinal("Anio")),r.GetByte(r.GetOrdinal("Mes")),r.Text("Nombre"),Dec(r,"Monto"),r.Text("Estado"),r.NullableText("Observacion"),Dec(r,"GastoReal"),Dec(r,"Disponible"),Dec(r,"PorcentajeEjecutado"),r.Date("FechaCreacion"),[]);
        var gastos=new List<GastoDto>();if(await r.NextResultAsync(ct))while(await r.ReadAsync(ct))gastos.Add(new(r.Int64("FinanzaGastoId"),r.Date("Fecha"),r.Text("Categoria"),r.Text("Concepto"),Dec(r,"Monto"),r.Text("OrigenModulo"),NullableInt64(r,"OrigenRegistroId"),r.NullableText("Referencia"),r.Text("NombreUsuario"),r.Date("FechaCreacion")));
        return dto with{Gastos=gastos};
    }

    public async Task<FinanzaOpcionesDto> OpcionesAsync(AlcanceFinanza a,CancellationToken ct)
    {
        await using var cn=connections.Create();await cn.OpenAsync(ct);await using var cmd=Proc(cn,"sp_finanzas_leer_opciones");Scope(cmd,a);await using var r=await cmd.ExecuteReaderAsync(ct);
        var giros=await Catalogos(r,ct);var sedes=await r.NextResultAsync(ct)?await Catalogos(r,ct):[];return new(giros,sedes);
    }

    public Task<long> CrearAsync(CrearPresupuestoRequest x,AlcanceFinanza a,CancellationToken ct)=>Scalar("sp_finanzas_crear_presupuesto",a,ct,c=>{c.Parameters.Add("@GiroId",SqlDbType.Int).Value=x.GiroId;c.Parameters.Add("@SedeId",SqlDbType.Int).Value=x.SedeId;c.Parameters.Add("@Anio",SqlDbType.SmallInt).Value=x.Anio;c.Parameters.Add("@Mes",SqlDbType.TinyInt).Value=x.Mes;Text(c,"@Nombre",180,x.Nombre);Decimal(c,"@Monto",x.Monto);Text(c,"@Observacion",500,x.Observacion);});
    public Task<long> RegistrarGastoAsync(long id,RegistrarGastoRequest x,AlcanceFinanza a,CancellationToken ct)=>Scalar("sp_finanzas_registrar_gasto",a,ct,c=>{c.Parameters.Add("@PresupuestoId",SqlDbType.BigInt).Value=id;c.Parameters.Add("@Fecha",SqlDbType.Date).Value=x.Fecha.Date;Text(c,"@Categoria",30,x.Categoria);Text(c,"@Concepto",250,x.Concepto);Decimal(c,"@Monto",x.Monto);Text(c,"@OrigenModulo",30,x.OrigenModulo);c.Parameters.Add("@OrigenRegistroId",SqlDbType.BigInt).Value=Db(x.OrigenRegistroId);Text(c,"@Referencia",120,x.Referencia);});
    public async Task<bool> ActualizarEstadoAsync(long id,string estado,AlcanceFinanza a,CancellationToken ct){await using var cn=connections.Create();await cn.OpenAsync(ct);await using var cmd=Proc(cn,"sp_finanzas_actualizar_estado");cmd.Parameters.Add("@Id",SqlDbType.BigInt).Value=id;Text(cmd,"@Estado",20,estado);Scope(cmd,a);return Convert.ToInt32(await cmd.ExecuteScalarAsync(ct))>0;}
    public async Task<bool> EliminarAsync(long id,int usuarioId,CancellationToken ct){await using var cn=connections.Create();await cn.OpenAsync(ct);await using var cmd=Proc(cn,"sp_finanzas_eliminar_presupuesto");cmd.Parameters.Add("@Id",SqlDbType.BigInt).Value=id;cmd.Parameters.Add("@UsuarioId",SqlDbType.Int).Value=usuarioId;return Convert.ToInt32(await cmd.ExecuteScalarAsync(ct))>0;}

    private async Task<long> Scalar(string name,AlcanceFinanza a,CancellationToken ct,Action<SqlCommand> add){await using var cn=connections.Create();await cn.OpenAsync(ct);await using var cmd=Proc(cn,name);add(cmd);Scope(cmd,a);return Convert.ToInt64(await cmd.ExecuteScalarAsync(ct));}
    private static async Task<IReadOnlyList<CatalogoDto>> Catalogos(SqlDataReader r,CancellationToken ct){var list=new List<CatalogoDto>();while(await r.ReadAsync(ct))list.Add(new(r.Int32("Id"),r.Text("Nombre")));return list;}
    private static SqlCommand Proc(SqlConnection cn,string name)=>new(name,cn){CommandType=CommandType.StoredProcedure};
    private static void Scope(SqlCommand c,AlcanceFinanza a){c.Parameters.Add("@UsuarioId",SqlDbType.Int).Value=a.UsuarioId;c.Parameters.Add("@EsAdministrador",SqlDbType.Bit).Value=a.EsAdministrador;}
    private static object Db(object? value)=>value??DBNull.Value;
    private static void Text(SqlCommand c,string name,int size,string? value)=>c.Parameters.Add(name,SqlDbType.NVarChar,size).Value=Db(string.IsNullOrWhiteSpace(value)?null:value.Trim());
    private static void Decimal(SqlCommand c,string name,decimal value){var p=c.Parameters.Add(name,SqlDbType.Decimal);p.Precision=18;p.Scale=2;p.Value=value;}
    private static decimal Dec(SqlDataReader r,string name)=>r.GetDecimal(r.GetOrdinal(name));
    private static long? NullableInt64(SqlDataReader r,string name){var i=r.GetOrdinal(name);return r.IsDBNull(i)?null:r.GetInt64(i);}
}

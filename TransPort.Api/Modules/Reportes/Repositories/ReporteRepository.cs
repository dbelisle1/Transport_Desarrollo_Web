using System.Data;
using Microsoft.Data.SqlClient;
using TransPort.Api.Configuration;
using TransPort.Api.Modules.Reportes.DTOs;
using TransPort.Api.Modules.Shared.DTOs;
using TransPort.Api.Modules.Shared.Repositories;

namespace TransPort.Api.Modules.Reportes.Repositories;

public sealed class ReporteRepository(ISqlConnectionFactory connections):IReporteRepository
{
    public async Task<ReporteOpcionesDto> OpcionesAsync(AlcanceReporte a,CancellationToken ct)
    {
        await using var cn=connections.Create();await cn.OpenAsync(ct);await using var cmd=Proc(cn,"sp_reportes_leer_opciones");Scope(cmd,a);await using var r=await cmd.ExecuteReaderAsync(ct);
        var giros=await Catalogos(r,ct);var sedes=await r.NextResultAsync(ct)?await Catalogos(r,ct):[];return new(giros,sedes);
    }

    public async Task<ReporteInternoDto> InternoAsync(DateTime? desde,DateTime? hasta,int? giroId,int? sedeId,AlcanceReporte a,CancellationToken ct)
    {
        await using var cn=connections.Create();await cn.OpenAsync(ct);await using var cmd=Proc(cn,"sp_reportes_leer_interno");Scope(cmd,a);Date(cmd,"@Desde",desde);Date(cmd,"@Hasta",hasta);cmd.Parameters.Add("@GiroId",SqlDbType.Int).Value=Db(giroId);cmd.Parameters.Add("@SedeId",SqlDbType.Int).Value=Db(sedeId);await using var r=await cmd.ExecuteReaderAsync(ct);
        await r.ReadAsync(ct);var resumen=new ReporteInternoResumenDto(r.Date("Desde"),r.Date("Hasta"),r.Int32("Giros"),r.Int32("Sedes"),Long(r,"Operaciones"),Long(r,"Completadas"),Dec(r,"Presupuesto"),Dec(r,"Gastos"),Dec(r,"Ingresos"),Dec(r,"Resultado"));
        var giros=new List<ReporteGiroDto>();if(await r.NextResultAsync(ct))while(await r.ReadAsync(ct))giros.Add(new(r.Int32("GiroNegocioId"),r.Text("Giro"),Long(r,"Operaciones"),Long(r,"Completadas"),r.Text("Indicador"),Dec(r,"ValorIndicador"),r.Text("UnidadIndicador"),Dec(r,"Presupuesto"),Dec(r,"Gastos"),Dec(r,"Ingresos"),Dec(r,"Resultado")));
        var periodos=new List<ReportePeriodoDto>();if(await r.NextResultAsync(ct))while(await r.ReadAsync(ct))periodos.Add(new(r.GetInt16(r.GetOrdinal("Anio")),r.GetByte(r.GetOrdinal("Mes")),r.Text("Periodo"),Dec(r,"Presupuesto"),Dec(r,"Gastos"),Dec(r,"Ingresos"),Dec(r,"Resultado")));
        return new(resumen,giros,periodos);
    }

    public async Task<ReporteClienteDto> ClienteAsync(DateTime? desde,DateTime? hasta,int? clienteId,AlcanceReporte a,CancellationToken ct)
    {
        await using var cn=connections.Create();await cn.OpenAsync(ct);await using var cmd=Proc(cn,"sp_reportes_leer_cliente");Scope(cmd,a);Date(cmd,"@Desde",desde);Date(cmd,"@Hasta",hasta);cmd.Parameters.Add("@ClienteId",SqlDbType.Int).Value=Db(clienteId);await using var r=await cmd.ExecuteReaderAsync(ct);
        await r.ReadAsync(ct);var resumen=new ReporteClienteResumenDto(r.Date("Desde"),r.Date("Hasta"),r.Int32("Empresas"),Long(r,"Pedidos"),Long(r,"Completados"),Dec(r,"MontoCotizado"),Long(r,"Viajes"),Long(r,"Entregados"),Dec(r,"PesoTransportado"),Long(r,"Contratos"),Dec(r,"MontoContratos"),Long(r,"Proyectos"),Dec(r,"PresupuestoObras"),Dec(r,"AvancePromedio"),Dec(r,"IngresosRegistrados"));
        var empresas=new List<ReporteClienteEmpresaDto>();if(await r.NextResultAsync(ct))while(await r.ReadAsync(ct))empresas.Add(new(r.Int32("ClienteId"),r.Text("Cliente"),Long(r,"Pedidos"),Long(r,"Completados"),Dec(r,"MontoCotizado"),Long(r,"Viajes"),Long(r,"Entregados"),Dec(r,"PesoTransportado"),Long(r,"Contratos"),Dec(r,"MontoContratos"),Long(r,"Proyectos"),Dec(r,"PresupuestoObras"),Dec(r,"AvancePromedio"),Dec(r,"IngresosRegistrados")));
        var periodos=new List<ReporteClientePeriodoDto>();if(await r.NextResultAsync(ct))while(await r.ReadAsync(ct))periodos.Add(new(r.GetInt16(r.GetOrdinal("Anio")),r.GetByte(r.GetOrdinal("Mes")),r.Text("Periodo"),Long(r,"Pedidos"),Long(r,"Operaciones"),Dec(r,"IngresosRegistrados")));
        return new(resumen,empresas,periodos);
    }

    private static async Task<IReadOnlyList<CatalogoDto>> Catalogos(SqlDataReader r,CancellationToken ct){var x=new List<CatalogoDto>();while(await r.ReadAsync(ct))x.Add(new(r.Int32("Id"),r.Text("Nombre")));return x;}
    private static SqlCommand Proc(SqlConnection cn,string name)=>new(name,cn){CommandType=CommandType.StoredProcedure};
    private static void Scope(SqlCommand c,AlcanceReporte a){c.Parameters.Add("@UsuarioId",SqlDbType.Int).Value=a.UsuarioId;c.Parameters.Add("@EsAdministrador",SqlDbType.Bit).Value=a.EsAdministrador;}
    private static void Date(SqlCommand c,string name,DateTime? value)=>c.Parameters.Add(name,SqlDbType.Date).Value=value.HasValue?value.Value.Date:DBNull.Value;
    private static object Db(object? value)=>value??DBNull.Value;
    private static long Long(SqlDataReader r,string name)=>Convert.ToInt64(r.GetValue(r.GetOrdinal(name)));
    private static decimal Dec(SqlDataReader r,string name)=>Convert.ToDecimal(r.GetValue(r.GetOrdinal(name)));
}

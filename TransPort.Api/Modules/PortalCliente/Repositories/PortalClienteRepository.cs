using System.Data;
using Microsoft.Data.SqlClient;
using TransPort.Api.Configuration;
using TransPort.Api.Modules.Comercial.DTOs;
using TransPort.Api.Modules.PortalCliente.DTOs;
using TransPort.Api.Modules.Shared.DTOs;
using TransPort.Api.Modules.Shared.Repositories;

namespace TransPort.Api.Modules.PortalCliente.Repositories;

public sealed class PortalClienteRepository(ISqlConnectionFactory connections) : IPortalClienteRepository
{
    public async Task<PortalClienteResumenDto> ResumenAsync(
        int usuarioId, bool esAdministrador, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = new SqlCommand("sp_portalcliente_leer_resumen", connection)
            { CommandType = CommandType.StoredProcedure };
        command.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = usuarioId;
        command.Parameters.Add("@EsAdministrador", SqlDbType.Bit).Value = esAdministrador;
        await using var reader = await command.ExecuteReaderAsync(ct);

        var empresas = new Dictionary<int, EmpresaTemporal>();
        while (await reader.ReadAsync(ct))
        {
            var id = reader.Int32("ClienteId");
            if (!empresas.TryGetValue(id, out var empresa))
            {
                empresa = new EmpresaTemporal(
                    id, reader.Text("Nombre"), reader.NullableText("Nit"),
                    reader.NullableText("CorreoContacto"), []);
                empresas.Add(id, empresa);
            }
            var giroId = reader.NullableInt32("GiroNegocioId");
            if (giroId.HasValue) empresa.Servicios.Add(new CatalogoDto(giroId.Value, reader.Text("Giro")));
        }

        long total = 0, solicitadas = 0, enGestion = 0, completadas = 0, documentos = 0;
        if (await reader.NextResultAsync(ct) && await reader.ReadAsync(ct))
        {
            total = Numero(reader, "TotalSolicitudes");
            solicitadas = Numero(reader, "Solicitadas");
            enGestion = Numero(reader, "EnGestion");
            completadas = Numero(reader, "Completadas");
            documentos = Numero(reader, "Documentos");
        }

        var recientes = new List<PedidoListadoDto>();
        if (await reader.NextResultAsync(ct))
            while (await reader.ReadAsync(ct))
                recientes.Add(new PedidoListadoDto(
                    reader.Int64("PedidoId"), reader.Int32("ClienteId"), reader.Text("Cliente"),
                    reader.Int32("GiroNegocioId"), reader.Text("Giro"), reader.Text("TipoSolicitud"),
                    reader.Text("Titulo"), reader.Text("Estado"), reader.NullableDate("FechaRequerida"),
                    Decimal(reader, "MontoCotizado"), reader.NullableInt32("VendedorUsuarioId"),
                    reader.NullableText("Vendedor"), reader.Date("FechaCreacion"), reader.NullableDate("FechaModificacion")));

        return new PortalClienteResumenDto(
            empresas.Values.Select(x => new EmpresaPortalClienteDto(
                x.Id, x.Nombre, x.Nit, x.Correo, x.Servicios)).ToArray(),
            total, solicitadas, enGestion, completadas, documentos, recientes);
    }

    public async Task<PortalClienteOperacionesDto> OperacionesAsync(
        int usuarioId, bool esAdministrador, int? clienteId, CancellationToken ct)
    {
        await using var connection = connections.Create();
        await connection.OpenAsync(ct);
        await using var command = new SqlCommand("sp_portalcliente_leer_operaciones", connection)
            { CommandType = CommandType.StoredProcedure };
        command.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = usuarioId;
        command.Parameters.Add("@EsAdministrador", SqlDbType.Bit).Value = esAdministrador;
        command.Parameters.Add("@ClienteId", SqlDbType.Int).Value =
            clienteId.HasValue ? clienteId.Value : DBNull.Value;
        await using var reader = await command.ExecuteReaderAsync(ct);

        long viajesActivos = 0, contratosActivos = 0, proyectosActivos = 0;
        if (await reader.ReadAsync(ct))
        {
            viajesActivos = Numero(reader, "ViajesActivos");
            contratosActivos = Numero(reader, "ContratosActivos");
            proyectosActivos = Numero(reader, "ProyectosActivos");
        }

        var viajes = new List<PortalClienteViajeDto>();
        if (await reader.NextResultAsync(ct))
            while (await reader.ReadAsync(ct))
                viajes.Add(new(
                    reader.Int64("TransporteViajeId"), reader.Int32("ClienteId"), reader.Text("Cliente"),
                    reader.Text("Tipo"), reader.Text("Origen"), reader.Text("Destino"),
                    reader.Text("DescripcionCarga"), reader.Date("FechaSalidaPlanificada"),
                    reader.NullableDate("FechaSalidaReal"), reader.NullableDate("FechaEntrega"),
                    reader.Text("Estado"), reader.Text("Placa"), reader.Text("Conductor"),
                    reader.Int32("IncidenciasAbiertas")));

        var contratos = new List<PortalClienteContratoDto>();
        if (await reader.NextResultAsync(ct))
            while (await reader.ReadAsync(ct))
                contratos.Add(new(
                    reader.Int64("MaquinariaContratoId"), reader.Int32("ClienteId"), reader.Text("Cliente"),
                    reader.Int32("MaquinariaEquipoId"), reader.Text("Codigo"), reader.Text("Equipo"),
                    reader.Text("Tipo"), reader.Date("FechaInicio"), reader.NullableDate("FechaFin"),
                    reader.GetDecimal(reader.GetOrdinal("MontoTotal")), reader.Text("Estado"),
                    Decimal(reader, "HorasEntrega"), Decimal(reader, "HorasDevolucion")));

        var proyectos = new List<PortalClienteProyectoDto>();
        if (await reader.NextResultAsync(ct))
            while (await reader.ReadAsync(ct))
                proyectos.Add(new(
                    reader.Int64("ConstruccionProyectoId"), reader.Int32("ClienteId"), reader.Text("Cliente"),
                    reader.Text("Nombre"), reader.Text("TipoObra"), reader.Text("Ubicacion"),
                    reader.Date("FechaInicioPlanificada"), reader.Date("FechaFinPlanificada"),
                    reader.GetDecimal(reader.GetOrdinal("Presupuesto")), reader.Text("Estado"),
                    reader.GetDecimal(reader.GetOrdinal("PorcentajeAvance")),
                    reader.GetDecimal(reader.GetOrdinal("CostoReal"))));

        return new PortalClienteOperacionesDto(
            viajesActivos, contratosActivos, proyectosActivos,
            viajes, contratos, proyectos);
    }

    private static long Numero(SqlDataReader reader, string name) =>
        Convert.ToInt64(reader.GetValue(reader.GetOrdinal(name)));

    private static decimal? Decimal(SqlDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetDecimal(ordinal);
    }

    private sealed record EmpresaTemporal(
        int Id, string Nombre, string? Nit, string? Correo, List<CatalogoDto> Servicios);
}

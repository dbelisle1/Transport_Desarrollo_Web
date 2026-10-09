using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Modules.Organizacion.DTOs;
using TransPort.Api.Modules.Organizacion.Repositories;

namespace TransPort.Api.Controllers;

[ApiController]
[Route("api/administracion")]
[Authorize(Roles = "AdministradorGeneral")]
public sealed class AdministracionController(IOperacionesRepository operaciones) : ControllerBase
{
    [HttpGet("resumen")]
    public Task<DashboardDto> Resumen(CancellationToken ct) => operaciones.ObtenerResumenAsync(ct);

    [HttpGet("auditoria")]
    public Task<IReadOnlyList<AuditoriaDto>> Auditoria([FromQuery] int cantidad = 100, CancellationToken ct = default) =>
        operaciones.ListarAuditoriaAsync(cantidad, ct);
}

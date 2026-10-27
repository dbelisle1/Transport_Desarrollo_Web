using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Api.Modules.PortalCliente.DTOs;
using TransPort.Api.Modules.PortalCliente.Repositories;

namespace TransPort.Api.Controllers;

[ApiController]
[Route("api/portal-cliente")]
[Authorize(Roles = "Cliente,AdministradorGeneral")]
public sealed class PortalClienteController(IPortalClienteRepository portal) : ControllerBase
{
    [HttpGet("resumen")]
    public Task<PortalClienteResumenDto> Resumen(CancellationToken ct) =>
        portal.ResumenAsync(
            int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!),
            User.IsInRole("AdministradorGeneral"), ct);
}

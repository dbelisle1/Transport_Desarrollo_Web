using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace TransPort.Web.Controllers;

[Authorize]
[Route("portal")]
public sealed class PortalController : Controller
{
    [HttpGet("cambiar/{destino}")]
    public IActionResult Cambiar(string destino) => destino.ToLowerInvariant() switch
    {
        "admin" when User.IsInRole("AdministradorGeneral") => Redirect("/admin"),
        "cliente" when User.IsInRole("Cliente") || User.IsInRole("AdministradorGeneral") => Redirect("/cliente"),
        "gestion" when User.IsInRole("AdministradorGeneral") || User.IsInRole("Gerente") ||
                       User.IsInRole("Empleado") || User.IsInRole("Operativo") || User.IsInRole("Vendedor") => Redirect("/gestion"),
        _ => Redirect("/acceso/denegado")
    };
}

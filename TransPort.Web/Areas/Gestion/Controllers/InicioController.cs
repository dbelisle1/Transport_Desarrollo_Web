using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace TransPort.Web.Areas.Gestion.Controllers;

[Area("Gestion")]
[Authorize(Policy = "Gestion")]
[Route("gestion")]
public sealed class InicioController : Controller
{
    [HttpGet("")]
    public IActionResult Index() => View();
}

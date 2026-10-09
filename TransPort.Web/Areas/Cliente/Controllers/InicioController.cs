using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace TransPort.Web.Areas.Cliente.Controllers;

[Area("Cliente")]
[Authorize(Policy = "Cliente")]
[Route("cliente")]
public sealed class InicioController : Controller
{
    [HttpGet("")]
    public IActionResult Index() => View();
}

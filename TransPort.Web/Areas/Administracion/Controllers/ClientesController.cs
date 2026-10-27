using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Areas.Administracion.Controllers;

[Area("Administracion")]
[Authorize(Policy = "Administracion")]
[Route("admin/clientes")]
public sealed class ClientesController(ITransportApiClient api, ILogger<ClientesController> logger) : Controller
{
    [HttpGet("")]
    public async Task<IActionResult> Index(string? busqueda, bool? esActivo, CancellationToken ct)
    {
        try
        {
            return View(new ClienteFiltroViewModel
            {
                Busqueda = busqueda,
                EsActivo = esActivo,
                Clientes = await api.ClientesAsync(busqueda, esActivo, ct)
            });
        }
        catch (Exception ex) when (ex is HttpRequestException or TransportApiException)
        {
            logger.LogError(ex, "No fue posible cargar clientes.");
            TempData["Error"] = "No fue posible consultar los clientes.";
            return View(new ClienteFiltroViewModel());
        }
    }

    [HttpGet("crear")]
    public async Task<IActionResult> Crear(CancellationToken ct) =>
        View("Formulario", await PrepararAsync(new ClienteFormViewModel(), ct));

    [HttpPost("crear")]
    public async Task<IActionResult> Crear(ClienteFormViewModel model, CancellationToken ct)
    {
        if (!ModelState.IsValid) return View("Formulario", await PrepararAsync(model, ct));
        try
        {
            model.ClienteId = await api.CrearClienteAsync(model, ct);
            TempData["Exito"] = "Cliente creado correctamente.";
            return RedirectToAction(nameof(Index));
        }
        catch (Exception ex) when (ex is HttpRequestException or TransportApiException)
        {
            logger.LogWarning(ex, "No fue posible crear el cliente.");
            ModelState.AddModelError(string.Empty, "No fue posible crear el cliente. Verifique que el NIT sea único.");
            return View("Formulario", await PrepararAsync(model, ct));
        }
    }

    [HttpGet("{id:int}/editar")]
    public async Task<IActionResult> Editar(int id, CancellationToken ct)
    {
        var cliente = await api.ClienteAsync(id, ct);
        if (cliente is null) return NotFound();
        return View("Formulario", await PrepararAsync(new ClienteFormViewModel
        {
            ClienteId = cliente.ClienteId,
            Nombre = cliente.Nombre,
            Nit = cliente.Nit,
            CorreoContacto = cliente.CorreoContacto,
            EsActivo = cliente.EsActivo,
            UsuariosSeleccionados = cliente.Usuarios.Select(x => x.Id).ToList(),
            GirosSeleccionados = cliente.Giros.Select(x => x.Id).ToList()
        }, ct));
    }

    [HttpPost("{id:int}/editar")]
    public async Task<IActionResult> Editar(int id, ClienteFormViewModel model, CancellationToken ct)
    {
        if (id != model.ClienteId) return BadRequest();
        if (!ModelState.IsValid) return View("Formulario", await PrepararAsync(model, ct));
        try
        {
            await api.ActualizarClienteAsync(model, ct);
            TempData["Exito"] = "Cliente actualizado correctamente.";
            return RedirectToAction(nameof(Index));
        }
        catch (Exception ex) when (ex is HttpRequestException or TransportApiException)
        {
            logger.LogWarning(ex, "No fue posible actualizar el cliente {ClienteId}.", id);
            ModelState.AddModelError(string.Empty, "No fue posible actualizar el cliente. Verifique que el NIT sea único.");
            return View("Formulario", await PrepararAsync(model, ct));
        }
    }

    [HttpPost("{id:int}/estado")]
    public async Task<IActionResult> CambiarEstado(int id, CancellationToken ct)
    {
        var cliente = await api.ClienteAsync(id, ct);
        if (cliente is null) return NotFound();
        var model = new ClienteFormViewModel
        {
            ClienteId = cliente.ClienteId,
            Nombre = cliente.Nombre,
            Nit = cliente.Nit,
            CorreoContacto = cliente.CorreoContacto,
            EsActivo = !cliente.EsActivo,
            UsuariosSeleccionados = cliente.Usuarios.Select(x => x.Id).ToList(),
            GirosSeleccionados = cliente.Giros.Select(x => x.Id).ToList()
        };
        await api.ActualizarClienteAsync(model, ct);
        TempData["Exito"] = model.EsActivo ? "Cliente activado." : "Cliente desactivado.";
        return RedirectToAction(nameof(Index));
    }

    [HttpPost("{id:int}/eliminar")]
    public async Task<IActionResult> Eliminar(int id, CancellationToken ct)
    {
        try
        {
            await api.EliminarClienteAsync(id, ct);
            TempData["Exito"] = "Cliente eliminado lógicamente.";
        }
        catch (TransportApiException ex)
        {
            logger.LogWarning(ex, "No fue posible eliminar el cliente {ClienteId}.", id);
            TempData["Error"] = "No fue posible eliminar el cliente.";
        }
        return RedirectToAction(nameof(Index));
    }

    private async Task<ClienteFormViewModel> PrepararAsync(ClienteFormViewModel model, CancellationToken ct)
    {
        model.UsuariosDisponibles = await api.UsuariosAsync(null, null, null, ct);
        model.GirosDisponibles = await api.CatalogoAsync("giros", ct);
        return model;
    }
}

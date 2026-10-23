using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Models.Clientes;
using TransPort.Web.Services;

namespace TransPort.Web.Controllers;

[Authorize(Policy = "Administracion")]
public sealed class ClientesController(ITransportApiClient api) : Controller
{
    [HttpGet]
    public async Task<IActionResult> Index(string? busqueda, bool? esActivo, CancellationToken ct)
    {
        ViewBag.Busqueda = busqueda;
        ViewBag.EsActivo = esActivo;
        return View(await api.ListarClientesAsync(busqueda, esActivo, ct));
    }

    [HttpGet]
    public IActionResult Create() => View(new CrearClienteWebRequest());

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(CrearClienteWebRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid) return View(request);
        await api.CrearClienteAsync(request, ct);
        TempData["Ok"] = "Cliente creado correctamente.";
        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    public async Task<IActionResult> Edit(int id, CancellationToken ct)
    {
        var c = await api.ObtenerClienteAsync(id, ct);
        if (c is null) return NotFound();
        return View(new ActualizarClienteWebRequest { Nombre = c.Nombre, Nit = c.Nit, CorreoContacto = c.CorreoContacto, EsActivo = c.EsActivo });
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(int id, ActualizarClienteWebRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid) return View(request);
        await api.ActualizarClienteAsync(id, request, ct);
        TempData["Ok"] = "Cliente actualizado.";
        return RedirectToAction(nameof(Index));
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(int id, CancellationToken ct)
    {
        await api.EliminarClienteAsync(id, ct);
        TempData["Ok"] = "Cliente eliminado.";
        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    public async Task<IActionResult> Details(int id, CancellationToken ct)
    {
        var c = await api.ObtenerClienteAsync(id, ct);
        if (c is null) return NotFound();
        return View(c);
    }
}
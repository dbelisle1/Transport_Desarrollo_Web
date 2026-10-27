using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Areas.Gestion.Controllers;

[Area("Gestion")]
[Authorize(Roles = "AdministradorGeneral,Gerente,Vendedor")]
[Route("gestion/pedidos")]
public sealed class PedidosController(ITransportApiClient api, ILogger<PedidosController> logger) : Controller
{
    [HttpGet("")]
    public async Task<IActionResult> Index(
        string? busqueda, string? estado, int? clienteId, int? giroId, CancellationToken ct)
    {
        try
        {
            return View(new PedidoFiltroViewModel
            {
                Busqueda = busqueda, Estado = estado, ClienteId = clienteId, GiroId = giroId,
                Pedidos = await api.PedidosAsync(busqueda, estado, clienteId, giroId, ct),
                Opciones = await api.PedidoOpcionesAsync(ct)
            });
        }
        catch (Exception ex) when (ex is HttpRequestException or TransportApiException)
        {
            logger.LogError(ex, "No fue posible cargar los pedidos comerciales.");
            TempData["Error"] = "No fue posible consultar los pedidos.";
            return View(new PedidoFiltroViewModel());
        }
    }

    [HttpGet("{id:long}")]
    public async Task<IActionResult> Detalle(long id, CancellationToken ct)
    {
        var pedido = await api.PedidoAsync(id, ct);
        if (pedido is null) return NotFound();
        return View(new PedidoDetalleViewModel { Pedido = pedido, Opciones = await api.PedidoOpcionesAsync(ct) });
    }

    [HttpPost("{id:long}/gestion")]
    public async Task<IActionResult> Gestionar(long id, PedidoGestionViewModel model, CancellationToken ct)
    {
        if (id != model.PedidoId) return BadRequest();
        if (!ModelState.IsValid)
        {
            TempData["Error"] = "Revise los datos de gestión ingresados.";
            return RedirectToAction(nameof(Detalle), new { id });
        }
        await api.GestionarPedidoAsync(model, ct);
        TempData["Exito"] = "Gestión del pedido actualizada.";
        return RedirectToAction(nameof(Detalle), new { id });
    }

    [HttpPost("{id:long}/comentar")]
    public async Task<IActionResult> Comentar(long id, string comentario, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(comentario)) TempData["Error"] = "Ingrese un comentario.";
        else
        {
            await api.ComentarPedidoAsync(id, comentario, ct);
            TempData["Exito"] = "Comentario agregado.";
        }
        return RedirectToAction(nameof(Detalle), new { id });
    }

    [HttpPost("{id:long}/documentos")]
    public async Task<IActionResult> Documento(
        long id, string nombre, string tipoDocumento, string url, CancellationToken ct)
    {
        if (!Uri.TryCreate(url, UriKind.Absolute, out _)) TempData["Error"] = "Ingrese una URL válida.";
        else
        {
            await api.AgregarDocumentoPedidoAsync(id, nombre, tipoDocumento, url, ct);
            TempData["Exito"] = "Documento vinculado.";
        }
        return RedirectToAction(nameof(Detalle), new { id });
    }

    [HttpPost("{id:long}/eliminar")]
    [Authorize(Roles = "AdministradorGeneral")]
    public async Task<IActionResult> Eliminar(long id, CancellationToken ct)
    {
        await api.EliminarPedidoAsync(id, ct);
        TempData["Exito"] = "Pedido eliminado lógicamente.";
        return RedirectToAction(nameof(Index));
    }
}

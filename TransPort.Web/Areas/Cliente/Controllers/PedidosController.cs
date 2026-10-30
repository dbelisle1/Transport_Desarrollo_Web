using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Areas.Cliente.Controllers;

[Area("Cliente")]
[Authorize(Policy = "Cliente")]
[Route("cliente/pedidos")]
public sealed class PedidosController(ITransportApiClient api, ILogger<PedidosController> logger) : Controller
{
    [HttpGet("")]
    public async Task<IActionResult> Index(string? busqueda, string? estado, CancellationToken ct)
    {
        try
        {
            return View(new PedidoFiltroViewModel
            {
                Busqueda = busqueda, Estado = estado,
                Pedidos = await api.PedidosAsync(busqueda, estado, null, null, ct)
            });
        }
        catch (Exception ex) when (ex is HttpRequestException or TransportApiException)
        {
            logger.LogError(ex, "No fue posible cargar los pedidos del cliente.");
            TempData["Error"] = "No fue posible consultar sus solicitudes.";
            return View(new PedidoFiltroViewModel());
        }
    }

    [HttpGet("crear")]
    public async Task<IActionResult> Crear(CancellationToken ct) =>
        View(await PrepararAsync(new PedidoCrearViewModel(), ct));

    [HttpPost("crear")]
    public async Task<IActionResult> Crear(PedidoCrearViewModel model, CancellationToken ct)
    {
        var lineasSeleccionadas = model.Lineas.Where(x => x.CatalogoOfertaId > 0 || x.Cantidad > 0).ToList();
        if (lineasSeleccionadas.Any(x => x.CatalogoOfertaId <= 0 || x.Cantidad <= 0))
            ModelState.AddModelError(nameof(model.Lineas), "Cada línea debe incluir una oferta y una cantidad mayor que cero.");
        if (lineasSeleccionadas.GroupBy(x => x.CatalogoOfertaId).Any(x => x.Count() > 1))
            ModelState.AddModelError(nameof(model.Lineas), "No repita la misma oferta en el pedido.");
        if (!ModelState.IsValid) return View(await PrepararAsync(model, ct));
        try
        {
            var id = await api.CrearPedidoAsync(model, ct);
            TempData["Exito"] = "Solicitud creada correctamente.";
            return RedirectToAction(nameof(Detalle), new { id });
        }
        catch (Exception ex) when (ex is HttpRequestException or TransportApiException)
        {
            logger.LogWarning(ex, "No fue posible crear la solicitud.");
            ModelState.AddModelError(string.Empty, "No fue posible crear la solicitud. Verifique el cliente y giro seleccionados.");
            return View(await PrepararAsync(model, ct));
        }
    }

    [HttpGet("{id:long}")]
    public async Task<IActionResult> Detalle(long id, CancellationToken ct)
    {
        var pedido = await api.PedidoAsync(id, ct);
        return pedido is null ? NotFound() : View(new PedidoDetalleViewModel { Pedido = pedido });
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

    private async Task<PedidoCrearViewModel> PrepararAsync(PedidoCrearViewModel model, CancellationToken ct)
    {
        model.Opciones = await api.PedidoOpcionesAsync(ct);
        while (model.Lineas.Count < 3) model.Lineas.Add(new PedidoCrearLineaViewModel());
        if (model.ClienteId == 0 && model.Opciones.Clientes.Count == 1) model.ClienteId = model.Opciones.Clientes[0].Id;
        if (model.GiroNegocioId == 0 && model.Opciones.Giros.Count == 1) model.GiroNegocioId = model.Opciones.Giros[0].Id;
        return model;
    }
}

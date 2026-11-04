using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Areas.Gestion.Controllers;

[Area("Gestion")]
[Authorize(Roles = "AdministradorGeneral,Gerente")]
[Route("gestion/catalogo")]
public sealed class CatalogoController(ITransportApiClient api) : Controller
{
    [HttpGet("")]
    public async Task<IActionResult> Index(
        string? busqueda, int? giroId, string? tipo, bool? esActivo, CancellationToken ct)
    {
        var opciones = await api.CatalogoComercialOpcionesAsync(ct);
        return View(new CatalogoComercialPaginaViewModel
        {
            Busqueda = busqueda,
            GiroId = giroId,
            Tipo = tipo,
            EsActivo = esActivo,
            Ofertas = await api.CatalogoComercialAsync(busqueda, giroId, tipo, esActivo, ct),
            Opciones = opciones,
            Nueva = new OfertaCatalogoEditarViewModel { Opciones = opciones }
        });
    }

    [HttpPost("crear")]
    public async Task<IActionResult> Crear(OfertaCatalogoEditarViewModel model, CancellationToken ct)
    {
        if (!ModelState.IsValid)
        {
            TempData["Error"] = "Revise los datos de la oferta.";
            return RedirectToAction(nameof(Index));
        }
        await api.CrearOfertaCatalogoAsync(model, ct);
        TempData["Exito"] = "Oferta comercial creada.";
        return RedirectToAction(nameof(Index));
    }

    [HttpGet("{id:int}/editar")]
    public async Task<IActionResult> Editar(int id, CancellationToken ct)
    {
        var oferta = (await api.CatalogoComercialAsync(null, null, null, null, ct))
            .SingleOrDefault(x => x.CatalogoOfertaId == id);
        if (oferta is null) return NotFound();
        return View(new OfertaCatalogoEditarViewModel
        {
            CatalogoOfertaId = oferta.CatalogoOfertaId,
            GiroNegocioId = oferta.GiroNegocioId,
            Codigo = oferta.Codigo,
            Tipo = oferta.Tipo,
            Nombre = oferta.Nombre,
            Descripcion = oferta.Descripcion,
            UnidadMedida = oferta.UnidadMedida,
            PrecioBase = oferta.PrecioBase,
            EsPublico = oferta.EsPublico,
            EsActivo = oferta.EsActivo,
            Opciones = await api.CatalogoComercialOpcionesAsync(ct)
        });
    }

    [HttpPost("{id:int}/editar")]
    public async Task<IActionResult> Editar(int id, OfertaCatalogoEditarViewModel model, CancellationToken ct)
    {
        if (id != model.CatalogoOfertaId) return BadRequest();
        if (!ModelState.IsValid)
        {
            model.Opciones = await api.CatalogoComercialOpcionesAsync(ct);
            return View(model);
        }
        await api.ActualizarOfertaCatalogoAsync(model, ct);
        TempData["Exito"] = "Oferta comercial actualizada.";
        return RedirectToAction(nameof(Index));
    }

    [HttpPost("{id:int}/eliminar")]
    public async Task<IActionResult> Eliminar(int id, CancellationToken ct)
    {
        await api.EliminarOfertaCatalogoAsync(id, ct);
        TempData["Exito"] = "Oferta eliminada lógicamente.";
        return RedirectToAction(nameof(Index));
    }
}

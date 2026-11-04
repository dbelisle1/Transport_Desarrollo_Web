using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Areas.Administracion.Controllers;

[Area("Administracion")]
[Authorize(Policy = "Administracion")]
[Route("admin/catalogos")]
public sealed class CatalogosController(ITransportApiClient api, ILogger<CatalogosController> logger) : Controller
{
    private sealed record CatalogoMeta(string Tipo, string Titulo, string Singular, string Descripcion);

    private static readonly IReadOnlyDictionary<string, CatalogoMeta> Tipos =
        new Dictionary<string, CatalogoMeta>(StringComparer.OrdinalIgnoreCase)
        {
            ["roles"] = new("roles", "Roles", "rol", "Perfiles que determinan el acceso general de cada usuario."),
            ["giros"] = new("giros", "Giros de negocio", "giro de negocio", "Unidades operativas y comerciales de TransPort."),
            ["sedes"] = new("sedes", "Sedes", "sede", "Plantas, oficinas y ubicaciones donde opera la organización.")
        };

    [HttpGet("")]
    public IActionResult Inicio() => RedirectToAction(nameof(Index), new { tipo = "roles" });

    [HttpGet("{tipo}")]
    public async Task<IActionResult> Index(string tipo, string? busqueda, bool? esActivo, CancellationToken ct)
    {
        if (!TryMeta(tipo, out var meta)) return NotFound();
        try
        {
            var elementos = await api.CatalogoAsync(meta.Tipo, ct);
            if (!string.IsNullOrWhiteSpace(busqueda))
            {
                elementos = elementos.Where(x =>
                    x.Nombre.Contains(busqueda, StringComparison.OrdinalIgnoreCase) ||
                    (x.Descripcion?.Contains(busqueda, StringComparison.OrdinalIgnoreCase) ?? false)).ToArray();
            }
            if (esActivo.HasValue) elementos = elementos.Where(x => x.EsActivo == esActivo.Value).ToArray();

            return View(new CatalogoFiltroViewModel
            {
                Tipo = meta.Tipo,
                Titulo = meta.Titulo,
                Singular = meta.Singular,
                Descripcion = meta.Descripcion,
                Busqueda = busqueda,
                EsActivo = esActivo,
                Elementos = elementos
            });
        }
        catch (Exception ex) when (ex is HttpRequestException or TransportApiException)
        {
            logger.LogError(ex, "No fue posible cargar el catálogo {Tipo}.", meta.Tipo);
            TempData["Error"] = $"No fue posible consultar {meta.Titulo.ToLowerInvariant()}.";
            return View(new CatalogoFiltroViewModel
            {
                Tipo = meta.Tipo,
                Titulo = meta.Titulo,
                Singular = meta.Singular,
                Descripcion = meta.Descripcion
            });
        }
    }

    [HttpGet("{tipo}/crear")]
    public IActionResult Crear(string tipo)
    {
        if (!TryMeta(tipo, out var meta)) return NotFound();
        return View("Formulario", Preparar(new CatalogoFormViewModel(), meta));
    }

    [HttpPost("{tipo}/crear")]
    public async Task<IActionResult> Crear(string tipo, CatalogoFormViewModel model, CancellationToken ct)
    {
        if (!TryMeta(tipo, out var meta)) return NotFound();
        Preparar(model, meta);
        if (!ModelState.IsValid) return View("Formulario", model);
        try
        {
            model.Id = await api.CrearCatalogoAsync(model, ct);
            TempData["Exito"] = $"{Capitalizar(meta.Singular)} creado correctamente.";
            return RedirectToAction(nameof(Index), new { tipo = meta.Tipo });
        }
        catch (Exception ex) when (ex is HttpRequestException or TransportApiException)
        {
            logger.LogWarning(ex, "No fue posible crear el catálogo {Tipo}.", meta.Tipo);
            ModelState.AddModelError(string.Empty, $"No fue posible crear el {meta.Singular}. Verifique que el nombre sea único.");
            return View("Formulario", model);
        }
    }

    [HttpGet("{tipo}/{id:int}/editar")]
    public async Task<IActionResult> Editar(string tipo, int id, CancellationToken ct)
    {
        if (!TryMeta(tipo, out var meta)) return NotFound();
        var item = await api.CatalogoItemAsync(meta.Tipo, id, ct);
        if (item is null) return NotFound();
        return View("Formulario", Preparar(new CatalogoFormViewModel
        {
            Id = item.Id,
            Nombre = item.Nombre,
            Descripcion = item.Descripcion,
            EsActivo = item.EsActivo
        }, meta));
    }

    [HttpPost("{tipo}/{id:int}/editar")]
    public async Task<IActionResult> Editar(string tipo, int id, CatalogoFormViewModel model, CancellationToken ct)
    {
        if (!TryMeta(tipo, out var meta)) return NotFound();
        if (id != model.Id) return BadRequest();
        Preparar(model, meta);
        if (!ModelState.IsValid) return View("Formulario", model);
        try
        {
            await api.ActualizarCatalogoAsync(model, ct);
            TempData["Exito"] = $"{Capitalizar(meta.Singular)} actualizado correctamente.";
            return RedirectToAction(nameof(Index), new { tipo = meta.Tipo });
        }
        catch (Exception ex) when (ex is HttpRequestException or TransportApiException)
        {
            logger.LogWarning(ex, "No fue posible actualizar {Tipo} {Id}.", meta.Tipo, id);
            ModelState.AddModelError(string.Empty, $"No fue posible actualizar el {meta.Singular}. Verifique el nombre y el estado.");
            return View("Formulario", model);
        }
    }

    [HttpPost("{tipo}/{id:int}/estado")]
    public async Task<IActionResult> CambiarEstado(string tipo, int id, CancellationToken ct)
    {
        if (!TryMeta(tipo, out var meta)) return NotFound();
        var item = await api.CatalogoItemAsync(meta.Tipo, id, ct);
        if (item is null) return NotFound();
        try
        {
            await api.ActualizarCatalogoAsync(Preparar(new CatalogoFormViewModel
            {
                Id = item.Id,
                Nombre = item.Nombre,
                Descripcion = item.Descripcion,
                EsActivo = !item.EsActivo
            }, meta), ct);
            TempData["Exito"] = item.EsActivo ? $"{Capitalizar(meta.Singular)} desactivado." : $"{Capitalizar(meta.Singular)} activado.";
        }
        catch (TransportApiException ex)
        {
            logger.LogWarning(ex, "No fue posible cambiar el estado de {Tipo} {Id}.", meta.Tipo, id);
            TempData["Error"] = $"No fue posible cambiar el estado del {meta.Singular}.";
        }
        return RedirectToAction(nameof(Index), new { tipo = meta.Tipo });
    }

    [HttpPost("{tipo}/{id:int}/eliminar")]
    public async Task<IActionResult> Eliminar(string tipo, int id, CancellationToken ct)
    {
        if (!TryMeta(tipo, out var meta)) return NotFound();
        try
        {
            await api.EliminarCatalogoAsync(meta.Tipo, id, ct);
            TempData["Exito"] = $"{Capitalizar(meta.Singular)} eliminado lógicamente.";
        }
        catch (TransportApiException ex)
        {
            logger.LogWarning(ex, "No fue posible eliminar {Tipo} {Id}.", meta.Tipo, id);
            TempData["Error"] = $"No fue posible eliminar el {meta.Singular}.";
        }
        return RedirectToAction(nameof(Index), new { tipo = meta.Tipo });
    }

    private static CatalogoFormViewModel Preparar(CatalogoFormViewModel model, CatalogoMeta meta)
    {
        model.Tipo = meta.Tipo;
        model.Titulo = meta.Titulo;
        model.Singular = meta.Singular;
        model.Protegido = meta.Tipo == "roles" &&
                           model.Nombre.Equals("AdministradorGeneral", StringComparison.OrdinalIgnoreCase);
        return model;
    }

    private static bool TryMeta(string tipo, out CatalogoMeta meta) => Tipos.TryGetValue(tipo, out meta!);
    private static string Capitalizar(string value) => char.ToUpperInvariant(value[0]) + value[1..];
}

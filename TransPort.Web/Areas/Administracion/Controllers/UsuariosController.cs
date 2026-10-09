using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransPort.Web.Models;
using TransPort.Web.Services;

namespace TransPort.Web.Areas.Administracion.Controllers;

[Area("Administracion")]
[Authorize(Policy = "Administracion")]
[Route("admin/usuarios")]
public sealed class UsuariosController(ITransportApiClient api, ILogger<UsuariosController> logger) : Controller
{
    [HttpGet("")]
    public async Task<IActionResult> Index(string? busqueda, bool? esActivo, int? rolId, CancellationToken ct)
    {
        try
        {
            return View(new UsuarioFiltroViewModel
            {
                Busqueda = busqueda,
                EsActivo = esActivo,
                RolId = rolId,
                Usuarios = await api.UsuariosAsync(busqueda, esActivo, rolId, ct),
                Roles = await api.CatalogoAsync("roles", ct)
            });
        }
        catch (Exception ex) when (ex is HttpRequestException or TransportApiException)
        {
            logger.LogError(ex, "No fue posible cargar usuarios.");
            TempData["Error"] = "No fue posible consultar los usuarios.";
            return View(new UsuarioFiltroViewModel());
        }
    }

    [HttpGet("crear")]
    public async Task<IActionResult> Crear(CancellationToken ct) => View("Formulario", await PrepararAsync(new UsuarioFormViewModel(), ct));

    [HttpPost("crear")]
    public async Task<IActionResult> Crear(UsuarioFormViewModel model, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(model.Clave) || model.Clave.Length < 6)
            ModelState.AddModelError(nameof(model.Clave), "La contraseña debe tener al menos 6 caracteres.");
        if (!ModelState.IsValid) return View("Formulario", await PrepararAsync(model, ct));
        try
        {
            model.UsuarioId = await api.CrearUsuarioAsync(model, ct);
            await api.ActualizarAsignacionesAsync(model, ct);
            TempData["Exito"] = "Usuario creado correctamente.";
            return RedirectToAction(nameof(Index));
        }
        catch (Exception ex) when (ex is HttpRequestException or TransportApiException)
        {
            logger.LogWarning(ex, "No fue posible crear el usuario.");
            ModelState.AddModelError(string.Empty, "No fue posible crear el usuario. Verifique que usuario y correo sean únicos.");
            return View("Formulario", await PrepararAsync(model, ct));
        }
    }

    [HttpGet("{id:int}/editar")]
    public async Task<IActionResult> Editar(int id, CancellationToken ct)
    {
        var usuario = await api.UsuarioAsync(id, ct);
        if (usuario is null) return NotFound();
        return View("Formulario", await PrepararAsync(new UsuarioFormViewModel
        {
            UsuarioId = usuario.UsuarioId,
            NombreUsuario = usuario.NombreUsuario,
            Nombre = usuario.Nombre,
            Apellido = usuario.Apellido,
            Correo = usuario.Correo,
            EsActivo = usuario.EsActivo,
            RolesSeleccionados = usuario.Roles.Select(x => x.Id).ToList(),
            GirosSeleccionados = usuario.Giros.Select(x => x.Id).ToList(),
            SedesSeleccionadas = usuario.Sedes.Select(x => x.Id).ToList()
        }, ct));
    }

    [HttpPost("{id:int}/editar")]
    public async Task<IActionResult> Editar(int id, UsuarioFormViewModel model, CancellationToken ct)
    {
        if (id != model.UsuarioId) return BadRequest();
        ModelState.Remove(nameof(model.Clave));
        if (!ModelState.IsValid) return View("Formulario", await PrepararAsync(model, ct));
        try
        {
            await api.ActualizarUsuarioAsync(model, ct);
            await api.ActualizarAsignacionesAsync(model, ct);
            TempData["Exito"] = "Usuario actualizado correctamente.";
            return RedirectToAction(nameof(Index));
        }
        catch (Exception ex) when (ex is HttpRequestException or TransportApiException)
        {
            logger.LogWarning(ex, "No fue posible actualizar el usuario {UsuarioId}.", id);
            ModelState.AddModelError(string.Empty, "No fue posible actualizar el usuario.");
            return View("Formulario", await PrepararAsync(model, ct));
        }
    }

    [HttpPost("{id:int}/estado")]
    public async Task<IActionResult> CambiarEstado(int id, CancellationToken ct)
    {
        var usuario = await api.UsuarioAsync(id, ct);
        if (usuario is null) return NotFound();
        var model = new UsuarioFormViewModel
        {
            UsuarioId=id, NombreUsuario=usuario.NombreUsuario, Nombre=usuario.Nombre, Apellido=usuario.Apellido,
            Correo=usuario.Correo, EsActivo=!usuario.EsActivo,
            RolesSeleccionados=usuario.Roles.Select(x=>x.Id).ToList(),
            GirosSeleccionados=usuario.Giros.Select(x=>x.Id).ToList(),
            SedesSeleccionadas=usuario.Sedes.Select(x=>x.Id).ToList()
        };
        await api.ActualizarUsuarioAsync(model, ct);
        TempData["Exito"] = model.EsActivo ? "Usuario activado." : "Usuario desactivado.";
        return RedirectToAction(nameof(Index));
    }

    [HttpPost("{id:int}/eliminar")]
    public async Task<IActionResult> Eliminar(int id, CancellationToken ct)
    {
        try
        {
            await api.EliminarUsuarioAsync(id, ct);
            TempData["Exito"] = "Usuario eliminado lógicamente.";
        }
        catch (TransportApiException ex)
        {
            logger.LogWarning(ex, "No fue posible eliminar el usuario {UsuarioId}.", id);
            TempData["Error"] = "No fue posible eliminar el usuario.";
        }
        return RedirectToAction(nameof(Index));
    }

    private async Task<UsuarioFormViewModel> PrepararAsync(UsuarioFormViewModel model, CancellationToken ct)
    {
        model.RolesDisponibles = await api.CatalogoAsync("roles", ct);
        model.GirosDisponibles = await api.CatalogoAsync("giros", ct);
        model.SedesDisponibles = await api.CatalogoAsync("sedes", ct);
        return model;
    }
}

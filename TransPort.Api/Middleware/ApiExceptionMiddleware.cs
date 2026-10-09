using Microsoft.Data.SqlClient;
using Microsoft.AspNetCore.Mvc;

namespace TransPort.Api.Middleware;

public sealed class ApiExceptionMiddleware(RequestDelegate next, ILogger<ApiExceptionMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try { await next(context); }
        catch (SqlException ex) when (ex.Number is 50001 or 50002 or 2601 or 2627)
        {
            logger.LogWarning(ex, "Conflicto al procesar la operación de datos.");
            await Results.Conflict(new ProblemDetails
            {
                Title = "No fue posible completar la operación",
                Detail = ex.Message,
                Status = StatusCodes.Status409Conflict
            }).ExecuteAsync(context);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error no controlado en la API.");
            await Results.Problem(
                title: "Ocurrió un error interno.",
                detail: "Consulte los registros del servidor.",
                statusCode: StatusCodes.Status500InternalServerError).ExecuteAsync(context);
        }
    }
}

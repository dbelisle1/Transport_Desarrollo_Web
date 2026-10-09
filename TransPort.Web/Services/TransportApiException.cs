namespace TransPort.Web.Services;

public sealed class TransportApiException(string message, int statusCode) : Exception(message)
{
    public int StatusCode { get; } = statusCode;
}

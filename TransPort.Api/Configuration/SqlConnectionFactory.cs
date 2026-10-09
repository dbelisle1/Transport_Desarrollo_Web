using Microsoft.Data.SqlClient;

namespace TransPort.Api.Configuration;

public interface ISqlConnectionFactory
{
    SqlConnection Create();
}

public sealed class SqlConnectionFactory(IConfiguration configuration) : ISqlConnectionFactory
{
    public SqlConnection Create()
    {
        var connectionString = configuration.GetConnectionString("TransPort");
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "Configure ConnectionStrings__TransPort antes de usar operaciones de datos.");
        }

        return new SqlConnection(connectionString);
    }
}

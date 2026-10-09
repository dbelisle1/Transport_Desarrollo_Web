using System.Data.Common;

namespace TransPort.Api.Modules.Shared.Repositories;

internal static class DataReaderExtensions
{
    public static int Int32(this DbDataReader reader, string name) => reader.GetInt32(reader.GetOrdinal(name));
    public static long Int64(this DbDataReader reader, string name) => reader.GetInt64(reader.GetOrdinal(name));
    public static string Text(this DbDataReader reader, string name) => reader.GetString(reader.GetOrdinal(name));
    public static bool Bool(this DbDataReader reader, string name) => reader.GetBoolean(reader.GetOrdinal(name));
    public static DateTime Date(this DbDataReader reader, string name) => reader.GetDateTime(reader.GetOrdinal(name));

    public static string? NullableText(this DbDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetString(ordinal);
    }

    public static DateTime? NullableDate(this DbDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetDateTime(ordinal);
    }

    public static int? NullableInt32(this DbDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetInt32(ordinal);
    }
}

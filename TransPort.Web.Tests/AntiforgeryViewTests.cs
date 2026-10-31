using System.Text.RegularExpressions;

namespace TransPort.Web.Tests;

public sealed class AntiforgeryViewTests
{
    private static readonly string Root = Path.GetFullPath(
        Path.Combine(AppContext.BaseDirectory, "..", "..", "..", ".."));

    [Fact]
    public void FormulariosPostConActionExplicita_IncluyenTokenAntifalsificacion()
    {
        var viewsRoot = Path.Combine(Root, "TransPort.Web");
        var missing = new List<string>();
        var formPattern = new Regex("<form\\b[^>]*>", RegexOptions.IgnoreCase);
        var postPattern = new Regex("\\bmethod\\s*=\\s*[\"']post[\"']", RegexOptions.IgnoreCase);
        var actionPattern = new Regex("\\baction\\s*=\\s*[\"'][^\"']+[\"']", RegexOptions.IgnoreCase);

        foreach (var file in Directory.EnumerateFiles(viewsRoot, "*.cshtml", SearchOption.AllDirectories))
        {
            var source = File.ReadAllText(file);
            foreach (Match form in formPattern.Matches(source))
            {
                if (!postPattern.IsMatch(form.Value) || !actionPattern.IsMatch(form.Value))
                    continue;
                if (form.Value.Contains("asp-action=", StringComparison.OrdinalIgnoreCase)
                    || form.Value.Contains("asp-controller=", StringComparison.OrdinalIgnoreCase)
                    || form.Value.Contains("asp-antiforgery=", StringComparison.OrdinalIgnoreCase))
                    continue;

                var bodyStart = form.Index + form.Length;
                var length = Math.Min(100, source.Length - bodyStart);
                var beginning = source.Substring(bodyStart, length);
                if (!beginning.Contains("@Html.AntiForgeryToken()", StringComparison.Ordinal))
                {
                    var line = source[..form.Index].Count(character => character == '\n') + 1;
                    missing.Add($"{Path.GetRelativePath(Root, file)}:{line}");
                }
            }
        }

        Assert.True(missing.Count == 0,
            "Formularios POST sin token antifalsificación: " + string.Join(", ", missing));
    }
}

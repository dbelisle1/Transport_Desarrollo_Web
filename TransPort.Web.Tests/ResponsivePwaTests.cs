using System.Buffers.Binary;
using System.Text.Json;

namespace TransPort.Web.Tests;

public sealed class ResponsivePwaTests
{
    private static readonly string Root=Path.GetFullPath(Path.Combine(AppContext.BaseDirectory,"..","..","..",".."));
    [Fact] public void Manifest_DeclaraIconosPngInstalables(){using var json=JsonDocument.Parse(File.ReadAllText(Path.Combine(Root,"TransPort.Web","wwwroot","manifest.webmanifest")));var icons=json.RootElement.GetProperty("icons").EnumerateArray().ToArray();Assert.Contains(icons,x=>x.GetProperty("src").GetString()=="/images/icon-192.png"&&x.GetProperty("sizes").GetString()=="192x192");Assert.Contains(icons,x=>x.GetProperty("src").GetString()=="/images/icon-512.png"&&x.GetProperty("sizes").GetString()=="512x512");}
    [Theory][InlineData("icon-192.png",192)][InlineData("icon-512.png",512)] public void Icono_TieneDimensionesCorrectas(string name,int size){var data=File.ReadAllBytes(Path.Combine(Root,"TransPort.Web","wwwroot","images",name));Assert.Equal("PNG",System.Text.Encoding.ASCII.GetString(data,1,3));Assert.Equal(size,BinaryPrimitives.ReadInt32BigEndian(data.AsSpan(16,4)));Assert.Equal(size,BinaryPrimitives.ReadInt32BigEndian(data.AsSpan(20,4)));}
    [Fact] public void ServiceWorker_ExcluyeRutasAutenticadas(){var text=File.ReadAllText(Path.Combine(Root,"TransPort.Web","wwwroot","service-worker.js"));Assert.Contains("PRIVATE_PREFIXES",text);foreach(var route in new[]{"/acceso","/admin","/gestion","/cliente","/portal"})Assert.Contains($"'{route}'",text);Assert.Contains("transport-public-v2",text);}
    [Fact] public void Layout_IncluyeSidebarAccesible(){var text=File.ReadAllText(Path.Combine(Root,"TransPort.Web","Views","Shared","_Layout.cshtml"));Assert.Contains("aria-controls=\"admin-sidebar\"",text);Assert.Contains("aria-label=\"Navegación administrativa\"",text);Assert.Contains("admin-sidebar-overlay",text);}
    [Fact] public void Css_ConservaBreakpointsRequeridos(){var text=File.ReadAllText(Path.Combine(Root,"TransPort.Web","wwwroot","css","site.css"));foreach(var width in new[]{768,1100,1920})Assert.Contains($"min-width:{width}px",text);Assert.Contains("sidebar-collapsed",text);}
}

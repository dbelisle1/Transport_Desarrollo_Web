FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY TransPort.Web/TransPort.Web.csproj TransPort.Web/
RUN dotnet restore TransPort.Web/TransPort.Web.csproj
COPY TransPort.Web/ TransPort.Web/
RUN dotnet publish TransPort.Web/TransPort.Web.csproj -c Release -o /app/publish --no-restore /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080
COPY --from=build /app/publish .
USER root
RUN mkdir -p /var/transport/keys && chown -R app:app /var/transport
USER app
ENTRYPOINT ["dotnet", "TransPort.Web.dll"]

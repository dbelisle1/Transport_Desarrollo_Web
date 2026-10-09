FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY TransPort.Api/TransPort.Api.csproj TransPort.Api/
RUN dotnet restore TransPort.Api/TransPort.Api.csproj
COPY TransPort.Api/ TransPort.Api/
RUN dotnet publish TransPort.Api/TransPort.Api.csproj -c Release -o /app/publish --no-restore /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080
COPY --from=build /app/publish .
USER app
ENTRYPOINT ["dotnet", "TransPort.Api.dll"]

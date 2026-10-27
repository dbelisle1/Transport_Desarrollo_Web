# TransPort — Base técnica y administración

Base técnica del sistema TransPort construida con .NET 8, ASP.NET Core MVC, Web API, ADO.NET, SQL Server y Docker. Incluye organización, autenticación/autorización, paneles iniciales, visor de auditoría y CRUD administrativos de usuarios, clientes y catálogos. Los módulos comerciales todavía no están implementados.

## Arquitectura

```text
Navegador -> TransPort.Web (cookie HttpOnly + sesión de servidor)
                |
                | HttpClient + Bearer JWT
                v
             TransPort.Api (autorización independiente)
                |
                | ADO.NET + procedimientos almacenados
                v
             TransPortDB (SQL Server externo a Compose)
```

- `TransPort.Web`: MVC, Razor Views, PWA pública y paneles responsive.
- `TransPort.Api`: API, lógica de autenticación, repositorios y autorización.
- `TransPort.Api.Tests`: pruebas unitarias del token y del flujo de autenticación.
- `database`: instalación idempotente de `TransPortDB`.
- `docker-compose.yml`: exactamente dos servicios de aplicación, `web` y `api`.

## Inicio rápido

Consulte también [instruccionesInicio.txt](instruccionesInicio.txt), preparado para compartir con el equipo.

### 1. Crear la base

Desde PowerShell, en la carpeta `database`:

```powershell
sqlcmd -S ".\SQLEXPRESS" -E -i .\000_instalar_todo.sql
```

El instalador ejecuta en orden:

1. `000_crear_base.sql`
2. `001_tablas.sql`
3. `002_indices_relaciones.sql`
4. `003_procedimientos.sql`
5. `004_datos_iniciales.sql`

Puede ejecutarse varias veces sin duplicar los datos iniciales. Si usa SSMS, ejecute los archivos anteriores en ese mismo orden y con modo SQLCMD para `000_instalar_todo.sql`.

### 2. Ejecutar con Docker

Copie `.env.example` como `.env`, coloque un usuario SQL válido y genere una clave JWT aleatoria de 32 caracteres o más. En Docker no se usa `localhost` para alcanzar SQL Server del host; se usa `host.docker.internal`.

```powershell
Copy-Item .env.example .env
docker compose up --build
```

En instalaciones con Compose clásico:

```powershell
docker-compose up --build
```

- Web: <http://localhost:8080>
- API/salud: <http://localhost:8081/salud>

Para SQL Server Express, habilite TCP/IP. Si la instancia no escucha en 1433, ajuste el puerto en `.env`; los nombres de instancia dependen de SQL Browser y suelen ser menos confiables desde contenedores.

### 3. Ejecutar sin Docker

En una terminal para la API:

```powershell
$env:ConnectionStrings__TransPort='Server=localhost\SQLEXPRESS;Database=TransPortDB;Integrated Security=True;Encrypt=True;TrustServerCertificate=True'
$env:Jwt__SigningKey='CAMBIE_ESTA_CLAVE_POR_UN_VALOR_ALEATORIO_DE_32_CARACTERES'
dotnet run --project .\TransPort.Api --urls http://localhost:8081
```

En otra terminal para MVC:

```powershell
$env:Api__BaseUrl='http://localhost:8081/'
dotnet run --project .\TransPort.Web --urls http://localhost:8080
```

No agregue cadenas ni claves reales a `appsettings.json`. Use variables de entorno, secretos de desarrollo o un almacén de secretos en despliegues reales.

## Usuarios de demostración

| Perfil | Usuario | Contraseña |
|---|---|---|
| AdministradorGeneral | `admin.demo` | `TransPortAdmin2026!` |
| Empleado | `empleado.demo` | `TransPortEmpleado2026!` |
| Cliente | `cliente.demo` | `TransPortCliente2026!` |

Estas claves son únicamente para desarrollo académico. Se almacenan en texto plano por requisito de esta fase y son inseguras para producción. Cámbielas o elimínelas fuera del entorno local. La abstracción del servicio permite reemplazar la comparación por hashes sin modificar los controladores.

## Base de datos

Tablas: `Usuario`, `Rol`, `UsuarioRol`, `GiroNegocio`, `Sede`, `SedeGiroNegocio`, `UsuarioGiroNegocio`, `UsuarioSede`, `Cliente`, `ClienteUsuario`, `ClienteGiroNegocio` y `Auditoria`.

Procedimientos principales:

- Usuarios: crear, leer por id/listado, actualizar, eliminar lógico, validar credenciales y leer roles/giros/sedes/clientes.
- Roles, giros y sedes: CRUD con eliminación lógica.
- Asignaciones: usuario-rol, usuario-giro, usuario-sede y sede-giro.
- Auditoría: crear evento y consultar el historial con filtros y paginación.
- Administración: resumen real de usuarios, clientes, giros y sedes.
- Clientes: CRUD, filtros, eliminación lógica y asignación de usuarios y giros.

Los repositorios no consultan tablas directamente cuando existe un procedimiento para la operación. La contraseña no aparece en listados, DTOs, tokens, auditoría ni logs.

## Endpoints API

| Método | Ruta | Autorización |
|---|---|---|
| `GET` | `/salud` | Pública |
| `POST` | `/api/auth/login` | Pública |
| `GET` | `/api/auth/me` | Autenticado |
| `GET/POST` | `/api/usuarios` | AdministradorGeneral |
| `GET/PUT/DELETE` | `/api/usuarios/{id}` | AdministradorGeneral |
| `PUT` | `/api/usuarios/{id}/asignaciones` | AdministradorGeneral |
| `GET/POST` | `/api/clientes` | AdministradorGeneral |
| `GET/PUT/DELETE` | `/api/clientes/{id}` | AdministradorGeneral |
| `PUT` | `/api/clientes/{id}/asignaciones` | AdministradorGeneral |
| `GET/POST` | `/api/catalogos/{roles|giros|sedes}` | AdministradorGeneral |
| `GET/PUT/DELETE` | `/api/catalogos/{tipo}/{id}` | AdministradorGeneral |
| `GET` | `/api/administracion/resumen` | AdministradorGeneral |
| `GET` | `/api/administracion/auditoria` | AdministradorGeneral |

## Rutas web

- `/`: sitio público y seis giros de negocio.
- `/acceso`: login único.
- `/cliente`: panel del cliente.
- `/gestion`: panel interno según roles, giros y sedes.
- `/admin`: panel general con conteos reales.
- `/admin/usuarios`: CRUD y filtros de usuarios.
- `/admin/clientes`: CRUD, filtros y asociaciones de empresas cliente.
- `/admin/catalogos/{roles|giros|sedes}`: CRUD, filtros y estado de catálogos organizacionales.
- `/admin/auditoria`: visor de auditoría con filtros por fecha, módulo, operación, usuario y resultado.
- `/portal/cambiar/{admin|cliente|gestion}`: cambio de área sin reiniciar sesión.

## Pruebas

```powershell
dotnet restore TransPort.sln
dotnet build TransPort.sln --no-restore
dotnet test TransPort.sln --no-restore
```

Las 16 pruebas actuales cubren firma y validación de JWT, rechazo de token alterado, requisito mínimo de clave de firma, login válido, auditoría segura del login fallido, cierre de sesión, controladores API de clientes y catálogos, protección del rol administrador y filtros/paginación/autorización del visor de auditoría.

## Pendiente para fases posteriores

Pedidos, producción, abastecimiento entre giros, transporte y GPS, inventarios, construcción, alertas, comunicación, integraciones de terceros, reportes operativos/financieros y funcionamiento offline transaccional. Las tarjetas de esos módulos se muestran explícitamente como pendientes y no simulan datos reales.

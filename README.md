# TransPort — Base técnica y administración

Sistema TransPort construido con .NET 8, ASP.NET Core MVC, Web API, ADO.NET, SQL Server y Docker. Incluye organización, autenticación/autorización, administración, auditoría y módulos comerciales y operativos conectados de extremo a extremo.

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
sqlcmd -S ".\SQLEXPRESS" -E -f 65001 -i .\000_instalar_todo.sql
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

La base incluye organización, seguridad, clientes, pedidos, inventarios,
abastecimiento, extracción, producción, maquinaria, transporte, GPS,
construcción, finanzas, alertas, catálogo comercial y comunicaciones. Los
scripts son la fuente ejecutable del esquema y se mantienen idempotentes; los
conteos se actualizan al cerrar cada módulo.

Procedimientos principales:

- Usuarios: crear, leer por id/listado, actualizar, eliminar lógico, validar credenciales y leer roles/giros/sedes/clientes.
- Roles, giros y sedes: CRUD con eliminación lógica.
- Asignaciones: usuario-rol, usuario-giro, usuario-sede y sede-giro.
- Auditoría: crear evento y consultar el historial con filtros y paginación.
- Administración: resumen real de usuarios, clientes, giros y sedes.
- Clientes: CRUD, filtros, eliminación lógica y asignación de usuarios y giros.
- Pedidos: listado por alcance, detalle, opciones, creación, gestión comercial,
  comentarios, documentos, líneas de producto/servicio, cotización y
  eliminación lógica.
- Catálogo comercial: productos y servicios por giro, precios base,
  publicación, estados, sala de ventas y administración por alcance.
- Portal del cliente: empresas y servicios contratados, indicadores,
  solicitudes, viajes, contratos de maquinaria y obras con aislamiento por identidad.
- Inventarios: artículos, existencias por sede, movimientos, reservas,
  transferencias, mínimos y trazabilidad por giro/sede.
- Abastecimiento: solicitudes entre giros con aprobación, preparación,
  despacho, recepción e integración transaccional con inventarios.
- Extracción: jornadas por planta, balance aprovechable, destinos, historial e
  integración transaccional de entradas y salidas con inventarios.
- Producción: órdenes, etapas secuenciales, consumo de materia prima, producto
  terminado, rendimiento, merma, costos e historial.
- Maquinaria: equipos por sede, disponibilidad, venta/alquiler, contratos,
  devolución por horómetro y mantenimiento.
- Transporte: flota, conductores, capacidades, viajes, rutas, cargas, entregas
  e incidencias nacionales o internacionales.
- GPS: dispositivos, posiciones, recorridos, velocidad, tiempo de uso,
  kilometraje y alertas, con simulador de fuente externa precargado.
- Construcción: proyectos y obras, actividades, responsables, avances,
  materiales, maquinaria, personal, presupuestos y costos reales.
- Finanzas: presupuestos mensuales por giro/sede, gastos, ejecución real y
  vínculos con pedidos, producción, transporte y construcción.
- Alertas: avisos y recordatorios segmentados por rol, giro, sede o usuario,
  lectura individual, seguimientos, estados y trazabilidad del módulo origen.
- Comunicaciones: conversaciones con clientes o internas, responsables,
  estados, vínculos con pedidos/operaciones y notas privadas para el personal.

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
| `GET/POST` | `/api/pedidos` | AdministradorGeneral, Gerente, Vendedor o Cliente, según alcance |
| `GET` | `/api/pedidos/{id}` | Roles comerciales, limitado por cliente o giro |
| `PUT` | `/api/pedidos/{id}/gestion` | AdministradorGeneral, Gerente o Vendedor |
| `PUT` | `/api/pedidos/{id}/lineas/{lineaId}/cotizacion` | Personal comercial autorizado |
| `POST` | `/api/pedidos/{id}/{comentarios|documentos}` | Roles comerciales, según alcance |
| `DELETE` | `/api/pedidos/{id}` | AdministradorGeneral |
| `GET` | `/api/catalogo-comercial/publico` | Pública |
| `GET/POST` | `/api/catalogo-comercial` | AdministradorGeneral o Gerente, según giro |
| `PUT/DELETE` | `/api/catalogo-comercial/{id}` | AdministradorGeneral o Gerente, según giro |
| `GET` | `/api/portal-cliente/resumen` | Cliente o AdministradorGeneral, filtrado por identidad |
| `GET` | `/api/portal-cliente/operaciones` | Viajes, maquinaria y obras filtrados por empresa autorizada |
| `GET` | `/api/inventarios` | Personal interno, filtrado por giro y sede |
| `GET` | `/api/inventarios/movimientos` | Trazabilidad de inventario autorizada |
| `POST` | `/api/inventarios/articulos` | AdministradorGeneral o Gerente |
| `POST` | `/api/inventarios/movimientos` | Personal interno autorizado |
| `GET/POST` | `/api/abastecimientos` | Personal interno según giro y sede |
| `GET` | `/api/abastecimientos/{id}` | Detalle e historial autorizado |
| `PUT` | `/api/abastecimientos/{id}/estado` | Flujo de aprobación, despacho y recepción |
| `GET/POST` | `/api/extracciones` | Jornadas filtradas por planta y alcance |
| `GET` | `/api/extracciones/{id}` | Detalle e historial autorizado |
| `PUT` | `/api/extracciones/{id}/estado` | Confirmación, entrega o cancelación |
| `GET/POST` | `/api/producciones` | Órdenes filtradas por planta y alcance |
| `PUT` | `/api/producciones/{id}/estado` | Inicio, cierre o cancelación de orden |
| `PUT` | `/api/producciones/{id}/etapas/{etapaId}/completar` | Avance secuencial de producción |
| `GET/POST` | `/api/maquinarias` | Catálogo y alta de equipos según alcance |
| `POST/PUT` | `/api/maquinarias/contratos` | Reservas, contratos y devoluciones |
| `POST/PUT` | `/api/maquinarias/mantenimientos` | Programación y ejecución de mantenimiento |
| `GET/POST` | `/api/transportes` | Viajes y asignaciones según alcance |
| `POST` | `/api/transportes/{vehiculos|conductores}` | Catálogo de recursos logísticos |
| `POST/PUT` | `/api/transportes/{id}/incidencias` | Incidencias y resolución del viaje |
| `GET` | `/api/gps` | Dispositivos, últimas posiciones y alertas según alcance |
| `POST` | `/api/gps/simular` | Simular texto JSON recibido de una fuente GPS externa |
| `GET` | `/api/gps/dispositivos/{id}/recorrido` | Historial de posiciones del activo |
| `GET/POST` | `/api/construcciones` | Listar o crear proyectos según giro y sede |
| `GET` | `/api/construcciones/{id}` | Detalle, actividades, recursos y avances |
| `POST` | `/api/construcciones/{id}/{actividades|recursos}` | Planificar actividades y asignar recursos |
| `POST` | `/api/construcciones/actividades/{id}/avances` | Registrar avance físico e historial |
| `PUT` | `/api/construcciones/{id}/estado` | Iniciar, suspender, reanudar, completar o cancelar |
| `GET/POST` | `/api/finanzas` | Consultar o crear presupuestos por alcance |
| `GET` | `/api/finanzas/{id}` | Comparación presupuesto-real y gastos |
| `POST` | `/api/finanzas/{id}/gastos` | Registrar un gasto manual o vinculado |
| `PUT` | `/api/finanzas/{id}/estado` | Cerrar o cancelar el presupuesto |
| `GET/POST` | `/api/alertas` | Consultar por alcance o crear avisos autorizados |
| `GET` | `/api/alertas/{id}` | Detalle y seguimientos de un aviso autorizado |
| `PUT` | `/api/alertas/{id}/leer` | Confirmar lectura individual |
| `POST` | `/api/alertas/{id}/seguimientos` | Registrar seguimiento operativo |
| `PUT` | `/api/alertas/{id}/estado` | Resolver o cancelar según permisos |
| `DELETE` | `/api/alertas/{id}` | Eliminación lógica administrativa tras el cierre |
| `GET/POST` | `/api/comunicaciones` | Bandeja o creación según empresa, giro y usuario |
| `GET` | `/api/comunicaciones/{id}` | Conversación autorizada; oculta notas internas al cliente |
| `POST` | `/api/comunicaciones/{id}/mensajes` | Agregar respuesta pública o nota interna autorizada |
| `PUT` | `/api/comunicaciones/{id}/gestion` | Asignar responsable y abrir/cerrar la conversación |
| `DELETE` | `/api/comunicaciones/{id}` | Eliminación lógica administrativa tras el cierre |

## Rutas web

- `/`: sitio público y seis giros de negocio.
- `/catalogo`: sala de ventas pública con productos, servicios y precios base.
- `/acceso`: login único.
- `/cliente`: dashboard operativo con empresas, servicios e indicadores reales.
- `/cliente/pedidos`: solicitudes y seguimiento del cliente.
- `/cliente/pedidos/crear`: nuevo pedido, cotización o reunión.
- `/cliente/comunicaciones`: bandeja y conversaciones del cliente.
- `/cliente/operaciones`: seguimiento de viajes, maquinaria y construcción.
- `/gestion`: panel interno según roles, giros y sedes.
- `/gestion/inventarios`: existencias, mínimos, artículos y movimientos.
- `/gestion/abastecimientos`: solicitudes y trazabilidad entre giros.
- `/gestion/extracciones`: jornadas, balance, destinos e historial de extracción.
- `/gestion/producciones`: órdenes, etapas, rendimiento, merma y costos.
- `/gestion/maquinarias`: equipos, contratos, devoluciones y mantenimiento.
- `/gestion/transportes`: flota, conductores, viajes, cargas e incidencias.
- `/gestion/gps`: dispositivos, simulación de datos, recorridos y alertas.
- `/gestion/construcciones`: obras, actividades, recursos, costos y avances.
- `/gestion/finanzas`: presupuestos, gastos y ejecución por giro/sede.
- `/gestion/alertas`: alertas, recordatorios, lectura y seguimiento por alcance.
- `/gestion/comunicaciones`: consultas de clientes y coordinación interna.
- `/gestion/pedidos`: asignación, cotización y seguimiento comercial.
- `/gestion/catalogo`: administración de ofertas por giro.
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

Las 86 pruebas actuales cubren seguridad JWT, autenticación, cierre de sesión,
clientes, catálogos, auditoría, pedidos, portal, inventarios, abastecimiento,
extracción, producción, maquinaria, transporte, GPS, construcción, finanzas y
alertas, catálogo comercial y comunicaciones: alcance, validaciones, autorización y
operaciones críticas.

## Pendiente para fases posteriores

Faltan simulaciones de terceros, registro mínimo de
ingresos, reportes operativos/financieros, cierre PWA/responsive y pruebas
HTTP/SQL reproducibles.
Los módulos que dependan de una fuente externa se probarán con formularios de
simulación y ejemplos funcionales precargados, identificando claramente el
origen simulado.

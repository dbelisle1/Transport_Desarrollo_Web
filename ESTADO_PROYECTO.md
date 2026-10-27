# Estado actual del proyecto TransPort

**Fecha de revisión:** 27 de octubre de 2026
**Etapa evaluada:** Fase 2 — flujo de pedidos y gestión comercial completado

## 1. Resumen ejecutivo

TransPort cuenta actualmente con una base funcional construida en .NET 8, ASP.NET Core MVC, Web API, ADO.NET, SQL Server y Docker. La solución está separada en dos aplicaciones desplegables (`TransPort.Web` y `TransPort.Api`) y la API está organizada como un monolito modular.

La Fase 1 está implementada en sus componentes principales:

- Sitio público responsive con los seis giros de negocio.
- Login único, JWT para la comunicación MVC–API y cookie segura para el navegador.
- Autorización por roles y asociaciones de usuarios con giros, sedes y clientes.
- Paneles iniciales para administración, gestión interna y clientes.
- CRUD administrativo de usuarios con eliminación lógica y asignación de permisos.
- Base de datos, relaciones, índices, procedimientos almacenados y datos iniciales.
- Auditoría básica.
- PWA básica.
- Contenedores independientes para MVC y API.
- Pruebas unitarias iniciales para seguridad y cierre de sesión.

El primer módulo comercial ya está implementado: los clientes pueden crear y seguir pedidos, cotizaciones o reuniones, mientras el equipo comercial asigna responsables, cotiza y actualiza estados. Producción, abastecimiento, transporte, GPS, maquinaria, construcción, inventarios, alertas, comunicación, integraciones y reportes consolidados continúan pendientes.

Después del cierre de la Fase 1 se implementó y verificó el módulo administrativo de clientes: CRUD, filtros, asociaciones transaccionales de usuarios y giros, eliminación lógica, auditoría, API, vistas MVC y pruebas. El recorrido MVC–API–SQL Server se validó con ambos contenedores activos.

También se completó la administración visual de roles, giros y sedes con búsqueda, filtros, formularios, estados, eliminación lógica, auditoría y protección del rol `AdministradorGeneral`.

El visor administrativo de auditoría permite consultar el historial con filtros combinables, fechas en horario de Guatemala, paginación ejecutada en SQL Server y acceso exclusivo para `AdministradorGeneral`.

M12 Pedidos y gestión comercial incorpora historial, documentos por enlace,
auditoría y aislamiento por cliente o giro. El flujo completo se verificó contra
SQL Server desde los contenedores de API y MVC.

M24 convirtió `/cliente` en un portal operativo con indicadores reales,
empresas, servicios contratados y solicitudes recientes, aislados por la
relación `ClienteUsuario`.

## 2. Arquitectura actual

```text
Navegador
   |
   | Cookies HttpOnly: TransPort.Auth y TransPort.Session
   v
TransPort.Web (ASP.NET Core MVC)
   |
   | HttpClient + Authorization: Bearer <JWT>
   v
TransPort.Api (ASP.NET Core Web API)
   |
   | ADO.NET + procedimientos almacenados
   v
TransPortDB (SQL Server externo a Docker Compose)
```

### Proyectos de la solución

| Proyecto | Responsabilidad | Estado |
|---|---|---|
| `TransPort.Web` | MVC, Razor Views, cookies, sesión, PWA y experiencia de usuario | Implementado |
| `TransPort.Api` | Autenticación, autorización, reglas, repositorios y acceso a datos | Implementado |
| `TransPort.Api.Tests` | Pruebas unitarias de autenticación y JWT | Implementado, cobertura inicial |
| `TransPort.Web.Tests` | Pruebas unitarias del flujo web | Implementado, cobertura inicial |
| `database` | Creación idempotente de base, tablas, relaciones, SP y datos demo | Implementado |

La solución no es un microservicio por módulo. La API despliega Seguridad y Organización juntas y comparte una sola base de datos; por ello se considera un **monolito modular** dentro de una arquitectura con MVC y API separados.

## 3. Estado de la Fase 1

Leyenda:

- **Completo:** existe flujo funcional desde la interfaz o API hasta SQL Server.
- **Parcial:** existe la base o el backend, pero falta interfaz, cobertura o endurecimiento.
- **Pendiente:** todavía no existe implementación funcional.

| Área requerida | Estado | Observaciones |
|---|---|---|
| Solución .NET 8 con MVC y API | Completo | Dos proyectos principales y dos proyectos de pruebas en `TransPort.sln`. |
| Separación MVC → API → SQL Server | Completo | El MVC no accede directamente a la base. |
| ADO.NET y procedimientos almacenados | Completo | Repositorios con `Microsoft.Data.SqlClient`; no se utiliza Entity Framework. |
| Base de datos actual | Completo | 15 tablas, 21 claves foráneas, 18 índices y 56 procedimientos definidos. |
| Datos de demostración | Completo | Script idempotente con giros, sedes, roles y usuarios demo. |
| Login único `/acceso` | Completo | Credenciales validadas por la API y SQL Server. |
| JWT MVC–API | Completo | Firma configurable, expiración y envío como Bearer. |
| Cookie y sesión del frontend | Completo | Cookie HttpOnly, Claims y JWT guardado solo en sesión del servidor. |
| Autorización por roles | Completo | Políticas MVC y validación independiente en la API. |
| Asociaciones por giro, sede y cliente | Completo y aplicado en M12 | La API filtra pedidos por empresa cliente, giro asignado, vendedor y rol. |
| Cierre de sesión | Completo | Limpia JWT/sesión, elimina cookies y usa antiforgery. |
| Sitio público | Completo | Presentación, seis giros, contacto demostrativo, navegación y acceso. |
| Panel administrativo | Completo para la base actual | Resumen real y acceso a usuarios, clientes y catálogos. |
| Panel de gestión | Parcial operativo | Muestra alcances y permite gestionar pedidos; otros módulos siguen pendientes. |
| Panel del cliente | Parcial operativo | Muestra empresas, crea y consulta solicitudes; otros servicios siguen pendientes. |
| CRUD de usuarios | Completo | Lista, filtra, crea, edita, activa/desactiva, elimina lógicamente y asigna permisos. |
| CRUD de clientes | Completo | SQL/API/MVC verificados con filtros, asociaciones, auditoría y eliminación lógica. |
| Catálogos de roles, giros y sedes | Completo | CRUD SQL/API/MVC, filtros, auditoría, eliminación lógica y protección del rol administrador. |
| Auditoría | Completo para la base actual | Registro, endpoint paginado, filtros, vista MVC y autorización administrativa. |
| PWA y responsive | Completo para Fase 1 | Manifest, ícono, service worker público y breakpoints 768/1100/1920 px. |
| Docker | Completo en configuración | Dos Dockerfiles multietapa, red interna, volumen de claves y Compose válido. |
| Documentación de inicio | Completo | `README.md`, `.env.example`, `.gitignore` e `instruccionesInicio.txt`. |
| Pruebas automatizadas | Parcial | 24 pruebas aprobadas; faltan pruebas amplias de integración de todos los módulos. |

## 4. Módulos desarrollados

### 4.1 Seguridad y acceso

**Estado: implementado**

Incluye:

- Login MVC en `/acceso`.
- Validación mediante `sp_usuario_validar_credenciales`.
- Generación y validación de JWT firmado y con vencimiento.
- Almacenamiento del JWT en la sesión del servidor MVC.
- Cookie de autenticación HttpOnly con Claims.
- Envío automático del JWT desde `TransportApiClient` a la API.
- Autorización independiente en MVC y API.
- Roles iniciales: AdministradorGeneral, Gerente, Empleado, Operativo, Vendedor y Cliente.
- Claims de roles, giros, sedes y clientes asociados.
- Cambio entre portales autorizados sin volver a iniciar sesión.
- Página de acceso denegado.
- Cierre completo de sesión mediante POST y antiforgery.
- Auditoría de inicios de sesión exitosos y fallidos sin registrar la contraseña.

### 4.2 Administración de usuarios

**Estado: implementado**

Incluye:

- Listado de usuarios.
- Búsqueda por nombre, usuario o correo.
- Filtros por estado y rol.
- Creación y edición.
- Activación y desactivación.
- Eliminación lógica.
- Asignación y retiro de roles.
- Asignación de giros de negocio.
- Asignación de sedes.
- Validaciones MVC y API.
- Restricción para impedir que el administrador elimine su propia cuenta.
- Restricción para impedir que retire todos sus propios roles.
- Registro de auditoría en las operaciones principales.

Flujo implementado:

```text
Vista Razor
  → UsuariosController MVC
  → ITransportApiClient
  → UsuariosController API
  → IUsuarioRepository
  → procedimiento almacenado
```

### 4.3 Organización y catálogos

**Estado: implementado y verificado**

Incluye el modelo y los procedimientos para:

- Roles.
- Giros de negocio.
- Sedes.
- Relación sede–giro.
- Relación usuario–rol.
- Relación usuario–giro.
- Relación usuario–sede.
- Clientes y sus relaciones con usuarios y giros.

La API y la interfaz administrativa exponen CRUD para roles, giros y sedes. Las pantallas permiten buscar, filtrar, crear, editar, activar, desactivar y eliminar lógicamente. El rol `AdministradorGeneral` conserva obligatoriamente su nombre y estado activo y no puede eliminarse.

### 4.4 Administración de clientes

**Estado: implementado y verificado**

Incluye:

- Listado, búsqueda y filtro por estado.
- Creación, edición, activación/desactivación y eliminación lógica.
- Asociación transaccional de usuarios y giros contratados.
- Validaciones, autorización exclusiva de AdministradorGeneral y auditoría.
- Procedimientos almacenados, repositorio, controlador API, cliente HTTP, controlador MVC y vistas.
- Conteo de clientes en el dashboard administrativo.
- Tres pruebas unitarias nuevas del controlador API.

### 4.5 Administración general y auditoría

**Estado: implementado y verificado**

Incluye:

- Dashboard con conteos reales de usuarios, clientes, giros y sedes.
- Endpoint de resumen administrativo.
- Tabla y procedimiento paginado de auditoría.
- Endpoint con búsqueda y filtros por fecha, módulo, operación, usuario y resultado.
- Vista MVC responsive con detalle expandible y fechas en horario de Guatemala.
- Paginación configurable de 10, 25, 50 o 100 eventos.
- Acceso exclusivo para AdministradorGeneral en MVC y API.
- Auditoría integrada en login y operaciones críticas de usuarios/catálogos.

Pendiente dentro de la experiencia administrativa: reportes operativos, gerenciales y financieros consolidados.

### 4.6 Sitio público y portales

**Estado: implementado para la bienvenida de Fase 1**

Incluye:

- Página pública responsive.
- Presentación de los seis giros de negocio.
- Panel `/admin` para AdministradorGeneral.
- Panel `/gestion` para personal interno.
- Panel `/cliente` para usuarios cliente.
- Navegación condicionada por permisos.
- Mecanismo `/portal/cambiar/{destino}`.
- Módulos futuros visibles como pendientes, sin simular transacciones.

### 4.7 PWA y experiencia responsive

**Estado: PWA básica implementada**

Incluye:

- `manifest.webmanifest`.
- Ícono instalable.
- Registro de service worker.
- Caché limitada a recursos públicos.
- Exclusión de contenido autenticado de la caché pública.
- Navbar móvil con menú hamburguesa.
- Tabla administrativa con scroll propio.
- Formularios adaptables y controles táctiles.
- Breakpoints para móvil, tablet, escritorio y escritorio amplio.

No se implementó funcionamiento offline para operaciones administrativas, de acuerdo con el alcance definido.

### 4.8 Infraestructura y ejecución

**Estado: implementado para desarrollo**

Incluye:

- Dockerfile multietapa para MVC.
- Dockerfile multietapa para API.
- Dos servicios en Docker Compose: `web` y `api`.
- Red interna `transport-interna`.
- SQL Server externo mediante cadena configurable.
- Uso de `host.docker.internal` para SQL Server instalado en el host.
- Persistencia de claves de Data Protection en volumen Docker.
- Variables de entorno para conexión y firma JWT.
- Script instalador `database/000_instalar_todo.sql`.
- Instrucciones de inicio para otros integrantes del equipo.

### 4.9 Pedidos y gestión comercial

**Estado: implementado y verificado**

Incluye:

- Pedidos, solicitudes de cotización y reuniones creadas por clientes.
- Estados, asignación de vendedor, monto cotizado, fecha y enlace de reunión.
- Comentarios, documentos por URL, historial y auditoría.
- Pantallas separadas para el cliente y el personal comercial.
- Aislamiento de datos por empresa cliente y por giro o vendedor interno.
- Eliminación lógica exclusiva de AdministradorGeneral.
- Cinco pruebas unitarias y recorrido HTTP real MVC–API–SQL Server.

### 4.10 Portal operativo del cliente

**Estado: implementado sobre los módulos disponibles**

Incluye:

- Resumen real de empresas asociadas y servicios contratados.
- Indicadores y solicitudes recientes del módulo comercial.
- Acceso a detalle, documentos, comentarios e historial de M12.
- Aislamiento por `ClienteUsuario` aplicado dentro del procedimiento almacenado.
- Vista global administrativa y rechazo 403 para roles no autorizados.
- Puntos visibles de extensión para transporte (M18) y reportes (M26).

## 5. Inventario de base de datos

### Tablas implementadas (15)

1. `Usuario`
2. `Rol`
3. `GiroNegocio`
4. `Sede`
5. `Cliente`
6. `UsuarioRol`
7. `SedeGiroNegocio`
8. `UsuarioGiroNegocio`
9. `UsuarioSede`
10. `ClienteUsuario`
11. `ClienteGiroNegocio`
12. `Auditoria`
13. `Pedido`
14. `PedidoHistorial`
15. `PedidoDocumento`

También se implementaron:

- 21 claves foráneas.
- 18 índices normales o únicos.
- Eliminación lógica en entidades y relaciones.
- Fechas UTC mediante `DATETIME2`/`SYSUTCDATETIME()`.
- Transacciones y `XACT_ABORT` en operaciones compuestas.
- 56 procedimientos almacenados para usuarios, catálogos, asociaciones,
  clientes, pedidos, portal, dashboard y auditoría.

## 6. Rutas y endpoints disponibles

### Rutas web principales

| Ruta | Función | Acceso |
|---|---|---|
| `/` | Sitio público | Público |
| `/acceso` | Inicio de sesión | Público |
| `/acceso/salir` | Cierre de sesión | Autenticado, POST |
| `/cliente` | Portal del cliente | Cliente o AdministradorGeneral |
| `/cliente/pedidos` | Crear y seguir solicitudes | Cliente o AdministradorGeneral |
| `/gestion` | Portal interno | Roles internos o AdministradorGeneral |
| `/gestion/pedidos` | Gestión de pedidos y cotizaciones | AdministradorGeneral, Gerente o Vendedor |
| `/admin` | Dashboard administrativo | AdministradorGeneral |
| `/admin/usuarios` | Administración de usuarios | AdministradorGeneral |
| `/admin/clientes` | Administración de empresas cliente | AdministradorGeneral |
| `/admin/catalogos/{roles|giros|sedes}` | Administración de catálogos organizacionales | AdministradorGeneral |
| `/admin/auditoria` | Visor filtrado y paginado de auditoría | AdministradorGeneral |
| `/portal/cambiar/{destino}` | Cambio de portal | Según roles |

### Endpoints API principales

| Método | Ruta | Función |
|---|---|---|
| `GET` | `/salud` | Estado básico de la API |
| `POST` | `/api/auth/login` | Autenticación |
| `GET` | `/api/auth/me` | Perfil y alcances del usuario autenticado |
| `GET/POST` | `/api/usuarios` | Listar o crear usuarios |
| `GET/PUT/DELETE` | `/api/usuarios/{id}` | Consultar, actualizar o eliminar lógicamente |
| `PUT` | `/api/usuarios/{id}/asignaciones` | Administrar roles, giros y sedes |
| `GET/POST` | `/api/clientes` | Listar, filtrar o crear clientes |
| `GET/PUT/DELETE` | `/api/clientes/{id}` | Consultar, actualizar o eliminar lógicamente |
| `PUT` | `/api/clientes/{id}/asignaciones` | Administrar usuarios y giros del cliente |
| `GET/POST` | `/api/catalogos/{tipo}` | Listar o crear roles, giros y sedes |
| `GET/PUT/DELETE` | `/api/catalogos/{tipo}/{id}` | CRUD de un catálogo |
| `GET` | `/api/administracion/resumen` | Conteos administrativos |
| `GET` | `/api/administracion/auditoria` | Eventos filtrados y paginados de auditoría |
| `GET/POST` | `/api/pedidos` | Listar o crear solicitudes según alcance |
| `GET` | `/api/pedidos/{id}` | Detalle, historial y documentos según alcance |
| `PUT` | `/api/pedidos/{id}/gestion` | Asignar, cotizar y actualizar estado |
| `POST` | `/api/pedidos/{id}/{comentarios|documentos}` | Agregar seguimiento |
| `DELETE` | `/api/pedidos/{id}` | Eliminación lógica administrativa |
| `GET` | `/api/portal-cliente/resumen` | Resumen aislado del portal cliente |

## 7. Componentes parciales y mejoras pendientes de la base

Estos puntos mejoran la plataforma actual, aunque varios no eran obligatorios para cerrar la Fase 1:

1. **Ampliar pruebas automatizadas.** Faltan pruebas de controladores API, repositorios con SQL Server, autorización por roles, CRUD completo y flujos HTTP de extremo a extremo.
2. **Tratar cancelaciones HTTP por separado.** `ApiExceptionMiddleware` puede registrar una `OperationCanceledException` como error 500.
3. **Preparar escalamiento horizontal del MVC.** La sesión utiliza memoria local; para varias réplicas debe migrarse a Redis o SQL Server Distributed Cache.
4. **Agregar health checks de contenedores.** Existe `/salud`, pero Compose no define comprobaciones ni dependencias condicionadas por salud.
5. **Endurecer producción.** Cambiar contraseñas en texto plano por hashes, usar HTTPS obligatorio, secretos administrados y entorno `Production`.
6. **Mejorar observabilidad.** Agregar métricas, trazas, correlación de solicitudes y almacenamiento central de logs.
7. **Revisar autorización por alcance en futuros módulos.** Los giros, sedes y clientes ya forman parte de la identidad; cada endpoint comercial futuro deberá filtrar y validar esos alcances en la API.

## 8. Módulos pendientes para fases posteriores

Los siguientes módulos todavía no están desarrollados:

### 8.1 Abastecimiento entre giros

- Pedidos internos entre giros de negocio.
- Programación de abastecimiento.
- Documentos y seguimiento de entregas.

### 8.2 Producción y procesamiento

- Ingreso de materia prima.
- Órdenes de producción.
- Transformación y rendimiento.
- Control de productos terminados.
- Costos y trazabilidad del proceso.

### 8.3 Inventarios

- Existencias por sede y giro.
- Entradas, salidas y transferencias.
- Reservas para pedidos y producción.
- Niveles mínimos y alertas de reposición.

### 8.4 Maquinaria

- Catálogo de maquinaria.
- Venta y alquiler.
- Disponibilidad y reservas.
- Mantenimiento y uso.
- Contratos y entregas.

### 8.5 Transporte y logística

- Flota y unidades de carga.
- Conductores y asignaciones.
- Viajes, rutas y cargas.
- Transporte de materia prima.
- Operaciones nacionales e internacionales.
- Movimientos entre puertos, fronteras y bodegas.

### 8.6 GPS y monitoreo

- Integración con GPS-Inversiones.
- Posición y recorrido de unidades.
- Velocidad y tiempo de uso.
- Alertas por eventos o desviaciones.

### 8.7 Construcción

- Proyectos y obras.
- Presupuestos.
- Avance físico y financiero.
- Personal, materiales y maquinaria asignada.
- Control de puentes, carreteras y edificios.

### 8.8 Alertas y recordatorios

- Alertas según rol, giro y sede.
- Recordatorios operativos y administrativos.
- Notificaciones por eventos de negocio.
- Preferencias y confirmación de lectura.

### 8.9 Comunicación y gestión comercial

- Mensajería con clientes.
- Solicitud y agenda de reuniones.
- Asignación de vendedores.
- Seguimiento de oportunidades y acuerdos.

### 8.10 Integraciones externas

- API REST y webhooks para terceros.
- Intercambio EDI/CSV.
- Integraciones con clientes y proveedores.
- Sincronización y manejo de errores.

### 8.11 Reportes consolidados

- Reportes por giro de negocio.
- Consolidación administrativa general.
- Presupuestos y control de gastos.
- Indicadores operativos y financieros.
- Reportes disponibles para clientes según sus asociaciones.

## 9. Pruebas y validación realizadas

Revisión del 27 de octubre de 2026:

| Validación | Resultado |
|---|---|
| Compilación durante `dotnet test TransPort.sln --no-restore` | Correcta |
| Pruebas de API | 23 aprobadas, 0 fallidas |
| Pruebas de MVC | 1 aprobada, 0 fallidas |
| Total | **24 aprobadas, 0 fallidas** |
| `docker-compose config -q` | Configuración válida |
| Contenedores activos durante esta revisión | API y Web activos; `/salud`, `/` y `/admin/auditoria` respondieron correctamente |
| Smoke test de clientes | CRUD, filtro, asignaciones, auditoría y eliminación lógica correctos |
| Smoke test de catálogos | CRUD de roles, giros y sedes, MVC, auditoría y autorización correctos |
| Smoke test de auditoría | Filtros, dos páginas sin duplicados, MVC y autorización correctos |
| Smoke test de pedidos | Creación, cotización, comentarios, documentos, historial, aislamiento y eliminación lógica correctos |
| Smoke test del portal cliente | Empresas, servicios, indicadores, MVC, aislamiento entre clientes y autorización correctos |

Cobertura actual:

- Creación y validación de JWT.
- Rechazo de token alterado.
- Rechazo de clave JWT demasiado corta.
- Login válido y carga de alcances.
- Auditoría segura de login fallido.
- Limpieza de sesión y autenticación al cerrar sesión.
- Creación, eliminación y protección de asignaciones del controlador API de clientes.
- Creación y eliminación de catálogos, rechazo de tipos inválidos y protección del rol administrador.
- Paso de filtros y paginación del controlador de auditoría al repositorio.
- Exigencia del rol AdministradorGeneral en el controlador administrativo.
- Alcance de cliente, estados válidos, autorización comercial y eliminación en
  el controlador de pedidos.
- Propagación de identidad y autorización del resumen del portal cliente.

El smoke test creó un cliente temporal, consultó y actualizó sus datos, validó el filtro y las asignaciones de usuario/giro, y ejecutó su eliminación lógica. SQL Server confirmó cero relaciones activas, cinco eventos de auditoría y ningún cliente de prueba visible al finalizar.

El recorrido de M12 creó una cotización como cliente, la gestionó como
administrador, agregó comentario y documento, verificó historial y monto,
confirmó 403 para un empleado sin rol comercial y eliminó lógicamente todos los
registros temporales.

## 10. Riesgos y deuda técnica conocida

| Prioridad | Tema | Situación actual |
|---|---|---|
| Alta antes de producción | Contraseñas | Texto plano por decisión académica de Fase 1; deben migrarse a hashes seguros. |
| Alta antes de escalar | Sesión MVC | Se almacena en memoria de un único contenedor. |
| Alta antes de producción | Secretos y HTTPS | Deben administrarse fuera de archivos y desplegarse con HTTPS estricto. |
| Media | Pruebas | La cobertura actual es pequeña frente al número de endpoints y SP. |
| Media | Excepciones por cancelación | Conviene evitar registrar cancelaciones normales como fallos 500. |
| Media | Disponibilidad SQL Server | Existe una única instancia externa; no hay estrategia documentada de respaldo/alta disponibilidad. |
| Baja para Fase 1 | Escalamiento/orquestación | Compose cubre desarrollo, no balanceo o autoescalamiento de producción. |

## 11. Orden recomendado para la siguiente etapa

1. Aumentar pruebas de integración para usuarios, autorización, SQL Server y flujos HTTP.
2. Sustituir contraseñas en texto plano por hashes antes de usar datos reales.
3. Integrar en el portal el seguimiento de transporte cuando se implemente M18.
4. Implementar inventario y producción como soporte del flujo comercial.
5. Implementar transporte, maquinaria y GPS.
6. Agregar alertas, comunicación e integraciones externas.
7. Construir reportes operativos, financieros y consolidados.
8. Migrar la sesión a almacenamiento distribuido y agregar balanceo cuando se necesiten varias réplicas.

## 12. Conclusión

El proyecto dispone de una base técnica coherente y extensible. La Fase 1 cubre el acceso, la estructura organizacional, el control de usuarios, los portales iniciales, la persistencia y el despliegue local. M12 inicia la operación comercial real sobre esas asociaciones; el siguiente paso es ampliar el portal del cliente y conectar pedidos con inventario, abastecimiento y producción.


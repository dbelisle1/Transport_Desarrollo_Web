[CmdletBinding()]
param(
    [string]$ApiBaseUrl = 'http://localhost:8081',
    [string]$WebBaseUrl = 'http://localhost:8080',
    [string]$SqlServer = '.\SQLEXPRESS',
    [string]$SqlDatabase = 'TransPortDB',
    [string]$SqlUser = '',
    [switch]$VerificarInstalador,
    [string]$AdminUser = 'admin.demo',
    [string]$AdminPassword = 'TransPortAdmin2026!',
    [string]$EmployeeUser = 'empleado.demo',
    [string]$EmployeePassword = 'TransPortEmpleado2026!',
    [string]$ClientUser = 'cliente.demo',
    [string]$ClientPassword = 'TransPortCliente2026!',
    [string]$ManagerUser = 'gerente.demo',
    [string]$ManagerPassword = 'TransPortGerente2026!',
    [string]$OperatorUser = 'operativo.demo',
    [string]$OperatorPassword = 'TransPortOperativo2026!',
    [string]$SellerUser = 'vendedor.demo',
    [string]$SellerPassword = 'TransPortVendedor2026!',
    [string]$SecondClientUser = 'cliente2.demo',
    [string]$SecondClientPassword = 'TransPortCliente22026!',
    [string]$ThirdClientUser = 'cliente3.demo',
    [string]$ThirdClientPassword = 'TransPortCliente32026!'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Net.Http

$root = Split-Path -Parent $PSScriptRoot
$suffix = [Guid]::NewGuid().ToString('N').Substring(0, 12)
$temporaryUser = "c04.$suffix"
$temporaryPassword = 'TemporalC04!2026'
$temporaryNit = "C04-$suffix"
$invalidUser = "inexistente.$suffix"
$script:passed = 0
$script:auditStartId = 0L
$script:temporaryUserId = 0
$script:temporaryClientId = 0
$script:adminId = 0
$script:employeeId = 0
$script:demoClientUserId = 0
$script:managerId = 0
$script:operatorId = 0
$script:sellerId = 0
$script:secondClientUserId = 0
$script:thirdClientUserId = 0

$ApiBaseUrl = $ApiBaseUrl.TrimEnd('/')
$WebBaseUrl = $WebBaseUrl.TrimEnd('/')

function Write-Pass([string]$Message) {
    $script:passed++
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "Validación fallida: $Message" }
}

function Assert-Status($Response, [int[]]$Expected, [string]$Message) {
    if ($Expected -notcontains $Response.Status) {
        throw "Validación fallida: $Message. HTTP $($Response.Status). Respuesta: $($Response.Body)"
    }
    Write-Pass "$Message (HTTP $($Response.Status))"
}

function Assert-List([string]$Path, [string]$Token, [string]$Message) {
    $response = Invoke-TransportHttp -Method GET -Path $Path -Token $Token
    if ($response.Status -ne 200) {
        throw "Validación fallida: $Message. HTTP $($response.Status). Respuesta: $($response.Body)"
    }
    if (@($response.Json).Count -lt 1) {
        throw "Validación fallida: $Message no devolvió registros."
    }
    Write-Pass "$Message ($(@($response.Json).Count) registros)"
    return $response
}

function Invoke-TransportHttp {
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Path,
        [string]$Token = '',
        $Body = $null,
        [string]$BaseUrl = $ApiBaseUrl
    )

    $uri = if ($Path.StartsWith('http', [StringComparison]::OrdinalIgnoreCase)) {
        $Path
    } else {
        "$($BaseUrl.TrimEnd('/'))/$($Path.TrimStart('/'))"
    }

    $request = [System.Net.Http.HttpRequestMessage]::new(
        [System.Net.Http.HttpMethod]::new($Method.ToUpperInvariant()), $uri)
    try {
        if (-not [string]::IsNullOrWhiteSpace($Token)) {
            $request.Headers.Authorization =
                [System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $Token)
        }
        if ($null -ne $Body) {
            $json = $Body | ConvertTo-Json -Depth 20 -Compress
            $request.Content = [System.Net.Http.StringContent]::new(
                $json, [Text.Encoding]::UTF8, 'application/json')
        }

        $response = $script:http.SendAsync($request).GetAwaiter().GetResult()
        try {
            $text = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            $data = $null
            if (-not [string]::IsNullOrWhiteSpace($text)) {
                try { $data = $text | ConvertFrom-Json } catch { $data = $null }
            }
            $location = if ($null -ne $response.Headers.Location) {
                $response.Headers.Location.ToString()
            } else { '' }
            return [pscustomobject]@{
                Status = [int]$response.StatusCode
                Body = $text
                Json = $data
                Location = $location
            }
        }
        finally { $response.Dispose() }
    }
    finally { $request.Dispose() }
}

function Login([string]$User, [string]$Password, [string]$Label) {
    $response = Invoke-TransportHttp -Method POST -Path '/api/auth/login' -Body @{
        nombreUsuario = $User
        clave = $Password
    }
    Assert-Status $response @(200) "Login de $Label"
    Assert-True (-not [string]::IsNullOrWhiteSpace([string]$response.Json.token)) `
        "El login de $Label debe emitir un token"
    return $response.Json
}

function Get-SqlArguments([switch]$WithoutDatabase) {
    $arguments = @('-S', $SqlServer, '-C', '-b', '-r', '1', '-W')
    if (-not $WithoutDatabase) { $arguments += @('-d', $SqlDatabase) }
    if ([string]::IsNullOrWhiteSpace($SqlUser)) {
        $arguments += '-E'
    } else {
        if ([string]::IsNullOrWhiteSpace($env:SQLCMDPASSWORD)) {
            throw 'Defina SQLCMDPASSWORD antes de usar -SqlUser; la clave no se acepta como argumento.'
        }
        $arguments += @('-U', $SqlUser)
    }
    return $arguments
}

function Invoke-SqlText([string]$Query) {
    $arguments = Get-SqlArguments
    $arguments += @('-h', '-1', '-s', '|', '-Q', $Query)
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & sqlcmd @arguments 2>&1 | Out-String
        $exitCode = $LASTEXITCODE
    }
    finally { $ErrorActionPreference = $previousPreference }
    if ($exitCode -ne 0) { throw "SQLCMD falló: $output" }
    return $output.Trim()
}

function Invoke-Installer {
    $arguments = Get-SqlArguments -WithoutDatabase
    $arguments += @('-f', '65001', '-i', '.\000_instalar_todo.sql')
    Push-Location (Join-Path $root 'database')
    try {
        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $output = & sqlcmd @arguments 2>&1 | Out-String
            $exitCode = $LASTEXITCODE
        }
        finally { $ErrorActionPreference = $previousPreference }
        if ($exitCode -ne 0) { throw "El instalador SQL falló: $output" }
    }
    finally { Pop-Location }
}

function Sql-Literal([string]$Value) {
    return "N'$($Value.Replace("'", "''"))'"
}

function Cleanup-TestData {
    $userLiteral = Sql-Literal $temporaryUser
    $invalidLiteral = Sql-Literal $invalidUser
    $nitLiteral = Sql-Literal $temporaryNit
    $query = @"
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_WARNINGS ON;
SET ANSI_PADDING ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
BEGIN TRANSACTION;
DECLARE @UsuarioId INT=(SELECT TOP(1) UsuarioId FROM dbo.Usuario WHERE NombreUsuario=$userLiteral);
DECLARE @ClienteId INT=(SELECT TOP(1) ClienteId FROM dbo.Cliente WHERE Nit=$nitLiteral);
DELETE FROM dbo.Auditoria
WHERE AuditoriaId>$($script:auditStartId)
  AND (
      UsuarioId=@UsuarioId
      OR (Modulo=N'Usuarios' AND IdentificadorRegistro=CONVERT(NVARCHAR(100),@UsuarioId))
      OR (Modulo=N'Clientes' AND IdentificadorRegistro=CONVERT(NVARCHAR(100),@ClienteId))
      OR (Modulo=N'Seguridad' AND IdentificadorRegistro IN
          ($userLiteral,$invalidLiteral,CONVERT(NVARCHAR(100),@UsuarioId),
           N'$($script:adminId)',N'$($script:employeeId)',N'$($script:demoClientUserId)',
           N'$($script:managerId)',N'$($script:operatorId)',N'$($script:sellerId)',
           N'$($script:secondClientUserId)',N'$($script:thirdClientUserId)'))
  );
IF @ClienteId IS NOT NULL
BEGIN
    DELETE FROM dbo.ClienteGiroNegocio WHERE ClienteId=@ClienteId;
    DELETE FROM dbo.ClienteUsuario WHERE ClienteId=@ClienteId;
    DELETE FROM dbo.Cliente WHERE ClienteId=@ClienteId;
END;
IF @UsuarioId IS NOT NULL
BEGIN
    DELETE FROM dbo.UsuarioRol WHERE UsuarioId=@UsuarioId;
    DELETE FROM dbo.UsuarioGiroNegocio WHERE UsuarioId=@UsuarioId;
    DELETE FROM dbo.UsuarioSede WHERE UsuarioId=@UsuarioId;
    DELETE FROM dbo.Usuario WHERE UsuarioId=@UsuarioId;
END;
COMMIT TRANSACTION;
SELECT N'LIMPIO';
"@
    $result = Invoke-SqlText $query
    Assert-True ($result -match 'LIMPIO') 'La limpieza SQL debe finalizar correctamente'
}

if ($null -eq (Get-Command sqlcmd -ErrorAction SilentlyContinue)) {
    throw 'No se encontró SQLCMD. Instálelo o ejecute la validación desde una máquina con las herramientas de SQL Server.'
}

$handler = [System.Net.Http.HttpClientHandler]::new()
$handler.AllowAutoRedirect = $false
$script:http = [System.Net.Http.HttpClient]::new($handler)
$script:http.Timeout = [TimeSpan]::FromSeconds(30)
$failure = $null

try {
    if ($VerificarInstalador) {
        Invoke-Installer
        Invoke-Installer
        Write-Pass 'Instalador SQL idempotente ejecutado dos veces'
    }

    $script:auditStartId = [long](Invoke-SqlText `
        'SET NOCOUNT ON; SELECT ISNULL(MAX(AuditoriaId),0) FROM dbo.Auditoria;')

    $schema = (Invoke-SqlText @'
SET NOCOUNT ON;
SELECT CONCAT(
 (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0),N'|',
 (SELECT COUNT(*) FROM sys.foreign_keys),N'|',
 (SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0));
'@).Split('|')
    Assert-True ([int]$schema[0] -ge 51) 'La base debe contener al menos 51 tablas'
    Assert-True ([int]$schema[1] -ge 114) 'La base debe contener al menos 114 claves foráneas'
    Assert-True ([int]$schema[2] -ge 163) 'La base debe contener al menos 163 procedimientos'
    Write-Pass "Esquema SQL completo: $($schema[0]) tablas, $($schema[1]) FK, $($schema[2]) SP"

    $requiredProcedures = [int](Invoke-SqlText @'
SET NOCOUNT ON;
SELECT COUNT(*) FROM sys.procedures WHERE name IN
(N'sp_usuario_validar_credenciales',N'sp_usuario_crear_registro',N'sp_usuario_eliminar_logico',
 N'sp_cliente_crear_registro',N'sp_cliente_eliminar_logico',N'sp_reportes_leer_interno',
 N'sp_reportes_leer_cliente');
'@)
    Assert-True ($requiredProcedures -eq 7) 'Deben existir los siete procedimientos críticos auditados'
    Write-Pass 'Procedimientos críticos disponibles'

    $health = Invoke-TransportHttp -Method GET -Path '/salud'
    Assert-Status $health @(200) 'API saludable'
    Assert-True ($health.Json.estado -eq 'ok') 'El endpoint de salud debe responder estado ok'

    $publicHome = Invoke-TransportHttp -Method GET -Path '/' -BaseUrl $WebBaseUrl
    Assert-Status $publicHome @(200) 'Sitio público disponible'
    $adminAnonymous = Invoke-TransportHttp -Method GET -Path '/admin' -BaseUrl $WebBaseUrl
    Assert-Status $adminAnonymous @(302) 'Panel administrativo protegido por cookie'
    Assert-True ($adminAnonymous.Location -match '/acceso') 'El panel anónimo debe redirigir al acceso'

    $publicCatalog = Invoke-TransportHttp -Method GET -Path '/api/catalogo-comercial/publico'
    Assert-Status $publicCatalog @(200) 'Catálogo público anónimo'
    $anonymousAdmin = Invoke-TransportHttp -Method GET -Path '/api/administracion/resumen'
    Assert-Status $anonymousAdmin @(401) 'API administrativa rechaza solicitudes anónimas'

    $badLogin = Invoke-TransportHttp -Method POST -Path '/api/auth/login' -Body @{
        nombreUsuario = $invalidUser
        clave = 'incorrecta'
    }
    Assert-Status $badLogin @(401) 'Credenciales inválidas rechazadas'

    $admin = Login $AdminUser $AdminPassword 'AdministradorGeneral'
    $employee = Login $EmployeeUser $EmployeePassword 'Empleado'
    $demoClient = Login $ClientUser $ClientPassword 'Cliente'
    $manager = Login $ManagerUser $ManagerPassword 'Gerente'
    $operator = Login $OperatorUser $OperatorPassword 'Operativo'
    $seller = Login $SellerUser $SellerPassword 'Vendedor'
    $secondClient = Login $SecondClientUser $SecondClientPassword 'Cliente 2'
    $thirdClient = Login $ThirdClientUser $ThirdClientPassword 'Cliente 3'
    $script:adminId = [int]$admin.usuario.usuarioId
    $script:employeeId = [int]$employee.usuario.usuarioId
    $script:demoClientUserId = [int]$demoClient.usuario.usuarioId
    $script:managerId = [int]$manager.usuario.usuarioId
    $script:operatorId = [int]$operator.usuario.usuarioId
    $script:sellerId = [int]$seller.usuario.usuarioId
    $script:secondClientUserId = [int]$secondClient.usuario.usuarioId
    $script:thirdClientUserId = [int]$thirdClient.usuario.usuarioId

    Assert-True (@($admin.usuario.roles) -contains 'AdministradorGeneral') 'El administrador debe recibir su rol'
    Assert-True (@($employee.usuario.roles) -contains 'Empleado') 'El empleado debe recibir su rol'
    Assert-True (@($demoClient.usuario.roles) -contains 'Cliente') 'El cliente debe recibir su rol'
    Assert-True (@($manager.usuario.roles) -contains 'Gerente') 'El gerente debe recibir su rol'
    Assert-True (@($operator.usuario.roles) -contains 'Operativo') 'El operativo debe recibir su rol'
    Assert-True (@($seller.usuario.roles) -contains 'Vendedor') 'El vendedor debe recibir su rol'
    Assert-True (@($secondClient.usuario.roles) -contains 'Cliente') 'El cliente 2 debe recibir su rol'
    Assert-True (@($thirdClient.usuario.roles) -contains 'Cliente') 'El cliente 3 debe recibir su rol'
    Assert-True (@($secondClient.usuario.clientes).Count -eq 1) 'El cliente 2 debe tener una empresa'
    Assert-True (@($thirdClient.usuario.clientes).Count -eq 2) 'El cliente 3 debe tener dos empresas'
    Write-Pass 'Claims de todos los roles y clientes cargados desde SQL Server'

    $adminSummary = Invoke-TransportHttp -Method GET -Path '/api/administracion/resumen' -Token $admin.token
    Assert-Status $adminSummary @(200) 'Administrador accede al resumen'
    $employeeAdmin = Invoke-TransportHttp -Method GET -Path '/api/administracion/resumen' -Token $employee.token
    Assert-Status $employeeAdmin @(403) 'Empleado no accede a administración'
    $clientAdmin = Invoke-TransportHttp -Method GET -Path '/api/administracion/resumen' -Token $demoClient.token
    Assert-Status $clientAdmin @(403) 'Cliente no accede a administración'
    $managerAdmin = Invoke-TransportHttp -Method GET -Path '/api/clientes' -Token $manager.token
    Assert-Status $managerAdmin @(403) 'Gerente no accede al CRUD reservado al administrador'

    Assert-List '/api/pedidos?busqueda=DEMO' $manager.token 'Gerente consulta pedidos demo' | Out-Null
    Assert-List '/api/inventarios?busqueda=DEMO' $manager.token 'Gerente consulta inventario demo' | Out-Null
    Assert-List '/api/abastecimientos?busqueda=DEMO' $manager.token 'Gerente consulta abastecimientos demo' | Out-Null
    Assert-List '/api/extracciones' $manager.token 'Gerente consulta extracciones' | Out-Null
    Assert-List '/api/producciones' $manager.token 'Gerente consulta producción' | Out-Null
    Assert-List '/api/maquinarias?busqueda=DEMO' $manager.token 'Gerente consulta maquinaria demo' | Out-Null
    Assert-List '/api/transportes' $manager.token 'Gerente consulta transporte' | Out-Null
    Assert-List '/api/construcciones?busqueda=DEMO' $manager.token 'Gerente consulta construcciones demo' | Out-Null
    Assert-List '/api/finanzas' $manager.token 'Gerente consulta presupuestos' | Out-Null
    Assert-List '/api/finanzas/ingresos' $manager.token 'Gerente consulta ingresos' | Out-Null
    Assert-List '/api/alertas' $manager.token 'Gerente consulta alertas' | Out-Null
    Assert-List '/api/comunicaciones?busqueda=DEMO' $manager.token 'Gerente consulta comunicaciones demo' | Out-Null
    Assert-List '/api/integraciones?busqueda=DEMO' $manager.token 'Gerente consulta integraciones demo' | Out-Null
    $managerGps = Invoke-TransportHttp -Method GET -Path '/api/gps' -Token $manager.token
    Assert-Status $managerGps @(200) 'Gerente consulta resumen GPS'
    $managerReport = Invoke-TransportHttp -Method GET -Path '/api/reportes/interno' -Token $manager.token
    Assert-Status $managerReport @(200) 'Gerente consulta reporte consolidado'

    Assert-List '/api/extracciones' $employee.token 'Empleado consulta extracción de su sede' | Out-Null
    Assert-List '/api/producciones' $operator.token 'Operativo consulta producción asignada' | Out-Null
    Assert-List '/api/transportes' $operator.token 'Operativo consulta viajes asignados' | Out-Null
    Assert-List '/api/pedidos?busqueda=DEMO' $seller.token 'Vendedor consulta pedidos comerciales' | Out-Null
    $sellerProduction = Invoke-TransportHttp -Method GET -Path '/api/producciones' -Token $seller.token
    Assert-Status $sellerProduction @(403) 'Vendedor no accede a producción interna'

    $secondClientPortal = Invoke-TransportHttp -Method GET -Path '/api/portal-cliente/operaciones' -Token $secondClient.token
    Assert-Status $secondClientPortal @(200) 'Cliente 2 consulta sus operaciones'
    $secondClientReport = Invoke-TransportHttp -Method GET -Path '/api/reportes/cliente' -Token $secondClient.token
    Assert-Status $secondClientReport @(200) 'Cliente 2 consulta su reporte'
    Assert-True ([int]$secondClientReport.Json.resumen.empresas -eq 1) 'El reporte del cliente 2 debe incluir una empresa'
    $thirdClientPortal = Invoke-TransportHttp -Method GET -Path '/api/portal-cliente/operaciones' -Token $thirdClient.token
    Assert-Status $thirdClientPortal @(200) 'Cliente 3 consulta operaciones de dos empresas'
    $thirdClientReport = Invoke-TransportHttp -Method GET -Path '/api/reportes/cliente' -Token $thirdClient.token
    Assert-Status $thirdClientReport @(200) 'Cliente 3 consulta su reporte consolidado'
    Assert-True ([int]$thirdClientReport.Json.resumen.empresas -eq 2) 'El reporte del cliente 3 debe incluir dos empresas'
    Write-Pass 'Aislamiento de clientes demo verificado para una y dos empresas'

    $roles = Invoke-TransportHttp -Method GET -Path '/api/catalogos/roles' -Token $admin.token
    $giros = Invoke-TransportHttp -Method GET -Path '/api/catalogos/giros' -Token $admin.token
    $sedes = Invoke-TransportHttp -Method GET -Path '/api/catalogos/sedes' -Token $admin.token
    Assert-Status $roles @(200) 'Catálogo de roles accesible al administrador'
    Assert-Status $giros @(200) 'Catálogo de giros accesible al administrador'
    Assert-Status $sedes @(200) 'Catálogo de sedes accesible al administrador'

    $clientRole = @($roles.Json) | Where-Object { $_.nombre -eq 'Cliente' } | Select-Object -First 1
    $transportGiro = @($giros.Json) | Where-Object { $_.nombre -eq 'Transporte nacional e internacional' } | Select-Object -First 1
    Assert-True ($null -ne $clientRole) 'Debe existir el rol Cliente'
    Assert-True ($null -ne $transportGiro) 'Debe existir el giro de transporte internacional'

    $employeeGiro = @($employee.usuario.giros) | Select-Object -First 1
    $employeeSite = @($employee.usuario.sedes) | Select-Object -First 1
    Assert-True ($null -ne $employeeGiro) 'El empleado demo debe tener un giro asignado'
    Assert-True ($null -ne $employeeSite) 'El empleado demo debe tener una sede asignada'
    $foreignGiro = @($giros.Json) | Where-Object { [int]$_.id -ne [int]$employeeGiro.id } | Select-Object -First 1
    $foreignSite = @($sedes.Json) | Where-Object { [int]$_.id -ne [int]$employeeSite.id } | Select-Object -First 1

    $employeeAllowed = Invoke-TransportHttp -Method GET `
        -Path "/api/reportes/interno?giroId=$($employeeGiro.id)&sedeId=$($employeeSite.id)" `
        -Token $employee.token
    Assert-Status $employeeAllowed @(200) 'Empleado consulta su giro y sede asignados'
    $employeeForeignGiro = Invoke-TransportHttp -Method GET `
        -Path "/api/reportes/interno?giroId=$($foreignGiro.id)" -Token $employee.token
    Assert-Status $employeeForeignGiro @(409) 'Empleado no consulta un giro ajeno'
    $employeeForeignSite = Invoke-TransportHttp -Method GET `
        -Path "/api/reportes/interno?sedeId=$($foreignSite.id)" -Token $employee.token
    Assert-Status $employeeForeignSite @(409) 'Empleado no consulta una sede ajena'
    $clientInternal = Invoke-TransportHttp -Method GET -Path '/api/reportes/interno' -Token $demoClient.token
    Assert-Status $clientInternal @(403) 'Cliente no accede a reportes internos'
    $employeeClientReport = Invoke-TransportHttp -Method GET -Path '/api/reportes/cliente' -Token $employee.token
    Assert-Status $employeeClientReport @(403) 'Empleado no accede a reportes de cliente'

    $createUser = Invoke-TransportHttp -Method POST -Path '/api/usuarios' -Token $admin.token -Body @{
        nombreUsuario = $temporaryUser
        nombre = 'Prueba'
        apellido = 'Integracion C04'
        correo = "$temporaryUser@transport.local"
        clave = $temporaryPassword
        esActivo = $true
    }
    Assert-Status $createUser @(201) 'Creación HTTP de usuario temporal'
    $script:temporaryUserId = [int]$createUser.Json.id

    $assignUser = Invoke-TransportHttp -Method PUT `
        -Path "/api/usuarios/$($script:temporaryUserId)/asignaciones" -Token $admin.token -Body @{
        roles = @([int]$clientRole.id)
        giros = @()
        sedes = @()
    }
    Assert-Status $assignUser @(204) 'Asignación transaccional del rol Cliente'

    $createClient = Invoke-TransportHttp -Method POST -Path '/api/clientes' -Token $admin.token -Body @{
        nombre = "Cliente integración C04 $suffix"
        nit = $temporaryNit
        correoContacto = "$temporaryUser@transport.local"
        esActivo = $true
        usuarios = @($script:temporaryUserId)
        giros = @([int]$transportGiro.id)
    }
    Assert-Status $createClient @(201) 'Creación HTTP de cliente con asociaciones'
    $script:temporaryClientId = [int]$createClient.Json.id

    $clientDetail = Invoke-TransportHttp -Method GET `
        -Path "/api/clientes/$($script:temporaryClientId)" -Token $admin.token
    Assert-Status $clientDetail @(200) 'Lectura del cliente creado'
    Assert-True (@($clientDetail.Json.usuarios.id) -contains $script:temporaryUserId) `
        'La relación cliente-usuario debe persistirse'
    Assert-True (@($clientDetail.Json.giros.id) -contains [int]$transportGiro.id) `
        'La relación cliente-giro debe persistirse'
    Write-Pass 'Asociaciones cliente-usuario-giro verificadas'

    $updateClient = Invoke-TransportHttp -Method PUT `
        -Path "/api/clientes/$($script:temporaryClientId)" -Token $admin.token -Body @{
        nombre = "Cliente integración C04 actualizado $suffix"
        nit = $temporaryNit
        correoContacto = "actualizado.$temporaryUser@transport.local"
        esActivo = $true
        usuarios = @($script:temporaryUserId)
        giros = @([int]$transportGiro.id)
    }
    Assert-Status $updateClient @(204) 'Actualización HTTP del cliente'

    $temporaryLogin = Login $temporaryUser $temporaryPassword 'Cliente temporal'
    Assert-True (@($temporaryLogin.usuario.clientes.id) -contains $script:temporaryClientId) `
        'El JWT debe incluir solamente la empresa asociada al usuario temporal'
    Write-Pass 'Identidad temporal incluye su relación de cliente'

    $ownReport = Invoke-TransportHttp -Method GET `
        -Path "/api/reportes/cliente?clienteId=$($script:temporaryClientId)" -Token $temporaryLogin.token
    Assert-Status $ownReport @(200) 'Cliente consulta el reporte de su empresa'
    Assert-True ([int]$ownReport.Json.resumen.empresas -eq 1) 'El reporte propio debe incluir una empresa'

    $allClients = Invoke-TransportHttp -Method GET -Path '/api/clientes' -Token $admin.token
    $foreignClient = @($allClients.Json) | Where-Object {
        [int]$_.clienteId -ne $script:temporaryClientId
    } | Select-Object -First 1
    Assert-True ($null -ne $foreignClient) 'Debe existir una empresa ajena para validar aislamiento'
    $foreignReport = Invoke-TransportHttp -Method GET `
        -Path "/api/reportes/cliente?clienteId=$($foreignClient.clienteId)" -Token $temporaryLogin.token
    Assert-Status $foreignReport @(200) 'Consulta aislada de empresa ajena'
    Assert-True ([int]$foreignReport.Json.resumen.empresas -eq 0) `
        'Una empresa ajena no debe exponer información al cliente'
    Write-Pass 'Aislamiento entre empresas cliente verificado'

    $temporaryAdmin = Invoke-TransportHttp -Method GET -Path '/api/clientes' -Token $temporaryLogin.token
    Assert-Status $temporaryAdmin @(403) 'Cliente temporal no accede al CRUD administrativo'

    $deleteClient = Invoke-TransportHttp -Method DELETE `
        -Path "/api/clientes/$($script:temporaryClientId)" -Token $admin.token
    Assert-Status $deleteClient @(204) 'Eliminación lógica HTTP del cliente'
    $deletedClient = Invoke-TransportHttp -Method GET `
        -Path "/api/clientes/$($script:temporaryClientId)" -Token $admin.token
    Assert-Status $deletedClient @(404) 'Cliente eliminado deja de estar disponible'

    $clientSql = (Invoke-SqlText @"
SET NOCOUNT ON;
SELECT CONCAT(CONVERT(INT,c.Eliminado),N'|',CONVERT(INT,c.EsActivo),N'|',
 (SELECT COUNT(*) FROM dbo.ClienteUsuario WHERE ClienteId=c.ClienteId AND Eliminado=1),N'|',
 (SELECT COUNT(*) FROM dbo.ClienteGiroNegocio WHERE ClienteId=c.ClienteId AND Eliminado=1),N'|',
 (SELECT COUNT(*) FROM dbo.Auditoria WHERE Modulo=N'Clientes' AND IdentificadorRegistro=CONVERT(NVARCHAR(100),c.ClienteId)))
FROM dbo.Cliente c WHERE c.ClienteId=$($script:temporaryClientId);
"@).Split('|')
    Assert-True ($clientSql[0] -eq '1' -and $clientSql[1] -eq '0') `
        'SQL debe marcar el cliente como eliminado e inactivo'
    Assert-True ([int]$clientSql[2] -ge 1 -and [int]$clientSql[3] -ge 1) `
        'SQL debe eliminar lógicamente las asociaciones del cliente'
    Assert-True ([int]$clientSql[4] -ge 4) 'Las operaciones del cliente deben quedar auditadas'
    Write-Pass 'Eliminación lógica, asociaciones y auditoría del cliente verificadas en SQL'

    $deleteUser = Invoke-TransportHttp -Method DELETE `
        -Path "/api/usuarios/$($script:temporaryUserId)" -Token $admin.token
    Assert-Status $deleteUser @(204) 'Eliminación lógica HTTP del usuario'
    $deletedUserLogin = Invoke-TransportHttp -Method POST -Path '/api/auth/login' -Body @{
        nombreUsuario = $temporaryUser
        clave = $temporaryPassword
    }
    Assert-Status $deletedUserLogin @(401) 'Usuario eliminado no puede iniciar sesión'

    $userSql = (Invoke-SqlText @"
SET NOCOUNT ON;
SELECT CONCAT(CONVERT(INT,u.Eliminado),N'|',CONVERT(INT,u.EsActivo),N'|',
 (SELECT COUNT(*) FROM dbo.UsuarioRol WHERE UsuarioId=u.UsuarioId AND Eliminado=1),N'|',
 (SELECT COUNT(*) FROM dbo.Auditoria WHERE Modulo=N'Usuarios' AND IdentificadorRegistro=CONVERT(NVARCHAR(100),u.UsuarioId)))
FROM dbo.Usuario u WHERE u.UsuarioId=$($script:temporaryUserId);
"@).Split('|')
    Assert-True ($userSql[0] -eq '1' -and $userSql[1] -eq '0') `
        'SQL debe marcar el usuario como eliminado e inactivo'
    Assert-True ([int]$userSql[2] -ge 1) 'SQL debe eliminar lógicamente el rol asignado'
    Assert-True ([int]$userSql[3] -ge 3) 'Las operaciones del usuario deben quedar auditadas'
    Write-Pass 'Eliminación lógica, rol y auditoría del usuario verificados en SQL'
}
catch {
    $failure = $_
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    try {
        Cleanup-TestData
        Write-Host '[LIMPIEZA] Los registros temporales y sus auditorías fueron retirados.' -ForegroundColor Cyan
    }
    catch {
        Write-Host "[ERROR DE LIMPIEZA] $($_.Exception.Message)" -ForegroundColor Red
        if ($null -eq $failure) { $failure = $_ }
    }
    $script:http.Dispose()
    $handler.Dispose()
}

if ($null -ne $failure) { throw $failure }

$artifactDirectory = Join-Path $root 'artifacts\integracion'
New-Item -ItemType Directory -Path $artifactDirectory -Force | Out-Null
$reportPath = Join-Path $artifactDirectory 'ultimo-resultado.json'
[pscustomobject]@{
    fechaUtc = [DateTime]::UtcNow.ToString('O')
    resultado = 'Correcto'
    comprobaciones = $script:passed
    api = $ApiBaseUrl
    sqlServer = $SqlServer
    esquema = $SqlDatabase
    datosTemporalesLimpiados = $true
} | ConvertTo-Json | Set-Content -Path $reportPath -Encoding UTF8

Write-Host "Validación HTTP/SQL correcta: $($script:passed) comprobaciones." -ForegroundColor Green
Write-Host "Resultado: $reportPath"

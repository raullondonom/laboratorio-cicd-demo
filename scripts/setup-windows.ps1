#Requires -Version 5.1
<#
.SYNOPSIS
  Prepara una maquina Windows para el Laboratorio CI/CD.

.DESCRIPTION
  Idempotente. Para cada componente:
    - Detecta si esta instalado y en la version correcta.
    - Si no, lo desinstala (si aplica) y lo instala con winget / nvm.
    - Refresca el PATH del proceso actual.
    - Valida con la version esperada.

  Componentes:
    * Python 3.12.10 (desinstala TODAS las versiones previas de Python).
    * nvm-windows (CoreyButler.NVMforWindows).
    * Node.js 20.11.1 via nvm.
    * GitHub CLI (gh).
    * Verifica Docker Desktop y git.

  Salida: tabla resumen con estado final (OK / FALLO) y codigo de salida 0/1.

.PARAMETER NoConfirm
  Salta la confirmacion interactiva antes de desinstalar Python.

.PARAMETER DryRun
  Modo simulacion: NO desinstala, NO instala, NO borra carpetas, NO modifica PATH.
  Solo imprime que haria. Util para auditar antes de ejecutar de verdad.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\scripts\setup-windows.ps1 -DryRun
  powershell -ExecutionPolicy Bypass -File .\scripts\setup-windows.ps1 -NoConfirm
#>

[CmdletBinding()]
param(
  [switch]$NoConfirm,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$PythonTargetVersion = '3.12.10'
$PythonTargetMajMin  = '3.12'      # se usa para no desinstalar el paquete winget de la familia objetivo
$NodeTargetVersion   = '20.11.1'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-Section($Title) {
  $line = '=' * 70
  Write-Host ''
  Write-Host $line -ForegroundColor Cyan
  Write-Host (" " + $Title) -ForegroundColor Cyan
  Write-Host $line -ForegroundColor Cyan
}

function Write-Step($Msg)    { Write-Host "[*] $Msg" -ForegroundColor White }
function Write-Ok($Msg)      { Write-Host "[OK] $Msg" -ForegroundColor Green }
function Write-Warn2($Msg)   { Write-Host "[!] $Msg" -ForegroundColor Yellow }
function Write-Err2($Msg)    { Write-Host "[X] $Msg" -ForegroundColor Red }
function Write-Dry($Msg)     { Write-Host "[DRY-RUN] $Msg" -ForegroundColor Magenta }

function Test-IsAdmin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object Security.Principal.WindowsPrincipal($id)
  return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Update-EnvPath {
  $machine = [Environment]::GetEnvironmentVariable('PATH','Machine')
  $user    = [Environment]::GetEnvironmentVariable('PATH','User')
  $env:PATH = "$machine;$user"
}

function Test-WingetAvailable {
  try { (Get-Command winget -ErrorAction Stop) | Out-Null; return $true }
  catch { return $false }
}

function Invoke-Winget {
  param([Parameter(Mandatory)][string[]]$WingetArgs)
  if ($DryRun) {
    Write-Dry "winget $($WingetArgs -join ' ')"
    return 0
  }
  Write-Step "winget $($WingetArgs -join ' ')"
  & winget @WingetArgs 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
  return $LASTEXITCODE
}

function Remove-FolderSafe {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path $Path)) { return }
  if ($DryRun) {
    $size = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $sizeMB = [math]::Round(($size / 1MB), 1)
    Write-Dry "Borraria carpeta: $Path  (~$sizeMB MB)"
    return
  }
  Write-Step "Borrando $Path ..."
  try {
    Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
    Write-Ok "Eliminado: $Path"
  } catch {
    Write-Warn2 "No se pudo eliminar $Path : $($_.Exception.Message)"
  }
}

function Remove-PathEntries {
  param([Parameter(Mandatory)][string[]]$Patterns)
  foreach ($scope in 'User','Machine') {
    $current = [Environment]::GetEnvironmentVariable('PATH', $scope)
    if (-not $current) { continue }
    $entries = $current -split ';' | Where-Object { $_ -ne '' }
    $kept = @()
    $removed = @()
    foreach ($e in $entries) {
      $match = $false
      foreach ($p in $Patterns) { if ($e -like $p) { $match = $true; break } }
      if ($match) { $removed += $e } else { $kept += $e }
    }
    # Tambien deduplicamos
    $kept = $kept | Select-Object -Unique
    if ($removed.Count -eq 0) { continue }
    if ($DryRun) {
      foreach ($r in $removed) { Write-Dry "PATH [$scope]: quitaria '$r'" }
      continue
    }
    Write-Step "Limpiando PATH [$scope] (quita $($removed.Count) entradas)"
    foreach ($r in $removed) { Write-Host "    - $r" -ForegroundColor DarkGray }
    try {
      [Environment]::SetEnvironmentVariable('PATH', ($kept -join ';'), $scope)
      Write-Ok "PATH [$scope] actualizado."
    } catch {
      Write-Warn2 "No se pudo actualizar PATH [$scope]: $($_.Exception.Message). Es posible que necesites permisos de Administrador para el scope Machine."
    }
  }
}

# ---------------------------------------------------------------------------
# Banner inicial
# ---------------------------------------------------------------------------

Write-Section "Laboratorio CI/CD - Setup de Windows"
if ($DryRun) {
  Write-Host "**** MODO DRY-RUN: no se modificara nada en tu sistema. ****" -ForegroundColor Magenta
  Write-Host ''
}
Write-Host "Este script va a:"
Write-Host "  1. Desinstalar TODAS las versiones de Python detectadas (excepto si ya tienes $PythonTargetVersion sano)."
Write-Host "  2. Instalar Python $PythonTargetVersion."
Write-Host "  3. Instalar nvm-windows (si no esta) y Node.js $NodeTargetVersion."
Write-Host "  4. Instalar GitHub CLI (gh)."
Write-Host "  5. Verificar Docker Desktop y git."
Write-Host ''
Write-Warn2 "ADVERTENCIA: Otras herramientas instaladas con 'pip' (poetry, awscli,"
Write-Warn2 "ansible, pre-commit, etc.) dejaran de funcionar y deberan reinstalarse."
Write-Host ''

if (-not $NoConfirm -and -not $DryRun) {
  Write-Host "Pulsa ENTER para continuar o Ctrl+C para abortar..." -ForegroundColor Yellow
  [void](Read-Host)
}

if (-not (Test-IsAdmin)) {
  Write-Warn2 "No estas ejecutando como Administrador. Algunos pasos pediran UAC."
}

if (-not (Test-WingetAvailable)) {
  Write-Err2 "winget no esta disponible. Instala 'App Installer' desde Microsoft Store y reintenta."
  exit 1
}

# ---------------------------------------------------------------------------
# 1. PYTHON: desinstalar todas las versiones e instalar 3.12.10
# ---------------------------------------------------------------------------

Write-Section "Python: limpieza e instalacion de $PythonTargetVersion"

# Si el Python instalado ya es exactamente el target, saltamos limpieza para no romper nada
$skipPython = $false
try {
  $existingPy = (Get-Command python -ErrorAction Stop).Source
  $existingVer = (& $existingPy --version 2>&1) -replace 'Python\s+',''
  if ($existingVer -eq $PythonTargetVersion -and $existingPy -notlike "*\AppData\Local\Python\bin*") {
    # Verificar tambien que pip apunte al mismo Python (no a un pymanager 3.14 huerfano)
    $pipPath = (Get-Command pip -ErrorAction SilentlyContinue).Source
    $pipBase = if ($pipPath) { Split-Path (Split-Path $pipPath -Parent) -Parent } else { '' }
    $pyBase  = Split-Path $existingPy -Parent
    if ($pipBase -eq $pyBase) {
      Write-Ok "Python $PythonTargetVersion ya esta instalado y consistente con pip. Saltando reinstalacion."
      $skipPython = $true
    }
  }
} catch {}

if (-not $skipPython) {
  Write-Step "Buscando Python instalado via winget..."
  # winget list muestra columnas de ancho fijo. Cualquier paquete cuyo Name empiece con
  # "Python" lo consideramos candidato. El Id puede tener prefijo ARP\... cuando proviene
  # del Python Install Manager (pymanager) en lugar de winget directamente.
  $wingetRaw = & winget list --source winget 2>$null | Out-String
  $pythonIds = @()
  foreach ($line in ($wingetRaw -split "`r?`n")) {
    if ($line.Trim().Length -eq 0) { continue }
    # Filtramos solo lineas que empiecen con "Python" (Name column)
    if ($line -notmatch '^\s*Python') { continue }
    # Extraemos cualquier token que parezca un Id valido
    $tokens = $line -split '\s{2,}' | Where-Object { $_.Trim().Length -gt 0 }
    foreach ($t in $tokens) {
      $tt = $t.Trim()
      if ($tt -match '^(Python\.Python\.\S+|Python\.PythonInstallManager|Python\.Launcher)$') { $pythonIds += $tt }
      elseif ($tt -match '(pymanager-pythoncore-\S+)$') { $pythonIds += $Matches[1] }
      elseif ($tt -match '^ARP\\(User|Machine)\\(X64|X86)\\(\S+)$') { $pythonIds += $Matches[3] }
    }
  }
  $pythonIds = $pythonIds | Sort-Object -Unique

  if ($pythonIds.Count -eq 0) {
    Write-Ok "No se encontraron paquetes Python en winget."
  } else {
    Write-Step ("Encontrados en winget: " + ($pythonIds -join ', '))
    # Orden: runtimes primero, launcher y manager al final
    $order = @()
    $order += $pythonIds | Where-Object { $_ -like 'pymanager-pythoncore-*' }
    # Mantener intacto el paquete winget de la familia objetivo (Python.Python.3.12)
    $order += $pythonIds | Where-Object { $_ -like 'Python.Python.*' -and $_ -ne "Python.Python.$PythonTargetMajMin" }
    $order += $pythonIds | Where-Object { $_ -eq 'Python.Launcher' }
    $order += $pythonIds | Where-Object { $_ -eq 'Python.PythonInstallManager' }
    foreach ($id in $order) {
      Write-Step "Desinstalando $id ..."
      $rc = Invoke-Winget @('uninstall','--id',$id,'--silent','--accept-source-agreements','--disable-interactivity')
      if ($rc -ne 0) { Write-Warn2 "Codigo de salida $rc al desinstalar $id (continuando)." }
    }
  }

  # ---------------------------------------------------------------------------
  # Limpieza de restos del Python Install Manager (pymanager)
  # ---------------------------------------------------------------------------
  # Cuando se usa el Python Install Manager (publicado por Microsoft / PSF) los
  # runtimes se instalan en %LOCALAPPDATA%\Python\pythoncore-<ver>-<arch>\
  # y el shim 'python.exe' queda en %LOCALAPPDATA%\Python\bin\
  # Al desinstalar el manager via winget, estas carpetas quedan huerfanas y
  # contaminan el PATH (haciendo que 'pip' apunte a una version que ya no esta
  # gestionada). Las eliminamos manualmente.
  $pymanagerRoots = @(
    "$env:LOCALAPPDATA\Python\bin",
    "$env:LOCALAPPDATA\Python\pythoncore-3.14-64",
    "$env:LOCALAPPDATA\Python\pythoncore-3.14-32",
    "$env:LOCALAPPDATA\Python\pythoncore-3.13-64",
    "$env:LOCALAPPDATA\Python\pythoncore-3.13-32",
    "$env:LOCALAPPDATA\Python\pythoncore-3.11-64",
    "$env:LOCALAPPDATA\Python\pythoncore-3.10-64"
  )
  # Tambien detectar cualquier otro pythoncore-* que aparezca
  if (Test-Path "$env:LOCALAPPDATA\Python") {
    $extra = Get-ChildItem "$env:LOCALAPPDATA\Python" -Directory -ErrorAction SilentlyContinue |
             Where-Object { $_.Name -like 'pythoncore-*' } |
             ForEach-Object { $_.FullName }
    $pymanagerRoots = ($pymanagerRoots + $extra) | Select-Object -Unique
  }
  $found = $pymanagerRoots | Where-Object { Test-Path $_ }
  if ($found) {
    Write-Step "Detectados restos de Python Install Manager (pymanager):"
    foreach ($f in $found) { Write-Host "    - $f" -ForegroundColor DarkGray }
    foreach ($f in $found) { Remove-FolderSafe -Path $f }
    # Si %LOCALAPPDATA%\Python quedo vacio, lo borramos tambien
    if ((Test-Path "$env:LOCALAPPDATA\Python") -and -not (Get-ChildItem "$env:LOCALAPPDATA\Python" -Force -ErrorAction SilentlyContinue)) {
      Remove-FolderSafe -Path "$env:LOCALAPPDATA\Python"
    }
  } else {
    Write-Ok "Sin restos de pymanager."
  }

  # ---------------------------------------------------------------------------
  # Limpieza de entradas del PATH que apunten a Python eliminados
  # ---------------------------------------------------------------------------
  $pathPatterns = @(
    "$env:LOCALAPPDATA\Python\*",
    "$env:LOCALAPPDATA\Python",
    "$env:LOCALAPPDATA\Programs\Python\Python311*",
    "$env:LOCALAPPDATA\Programs\Python\Python313*",
    "$env:LOCALAPPDATA\Programs\Python\Python314*",
    "C:\Python311*","C:\Python313*","C:\Python314*"
  )
  Remove-PathEntries -Patterns $pathPatterns
  Update-EnvPath
}

Update-EnvPath

if (-not $skipPython) {
  Write-Step "Instalando Python $PythonTargetVersion ..."
  $rc = Invoke-Winget @(
    'install','--id','Python.Python.3.12',
    '--version',$PythonTargetVersion,
    '--silent','--accept-package-agreements','--accept-source-agreements',
    '--disable-interactivity',
    '--scope','user',
    '--override','InstallAllUsers=0 PrependPath=1 Include_launcher=1 Include_test=0'
  )
  # -1978335189 = NO_APPLICABLE_UPDATE_FOUND (ya esta instalado en la version pedida)
  if ($rc -ne 0 -and $rc -ne -1978335189) {
    Write-Warn2 "winget devolvio $rc; verificare si Python quedo instalado igualmente."
  } elseif ($rc -eq -1978335189) {
    Write-Ok "Python $PythonTargetVersion ya estaba instalado (no se requiere accion)."
  }
  Update-EnvPath
}

# Buscar python.exe en ubicaciones tipicas si el PATH aun no se refresco
$pythonExe = $null
$candidates = @(
  "$env:ProgramFiles\Python312\python.exe",
  "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
  "C:\Python312\python.exe"
)
foreach ($c in $candidates) { if (Test-Path $c) { $pythonExe = $c; break } }
if (-not $pythonExe) {
  try { $pythonExe = (Get-Command python -ErrorAction Stop).Source } catch {}
}

if ($pythonExe -and (Test-Path $pythonExe)) {
  $pyVer = & $pythonExe --version 2>&1
  Write-Ok "Python en $pythonExe -> $pyVer"
} else {
  Write-Err2 "No se pudo localizar python.exe tras la instalacion."
}

# ---------------------------------------------------------------------------
# 2. nvm-windows
# ---------------------------------------------------------------------------

Write-Section "nvm-windows + Node.js $NodeTargetVersion"

$nvmOk = $false
try { (Get-Command nvm -ErrorAction Stop) | Out-Null; $nvmOk = $true } catch {}

if (-not $nvmOk) {
  Write-Step "nvm no encontrado; instalando CoreyButler.NVMforWindows ..."
  $rc = Invoke-Winget @('install','--id','CoreyButler.NVMforWindows','--silent','--accept-package-agreements','--accept-source-agreements','--disable-interactivity')
  if ($rc -ne 0) { Write-Warn2 "winget devolvio $rc al instalar nvm." }
  Update-EnvPath
  # Variables que crea el instalador
  if (-not $env:NVM_HOME)    { $env:NVM_HOME    = "$env:APPDATA\nvm" }
  if (-not $env:NVM_SYMLINK) { $env:NVM_SYMLINK = "C:\Program Files\nodejs" }
} else {
  Write-Ok "nvm ya esta instalado."
}

# Refrescar nuevamente y aniadir nvm/symlink al PATH del proceso
Update-EnvPath
if ($env:NVM_HOME    -and -not ($env:PATH -split ';' | Where-Object { $_ -eq $env:NVM_HOME }))    { $env:PATH = "$env:NVM_HOME;$env:PATH" }
if ($env:NVM_SYMLINK -and -not ($env:PATH -split ';' | Where-Object { $_ -eq $env:NVM_SYMLINK })) { $env:PATH = "$env:NVM_SYMLINK;$env:PATH" }

# Idempotencia: si Node ya esta en la version objetivo, no reinstalamos
$nodeVer = $null
try { $nodeVer = (& node --version 2>$null).Trim().TrimStart('v') } catch {}
if ($nodeVer -eq $NodeTargetVersion) {
  Write-Ok "Node $NodeTargetVersion ya esta activo."
} else {
  if ($DryRun) {
    Write-Dry "nvm install $NodeTargetVersion"
    Write-Dry "nvm use $NodeTargetVersion"
  } else {
    try {
      Write-Step "nvm install $NodeTargetVersion ..."
      & nvm install $NodeTargetVersion 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
      Write-Step "nvm use $NodeTargetVersion ..."
      & nvm use $NodeTargetVersion 2>&1     | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    } catch {
      Write-Err2 "Fallo al instalar/usar Node con nvm: $_"
    }
  }
}

Update-EnvPath
if ($env:NVM_SYMLINK -and -not ($env:PATH -split ';' | Where-Object { $_ -eq $env:NVM_SYMLINK })) {
  $env:PATH = "$env:NVM_SYMLINK;$env:PATH"
}

# ---------------------------------------------------------------------------
# 3. GitHub CLI
# ---------------------------------------------------------------------------

Write-Section "GitHub CLI"

$ghOk = $false
try { (Get-Command gh -ErrorAction Stop) | Out-Null; $ghOk = $true } catch {}
if ($ghOk) {
  Write-Ok "gh ya esta instalado."
} else {
  Write-Step "Instalando GitHub.cli ..."
  $rc = Invoke-Winget @('install','--id','GitHub.cli','--silent','--accept-package-agreements','--accept-source-agreements','--disable-interactivity')
  if ($rc -ne 0) { Write-Warn2 "winget devolvio $rc al instalar gh." }
  Update-EnvPath
}

# ---------------------------------------------------------------------------
# 4. Validacion final
# ---------------------------------------------------------------------------

Write-Section "Validacion final"
Update-EnvPath

function Get-Tool {
  param([string]$Name, [string]$ExpectedSubstring = $null)
  try {
    $cmd = Get-Command $Name -ErrorAction Stop
    $out = & $cmd.Source --version 2>&1 | Select-Object -First 1
    $ok  = $true
    if ($ExpectedSubstring) { $ok = ($out -like "*$ExpectedSubstring*") }
    return [pscustomobject]@{ Tool=$Name; Status=($(if($ok){'OK'}else{'WRONG'})); Version="$out" }
  } catch {
    return [pscustomobject]@{ Tool=$Name; Status='MISSING'; Version='' }
  }
}

$results = @()
$results += Get-Tool -Name 'python' -ExpectedSubstring '3.12.10'
$results += Get-Tool -Name 'pip'
$results += Get-Tool -Name 'node'   -ExpectedSubstring $NodeTargetVersion
$results += Get-Tool -Name 'npm'
$results += Get-Tool -Name 'nvm'
$results += Get-Tool -Name 'git'
$results += Get-Tool -Name 'gh'
$results += Get-Tool -Name 'docker'

$results | Format-Table -AutoSize | Out-String | Write-Host

$bad = $results | Where-Object { $_.Status -ne 'OK' }
if ($bad.Count -eq 0) {
  Write-Host ''
  Write-Ok "Todo listo. Cierra y abre una nueva terminal para que el PATH se aplique en todas las sesiones."
  exit 0
} else {
  Write-Host ''
  Write-Warn2 "Algunos componentes no pasaron la verificacion. Revisa los mensajes anteriores."
  Write-Warn2 "Si recien terminaste de instalar, cierra esta terminal y abre una nueva antes de reintentar."
  exit 1
}

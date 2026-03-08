[CmdletBinding()]
param(
  [ValidateSet('doctor', 'verify', 'run')]
  [string]$Command = 'doctor',
  [ValidateSet('mock', 'live')]
  [string]$Mode = 'mock',
  [ValidateSet('android', 'chrome', 'windows')]
  [string]$Target = 'android',
  [string]$DeviceId,
  [string]$RepoRoot,
  [string]$AppPath,
  [string]$FlutterPath,
  [string]$ApiBaseUrl = 'http://127.0.0.1:8000',
  [switch]$SkipPubGet,
  [switch]$SkipAnalyze,
  [switch]$SkipTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-ExistingPath {
  param(
    [Parameter(Mandatory = $true)][string]$PathValue,
    [Parameter(Mandatory = $true)][string]$Description
  )

  if (-not (Test-Path $PathValue)) {
    throw "$Description not found: $PathValue"
  }

  return (Resolve-Path $PathValue).Path
}

function Resolve-FlutterExecutable {
  param([string]$ExplicitPath)

  $candidates = @()
  if ($ExplicitPath) {
    $candidates += $ExplicitPath
  }
  if ($env:SIGNALDESK_FLUTTER_BIN) {
    $candidates += $env:SIGNALDESK_FLUTTER_BIN
  }

  foreach ($candidate in $candidates) {
    if (-not $candidate) {
      continue
    }

    if (Test-Path $candidate) {
      $resolved = (Resolve-Path $candidate).Path
      if ((Get-Item $resolved).PSIsContainer) {
        $batPath = Join-Path $resolved 'flutter.bat'
        if (Test-Path $batPath) {
          return (Resolve-Path $batPath).Path
        }
      } else {
        return $resolved
      }
    }
  }

  $command = Get-Command flutter -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  throw 'Flutter SDK was not found. Install Flutter manually or set SIGNALDESK_FLUTTER_BIN to flutter.bat.'
}

function Invoke-External {
  param(
    [Parameter(Mandatory = $true)][string]$Executable,
    [Parameter(Mandatory = $true)][string[]]$Arguments,
    [string]$WorkingDirectory
  )

  $commandText = ($Arguments | ForEach-Object {
      if ($_ -match '\s') {
        '"' + $_ + '"'
      } else {
        $_
      }
    }) -join ' '

  if ($WorkingDirectory) {
    Push-Location $WorkingDirectory
  }

  try {
    Write-Host "> $Executable $commandText" -ForegroundColor DarkGray
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
      throw "Command failed with exit code ${LASTEXITCODE}: ${Executable} $commandText"
    }
  } finally {
    if ($WorkingDirectory) {
      Pop-Location
    }
  }
}

function Get-PlatformDirectoryName {
  param([string]$SelectedTarget)

  switch ($SelectedTarget) {
    'android' { return 'android' }
    'chrome' { return 'web' }
    'windows' { return 'windows' }
    default { throw "Unsupported target: $SelectedTarget" }
  }
}

function Get-FlutterDevices {
  param([string]$FlutterExecutable)

  $json = & $FlutterExecutable devices --machine 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $json) {
    return @()
  }

  try {
    $devices = $json | ConvertFrom-Json
    if ($null -eq $devices) {
      return @()
    }
    return @($devices)
  } catch {
    return @()
  }
}

function Assert-LiveApiHealth {
  param([string]$BaseUrl)

  $trimmed = $BaseUrl.TrimEnd('/')
  $healthUrl = "$trimmed/healthz"

  try {
    $response = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 5
  } catch {
    throw "Live API health check failed for $healthUrl. Start the local stack first and verify docs/ops/deploy-runbook.md. Error: $($_.Exception.Message)"
  }

  if ($response.StatusCode -ne 200) {
    throw "Live API health check returned HTTP $($response.StatusCode) for $healthUrl."
  }

  Write-Host "[ok] live API reachable at $healthUrl" -ForegroundColor Green
}

function Invoke-Doctor {
  param(
    [string]$FlutterExecutable,
    [string]$MobileAppPath,
    [string]$SelectedMode
  )

  Write-Host "[ok] mobile app path: $MobileAppPath" -ForegroundColor Green
  Write-Host "[ok] flutter executable: $FlutterExecutable" -ForegroundColor Green

  $devices = Get-FlutterDevices -FlutterExecutable $FlutterExecutable
  if ($devices.Count -gt 0) {
    Write-Host "[ok] visible Flutter devices:" -ForegroundColor Green
    foreach ($device in $devices) {
      Write-Host " - $($device.id) ($($device.name))"
    }
  } else {
    Write-Host "[warn] no Flutter devices reported. Android preview will remain blocked until an emulator or device is available." -ForegroundColor Yellow
  }

  if ($SelectedMode -eq 'live') {
    Assert-LiveApiHealth -BaseUrl $ApiBaseUrl
  }
}

function Invoke-Verify {
  param(
    [string]$FlutterExecutable,
    [string]$MobileAppPath
  )

  if (-not $SkipPubGet) {
    Invoke-External -Executable $FlutterExecutable -Arguments @('pub', 'get') -WorkingDirectory $MobileAppPath
  }
  if (-not $SkipAnalyze) {
    Invoke-External -Executable $FlutterExecutable -Arguments @('analyze') -WorkingDirectory $MobileAppPath
  }
  if (-not $SkipTest) {
    Invoke-External -Executable $FlutterExecutable -Arguments @('test') -WorkingDirectory $MobileAppPath
  }
}

function Invoke-RunPreview {
  param(
    [string]$FlutterExecutable,
    [string]$MobileAppPath,
    [string]$SelectedMode,
    [string]$SelectedTarget,
    [string]$SelectedDeviceId
  )

  $platformDir = Join-Path $MobileAppPath (Get-PlatformDirectoryName -SelectedTarget $SelectedTarget)
  if (-not (Test-Path $platformDir)) {
    throw "Target '$SelectedTarget' requires platform scaffold '$platformDir'. Do not generate it from this ops workflow; hand off to the mobile owner."
  }

  $deviceToUse = $SelectedDeviceId
  if (-not $deviceToUse) {
    if ($SelectedTarget -eq 'android') {
      throw "Android preview requires -DeviceId so emulator and device selection stays deterministic."
    }
    $deviceToUse = $SelectedTarget
  }

  $availableDevices = Get-FlutterDevices -FlutterExecutable $FlutterExecutable
  if ($availableDevices.Count -gt 0) {
    $matchingDevice = $availableDevices | Where-Object { $_.id -eq $deviceToUse } | Select-Object -First 1
    if (-not $matchingDevice) {
      throw "Requested device '$deviceToUse' was not reported by 'flutter devices'."
    }
  } elseif ($SelectedTarget -eq 'android') {
    throw "No Flutter devices were reported. Start an emulator or connect a device before running Android preview."
  }

  $dartDefines = @()
  if ($SelectedMode -eq 'mock') {
    $dartDefines += '--dart-define=SIGNALDESK_USE_MOCK=true'
  } else {
    $dartDefines += '--dart-define=SIGNALDESK_USE_MOCK=false'
    $dartDefines += "--dart-define=SIGNALDESK_API_BASE_URL=$ApiBaseUrl"
  }

  $runArgs = @('run', '-d', $deviceToUse) + $dartDefines
  Invoke-External -Executable $FlutterExecutable -Arguments $runArgs -WorkingDirectory $MobileAppPath
}

if (-not $RepoRoot) {
  $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
} else {
  $RepoRoot = Resolve-ExistingPath -PathValue $RepoRoot -Description 'Repo root'
}

if (-not $AppPath) {
  $AppPath = Join-Path $RepoRoot 'app\mobile'
}
$AppPath = Resolve-ExistingPath -PathValue $AppPath -Description 'Mobile app path'

$flutterExe = Resolve-FlutterExecutable -ExplicitPath $FlutterPath

Invoke-Doctor -FlutterExecutable $flutterExe -MobileAppPath $AppPath -SelectedMode $Mode

switch ($Command) {
  'doctor' {
    return
  }
  'verify' {
    Invoke-Verify -FlutterExecutable $flutterExe -MobileAppPath $AppPath
    return
  }
  'run' {
    Invoke-Verify -FlutterExecutable $flutterExe -MobileAppPath $AppPath
    Invoke-RunPreview -FlutterExecutable $flutterExe -MobileAppPath $AppPath -SelectedMode $Mode -SelectedTarget $Target -SelectedDeviceId $DeviceId
    return
  }
}

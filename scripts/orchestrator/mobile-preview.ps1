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

function Try-Resolve-FlutterExecutable {
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

  return $null
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

  if (-not $FlutterExecutable) {
    return @()
  }

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

function Test-LiveApiHealth {
  param([string]$BaseUrl)

  $trimmed = $BaseUrl.TrimEnd('/')
  $healthUrl = "$trimmed/healthz"

  try {
    $response = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 5
  } catch {
    return @{
      ok = $false
      message = "Live API health check failed for $healthUrl. Start the local stack first and verify docs/ops/deploy-runbook.md. Error: $($_.Exception.Message)"
    }
  }

  if ($response.StatusCode -ne 200) {
    return @{
      ok = $false
      message = "Live API health check returned HTTP $($response.StatusCode) for $healthUrl."
    }
  }

  return @{
    ok = $true
    message = "live API reachable at $healthUrl"
  }
}

function Add-CheckResult {
  param(
    [System.Collections.Generic.List[object]]$Checks,
    [string]$Status,
    [string]$Category,
    [string]$Message
  )

  $Checks.Add([pscustomobject]@{
      Status = $Status
      Category = $Category
      Message = $Message
    }) | Out-Null
}

function Write-CheckResults {
  param([System.Collections.Generic.List[object]]$Checks)

  foreach ($check in $Checks) {
    switch ($check.Status) {
      'ok' {
        Write-Host "[ok] $($check.Category): $($check.Message)" -ForegroundColor Green
      }
      'warn' {
        Write-Host "[warn] $($check.Category): $($check.Message)" -ForegroundColor Yellow
      }
      'blocker' {
        Write-Host "[blocker] $($check.Category): $($check.Message)" -ForegroundColor Red
      }
      default {
        Write-Host "[$($check.Status)] $($check.Category): $($check.Message)"
      }
    }
  }
}

function Get-PreflightReport {
  param(
    [string]$FlutterExecutable,
    [string]$MobileAppPath,
    [string]$SelectedMode,
    [string]$SelectedTarget,
    [string]$SelectedDeviceId,
    [string]$SelectedCommand
  )

  $checks = New-Object 'System.Collections.Generic.List[object]'
  Add-CheckResult -Checks $checks -Status 'ok' -Category 'app-path' -Message $MobileAppPath

  $platformDirName = Get-PlatformDirectoryName -SelectedTarget $SelectedTarget
  $platformDirPath = Join-Path $MobileAppPath $platformDirName
  if (Test-Path $platformDirPath) {
    Add-CheckResult -Checks $checks -Status 'ok' -Category 'platform-scaffold' -Message "$SelectedTarget scaffold found at $platformDirPath"
  } else {
    Add-CheckResult -Checks $checks -Status 'blocker' -Category 'platform-scaffold' -Message "$SelectedTarget requires $platformDirPath. Do not generate it from the ops workflow; hand off to the mobile owner."
  }

  if ($FlutterExecutable) {
    Add-CheckResult -Checks $checks -Status 'ok' -Category 'flutter' -Message $FlutterExecutable
  } else {
    Add-CheckResult -Checks $checks -Status 'blocker' -Category 'flutter' -Message 'Flutter SDK was not found. Install Flutter manually or set SIGNALDESK_FLUTTER_BIN to flutter.bat.'
  }

  $devices = @(Get-FlutterDevices -FlutterExecutable $FlutterExecutable)
  if ($FlutterExecutable) {
    if ($devices.Count -gt 0) {
      $visibleDevices = ($devices | ForEach-Object { "$($_.id) ($($_.name))" }) -join ', '
      Add-CheckResult -Checks $checks -Status 'ok' -Category 'devices' -Message $visibleDevices
    } else {
      Add-CheckResult -Checks $checks -Status 'warn' -Category 'devices' -Message 'No Flutter devices were reported.'
    }
  }

  if ($SelectedTarget -eq 'android') {
    if ($SelectedCommand -eq 'run' -and -not $SelectedDeviceId) {
      Add-CheckResult -Checks $checks -Status 'blocker' -Category 'device-selection' -Message 'Android preview requires -DeviceId so emulator and device selection stays deterministic.'
    } elseif ($SelectedDeviceId) {
      if ($devices.Count -eq 0) {
        Add-CheckResult -Checks $checks -Status 'blocker' -Category 'device-selection' -Message "Requested Android device '$SelectedDeviceId' cannot be validated because no Flutter devices were reported."
      } elseif ($devices | Where-Object { $_.id -eq $SelectedDeviceId }) {
        Add-CheckResult -Checks $checks -Status 'ok' -Category 'device-selection' -Message "Requested Android device '$SelectedDeviceId' is available."
      } else {
        Add-CheckResult -Checks $checks -Status 'blocker' -Category 'device-selection' -Message "Requested Android device '$SelectedDeviceId' was not reported by 'flutter devices'."
      }
    } elseif ($SelectedCommand -eq 'doctor' -and $devices.Count -eq 0) {
      Add-CheckResult -Checks $checks -Status 'warn' -Category 'device-selection' -Message 'Start an emulator or connect a device before Android preview.'
    }
  } elseif ($SelectedCommand -eq 'run') {
    $selectedDesktopDevice = $devices | Where-Object { $_.id -eq $SelectedTarget } | Select-Object -First 1
    if ($FlutterExecutable -and -not $selectedDesktopDevice) {
      Add-CheckResult -Checks $checks -Status 'blocker' -Category 'device-selection' -Message "Target device '$SelectedTarget' was not reported by 'flutter devices'."
    }
  }

  if ($SelectedMode -eq 'live') {
    $apiHealth = Test-LiveApiHealth -BaseUrl $ApiBaseUrl
    if ($apiHealth.ok) {
      Add-CheckResult -Checks $checks -Status 'ok' -Category 'api-health' -Message $apiHealth.message
    } else {
      Add-CheckResult -Checks $checks -Status 'blocker' -Category 'api-health' -Message $apiHealth.message
    }
  } else {
    Add-CheckResult -Checks $checks -Status 'ok' -Category 'api-mode' -Message 'Mock mode selected; live API health check skipped.'
  }

  $blockingCategories = @()
  foreach ($check in $checks) {
    if ($check.Status -eq 'blocker') {
      $blockingCategories += $check.Category
    }
  }

  return [pscustomobject]@{
    Checks = $checks
    Devices = @($devices)
    HasBlockers = $blockingCategories.Count -gt 0
    BlockingCategories = @($blockingCategories)
  }
}

function Assert-NoBlockers {
  param(
    [pscustomobject]$Report,
    [string]$SelectedCommand
  )

  if (-not $Report.HasBlockers) {
    return
  }

  $messages = foreach ($check in $Report.Checks) {
    if ($check.Status -eq 'blocker') {
      "- $($check.Category): $($check.Message)"
    }
  }

  throw "Preview preflight blocked for '$SelectedCommand':`n$($messages -join "`n")"
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

  $deviceToUse = $SelectedDeviceId
  if (-not $deviceToUse) {
    $deviceToUse = $SelectedTarget
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

$flutterExe = Try-Resolve-FlutterExecutable -ExplicitPath $FlutterPath
$report = Get-PreflightReport -FlutterExecutable $flutterExe -MobileAppPath $AppPath -SelectedMode $Mode -SelectedTarget $Target -SelectedDeviceId $DeviceId -SelectedCommand $Command
Write-CheckResults -Checks $report.Checks

switch ($Command) {
  'doctor' {
    if ($report.HasBlockers) {
      Assert-NoBlockers -Report $report -SelectedCommand $Command
    }
    return
  }
  'verify' {
    Assert-NoBlockers -Report $report -SelectedCommand $Command
    Invoke-Verify -FlutterExecutable $flutterExe -MobileAppPath $AppPath
    return
  }
  'run' {
    Assert-NoBlockers -Report $report -SelectedCommand $Command
    Invoke-Verify -FlutterExecutable $flutterExe -MobileAppPath $AppPath
    Invoke-RunPreview -FlutterExecutable $flutterExe -MobileAppPath $AppPath -SelectedMode $Mode -SelectedTarget $Target -SelectedDeviceId $DeviceId
    return
  }
}

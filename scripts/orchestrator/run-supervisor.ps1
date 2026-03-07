param(
  [ValidateSet('doctor', 'once', 'loop')]
  [string]$Command = 'once',
  [switch]$DryRun,
  [int]$Interval = 60
)

$repoRoot = 'E:\source\signal-desk'
$pythonCandidates = @(
  $env:SIGNALDESK_PYTHON,
  'C:\Users\admin\AppData\Local\Programs\Python\Python312\python.exe',
  'python'
) | Where-Object { $_ }

$pythonExe = $null
foreach ($candidate in $pythonCandidates) {
  if ($candidate -eq 'python') {
    $pythonExe = $candidate
    break
  }
  if (Test-Path $candidate) {
    $pythonExe = $candidate
    break
  }
}

if (-not $pythonExe) {
  throw 'No usable Python interpreter found. Set SIGNALDESK_PYTHON if needed.'
}

$args = @('-m', 'automation.main', $Command)
if ($DryRun) {
  $args += '--dry-run'
}
if ($Command -eq 'loop') {
  $args += '--interval'
  $args += $Interval
}

Push-Location $repoRoot
try {
  & $pythonExe @args
} finally {
  Pop-Location
}
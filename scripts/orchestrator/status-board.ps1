param(
  [string]$RepoRoot = 'E:\source\signal-desk'
)

$repoRoot = (Resolve-Path $RepoRoot).Path
$handoffDir = Join-Path $repoRoot 'coordination\handoffs'
$taskFile = Join-Path $repoRoot 'coordination\tasks.yaml'

Write-Host "== Worktrees ==" -ForegroundColor Cyan
git -C $repoRoot worktree list

Write-Host "`n== Task Snapshot ==" -ForegroundColor Cyan
Get-Content $taskFile | Select-String 'id:|title:|owner:|status:' | ForEach-Object { $_.Line }

Write-Host "`n== Recent Handoffs ==" -ForegroundColor Cyan
if (Test-Path $handoffDir) {
  Get-ChildItem $handoffDir -File | Sort-Object LastWriteTime -Descending | Select-Object -First 10 Name, LastWriteTime
} else {
  Write-Host 'No handoff directory found.'
}

Write-Host "`n== Main Branch Status ==" -ForegroundColor Cyan
git -C $repoRoot status --short --branch

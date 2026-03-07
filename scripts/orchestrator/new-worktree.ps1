param(
  [Parameter(Mandatory = $true)][string]$TaskId,
  [Parameter(Mandatory = $true)][string]$Branch,
  [Parameter(Mandatory = $true)][string]$Path,
  [string]$Base = 'main',
  [string]$RepoRoot = 'E:\source\signal-desk'
)

$repoRoot = (Resolve-Path $RepoRoot).Path
if (Test-Path $Path) {
  throw "Target path already exists: $Path"
}

git -C $repoRoot worktree add $Path -b $Branch $Base

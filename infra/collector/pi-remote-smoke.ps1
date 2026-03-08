param(
    [string]$PiHost = "192.168.0.33",
    [int]$PiPort = 22,
    [string]$PiUser = "admin",
    [string]$SshKeyPath = "$env:USERPROFILE\.ssh\id_ed25519",
    [string]$RemoteRoot = "~/signal-desk"
)

$ErrorActionPreference = "Stop"

function Invoke-Ssh {
    param([string]$RemoteCommand)

    $sshArgs = @(
        "-i", $SshKeyPath,
        "-o", "BatchMode=yes",
        "-o", "StrictHostKeyChecking=accept-new",
        "-o", "ConnectTimeout=10",
        "-p", "$PiPort",
        "$PiUser@$PiHost",
        $RemoteCommand
    )

    Write-Host ("ssh " + ($sshArgs -join " "))
    & ssh @sshArgs
    if ($LASTEXITCODE -ne 0) {
        throw "SSH command failed (exit=$LASTEXITCODE): $RemoteCommand"
    }
}

function Invoke-ScpDirectory {
    param(
        [string]$LocalPath,
        [string]$RemotePath
    )

    $scpArgs = @(
        "-i", $SshKeyPath,
        "-o", "BatchMode=yes",
        "-o", "StrictHostKeyChecking=accept-new",
        "-P", "$PiPort",
        "-r",
        $LocalPath,
        "${PiUser}@${PiHost}:$RemotePath"
    )

    Write-Host ("scp " + ($scpArgs -join " "))
    & scp @scpArgs
    if ($LASTEXITCODE -ne 0) {
        throw "SCP failed (exit=$LASTEXITCODE): $LocalPath -> $RemotePath"
    }
}

if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
    throw "OpenSSH client (ssh) is not installed."
}
if (-not (Get-Command scp -ErrorAction SilentlyContinue)) {
    throw "OpenSSH scp is not installed."
}
if (-not (Test-Path $SshKeyPath)) {
    throw "Missing SSH private key: $SshKeyPath"
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$infraCollectorPath = Join-Path $repoRoot "infra\collector"
$servicesCollectorPath = Join-Path $repoRoot "services\collector"

if (-not (Test-Path (Join-Path $infraCollectorPath "docker-compose.yml"))) {
    throw "Collector infra assets are missing under: $infraCollectorPath"
}
if (-not (Test-Path (Join-Path $servicesCollectorPath "Dockerfile"))) {
    throw "Collector service assets are missing under: $servicesCollectorPath"
}

Invoke-Ssh "echo SSH_OK"
Invoke-Ssh "docker --version"
Invoke-Ssh "docker compose version"
Invoke-Ssh "mkdir -p $RemoteRoot/infra $RemoteRoot/services"

Invoke-ScpDirectory $infraCollectorPath "$RemoteRoot/infra/"
Invoke-ScpDirectory $servicesCollectorPath "$RemoteRoot/services/"

Invoke-Ssh "cp -n $RemoteRoot/infra/collector/.env.example $RemoteRoot/infra/collector/.env || true"

Invoke-Ssh "docker compose -f $RemoteRoot/infra/collector/docker-compose.yml --env-file $RemoteRoot/infra/collector/.env down -v --remove-orphans"
Invoke-Ssh "docker compose -f $RemoteRoot/infra/collector/docker-compose.yml --env-file $RemoteRoot/infra/collector/.env up -d collector-db"
Invoke-Ssh "docker compose -f $RemoteRoot/infra/collector/docker-compose.yml --env-file $RemoteRoot/infra/collector/.env run --rm collector-bootstrap"
Invoke-Ssh "docker compose -f $RemoteRoot/infra/collector/docker-compose.yml --env-file $RemoteRoot/infra/collector/.env run --rm collector-runner"
Invoke-Ssh "cat $RemoteRoot/infra/collector/queries/spool-evidence.sql | docker compose -f $RemoteRoot/infra/collector/docker-compose.yml --env-file $RemoteRoot/infra/collector/.env exec -T collector-db psql -U collector -d signaldesk_collector -f -"

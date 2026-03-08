param(
    [switch]$StartDb
)

$ErrorActionPreference = "Stop"

$composeFile = Join-Path $PSScriptRoot "docker-compose.yml"
$envFile = Join-Path $PSScriptRoot ".env.example"
$composeArgs = @("-f", $composeFile, "--env-file", $envFile)

docker compose @composeArgs down -v --remove-orphans

if ($StartDb) {
    docker compose @composeArgs up -d collector-db
}


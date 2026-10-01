# Envía las solicitudes de ejemplo al webhook del flujo.
# Uso: .\scripts\test-flow.ps1 [-Test] [-BaseUrl http://localhost:5678] [-Files requests\01-cliente-preferencial.json]
#   -Test  -> usa la URL de prueba /webhook-test (flujo en "Listen for test event").
#   Sin -Test usa la URL de producción /webhook (flujo publicado).
param(
    [string]$BaseUrl = "http://localhost:5678",
    [string[]]$Files,
    [switch]$Test
)

$root = Split-Path -Parent $PSScriptRoot
$hook = if ($Test) { "webhook-test" } else { "webhook" }
if (-not $Files) { $Files = Get-ChildItem (Join-Path $root "requests") -Filter *.json | ForEach-Object { $_.FullName } }

foreach ($f in $Files) {
    Write-Host "=== $f" -ForegroundColor Cyan
    $body = [System.IO.File]::ReadAllBytes((Resolve-Path $f))
    try {
        $resp = Invoke-RestMethod -Method Post -Uri "$BaseUrl/$hook/solicitud-bancaria" `
            -ContentType "application/json; charset=utf-8" -Body $body
        $resp | ConvertTo-Json -Depth 10
    } catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
    Write-Host ""
}

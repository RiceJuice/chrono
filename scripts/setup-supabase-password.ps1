# Einmalige Einrichtung: Datenbankpasswort speichern, damit die Supabase-CLI
# nicht bei jedem Befehl (db push, link, …) erneut danach fragt.

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$envFile = Join-Path $repoRoot "config\supabase.local.env"
$exampleFile = Join-Path $repoRoot "config\supabase.local.env.example"

if (-not (Test-Path $exampleFile)) {
    Write-Error "Vorlage fehlt: $exampleFile"
}

Write-Host ""
Write-Host "Supabase-Datenbankpasswort einmalig speichern" -ForegroundColor Cyan
Write-Host "Passwort aus: Supabase Dashboard → Project Settings → Database"
Write-Host ""

$secure = Read-Host "Datenbankpasswort" -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
)

if ([string]::IsNullOrWhiteSpace($password)) {
    Write-Error "Kein Passwort eingegeben."
}

$content = @"
# Lokale Supabase-CLI-Zugangsdaten (NICHT committen).
# Erstellt von scripts/setup-supabase-password.ps1

SUPABASE_DB_PASSWORD=$password
"@

Set-Content -Path $envFile -Value $content -Encoding UTF8 -NoNewline
Write-Host "Gespeichert in: $envFile" -ForegroundColor Green

[Environment]::SetEnvironmentVariable("SUPABASE_DB_PASSWORD", $password, "User")
$env:SUPABASE_DB_PASSWORD = $password
Write-Host "Windows-Benutzerumgebungsvariable SUPABASE_DB_PASSWORD gesetzt." -ForegroundColor Green

Write-Host ""
Write-Host "Fertig. Neue Terminal-Fenster und Supabase-Befehle nutzen das Passwort automatisch."
Write-Host "Optional: supabase link --project-ref chrbvfaknykaycwumuba"

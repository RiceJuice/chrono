# Lädt config/supabase.local.env in die aktuelle PowerShell-Sitzung.
# Wird automatisch von Cursor/VS-Code-Terminals und scripts/supabase.ps1 genutzt.

$envFile = Join-Path $PSScriptRoot "..\config\supabase.local.env"
if (-not (Test-Path $envFile)) {
    return
}

Get-Content $envFile -Encoding UTF8 | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) {
        return
    }

    $eq = $line.IndexOf("=")
    if ($eq -lt 1) {
        return
    }

    $name = $line.Substring(0, $eq).Trim()
    $value = $line.Substring($eq + 1).Trim().Trim('"').Trim("'")
    if ($name -ne "") {
        Set-Item -Path "env:$name" -Value $value
    }
}

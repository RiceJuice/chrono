# Wrapper: lädt lokale Secrets und ruft die Supabase-CLI auf.
# Nutzung: .\scripts\supabase.ps1 db push

. (Join-Path $PSScriptRoot "load-supabase-env.ps1")
& supabase @args
exit $LASTEXITCODE

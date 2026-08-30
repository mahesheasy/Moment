param(
  [ValidateSet("apk", "appbundle")]
  [string]$Target = "apk"
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $PSScriptRoot)

if (-not (Test-Path "env.json")) {
  Write-Error "Copy env.json.example to env.json and fill in the Moment Supabase publishable values."
}

if ($Target -eq "appbundle") {
  flutter build appbundle --release
} else {
  flutter build apk --release
}

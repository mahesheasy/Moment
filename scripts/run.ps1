param(
  [string]$Device = ""
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $PSScriptRoot)

if (-not (Test-Path "env.json")) {
  Write-Error "Copy env.json.example to env.json and fill in the Moment Supabase publishable values."
}

if ($Device) {
  flutter run --dart-define-from-file=env.json -d $Device
} else {
  flutter run --dart-define-from-file=env.json
}

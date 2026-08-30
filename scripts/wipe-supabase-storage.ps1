# Deletes ALL files from every Supabase Storage bucket in the Moment project.
# Requires the service role key (Dashboard → Project Settings → API → service_role).
#
# Usage (PowerShell):
#   $env:SUPABASE_SERVICE_ROLE_KEY = "your-service-role-key"
#   .\scripts\wipe-supabase-storage.ps1
#
# Optional:
#   $env:SUPABASE_URL = "https://rqnzwvzziqflgipxiciz.supabase.co"

$ErrorActionPreference = "Stop"

$supabaseUrl = if ($env:SUPABASE_URL) { $env:SUPABASE_URL } else { "https://rqnzwvzziqflgipxiciz.supabase.co" }
$serviceRole = $env:SUPABASE_SERVICE_ROLE_KEY

if ([string]::IsNullOrWhiteSpace($serviceRole)) {
    Write-Error "Set SUPABASE_SERVICE_ROLE_KEY first (Supabase Dashboard → Settings → API → service_role secret)."
}

$headers = @{
    Authorization = "Bearer $serviceRole"
    apikey        = $serviceRole
}

$buckets = @("moments", "avatars", "circle-avatars", "memory-covers")
$totalDeleted = 0

foreach ($bucket in $buckets) {
    Write-Host "Listing $bucket..."
    $offset = 0
  $limit = 1000

    while ($true) {
        $listBody = @{
            prefix = ""
            limit  = $limit
            offset = $offset
        } | ConvertTo-Json

        $listUri = "$supabaseUrl/storage/v1/object/list/$bucket"
        $listed = Invoke-RestMethod -Method Post -Uri $listUri -Headers $headers -ContentType "application/json" -Body $listBody

        if (-not $listed -or $listed.Count -eq 0) {
            break
        }

        $paths = @($listed | ForEach-Object { $_.name })
        Write-Host "  Deleting $($paths.Count) objects from $bucket..."

        $deleteUri = "$supabaseUrl/storage/v1/object/$bucket"
        $deleteBody = ($paths | ConvertTo-Json -Compress)
        Invoke-RestMethod -Method Delete -Uri $deleteUri -Headers $headers -ContentType "application/json" -Body $deleteBody | Out-Null

        $totalDeleted += $paths.Count
        if ($paths.Count -lt $limit) {
            break
        }
        $offset += $limit
    }
}

Write-Host "Done. Deleted $totalDeleted storage objects."

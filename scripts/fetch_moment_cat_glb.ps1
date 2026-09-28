# Downloads a CC0 Quaternius-style cat GLB when you have a direct GLB URL.
# The Ultimate Animated Animals pack is distributed as ZIP from Quaternius —
# download manually, extract Cat glTF, convert/export to GLB, then copy to:
#   assets/pets/cat/cat.glb
#
# This script can fetch a direct GLB if you set $GlbUrl below.

param(
  [string]$GlbUrl = "",
  [string]$OutPath = "$PSScriptRoot\..\assets\pets\cat\cat.glb"
)

if ([string]::IsNullOrWhiteSpace($GlbUrl)) {
  Write-Host "No direct cat GLB URL configured."
  Write-Host ""
  Write-Host "Recommended workflow:"
  Write-Host "  1. Download Ultimate Animated Animals from https://quaternius.com/packs/ultimateanimatedanimals.html"
  Write-Host "  2. Extract the Cat model (glTF folder)"
  Write-Host "  3. In Blender: File > Import glTF, then File > Export glTF 2.0 (.glb)"
  Write-Host "  4. Save as assets/pets/cat/cat.glb"
  Write-Host ""
  Write-Host "Or pass a direct .glb URL:"
  Write-Host "  .\scripts\fetch_moment_cat_glb.ps1 -GlbUrl 'https://example.com/cat.glb'"
  exit 0
}

$dir = Split-Path $OutPath -Parent
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Invoke-WebRequest -Uri $GlbUrl -OutFile $OutPath -UseBasicParsing
Write-Host "Saved $OutPath ($((Get-Item $OutPath).Length) bytes)"

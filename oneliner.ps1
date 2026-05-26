# =============================================================================
# One-liner Windows — telecharge et lance le setup depuis GitHub
#
# Usage (PowerShell admin) :
#   irm https://raw.githubusercontent.com/DenZaiyy/devsetup/main/install.ps1 | iex
# =============================================================================

$REPO_URL = "https://raw.githubusercontent.com/DenZaiyy/devsetup/main"
$TmpFile  = Join-Path $env:TEMP "devsetup_install.ps1"

Write-Host "Telechargement du setup..." -ForegroundColor Cyan
Invoke-RestMethod "$REPO_URL/install.ps1" -OutFile $TmpFile

Write-Host "Lancement du setup..." -ForegroundColor Cyan
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $TmpFile

Remove-Item $TmpFile -ErrorAction SilentlyContinue

# =============================================================================
# DevSetup — Installation d'outils de développement (Windows)
# Prérequis : PowerShell 5.1+ lancé en tant qu'Administrateur
# Usage     : Set-ExecutionPolicy Bypass -Scope Process; .\install.ps1
# =============================================================================

#Requires -Version 5.1

param([switch]$NonInteractive)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# ─── Vérification droits admin ────────────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
  Write-Host ""
  Write-Host "  Ce script doit etre execute en tant qu'Administrateur !" -ForegroundColor Red
  Write-Host "  Clique-droit sur PowerShell -> 'Executer en tant qu''administrateur'" -ForegroundColor Yellow
  Write-Host ""
  Read-Host "Appuie sur Entree pour quitter"
  exit 1
}

# ─── Helpers ──────────────────────────────────────────────────────────────────
function Write-Info    { param($msg) Write-Host "  -> $msg" -ForegroundColor Cyan }
function Write-OK      { param($msg) Write-Host "  OK $msg" -ForegroundColor Green }
function Write-Warn    { param($msg) Write-Host "  !  $msg" -ForegroundColor Yellow }
function Write-Err     { param($msg) Write-Host "  X  $msg" -ForegroundColor Red }
function Write-Section { param($t)   Write-Host "`n== $t ==" -ForegroundColor White }

function Is-Installed {
  param($cmd)
  return $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Ask {
  param($prompt, $default = "Y")
  if ($NonInteractive) { return $true }
  $choices = if ($default -eq "Y") { "[Y/n]" } else { "[y/N]" }
  $answer  = Read-Host "? $prompt $choices"
  if ([string]::IsNullOrWhiteSpace($answer)) { $answer = $default }
  return $answer.ToUpper() -eq "Y"
}

function Winget-Install {
  param([string]$Id, [string]$Name = "")
  if ([string]::IsNullOrEmpty($Name)) { $Name = $Id }

  $installed = winget list --id $Id --accept-source-agreements 2>$null | Select-String $Id
  if ($installed) {
    Write-OK "$Name deja installe"
  } else {
    Write-Info "Installation de $Name..."
    $result = winget install --id $Id --silent --accept-package-agreements --accept-source-agreements 2>&1
    if ($LASTEXITCODE -eq 0) {
      Write-OK "$Name installe"
    } else {
      Write-Warn "$Name : echec (code $LASTEXITCODE) — verifier manuellement"
    }
  }
}

function Add-ToPath {
  param([string]$Dir)
  $current = [Environment]::GetEnvironmentVariable("Path", "Machine")
  if ($current -notlike "*$Dir*") {
    [Environment]::SetEnvironmentVariable("Path", "$current;$Dir", "Machine")
    $env:PATH += ";$Dir"
    Write-OK "$Dir ajoute au PATH systeme"
  }
}

function Refresh-Path {
  $env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
              [System.Environment]::GetEnvironmentVariable("Path","User")
}

# ─── Vérification winget ──────────────────────────────────────────────────────
function Check-Winget {
  Write-Section "Verification de winget"
  if (-not (Is-Installed winget)) {
    Write-Warn "winget non trouve. Installe 'App Installer' depuis le Microsoft Store :"
    Write-Warn "  -> Recherche 'App Installer' dans le Microsoft Store"
    Write-Warn "  -> Ou ouvre directement : ms-windows-store://pdp/?productid=9NBLGGH4NNS1"
    Read-Host "Appuie sur Entree apres installation de winget"
    Refresh-Path
    if (-not (Is-Installed winget)) {
      Write-Err "winget toujours absent. Impossible de continuer."
      exit 1
    }
  }
  Write-OK "winget disponible"
  # Accepter les sources au premier usage
  winget source update --accept-source-agreements 2>$null | Out-Null
}

# ─── Outils de base ───────────────────────────────────────────────────────────
function Install-Base {
  Write-Section "Outils de base"
  Winget-Install "Git.Git"                      "Git"
  Winget-Install "Microsoft.WindowsTerminal"    "Windows Terminal"
  Winget-Install "jqlang.jq"                    "jq"
  Winget-Install "sharkdp.bat"                  "bat (cat ameliore)"
  Winget-Install "sharkdp.fd"                   "fd (find ameliore)"
  Winget-Install "BurntSushi.ripgrep.MSVC"      "ripgrep"
  Winget-Install "junegunn.fzf"                 "fzf"
  Winget-Install "GnuWin32.Make"                "make"
  Winget-Install "JanDeDobbeleer.OhMyPosh"      "Oh My Posh"

  Refresh-Path

  # Configurer le profil PowerShell pour Oh My Posh
  if (Is-Installed oh-my-posh) {
    $profileContent = Get-Content $PROFILE -ErrorAction SilentlyContinue
    if (-not ($profileContent | Select-String "oh-my-posh")) {
      if (-not (Test-Path (Split-Path $PROFILE))) { New-Item -ItemType Directory (Split-Path $PROFILE) -Force | Out-Null }
      Add-Content $PROFILE "`noh-my-posh init pwsh | Invoke-Expression"
      Write-OK "Oh My Posh active dans le profil PowerShell"
    }
  }
}

# ─── Visual Studio Code ───────────────────────────────────────────────────────
function Install-VSCode {
  Write-Section "Visual Studio Code"
  Winget-Install "Microsoft.VisualStudioCode" "VS Code"
  Refresh-Path

  if ((Is-Installed code) -and (Ask "Installer les extensions VS Code recommandees ?")) {
    $extensions = @(
      "bmewburn.vscode-intelephense-client"   # PHP intellisense
      "xdebug.php-debug"                       # Xdebug
      "neilbrayfield.php-docblocker"           # PHP docblocks
      "symfony.vscode-symfony"                 # Symfony
      "ms-vscode.vscode-typescript-next"       # TypeScript
      "esbenp.prettier-vscode"                 # Prettier
      "dbaeumer.vscode-eslint"                 # ESLint
      "bradlc.vscode-tailwindcss"              # Tailwind CSS
      "ms-azuretools.vscode-docker"            # Docker
      "ms-vscode-remote.remote-containers"     # Dev Containers
      "eamodio.gitlens"                        # GitLens
      "github.vscode-github-actions"           # GitHub Actions
      "ms-python.python"                       # Python
      "ms-dotnettools.csharp"                  # C#
      "formulahendry.auto-rename-tag"          # Auto rename tag
      "christian-kohler.path-intellisense"     # Path intellisense
      "gruntfuggly.todo-tree"                  # TODO tree
      "usernamehw.errorlens"                   # Error lens
      "streetsidesoftware.code-spell-checker"  # Spell checker
    )
    foreach ($ext in $extensions) {
      code --install-extension $ext --force 2>$null
      Write-OK "Extension $ext"
    }
  }
}

# ─── Node.js via fnm ──────────────────────────────────────────────────────────
function Install-NodeJS {
  Write-Section "Node.js (via fnm)"

  if (-not (Is-Installed fnm)) {
    Write-Info "Installation de fnm (Fast Node Manager)..."
    Winget-Install "Schniz.fnm" "fnm"
    Refresh-Path

    # Ajouter fnm au profil PowerShell
    if (-not (Test-Path $PROFILE)) {
      New-Item -ItemType File $PROFILE -Force | Out-Null
    }
    $profileContent = Get-Content $PROFILE -ErrorAction SilentlyContinue
    if (-not ($profileContent | Select-String "fnm env")) {
      Add-Content $PROFILE "`nfnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression"
      Write-OK "fnm configure dans le profil PowerShell"
    }
    Write-Warn "Redémarre PowerShell pour activer fnm, puis relance ce script si necessaire"
  } else {
    Write-OK "fnm deja present"
  }

  if (Is-Installed fnm) {
    fnm install --lts 2>$null
    fnm default lts-latest 2>$null
    fnm use lts-latest 2>$null
    Refresh-Path
    Write-OK "Node.js LTS installe"

    if (Is-Installed npm) {
      if (Ask "Installer pnpm ?")         { npm install -g pnpm;          Write-OK "pnpm installe" }
      if (Ask "Installer yarn ?")         { npm install -g yarn;          Write-OK "yarn installe" }
      if (Ask "Installer Vercel CLI ?")   { npm install -g vercel;        Write-OK "vercel installe" }
      if (Ask "Installer firebase-tools ?") { npm install -g firebase-tools; Write-OK "firebase-tools installe" }
    }
  } else {
    Write-Warn "fnm installe. Relance PowerShell en admin et re-execute le script pour configurer Node."
  }
}

# ─── PHP + Composer + Symfony CLI ─────────────────────────────────────────────
function Install-PHP {
  Write-Section "PHP 8.x"

  if (-not (Is-Installed php)) {
    Write-Info "Installation de PHP via winget..."
    # Essai avec winget (XAMPP inclut PHP mais est lourd — on prefere PHP standalone)
    $phpInstalled = $false
    try {
      winget install --id "PHP.PHP.8.3" --silent --accept-package-agreements --accept-source-agreements
      $phpInstalled = $LASTEXITCODE -eq 0
    } catch {}

    if (-not $phpInstalled) {
      Write-Warn "PHP non disponible directement via winget."
      Write-Warn "Options recommandees :"
      Write-Warn "  1. Installe Laragon (PHP + MySQL + Apache integres) : https://laragon.org/"
      Write-Warn "  2. Installe Chocolatey puis : choco install php"
      Write-Warn "  3. Telecharge PHP manuellement : https://windows.php.net/download/"
    } else {
      Refresh-Path
      Write-OK "PHP installe"
    }
  } else {
    Write-OK "PHP deja present"
  }

  # Composer
  if (-not (Is-Installed composer)) {
    Write-Info "Telechargement de Composer..."
    $composerSetup = "$env:TEMP\Composer-Setup.exe"
    Invoke-WebRequest -Uri "https://getcomposer.org/Composer-Setup.exe" -OutFile $composerSetup -UseBasicParsing
    Start-Process -FilePath $composerSetup -ArgumentList "/SILENT" -Wait -NoNewWindow
    Remove-Item $composerSetup -ErrorAction SilentlyContinue
    Refresh-Path
    Write-OK "Composer installe"
  } else {
    Write-OK "Composer deja present"
  }

  # Symfony CLI
  if (-not (Is-Installed symfony)) {
    Write-Info "Installation de Symfony CLI..."
    Winget-Install "Symfony.CLI" "Symfony CLI"
    Refresh-Path
  } else {
    Write-OK "Symfony CLI deja present"
  }
}

# ─── Python ───────────────────────────────────────────────────────────────────
function Install-Python {
  Write-Section "Python 3.12"
  Winget-Install "Python.Python.3.12" "Python 3.12"
  Refresh-Path

  if (Is-Installed pip) {
    pip install --upgrade pip -q
    if (Ask "Installer Poetry ?") { pip install poetry -q;    Write-OK "Poetry installe" }
    if (Ask "Installer pipx ?")   { pip install pipx  -q;    Write-OK "pipx installe" }
  }
}

# ─── .NET SDK ─────────────────────────────────────────────────────────────────
function Install-DotNet {
  Write-Section ".NET SDK 8"
  Winget-Install "Microsoft.DotNet.SDK.8" ".NET SDK 8"
  Refresh-Path
}

# ─── Docker ───────────────────────────────────────────────────────────────────
function Install-Docker {
  Write-Section "Docker Desktop"

  if (Is-Installed docker) {
    Write-OK "Docker deja present"
    return
  }

  # Vérifier WSL2 (requis par Docker Desktop)
  $wslVersion = wsl --status 2>$null | Select-String "Default Version: 2"
  if (-not $wslVersion) {
    Write-Info "Activation de WSL2 (requis par Docker Desktop)..."
    wsl --install --no-distribution 2>$null
    Write-Warn "WSL2 installe. Un redemarrage peut etre necessaire avant Docker."
  }

  Winget-Install "Docker.DockerDesktop" "Docker Desktop"
  Write-OK "Docker Desktop installe"
  Write-Warn "Lance Docker Desktop une fois pour finaliser la configuration"
  Write-Warn "Un redemarrage Windows peut etre necessaire"
}

# ─── Outils API ───────────────────────────────────────────────────────────────
function Install-ApiTools {
  Write-Section "Outils API"
  if (Ask "Installer Postman ?")                      { Winget-Install "Postman.Postman"  "Postman" }
  if (Ask "Installer Bruno (open-source Postman) ?")  { Winget-Install "Bruno.Bruno"      "Bruno" }
  if (Ask "Installer HTTPie Desktop ?")               { Winget-Install "HTTPie.HTTPie"    "HTTPie" }
}

# ─── Outils base de données ───────────────────────────────────────────────────
function Install-DbTools {
  Write-Section "Outils base de donnees"
  if (Ask "Installer DBeaver (GUI BDD universel) ?") { Winget-Install "dbeaver.dbeaver"      "DBeaver" }
  if (Ask "Installer TablePlus ?")                   { Winget-Install "TablePlus.TablePlus"  "TablePlus" }
  if (Ask "Installer HeidiSQL ?")                    { Winget-Install "HeidiSQL.HeidiSQL"    "HeidiSQL" }
  if (Ask "Installer Redis Insight (GUI Redis) ?")   { Winget-Install "Redis.RedisInsight"   "Redis Insight" }
}

# ─── Outils DevOps / Cloud ────────────────────────────────────────────────────
function Install-DevOpsTools {
  Write-Section "Outils DevOps / Cloud"

  if (-not (Is-Installed gh)) {
    Winget-Install "GitHub.cli" "GitHub CLI"
  } else {
    Write-OK "GitHub CLI deja present"
  }

  if (Ask "Installer kubectl ?")   { Winget-Install "Kubernetes.kubectl"    "kubectl" }
  if (Ask "Installer Helm ?")      { Winget-Install "Helm.Helm"             "Helm" }
  if (Ask "Installer AWS CLI ?")   { Winget-Install "Amazon.AWSCLI"         "AWS CLI" }
  if (Ask "Installer Terraform ?") { Winget-Install "Hashicorp.Terraform"   "Terraform" }

  Refresh-Path
}

# ─── Terminal / WSL2 ──────────────────────────────────────────────────────────
function Install-TerminalTools {
  Write-Section "Terminal / Shell"

  if (Ask "Installer PowerShell 7 (cross-platform) ?") {
    Winget-Install "Microsoft.PowerShell" "PowerShell 7"
  }

  if (Ask "Installer WSL2 + Ubuntu 24.04 ?") {
    Write-Info "Installation de WSL2 + Ubuntu..."
    wsl --install -d Ubuntu-24.04
    Write-OK "WSL2 + Ubuntu installe"
    Write-Warn "Redémarre Windows et ouvre Ubuntu pour finaliser la configuration du compte"
  }
}

# ─── WP-CLI ───────────────────────────────────────────────────────────────────
function Install-WPCli {
  Write-Section "WP-CLI (WordPress)"

  if (Is-Installed wp) {
    Write-OK "WP-CLI deja present"
    return
  }

  if (-not (Is-Installed php)) {
    Write-Warn "PHP requis pour WP-CLI — installe PHP d'abord"
    return
  }

  $wpDir = "C:\ProgramData\wp-cli"
  New-Item -ItemType Directory -Path $wpDir -Force | Out-Null

  Write-Info "Telechargement de WP-CLI..."
  Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" `
    -OutFile "$wpDir\wp-cli.phar" -UseBasicParsing

  # Wrapper .bat
  Set-Content -Path "$wpDir\wp.bat" -Value "@echo off`nphp `"$wpDir\wp-cli.phar`" %*"

  Add-ToPath $wpDir
  Write-OK "WP-CLI installe dans $wpDir"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║         DevSetup — Installation dev tools           ║" -ForegroundColor Cyan
Write-Host "  ║                     Windows                          ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Check-Winget

Write-Host ""
Write-Host "Selectionne les outils a installer (Y/n par categorie) :" -ForegroundColor White
Write-Host ""

if (Ask "Outils de base (Git, Terminal, jq, bat, fzf...) ?") { Install-Base }
if (Ask "Visual Studio Code + extensions ?")                  { Install-VSCode }
if (Ask "Node.js (via fnm) + npm globals ?")                  { Install-NodeJS }
if (Ask "PHP 8.3 + Composer + Symfony CLI ?")                 { Install-PHP }
if (Ask "Python 3.12 ?")                                      { Install-Python }
if (Ask ".NET SDK 8 (C# / ASP.NET) ?")                       { Install-DotNet }
if (Ask "Docker Desktop ?")                                   { Install-Docker }
if (Ask "Outils API (Postman, Bruno, HTTPie) ?")              { Install-ApiTools }
if (Ask "Outils BDD (DBeaver, TablePlus, HeidiSQL) ?")        { Install-DbTools }
if (Ask "Outils DevOps/Cloud (gh, kubectl, Helm, AWS, TF) ?") { Install-DevOpsTools }
if (Ask "Terminal (PowerShell 7, WSL2 + Ubuntu) ?")           { Install-TerminalTools }
if (Ask "WP-CLI (WordPress) ?")                               { Install-WPCli }

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║         Installation terminee avec succes !         ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Warn "Redémarre ton terminal pour recharger le PATH et activer les outils."
Write-Warn "Si Docker a ete installe, un redemarrage Windows peut etre necessaire."
Write-Host ""
Read-Host "Appuie sur Entree pour quitter"

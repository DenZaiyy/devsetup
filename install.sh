gh auth refresh -h github.com -s repo,workflow  #!/usr/bin/env bash
# =============================================================================
# DevSetup — Installation d'outils de développement
# Compatible : macOS, Ubuntu/Debian, Fedora, Arch Linux
# Usage      : chmod +x install.sh && ./install.sh
# =============================================================================

set -uo pipefail
IFS=$'\n\t'

# ─── Couleurs ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${BLUE}  →${NC} $*"; }
success() { echo -e "${GREEN}  ✓${NC} $*"; }
warn()    { echo -e "${YELLOW}  !${NC} $*"; }
error()   { echo -e "${RED}  ✗${NC} $*" >&2; }
section() { echo -e "\n${BOLD}${CYAN}══ $* ══${NC}"; }

# ─── Détection OS ─────────────────────────────────────────────────────────────
OS=""
PKG_MANAGER=""

detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"; PKG_MANAGER="brew"
  elif [[ -f /etc/debian_version ]]; then
    OS="debian"; PKG_MANAGER="apt"
  elif [[ -f /etc/fedora-release ]]; then
    OS="fedora"; PKG_MANAGER="dnf"
  elif [[ -f /etc/arch-release ]]; then
    OS="arch"; PKG_MANAGER="pacman"
  else
    error "Système non supporté. Utilise macOS, Ubuntu/Debian, Fedora ou Arch."
    exit 1
  fi
  success "Système détecté : ${BOLD}$OS${NC}"
}

# ─── Utilitaires ──────────────────────────────────────────────────────────────
is_installed() { command -v "$1" &>/dev/null; }

ask() {
  local prompt="$1" default="${2:-y}" answer
  echo -en "${YELLOW}?${NC} $prompt [$([ "$default" = "y" ] && echo "Y/n" || echo "y/N")] "
  read -r answer </dev/tty
  answer="${answer:-$default}"
  [[ "${answer,,}" == "y" ]]
}

pkg_update() {
  case "$PKG_MANAGER" in
    brew)   brew update -q ;;
    apt)    sudo apt-get update -qq ;;
    dnf)    sudo dnf check-update -q || true ;;
    pacman) sudo pacman -Sy --noconfirm ;;
  esac
}

pkg_install() {
  case "$PKG_MANAGER" in
    brew)   brew install "$@" ;;
    apt)    sudo apt-get install -y "$@" ;;
    dnf)    sudo dnf install -y "$@" ;;
    pacman) sudo pacman -S --noconfirm "$@" ;;
  esac
}

cask_install() {
  [[ "$OS" == "macos" ]] && brew install --cask "$@"
}

# ─── Homebrew (macOS) ─────────────────────────────────────────────────────────
install_homebrew() {
  [[ "$OS" != "macos" ]] && return
  section "Homebrew"
  if ! is_installed brew; then
    info "Installation de Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
    success "Homebrew installé"
  else
    success "Homebrew déjà présent"
  fi
}

# ─── Outils de base ───────────────────────────────────────────────────────────
install_base() {
  section "Outils de base"
  local pkgs=()
  case "$OS" in
    macos)  pkgs=(git curl wget jq tree htop unzip make) ;;
    debian) pkgs=(git curl wget jq tree htop unzip make build-essential ca-certificates gnupg lsb-release) ;;
    fedora) pkgs=(git curl wget jq tree htop unzip make gcc) ;;
    arch)   pkgs=(git curl wget jq tree htop unzip base-devel) ;;
  esac
  for pkg in "${pkgs[@]}"; do
    if ! is_installed "$pkg"; then
      info "Installation de $pkg..."
      pkg_install "$pkg" && success "$pkg installé" || warn "$pkg : échec installation"
    else
      success "$pkg déjà présent"
    fi
  done
}

# ─── Visual Studio Code ───────────────────────────────────────────────────────
install_vscode() {
  section "Visual Studio Code"
  if ! is_installed code; then
    case "$OS" in
      macos)
        cask_install visual-studio-code
        ;;
      debian)
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
          | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] \
          https://packages.microsoft.com/repos/code stable main" \
          | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
        pkg_update && pkg_install code
        ;;
      fedora)
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
        pkg_update && pkg_install code
        ;;
      arch)
        if is_installed yay; then yay -S --noconfirm visual-studio-code-bin
        elif is_installed paru; then paru -S --noconfirm visual-studio-code-bin
        else warn "Installe yay ou paru puis relance pour VS Code sur Arch"; fi
        ;;
    esac
    success "VS Code installé"
  else
    success "VS Code déjà présent"
  fi

  if is_installed code && ask "Installer les extensions VS Code recommandées ?"; then
    local extensions=(
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
    for ext in "${extensions[@]}"; do
      code --install-extension "$ext" --force 2>/dev/null && success "Extension $ext" || warn "Extension $ext : échec"
    done
  fi
}

# ─── Node.js via nvm ──────────────────────────────────────────────────────────
install_nodejs() {
  section "Node.js (via nvm)"
  export NVM_DIR="$HOME/.nvm"

  if [[ ! -d "$NVM_DIR" ]]; then
    info "Installation de nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    success "nvm installé"
  else
    success "nvm déjà présent"
  fi

  # Sourcer nvm pour l'utiliser immédiatement
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

  if command -v nvm &>/dev/null; then
    if ! nvm list | grep -q "lts"; then
      info "Installation de Node.js LTS..."
      nvm install --lts
      nvm alias default "lts/*"
    fi
    nvm use --lts 2>/dev/null && success "Node.js LTS $(node --version) actif"
  else
    warn "nvm chargé mais 'nvm' n'est pas encore dans ce shell — réouvre un terminal"
  fi

  if is_installed npm; then
    if ask "Installer pnpm ?";  then npm install -g pnpm  && success "pnpm installé";  fi
    if ask "Installer yarn ?";  then npm install -g yarn  && success "yarn installé";  fi
    if ask "Installer Vercel CLI ?"; then npm install -g vercel && success "vercel installé"; fi
    if ask "Installer firebase-tools ?"; then npm install -g firebase-tools && success "firebase-tools installé"; fi
  fi
}

# ─── PHP + Composer + Symfony CLI ─────────────────────────────────────────────

_PHP_SELECTED_VERSIONS=()

_select_php_versions() {
  local -a versions=("8.1" "8.2" "8.3" "8.4")
  local -a labels=(
    "PHP 8.1  — fin de vie nov. 2025 (legacy, PrestaShop…)"
    "PHP 8.2  — support actif jusqu'en déc. 2026"
    "PHP 8.3  — recommandée · support actif jusqu'en nov. 2027"
    "PHP 8.4  — dernière stable · support actif jusqu'en déc. 2028"
  )

  echo ""
  echo -e "  ${BOLD}Versions disponibles :${NC}"
  echo ""
  local i
  for i in "${!versions[@]}"; do
    printf "    ${CYAN}[%d]${NC} %s\n" "$((i+1))" "${labels[$i]}"
  done
  echo ""
  echo -e "  ${BOLD}Extensions incluses avec chaque version :${NC}"
  echo -e "    Core  : bcmath · curl · fpm · gd · intl · mbstring · opcache · xml · zip"
  echo -e "    BDD   : mysql · pgsql · sqlite3"
  echo -e "    Cache : redis"
  echo -e "    Optionnel (à la demande) : xdebug · imagick"
  echo ""
  echo -en "${YELLOW}?${NC} Numéros à installer (ex: ${BOLD}3${NC}  |  ${BOLD}2 3${NC}  |  ${BOLD}1 2 3 4${NC}) [défaut: ${BOLD}3${NC}] : "

  local input
  read -r input </dev/tty
  input="${input:-3}"

  _PHP_SELECTED_VERSIONS=()
  local num
  for num in $input; do
    if [[ "$num" =~ ^[1-4]$ ]]; then
      _PHP_SELECTED_VERSIONS+=("${versions[$((num-1))]}")
    else
      warn "Numéro invalide ignoré : $num"
    fi
  done

  [[ ${#_PHP_SELECTED_VERSIONS[@]} -gt 0 ]] && info "Versions sélectionnées : ${_PHP_SELECTED_VERSIONS[*]}"
}

_install_php_macos() {
  local version="$1" xdebug="$2" imagick="$3"

  if ! brew tap | grep -q "shivammathur/php"; then
    info "Ajout du tap shivammathur/php..."
    brew tap shivammathur/php
  fi

  local formula="shivammathur/php/php@${version}"
  if brew list "$formula" &>/dev/null 2>&1; then
    success "PHP $version déjà présent"
  else
    info "Installation de PHP $version..."
    brew install "$formula" && success "PHP $version installé"
  fi

  local pecl_bin
  pecl_bin="$(brew --prefix "$formula" 2>/dev/null)/bin/pecl"

  if [[ "$xdebug" == "true" ]] && [[ -x "$pecl_bin" ]]; then
    info "Xdebug pour PHP $version..."
    echo "" | "$pecl_bin" install xdebug 2>/dev/null \
      && success "Xdebug PHP $version installé" \
      || warn "Xdebug PHP $version : échec (peut-être déjà installé)"
  fi

  if [[ "$imagick" == "true" ]] && [[ -x "$pecl_bin" ]]; then
    brew list imagemagick &>/dev/null || brew install imagemagick
    echo "" | "$pecl_bin" install imagick 2>/dev/null \
      && success "Imagick PHP $version installé" \
      || warn "Imagick PHP $version : échec"
  fi
}

_install_php_debian() {
  local version="$1" xdebug="$2" imagick="$3"
  local v="php${version}"

  local pkgs=(
    "${v}" "${v}-cli" "${v}-fpm" "${v}-common"
    "${v}-mysql" "${v}-pgsql" "${v}-sqlite3"
    "${v}-bcmath" "${v}-curl" "${v}-gd" "${v}-intl"
    "${v}-mbstring" "${v}-opcache" "${v}-xml" "${v}-zip"
    "${v}-redis"
  )

  info "Installation de PHP $version + extensions..."
  pkg_install "${pkgs[@]}" && success "PHP $version installé"

  if [[ "$xdebug" == "true" ]]; then
    pkg_install "${v}-xdebug" \
      && success "Xdebug PHP $version installé" \
      || warn "Xdebug PHP $version : échec"
  fi

  if [[ "$imagick" == "true" ]]; then
    pkg_install "${v}-imagick" \
      && success "Imagick PHP $version installé" \
      || warn "Imagick PHP $version : non disponible via apt"
  fi
}

_install_php_fedora() {
  local version="$1" xdebug="$2" imagick="$3"
  local mv="${version//./}"
  local p="php${mv}"

  if ! rpm -q remi-release &>/dev/null; then
    info "Ajout du dépôt Remi..."
    local fver
    fver=$(rpm -E %fedora)
    sudo dnf install -y "https://rpms.remirepo.net/fedora/remi-release-${fver}.rpm" 2>/dev/null \
      || warn "Dépôt Remi : ajout manuel requis"
  fi

  local pkgs=(
    "${p}" "${p}-php-cli" "${p}-php-fpm"
    "${p}-php-mysqlnd" "${p}-php-pgsql" "${p}-php-sqlite3"
    "${p}-php-bcmath" "${p}-php-gd" "${p}-php-intl"
    "${p}-php-mbstring" "${p}-php-opcache" "${p}-php-xml" "${p}-php-zip"
    "${p}-php-pecl-redis"
  )

  info "Installation de PHP $version + extensions..."
  pkg_install "${pkgs[@]}" && success "PHP $version installé"

  if [[ "$xdebug" == "true" ]]; then
    pkg_install "${p}-php-pecl-xdebug3" \
      && success "Xdebug PHP $version installé" \
      || warn "Xdebug PHP $version : échec"
  fi

  if [[ "$imagick" == "true" ]]; then
    pkg_install "${p}-php-pecl-imagick" \
      && success "Imagick PHP $version installé" \
      || warn "Imagick PHP $version : échec"
  fi
}

_install_php_arch() {
  local version="$1" xdebug="$2" imagick="$3"
  local mv="${version//./}"

  local aur=""
  is_installed yay  && aur="yay"
  is_installed paru && aur="paru"

  if [[ -z "$aur" ]]; then
    warn "PHP $version sur Arch nécessite yay ou paru (AUR) — ignoré."
    return
  fi

  info "Installation de PHP $version via $aur..."
  "$aur" -S --noconfirm "php${mv}" "php${mv}-intl" "php${mv}-gd" "php${mv}-sqlite" \
    && success "PHP $version installé" \
    || warn "PHP $version : échec AUR"

  if [[ "$xdebug" == "true" ]]; then
    "$aur" -S --noconfirm "php${mv}-xdebug" \
      && success "Xdebug PHP $version installé" \
      || warn "Xdebug PHP $version : non disponible"
  fi
}

_set_default_php() {
  local version="$1"
  case "$OS" in
    macos)
      brew unlink php 2>/dev/null || true
      brew link --force --overwrite "shivammathur/php/php@${version}" 2>/dev/null \
        && success "PHP $version activé par défaut" \
        || warn "Lien manuel : brew link --force shivammathur/php/php@${version}"
      ;;
    debian)
      sudo update-alternatives --set php "/usr/bin/php${version}" 2>/dev/null \
        && success "PHP $version activé (update-alternatives)" \
        || warn "Configure manuellement : sudo update-alternatives --config php"
      ;;
    fedora)
      warn "Sur Fedora, utilise '/usr/bin/php${version//./}' ou configure update-alternatives."
      ;;
    arch)
      warn "Sur Arch, utilise '/usr/bin/php${version//./}' directement."
      ;;
  esac
}

install_php() {
  section "PHP — Versions et extensions"

  _select_php_versions

  if [[ ${#_PHP_SELECTED_VERSIONS[@]} -eq 0 ]]; then
    warn "Aucune version PHP sélectionnée — étape ignorée."
    return
  fi

  local xdebug=false imagick=false
  ask "Installer Xdebug (débogage PHP, recommandé en dev) ?" && xdebug=true
  ask "Installer Imagick (traitement d'images avancé) ?"      && imagick=true

  if [[ "$OS" == "debian" ]]; then
    if ! grep -rq "ondrej/php" /etc/apt/sources.list.d/ 2>/dev/null; then
      info "Ajout du PPA ondrej/php..."
      sudo apt-get install -y software-properties-common
      sudo add-apt-repository ppa:ondrej/php -y
      pkg_update
    fi
  fi

  for version in "${_PHP_SELECTED_VERSIONS[@]}"; do
    echo ""
    echo -e "${BOLD}${CYAN}  ── PHP $version ──${NC}"
    case "$OS" in
      macos)  _install_php_macos  "$version" "$xdebug" "$imagick" ;;
      debian) _install_php_debian "$version" "$xdebug" "$imagick" ;;
      fedora) _install_php_fedora "$version" "$xdebug" "$imagick" ;;
      arch)   _install_php_arch   "$version" "$xdebug" "$imagick" ;;
    esac
  done

  if [[ ${#_PHP_SELECTED_VERSIONS[@]} -gt 1 ]]; then
    local last="${_PHP_SELECTED_VERSIONS[-1]}"
    echo ""
    echo -e "${BOLD}Versions installées :${NC} ${_PHP_SELECTED_VERSIONS[*]}"
    echo -en "${YELLOW}?${NC} Version à activer par défaut ? [${BOLD}${last}${NC}] : "
    local default_ver
    read -r default_ver </dev/tty
    _set_default_php "${default_ver:-$last}"
  fi

  # ── Composer ──
  if ! is_installed composer; then
    info "Installation de Composer..."
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/tmp --filename=composer
    sudo mv /tmp/composer /usr/local/bin/composer
    sudo chmod +x /usr/local/bin/composer
    success "Composer $(composer --version --no-ansi | awk '{print $3}') installé"
  else
    success "Composer déjà présent"
  fi

  # ── Symfony CLI ──
  if ! is_installed symfony; then
    info "Installation de Symfony CLI..."
    curl -sS https://get.symfony.com/cli/installer | bash
    local symfony_bin
    symfony_bin="$(find "$HOME" -name symfony -type f 2>/dev/null | head -1)"
    if [[ -n "$symfony_bin" && ! -f /usr/local/bin/symfony ]]; then
      sudo cp "$symfony_bin" /usr/local/bin/symfony
      sudo chmod +x /usr/local/bin/symfony
    fi
    success "Symfony CLI installé"
  else
    success "Symfony CLI déjà présent"
  fi
}

# ─── Python via pyenv ─────────────────────────────────────────────────────────
install_python() {
  section "Python (via pyenv)"
  local PYTHON_VERSION="3.12.3"

  # Dépendances
  case "$OS" in
    macos)  pkg_install openssl readline sqlite3 xz zlib ;;
    debian) pkg_install make build-essential libssl-dev zlib1g-dev libbz2-dev \
              libreadline-dev libsqlite3-dev libncursesw5-dev xz-utils \
              tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev ;;
    fedora) pkg_install make gcc zlib-devel bzip2-devel readline-devel sqlite-devel \
              openssl-devel tk-devel libffi-devel xz-devel ;;
    arch)   pkg_install base-devel openssl zlib xz tk ;;
  esac

  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"

  if [[ ! -d "$PYENV_ROOT" ]]; then
    info "Installation de pyenv..."
    curl https://pyenv.run | bash

    # Ajouter pyenv au shell rc
    local shell_rc="$HOME/.bashrc"
    [[ -n "${ZSH_VERSION:-}" || -f "$HOME/.zshrc" ]] && shell_rc="$HOME/.zshrc"
    cat >> "$shell_rc" <<'SHELL'

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
SHELL
    success "pyenv installé"
  else
    success "pyenv déjà présent"
  fi

  eval "$(pyenv init -)" 2>/dev/null || true

  if command -v pyenv &>/dev/null; then
    if ! pyenv versions 2>/dev/null | grep -q "$PYTHON_VERSION"; then
      info "Installation de Python $PYTHON_VERSION (peut prendre quelques minutes)..."
      pyenv install "$PYTHON_VERSION"
      pyenv global "$PYTHON_VERSION"
      success "Python $PYTHON_VERSION installé"
    else
      success "Python $PYTHON_VERSION déjà présent"
    fi
    pip install --upgrade pip -q
    if ask "Installer Poetry ?"; then pip install poetry -q && success "Poetry installé"; fi
    if ask "Installer pipx ?";   then pip install pipx  -q && success "pipx installé";  fi
  else
    warn "pyenv installé mais pas encore actif dans ce shell — réouvre un terminal"
  fi
}

# ─── .NET SDK ─────────────────────────────────────────────────────────────────
install_dotnet() {
  section ".NET SDK 8"
  if is_installed dotnet; then
    success ".NET déjà présent ($(dotnet --version))"
    return
  fi
  case "$OS" in
    macos)  cask_install dotnet-sdk ;;
    debian)
      local ubuntu_version
      ubuntu_version=$(lsb_release -rs 2>/dev/null || echo "22.04")
      wget -q "https://packages.microsoft.com/config/ubuntu/${ubuntu_version}/packages-microsoft-prod.deb" -O /tmp/ms-prod.deb
      sudo dpkg -i /tmp/ms-prod.deb
      pkg_update && pkg_install dotnet-sdk-8.0
      ;;
    fedora) pkg_install dotnet-sdk-8.0 ;;
    arch)   pkg_install dotnet-sdk ;;
  esac
  success ".NET SDK $(dotnet --version 2>/dev/null) installé"
}

# ─── Docker ───────────────────────────────────────────────────────────────────
install_docker() {
  section "Docker"
  if is_installed docker; then
    success "Docker déjà présent ($(docker --version | awk '{print $3}' | tr -d ','))"
    return
  fi
  case "$OS" in
    macos)
      cask_install docker
      success "Docker Desktop installé — ouvre l'application pour finaliser"
      ;;
    debian)
      sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
      pkg_install ca-certificates curl gnupg
      sudo install -m 0755 -d /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      sudo chmod a+r /etc/apt/keyrings/docker.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
      pkg_update
      pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      sudo systemctl enable --now docker
      sudo usermod -aG docker "$USER"
      success "Docker installé — déconnecte/reconnecte-toi pour les permissions"
      ;;
    fedora)
      pkg_install dnf-plugins-core
      sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
      pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      sudo systemctl enable --now docker
      sudo usermod -aG docker "$USER"
      success "Docker installé"
      ;;
    arch)
      pkg_install docker docker-compose
      sudo systemctl enable --now docker
      sudo usermod -aG docker "$USER"
      success "Docker installé"
      ;;
  esac
}

# ─── Outils API ───────────────────────────────────────────────────────────────
install_api_tools() {
  section "Outils API"

  if ask "Installer Postman ?"; then
    case "$OS" in
      macos) cask_install postman && success "Postman installé" ;;
      *)
        if is_installed snap; then
          sudo snap install postman && success "Postman installé"
        else
          warn "Télécharge Postman manuellement : https://www.postman.com/downloads/"
        fi
        ;;
    esac
  fi

  if ask "Installer Bruno (alternative open-source à Postman) ?"; then
    case "$OS" in
      macos) cask_install bruno && success "Bruno installé" ;;
      debian)
        sudo mkdir -p /etc/apt/keyrings
        sudo gpg --no-default-keyring --keyring /etc/apt/keyrings/bruno.gpg \
          --keyserver keyserver.ubuntu.com --recv-keys 9FA6017ECABE0266
        echo "deb [signed-by=/etc/apt/keyrings/bruno.gpg] http://debian.usebruno.com/ bruno stable" \
          | sudo tee /etc/apt/sources.list.d/bruno.list >/dev/null
        pkg_update && pkg_install bruno && success "Bruno installé"
        ;;
      *) warn "Télécharge Bruno manuellement : https://www.usebruno.com/" ;;
    esac
  fi

  if ask "Installer HTTPie (client HTTP CLI) ?"; then
    pkg_install httpie 2>/dev/null && success "HTTPie installé" \
      || { pip install httpie -q && success "HTTPie installé via pip"; }
  fi
}

# ─── Outils base de données ───────────────────────────────────────────────────
install_db_tools() {
  section "Outils base de données"

  if ask "Installer DBeaver (GUI BDD universel) ?"; then
    case "$OS" in
      macos) cask_install dbeaver-community && success "DBeaver installé" ;;
      debian)
        curl -fsSL https://dbeaver.io/files/dbeaver.gpg.key \
          | sudo gpg --dearmor -o /usr/share/keyrings/dbeaver.gpg
        echo "deb [signed-by=/usr/share/keyrings/dbeaver.gpg] https://dbeaver.io/debs/dbeaver-ce /" \
          | sudo tee /etc/apt/sources.list.d/dbeaver.list >/dev/null
        pkg_update && pkg_install dbeaver-ce && success "DBeaver installé"
        ;;
      *) warn "Télécharge DBeaver : https://dbeaver.io/download/" ;;
    esac
  fi

  if ask "Installer le client MySQL CLI ?"; then
    case "$OS" in
      macos)  pkg_install mysql-client ;;
      debian) pkg_install default-mysql-client ;;
      fedora) pkg_install mysql ;;
      arch)   pkg_install mysql-clients ;;
    esac && success "MySQL client installé" || true
  fi

  if ask "Installer le client PostgreSQL CLI ?"; then
    case "$OS" in
      macos)  pkg_install libpq ;;
      debian) pkg_install postgresql-client ;;
      fedora) pkg_install postgresql ;;
      arch)   pkg_install postgresql-libs ;;
    esac && success "PostgreSQL client installé" || true
  fi

  if ask "Installer Redis CLI ?"; then
    case "$OS" in
      macos)  pkg_install redis ;;
      debian) pkg_install redis-tools ;;
      fedora) pkg_install redis ;;
      arch)   pkg_install redis ;;
    esac && success "Redis CLI installé" || true
  fi
}

# ─── Outils DevOps / Cloud ────────────────────────────────────────────────────
install_devops_tools() {
  section "Outils DevOps / Cloud"

  # GitHub CLI
  if ! is_installed gh; then
    info "Installation de GitHub CLI..."
    case "$OS" in
      macos) pkg_install gh ;;
      debian)
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
          | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
          https://cli.github.com/packages stable main" \
          | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        pkg_update && pkg_install gh
        ;;
      fedora) pkg_install gh ;;
      arch)   pkg_install github-cli ;;
    esac
    success "GitHub CLI installé"
  else
    success "GitHub CLI déjà présent"
  fi

  if ask "Installer kubectl ?"; then
    case "$OS" in
      macos) pkg_install kubectl ;;
      debian|fedora)
        curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key \
          | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
        echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
          https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" \
          | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null
        pkg_update && pkg_install kubectl
        ;;
      arch) pkg_install kubectl ;;
    esac && success "kubectl installé"
  fi

  if ask "Installer Helm ?"; then
    case "$OS" in
      macos) pkg_install helm ;;
      *)     curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash ;;
    esac && success "Helm installé"
  fi

  if ask "Installer AWS CLI ?"; then
    case "$OS" in
      macos) pkg_install awscli ;;
      *)
        curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
        unzip -q /tmp/awscliv2.zip -d /tmp
        sudo /tmp/aws/install
        rm -rf /tmp/awscliv2.zip /tmp/aws
        ;;
    esac && success "AWS CLI installé"
  fi

  if ask "Installer Terraform ?"; then
    case "$OS" in
      macos) brew tap hashicorp/tap && pkg_install hashicorp/tap/terraform ;;
      debian)
        wget -O- https://apt.releases.hashicorp.com/gpg \
          | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
          https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
          | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
        pkg_update && pkg_install terraform
        ;;
      fedora) pkg_install terraform ;;
      arch) pkg_install terraform ;;
    esac && success "Terraform installé"
  fi
}

# ─── Outils terminal ──────────────────────────────────────────────────────────
install_terminal_tools() {
  section "Outils terminal"

  if ! is_installed zsh; then
    pkg_install zsh
    chsh -s "$(which zsh)" "$USER" && success "zsh défini comme shell par défaut" || warn "Lance 'chsh -s \$(which zsh)' manuellement"
  else
    success "zsh déjà présent"
  fi

  if [[ ! -d "$HOME/.oh-my-zsh" ]] && ask "Installer Oh My Zsh ?"; then
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    success "Oh My Zsh installé"
  elif [[ -d "$HOME/.oh-my-zsh" ]]; then
    success "Oh My Zsh déjà présent"
  fi

  if ask "Installer tmux ?"; then
    pkg_install tmux && success "tmux installé"
  fi

  if ask "Installer fzf (fuzzy finder) ?"; then
    case "$OS" in
      macos)  pkg_install fzf ;;
      debian) pkg_install fzf ;;
      fedora) pkg_install fzf ;;
      arch)   pkg_install fzf ;;
    esac && success "fzf installé"
  fi

  if ask "Installer bat (cat amélioré), ripgrep, fd ?"; then
    case "$OS" in
      macos)
        pkg_install bat ripgrep fd
        ;;
      debian)
        pkg_install bat ripgrep fd-find
        ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
        ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true
        ;;
      fedora) pkg_install bat ripgrep fd-find ;;
      arch)   pkg_install bat ripgrep fd ;;
    esac && success "bat, ripgrep, fd installés"
  fi
}

# ─── WP-CLI ───────────────────────────────────────────────────────────────────
install_wpcli() {
  section "WP-CLI (WordPress)"
  if ! is_installed wp; then
    info "Installation de WP-CLI..."
    curl -fsSL "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" -o /tmp/wp-cli.phar
    chmod +x /tmp/wp-cli.phar
    sudo mv /tmp/wp-cli.phar /usr/local/bin/wp
    success "WP-CLI $(wp --version 2>/dev/null) installé"
  else
    success "WP-CLI déjà présent"
  fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  clear
  echo -e "${BOLD}${CYAN}"
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║         DevSetup — Installation dev tools           ║"
  echo "║       macOS · Ubuntu/Debian · Fedora · Arch         ║"
  echo "╚══════════════════════════════════════════════════════╝"
  echo -e "${NC}"

  detect_os

  # Homebrew obligatoire sur macOS
  if [[ "$OS" == "macos" ]]; then
    install_homebrew
  else
    info "Mise à jour des dépôts..."
    pkg_update
  fi

  echo ""
  echo -e "${BOLD}Sélectionne les outils à installer (Y/n par catégorie) :${NC}"
  echo ""

  if ask "Outils de base (git, curl, jq, make…) ?";             then install_base; fi
  if ask "Visual Studio Code + extensions ?";                    then install_vscode; fi
  if ask "Node.js (via nvm) + npm globals ?";                    then install_nodejs; fi
  if ask "PHP (choix de version) + Composer + Symfony CLI ?";    then install_php; fi
  if ask "Python 3.12 (via pyenv) ?";                            then install_python; fi
  if ask ".NET SDK 8 (C# / ASP.NET) ?";                         then install_dotnet; fi
  if ask "Docker ?";                                             then install_docker; fi
  if ask "Outils API (Postman, Bruno, HTTPie) ?";                then install_api_tools; fi
  if ask "Outils BDD (DBeaver, clients MySQL/PG/Redis) ?";       then install_db_tools; fi
  if ask "Outils DevOps/Cloud (gh, kubectl, Helm, AWS, TF) ?";   then install_devops_tools; fi
  if ask "Outils terminal (zsh, Oh My Zsh, fzf, bat…) ?";        then install_terminal_tools; fi
  if ask "WP-CLI (WordPress) ?";                                 then install_wpcli; fi

  echo ""
  echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${GREEN}║         Installation terminée avec succès !         ║${NC}"
  echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
  echo ""
  warn "Redémarre ton terminal (ou tape : source ~/.zshrc) pour activer nvm, pyenv, etc."
  if [[ "$OS" != "macos" ]]; then
    warn "Si Docker a été installé, déconnecte/reconnecte-toi pour les permissions groupe."
  fi
}

main "$@"

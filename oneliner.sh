#!/usr/bin/env bash
# =============================================================================
# One-liner d'installation — telecharge et lance le setup depuis GitHub
#
# Usage Mac/Linux :
#   curl -fsSL https://raw.githubusercontent.com/DenZaiyy/devsetup/main/install.sh | bash
#
# Usage Windows (PowerShell admin) :
#   irm https://raw.githubusercontent.com/DenZaiyy/devsetup/main/install.ps1 | iex
# =============================================================================

set -euo pipefail

REPO_URL="https://raw.githubusercontent.com/DenZaiyy/devsetup/main"
TMP_DIR="$(mktemp -d)"
SCRIPT="$TMP_DIR/install.sh"

echo "Telechargement du setup..."
curl -fsSL "$REPO_URL/install.sh" -o "$SCRIPT"
chmod +x "$SCRIPT"

echo "Lancement du setup..."
bash "$SCRIPT"

rm -rf "$TMP_DIR"

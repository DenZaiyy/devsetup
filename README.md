# DevSetup

Installation interactive des outils de développement sur une machine vierge.

## Installation

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/DenZaiyy/devsetup/main/install.sh | bash
```

### Windows

PowerShell ouvert **en tant qu'administrateur** :

```powershell
irm https://raw.githubusercontent.com/DenZaiyy/devsetup/main/install.ps1 | iex
```

---

## Outils disponibles

| Catégorie | Outils |
|---|---|
| Base | git, curl, jq, make, ripgrep, bat, fd |
| IDE | VS Code + extensions (PHP, Symfony, Docker, TS, Tailwind…) |
| Node.js | nvm / fnm + LTS, pnpm, yarn, vercel, firebase |
| PHP | PHP 8.1 / 8.2 / 8.3 / 8.4 (multi-versions), Composer, Symfony CLI |
| Python | pyenv + Python 3.12, Poetry, pipx |
| .NET | SDK 8 |
| Docker | Docker Desktop (Mac/Win) / Docker CE (Linux) |
| API | Postman, Bruno, HTTPie |
| BDD | DBeaver, clients MySQL / PostgreSQL / Redis |
| DevOps | GitHub CLI, kubectl, Helm, AWS CLI, Terraform |
| Terminal | zsh, Oh My Zsh, fzf, tmux, bat |
| WordPress | WP-CLI |

Le script est interactif : il demande confirmation pour chaque catégorie.

---

## PHP — Sélection des versions

Lors de l'installation de PHP, le script propose un sélecteur multi-versions :

```
  Versions disponibles :

    [1] PHP 8.1  — fin de vie nov. 2025 (legacy, PrestaShop…)
    [2] PHP 8.2  — support actif jusqu'en déc. 2026
    [3] PHP 8.3  — recommandée · support actif jusqu'en nov. 2027
    [4] PHP 8.4  — dernière stable · support actif jusqu'en déc. 2028

? Numéros à installer (ex: 3  |  2 3  |  1 2 3 4) [défaut: 3] :
```

Il suffit de taper les numéros séparés par un espace (ex : `2 3` pour PHP 8.2 et 8.3).

### Extensions installées avec chaque version

| Catégorie | Extensions |
|-----------|-----------|
| Core | `bcmath` `curl` `fpm` `gd` `intl` `mbstring` `opcache` `xml` `zip` |
| BDD | `mysql` `pgsql` `sqlite3` |
| Cache | `redis` |
| Optionnel | `xdebug` · `imagick` (demandé séparément) |

### Dépôts utilisés par OS

| OS | Source |
|----|--------|
| macOS | tap `shivammathur/php` (Homebrew) |
| Debian / Ubuntu | PPA `ondrej/php` |
| Fedora | Dépôt Remi |
| Arch Linux | AUR via `yay` ou `paru` |

Quand plusieurs versions sont installées, le script propose de définir la version active par défaut (`update-alternatives` sur Linux, `brew link` sur macOS).

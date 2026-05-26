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
| PHP | PHP 8.3, Composer, Symfony CLI |
| Python | pyenv + Python 3.12, Poetry, pipx |
| .NET | SDK 8 |
| Docker | Docker Desktop (Mac/Win) / Docker CE (Linux) |
| API | Postman, Bruno, HTTPie |
| BDD | DBeaver, clients MySQL / PostgreSQL / Redis |
| DevOps | GitHub CLI, kubectl, Helm, AWS CLI, Terraform |
| Terminal | zsh, Oh My Zsh, fzf, tmux, bat |
| WordPress | WP-CLI |

Le script est interactif : il demande confirmation pour chaque catégorie.

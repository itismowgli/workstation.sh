# workstation.sh — Developer Environment Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![macOS](https://shields.io/badge/MacOS--9cf?logo=Apple&style=social)](#)
[![Linux](https://img.shields.io/badge/-Linux-grey?logo=linux)](#)
[![Shell](https://img.shields.io/badge/shell-Bash%205%2B-4EAA25?logo=gnu-bash&logoColor=white)](#)
[![Latest Release](https://img.shields.io/github/v/release/itismowgli/workstation.sh?sort=semver)](https://github.com/itismowgli/workstation.sh/releases)
[![Changelog](https://img.shields.io/badge/Changelog-📜-blue)](CHANGELOG.md)

`workstation.sh` is an **idempotent**, **multi‑OS** shell script that turns a vanilla macOS or Linux box into a ready‑to‑work developer machine in minutes.

> **Why another bootstrap script?** Dotfiles feel like black‑magic. `workstation.sh` guides you through every step so you _always_ know what’s being installed—without overwriting your setup blindly.

---

## Table of contents

- [Highlights](#highlights)
- [Quick‑start](#quick‑start)
- [Common flags](#common-flags)
- [Modules Overview](#modules-overview)
- [Modules](#modules)
- [Detailed package reference](#detailed-package-reference)
- [After installation](#after-installation)
- [Logging & Errors](#logging--errors)
- [Reverting](#reverting)
- [CI Support](#ci-support)
- [Contributing](#contributing)
- [License](#license)

---

## Highlights

- **One‑liner install** – copy‑paste and go.
- **Interactive _or_ fully automated** – pick modules in a menu, or run `--all` for hands‑off provisioning.
- **Dry‑run mode** – preview every step before anything changes.
- **Safe to re‑run** – already‑installed packages are skipped; dotfiles are backed up.
- **Works everywhere** – macOS (Homebrew), Debian/Ubuntu (apt), Fedora/RHEL (dnf), Arch (pacman), and CI environments.

---

## Quick‑start

```bash
curl -fsSL https://raw.githubusercontent.com/itismowgli/workstation.sh/main/workstation.sh | bash
```

### Manual:

```bash
curl -O https://raw.githubusercontent.com/itismowgli/workstation.sh/main/workstation.sh
chmod +x workstation.sh
./workstation.sh            # interactive menu
```

### One-command identical setup

Run every module and apply the canonical Git/Delta and Zsh configuration:

```bash
curl -fsSL https://raw.githubusercontent.com/itismowgli/workstation.sh/main/workstation.sh | \
  bash -s -- --all --name "Your Name" --email you@example.com
```

Existing `~/.gitconfig` and `~/.zshrc` files are backed up before the canonical
versions are written, so re-running this command keeps machines aligned while
leaving a recovery copy of the previous configuration.

### Updating the Script

```bash
./workstation.sh --update
```

This replaces your local version with the latest from `main`.

---

## Common flags

| Flag                                               | Purpose                                                                    |
| -------------------------------------------------- | -------------------------------------------------------------------------- |
| `--all`                                            | Install **all** modules without prompts (requires `--name` and `--email`). |
| `--dry-run`                                        | Preview what would happen without making changes.                          |
| `--name "Your Name"`<br/>`--email you@example.com` | Set your Git identity for module 6.                                        |
| `--signingkey ABCDEF123456`                        | Add GPG key for Git commit signing.                                        |
| `--update`                                         | Pull the latest version of the script.                                     |

Examples:

```bash
# Fully automated install
./workstation.sh --all --name "Ada Lovelace" --email ada@example.com

# Preview mode
./workstation.sh --all --dry-run
```

---

## Modules Overview

```text
0 Core            → git, curl, build-essential, Homebrew/apt/dnf/pacman
1 Zsh + P10k      → oh-my-zsh, powerlevel10k, plugins, ~/.zshrc
2 CLI toolchain   → delta, fzf, ripgrep, bat, eza, fd, bottom, dust, zoxide, thefuck
3 Nerd Font       → Meslo LG Nerd Font (skipped in WSL)
4 DB & Services   → MySQL/MariaDB, Redis, Nginx, dnsmasq
5 PHP Stack       → php, composer, direnv, Laravel Valet (macOS only)
6 Git config      → opinionated ~/.gitconfig with delta pager & aliases
7 Node & NVM      → nvm + latest LTS Node.js
```

---

## Modules

See [Detailed package reference](#detailed-package-reference) for a full list of tools in each module.

Run interactively or specify by ID:

```bash
./workstation.sh 0 1 2 7
```

---

## Detailed package reference

### Module 0: Core
- **git** - Version control system
- **curl** - Data transfer tool
- **build-essential** (Linux) - Compilation tools
- **Homebrew** (macOS) - Package manager

### Module 1: Zsh + Powerlevel10k
- **zsh** - Advanced shell
- **[Oh My Zsh](https://ohmyz.sh/)** - Zsh framework
- **[Powerlevel10k](https://github.com/romkatv/powerlevel10k)** - Zsh theme
- **[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)** - Syntax highlighting
- **[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)** - Command suggestions
- **[fzf-tab](https://github.com/Aloxaf/fzf-tab)** - Fuzzy tab completion

### Module 2: CLI Toolchain
- **[git-delta](https://dandavison.github.io/delta/)** - Syntax-highlighted Git diffs, installed with a recent `less` pager
- **[fzf](https://github.com/junegunn/fzf)** - Fuzzy finder
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** - Fast grep alternative
- **[bat](https://github.com/sharkdp/bat)** - Better cat with syntax highlighting
- **[eza](https://github.com/eza-community/eza)** - Modern ls replacement
- **[fd](https://github.com/sharkdp/fd)** - Fast find alternative
- **[bottom](https://github.com/ClementTsang/bottom)** - System monitor
- **[dust](https://github.com/bootandy/dust)** - Better du
- **[zoxide](https://github.com/ajeetdsouza/zoxide)** - Smart cd command
- **[thefuck](https://github.com/nvbn/thefuck)** - Command correction

### Module 3: Nerd Font
- **[Meslo LG Nerd Font](https://github.com/ryanoasis/nerd-fonts)** - Programming font with icons

### Module 4: Database & Services
- **MySQL/MariaDB** - Database server
- **Redis** - In-memory data store
- **Nginx** - Web server
- **dnsmasq** - DNS forwarder

### Module 5: PHP Stack (macOS only)
- **PHP** - Programming language
- **[Composer](https://getcomposer.org/)** - PHP dependency manager
- **[direnv](https://direnv.net/)** - Environment variable manager
- **[Laravel Valet](https://laravel.com/docs/valet)** - Development environment

### Module 6: Git Configuration
- Canonical `~/.gitconfig` with Delta pager, side-by-side diffs, line numbers, navigation, and hyperlinks
- Useful Git aliases and settings
- GPG signing support

### Module 7: Node & NVM
- **[NVM](https://github.com/nvm-sh/nvm)** - Node version manager
- **Node.js LTS** - JavaScript runtime

---

## After installation

1. **Restart your shell** (or `exec zsh`).
2. First-time Powerlevel10k? Run:

```bash
p10k configure
```

---

## Logging & Errors

If something goes wrong, logs are saved to:

```text
~/workstation.error.YYYYMMDD-HHMMSS.log
```

Helpful for debugging or sharing in issues.

---

## Reverting

- **Config files**: Backups like `~/.zshrc.bak.2025-07-11_16-08-00` are created.
- **Packages**: Use your OS package manager, e.g. `brew uninstall fzf`, `apt remove bat`.
- **Default shell**: To switch back to bash:

```bash
chsh -s /bin/bash
```

---

## CI Support

- Detects CI with `$CI` env var.
- Runs non-interactively with no color.
- Logs are saved if the script fails.

Use in CI/CD pipelines like so:

```bash
./workstation.sh --all --name "CI Bot" --email ci@example.com
```

---

## Contributing

Fixes, feature ideas, and PRs welcome. See `CONTRIBUTING.md` for guidelines.

---

## License

MIT © Parth

> Built with ❤️ by [@itismowgli](https://github.com/itismowgli)

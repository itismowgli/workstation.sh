#!/usr/bin/env bash
# =======================================================================================
# workstation.sh – Production-Ready Developer Workstation Installer
# =======================================================================================
# This script is idempotent, safe, and user-friendly. It automates developer setup
# on macOS and major Linux distributions.
#
# Features:
#   • Interactive menu & non-interactive --all mode.
#   • --dry-run flag to preview changes.
#   • --update flag to self-update.
#   • Auto-detects CI environments for automation.
#   • Logs all output to a timestamped file on error.
#   • Safely backs up dotfiles with checksums.
#   • Handles OS-specific package manager corner cases.
# =======================================================================================
# MODULE MATRIX
# 0 Core            → git, curl, build-essential, Homebrew/apt/dnf/pacman
# 1 Zsh + P10k      → oh-my-zsh, powerlevel10k, plugins, ~/.zshrc
# 2 CLI toolchain   → delta, fzf, ripgrep, bat, eza, fd, bottom, dust, zoxide, thefuck
# 3 Nerd Font       → Meslo LG Nerd Font (skipped in WSL)
# 4 DB & Services   → MySQL/MariaDB, Redis, Nginx, dnsmasq
# 5 PHP Stack       → php, composer, direnv, Laravel Valet (macOS)
# 6 Git config      → opinionated ~/.gitconfig with delta pager & aliases
# 7 Node & NVM      → nvm + latest LTS node
# =======================================================================================
set -euo pipefail

# --- Self-update ---
# Replace with your actual raw script URL after publishing
SCRIPT_URL="https://raw.githubusercontent.com/itismowgli/workstation.sh/main/workstation.sh"
if [[ "${1:-}" == "--update" ]]; then
    echo "Updating script from $SCRIPT_URL..."
    curl --connect-timeout 15 --retry 3 -fsSL "$SCRIPT_URL" -o "$0" || { echo "Update failed."; exit 1; }
    chmod +x "$0"
    echo "Update complete. Run the script again."
    exit 0
fi

# ---------------------------- Flags & Initial Setup ------------------------------------
DRY_RUN=false
INSTALL_ALL=false
NO_COLOR=false
GIT_NAME=""
GIT_EMAIL=""
GIT_SIGN=""

# Auto-detect CI environment
if [[ -n "${CI:-}" ]]; then
  INSTALL_ALL=true
  NO_COLOR=true
  echo "CI environment detected. Running in non-interactive, no-color mode."
fi

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY_RUN=true; shift;;
    --all) INSTALL_ALL=true; shift;;
    --name) GIT_NAME=$2; shift 2;;
    --email) GIT_EMAIL=$2; shift 2;;
    --signingkey) GIT_SIGN=$2; shift 2;;
    *) echo "Unknown flag $1"; exit 1;;
  esac
done

# ----------------------------- Logging & Cleanup ---------------------------------------
# Log to a temporary file. It will only be saved if an error occurs.
TMP_LOG_FILE=$(mktemp)
SUDO_LOOP_PID=""
# Graceful exit on Ctrl-C or script error
cleanup() {
    exit_code=$?
    if [[ -n "$SUDO_LOOP_PID" ]]; then
        kill "$SUDO_LOOP_PID" 2>/dev/null
    fi
    trap - INT TERM EXIT

    if [[ $exit_code -ne 0 ]]; then
        LOG_FILE="$HOME/workstation.error.$(date +%Y%m%d-%H%M%S).log"
        mv "$TMP_LOG_FILE" "$LOG_FILE"
        echo -e "\\nAborted with error. Log file is at $LOG_FILE"
    else
        rm -f "$TMP_LOG_FILE"
    fi
    exit $exit_code
}
trap cleanup INT TERM EXIT
exec > >(tee -a "$TMP_LOG_FILE") 2>&1

# ----------------------------- Color & Echo Helpers ------------------------------------
color() {
  if $NO_COLOR; then
    printf "%s" "$2"
  else
    printf "\e[%sm%s\e[0m" "$1" "$2"
  fi
}
echo_step() { color 36 "\n==> $1\n"; }
echo_info() { color 34 " -> $1\n"; }
echo_dry() { color 33 " [DRY RUN] $1\n"; }

echo_step "Starting setup. A log file will be created at ~/workstation.error.*.log if an error occurs."
if $DRY_RUN; then echo_step "Running in DRY RUN mode. No changes will be made."; fi

# ----------------------------- OS & Environment Detection ------------------------------
OS=$(uname -s)
PKG=""
SUDO="sudo"
[[ $EUID -eq 0 ]] && SUDO="" # Disable sudo if running as root

IS_WSL=false
if [[ -f /proc/sys/kernel/osrelease ]] && grep -qi "microsoft" /proc/sys/kernel/osrelease; then
  IS_WSL=true
  echo_info "WSL detected. Some features (like font installation) will be skipped."
fi

case $OS in
  Darwin) PKG="brew";;
  Linux)
    if command -v apt-get &>/dev/null; then PKG="apt";
    elif command -v dnf &>/dev/null; then PKG="dnf";
    elif command -v pacman &>/dev/null; then PKG="pacman";
    else echo "Unsupported Linux distribution"; exit 1; fi;;
  *) echo "Unsupported OS $OS"; exit 1;;
esac

# ----------------------------- Core Functions ------------------------------------------
backup_file() {
  if [ -f "$1" ]; then
    local backup_path="$1.bak.$(date +%Y-%m-%d_%H-%M-%S)"
    echo_info "Existing file '$1' found."
    if command -v sha256sum &>/dev/null; then
      echo_info "SHA-256 of original file: $(sha256sum "$1" | awk '{print $1}')"
    elif command -v shasum &>/dev/null; then
      echo_info "SHA-256 of original file: $(shasum -a 256 "$1" | awk '{print $1}')"
    fi
    echo_info "Backing it up to '$backup_path'."
    if ! $DRY_RUN; then
      mv "$1" "$backup_path"
    else
      echo_dry "Would move '$1' to '$backup_path'"
    fi
  fi
}

install_pkgs() {
  if $DRY_RUN; then
    echo_dry "Would check and install packages: $*"
    return 0 # Explicitly succeed in dry-run mode
  fi

  local pkgs_to_install=()
  for pkg in "$@"; do
    local is_installed=false
    local query_pkg=$pkg
    [[ $pkg == "bat" && $PKG == "apt" ]] && query_pkg="batcat"
    [[ $pkg == "fd" && ( $PKG == "apt" || $PKG == "dnf" ) ]] && query_pkg="fd-find"

    case $PKG in
      brew) (brew list "$pkg" &>/dev/null || brew list --cask "$pkg" &>/dev/null) && is_installed=true ;;
      apt) dpkg -s "$query_pkg" &>/dev/null && is_installed=true ;;
      dnf) rpm -q "$query_pkg" &>/dev/null && is_installed=true ;;
      pacman) pacman -Q "$pkg" &>/dev/null && is_installed=true ;;
    esac

    if $is_installed; then
      echo_info "Package '$pkg' is already installed. Skipping."
    else
      pkgs_to_install+=("$query_pkg")
    fi
  done

  if [ ${#pkgs_to_install[@]} -gt 0 ]; then
    echo_info "Installing missing packages: ${pkgs_to_install[*]}"
    case $PKG in
      brew) brew install "${pkgs_to_install[@]}";;
      apt) $SUDO apt-get update -qq && $SUDO apt-get install -y "${pkgs_to_install[@]}";;
      dnf) $SUDO dnf -y install "${pkgs_to_install[@]}";;
      pacman)
        local pac_flags=(--noconfirm --needed)
        if ! $NO_COLOR; then pac_flags+=(--color auto); fi
        $SUDO pacman -Sy "${pac_flags[@]}" "${pkgs_to_install[@]}"
        ;;
    esac
  else
    echo_info "All packages in this group are already installed."
  fi
}

# ----------------------------- Module Selection ----------------------------------------
mods=(
  "Core package manager & base utils"
  "Oh‑My‑Zsh + Powerlevel10k prompt"
  "CLI toolchain (fzf, delta, eza, bat, rg, fd, etc.)"
  "Nerd Font (Meslo)"
  "Database & web services (MySQL, Redis, Nginx, dnsmasq)"
  "PHP, Composer & Laravel Valet/Herd"
  "Opinionated ~/.gitconfig with delta"
  "Node & NVM"
)
if $IS_WSL; then
  mods[3]+=" (skipped in WSL)"
fi

sel=()
if $INSTALL_ALL; then
  sel=("${!mods[@]}")
else
  printf "\nSelect modules to install (e.g., '1 3 5' or 'all'):\n"
  for i in "${!mods[@]}"; do
    printf "%2d) %s\n" "$i" "${mods[$i]}"
  done
  read -rp 'Choice: ' picks < /dev/tty # Read from terminal, not stdin pipe
  if [[ $picks == all* ]]; then
    sel=("${!mods[@]}")
  else
    for i in $picks; do
      [[ $i =~ ^[0-9]+$ ]] && (( i < ${#mods[@]} )) && sel+=($i)
    done
  fi
fi

choose() { for i in "${sel[@]}"; do [[ $i == "$1" ]] && return 0; done; return 1; }
echo_info "Modules selected: ${sel[*]}"

# ----------------------------- Sudo Keep-Alive -----------------------------------------
if [[ -n "$SUDO" ]] && ! $DRY_RUN; then
    $SUDO -v # Ask for password upfront
    # Keep-alive: update existing `sudo` time stamp until script has finished
    while true; do $SUDO -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    SUDO_LOOP_PID=$!
fi

# ----------------------------- User Identity -------------------------------------------
# Only prompt for Git user details if module 6 is selected.
if choose 6; then
  if [[ -z $GIT_NAME && -z "${CI:-}" ]]; then read -rp "Your git user.name  : " GIT_NAME < /dev/tty; fi
  if [[ -z $GIT_EMAIL && -z "${CI:-}" ]]; then read -rp "Your git user.email : " GIT_EMAIL < /dev/tty; fi
  GIT_NAME=${GIT_NAME:-"CI Bot"}
  GIT_EMAIL=${GIT_EMAIL:-"ci@example.com"}
fi

# --------------------------  0. Core manager  -----------------------------------------
if choose 0; then
  echo_step "Installing core packages…"
  case $PKG in
    brew)
      if ! command -v brew &>/dev/null; then
        echo_info "Homebrew not found. Installing..."
        if ! $DRY_RUN; then
          NONINTERACTIVE=1 /bin/bash -c "$(curl --connect-timeout 15 --retry 3 -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
          echo_dry "Would run Homebrew install script."
        fi
      fi
      if ! $DRY_RUN; then
        eval "$(brew shellenv)"
        brew analytics off 2>/dev/null || true # Opt-out of telemetry
      fi
      ;;
    apt)
      install_pkgs "git" "curl" "build-essential" "software-properties-common"
      ;;
    dnf)
      if ! grep -q "max_parallel_downloads" /etc/dnf/dnf.conf &>/dev/null; then
        echo_info "Enabling parallel downloads for DNF..."
        if ! $DRY_RUN; then
            echo 'max_parallel_downloads=10' | $SUDO tee -a /etc/dnf/dnf.conf >/dev/null
        else
            echo_dry "Would add 'max_parallel_downloads=10' to /etc/dnf/dnf.conf"
        fi
      fi
      install_pkgs "git" "curl"
      ;;
    pacman)
      install_pkgs "git" "curl"
      ;;
  esac
fi

# --------------------------  1. Oh‑My‑Zsh & P10k --------------------------------------
if choose 1; then
  echo_step "Setting up Zsh prompt…"
  install_pkgs "zsh"
  export RUNZSH=no CHSH=no
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo_info "Installing Oh-My-Zsh..."
    if ! $DRY_RUN; then
      sh -c "$(curl --connect-timeout 15 --retry 3 -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
      echo_dry "Would run Oh-My-Zsh install script."
    fi
  fi
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  # Install a curated list of plugins for a balanced experience
  for p in romkatv/powerlevel10k zsh-syntax-highlighting zsh-autocomplete Aloxaf/fzf-tab jeffreytse/zsh-vi-mode mafredri/zsh-async zsh-autosuggestions zsh-history-substring-search; do
    repo_name=$(basename "$p")
    target_dir="$ZSH_CUSTOM/plugins/$repo_name"
    # Handle specific plugin names that differ from their repo name
    if [[ $p == "romkatv/powerlevel10k" ]]; then
        target_dir="$ZSH_CUSTOM/themes/powerlevel10k"
    elif [[ $p == "mafredri/zsh-async" ]]; then
        repo_name="async"
        target_dir="$ZSH_CUSTOM/plugins/$repo_name"
    fi

    if [[ ! -d "$target_dir" ]]; then
      echo_info "Cloning Zsh plugin: $repo_name"
      if ! $DRY_RUN; then
        git clone --depth=1 "https://github.com/$p.git" "$target_dir"
      else
        echo_dry "Would clone $p into $target_dir"
      fi
    else
      echo_info "Zsh plugin '$repo_name' already exists. Skipping."
    fi
  done
fi

# --------------------------  2. CLI toolchain  ----------------------------------------
if choose 2; then
  echo_step "Installing CLI toolkit…"
  install_pkgs "git-delta" "fzf" "ripgrep" "bat" "eza" "fd" "bottom" "dust" "zoxide" "thefuck"

  if ! $DRY_RUN; then
    if [[ $PKG == "dnf" ]] && command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        echo_info "Creating symlink for fd -> fdfind..."
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi
    if [[ $PKG == brew ]] && command -v fzf &>/dev/null; then
        echo_info "Running fzf install script..."
        "$(brew --prefix)/opt/fzf/install" --all --no-bash --no-fish --no-update-rc
    fi
  else
    echo_dry "Would run post-install steps for fzf and fd if needed."
  fi
fi

# --------------------------  3. Nerd Font  --------------------------------------------
if choose 3 && ! $IS_WSL; then
  echo_step "Installing Nerd Font (Meslo)..."
  if ! $DRY_RUN; then
    case $PKG in
      brew) brew tap homebrew/cask-fonts &>/dev/null || true; brew install --cask font-meslo-lg-nerd-font;;
      apt) $SUDO apt-get update -qq && $SUDO apt-get install -y fonts-noto fonts-noto-color-emoji;;
      dnf) $SUDO dnf install -y google-noto-emoji-color-fonts;;
      pacman) $SUDO pacman -Sy --noconfirm --needed noto-fonts-emoji;;
    esac
  else
    echo_dry "Would install Nerd Fonts using $PKG."
  fi
elif choose 3 && $IS_WSL; then
    echo_info "Skipping Nerd Font installation in WSL."
fi

# --------------------------  4. DB & Services -----------------------------------------
if choose 4; then
  echo_step "Installing MySQL, Redis, Nginx, dnsmasq…"
  case $PKG in
    brew) install_pkgs "mysql" "redis" "nginx" "dnsmasq";;
    apt) install_pkgs "mysql-server" "redis-server" "nginx" "dnsmasq";;
    dnf)
      echo_info "Attempting to install MySQL group via DNF..."
      ($SUDO dnf -y groupinstall "MySQL Database" || echo_info "Could not install 'MySQL Database' group. It may not be available. Continuing...")
      install_pkgs "redis" "nginx" "dnsmasq"
      ;;
    pacman) install_pkgs "mariadb" "redis" "nginx" "dnsmasq";;
  esac
fi

# --------------------------  5. PHP stack ---------------------------------------------
if choose 5; then
  echo_step "Installing PHP & Composer…"
  install_pkgs "php" "composer" "direnv"
  if [[ $PKG == brew ]]; then
      echo_info "Installing Laravel Valet for macOS..."
      if ! $DRY_RUN; then
        COMPOSER_BIN_DIR="$HOME/.composer/vendor/bin"
        if [[ -d "$HOME/Library/Application Support/composer/vendor/bin" ]]; then
          COMPOSER_BIN_DIR="$HOME/Library/Application Support/composer/vendor/bin"
        fi
        composer global require laravel/valet
        "$COMPOSER_BIN_DIR/valet" install --quiet
      else
        echo_dry "Would install Laravel Valet via Composer."
      fi
  fi
fi

# --------------------------  7. Node & NVM --------------------------------------------
if choose 7; then
  echo_step "Installing Node via NVM…"
  if [[ ! -d "$HOME/.nvm" ]]; then
    if ! $DRY_RUN; then
      curl --connect-timeout 15 --retry 3 -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    else
      echo_dry "Would install NVM using official script."
    fi
  else
    echo_info "NVM is already installed. Skipping installation."
  fi
  if ! $DRY_RUN; then
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
  else
    echo_dry "Would install LTS version of Node.js."
  fi
fi

# --------------------------  6. gitconfig ---------------------------------------------
if choose 6; then
  echo_step "Writing ~/.gitconfig…"
  if ! $DRY_RUN; then
    backup_file "$HOME/.gitconfig"
    cat > "$HOME/.gitconfig" <<EOF
# Generated by workstation.sh
[user]
    name  = $GIT_NAME
    email = $GIT_EMAIL
$( [[ -n $GIT_SIGN ]] && echo "    signingkey = $GIT_SIGN" )

# For multiple identities, uncomment and create the second file:
# [includeIf "gitdir:~/work/"]
#     path = ~/.gitconfig_work

[core]
    editor = nvim
    pager  = delta --paging=always
    excludesfile = ~/.gitignore_global
    autocrlf = input
[init]
    defaultBranch = main
[color]
    ui = auto
[pager]
    diff = delta
    log = delta
    show = delta
    reflog = delta
[interactive]
    diffFilter = delta --color-only --features=interactive
[delta]
    features = +decorations
    side-by-side = true
    line-numbers = true
    navigate = true
    hyperlinks = true
    hyperlinks-file-link-format = vscode://file/{path}:{line}
[delta "interactive"]
    keep-plus-minus-markers = false
[delta "decorations"]
    commit-decoration-style = blue ol
    commit-style = raw
    file-style = omit
    hunk-header-decoration-style = blue box
    hunk-header-file-style = red
    hunk-header-line-number-style = #067a00
    hunk-header-style = file line-number syntax
[pull]
    rebase = false
    ff = only
[push]
    default = current
    autoSetupRemote = true
[merge]
    conflictstyle = zdiff3
    ff = only
[rebase]
    autosquash = true
    autostash = true
[alias]
    co = checkout
    br = branch -vv
    st = status -sb
    ci = commit -v
    amend = commit --amend --no-edit
    fixup = commit --fixup
    rebase-i = rebase -i --autosquash
    lg = log --all --graph --decorate --oneline
    gd = diff
    gds = diff --staged
    pr = pull --rebase --autostash
EOF
  else
    echo_dry "Would create ~/.gitconfig (after backing up if it exists)."
  fi
fi

# --------------------------  8. Dotfiles (Zsh) ----------------------------------------
if choose 1; then
  echo_step "Configuring ~/.zshrc…"
  ZSHRC_BLOCK=$(cat <<'ZRC'
# --- workstation.sh block start ---
# Generated by workstation.sh
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Set history file and size to be effectively unlimited.
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
# Append to history, share it across all sessions, and save each command immediately.
setopt APPEND_HISTORY INC_APPEND_HISTORY SHARE_HISTORY

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# This minimal plugin list provides a stable, native-feeling shell.
# Standard up/down arrow history is enabled by default.
plugins=(git zsh-syntax-highlighting)

# To enable more advanced features, uncomment the following line.
# These plugins are already installed and ready to be enabled.
# plugins+=(zsh-autosuggestions zsh-autocomplete fzf-tab zsh-history-substring-search zsh-vi-mode async)

source "$ZSH/oh-my-zsh.sh"
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
autoload -Uz compinit && compinit

# For fzf-tab completion to work correctly with some configs, you may need:
# setopt no_menu_complete

# Add user-installed binaries to PATH
export PATH="$HOME/.local/bin:$PATH"
# Add Composer binaries to PATH on Linux
if [[ "$(uname -s)" == "Linux" ]]; then
  export PATH="$HOME/.config/composer/vendor/bin:$PATH"
fi

# Homebrew path (if exists)
[ -d /opt/homebrew/bin ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# NVM (Node Version Manager)
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Tool hooks
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
command -v thefuck &>/dev/null && eval "$(thefuck --alias)"

# Aliases
# ----
# eza (ls replacement)
alias ls='eza --icons'
alias ll='eza -alF --group-directories-first --ignore-glob=".DS_Store|.localized"'
alias lt='eza -alF --sort=modified --ignore-glob=".DS_Store|.localized"'

# bat (cat replacement) - handle batcat on older systems
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
  alias cat='batcat --paging=never'
  alias bat='batcat'
else
  alias cat='bat --paging=never'
fi

# Other modern tools
alias find='fd'
alias grep='rg'
alias top='btm'
alias du='dust'
# --- workstation.sh block end ---
ZRC
)
  if ! grep -q "# --- workstation.sh block start ---" "$HOME/.zshrc" 2>/dev/null; then
    echo_info "Appending workstation.sh configurations to ~/.zshrc..."
    if ! $DRY_RUN; then
      # backup_file is now handled by the append logic to avoid double-backup
      if [[ -f "$HOME/.zshrc" ]]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%Y-%m-%d_%H-%M-%S)"
        echo_info "Backed up existing ~/.zshrc"
      fi
      echo -e "\n$ZSHRC_BLOCK" >> "$HOME/.zshrc"
    else
      echo_dry "Would append configurations to ~/.zshrc (after backing up)."
    fi
  else
    echo_info "workstation.sh configurations already exist in ~/.zshrc. Skipping."
  fi
fi

# --------------------------  Finish ---------------------------------------------------
if choose 1; then
  echo_info "Run 'p10k configure' in a new shell to customize your prompt."
fi
color 32 "\n✔  Finished! Restart your shell or run 'exec zsh' to apply changes.\n"
if $DRY_RUN; then
  color 33 "Remember, this was a DRY RUN. No actual changes were made.\n"
fi

# Clean up the trap and sudo keep-alive
if [[ -n "$SUDO_LOOP_PID" ]]; then
    kill "$SUDO_LOOP_PID" 2>/dev/null
fi

# Self-delete if the script was run from a file
if [[ -f "$0" ]] && ! $DRY_RUN; then
    echo_info "Self-deleting script..."
    rm -- "$0"
fi

trap - INT TERM EXIT

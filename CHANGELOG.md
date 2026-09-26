# Changelog

All notable changes to this project will be documented here.

## \[Unreleased]

### Planned

- Add Python + pyenv module
- Add Docker + Docker Compose module
- Add cross-platform Rust toolchain

## \[v1.1.2] – 2026-09-26

### Fixed

- Linked the Homebrew `php` formula before installing Valet and verified the `bin/php` symlink that Valet requires.

## \[v1.1.1] – 2026-09-26

### Fixed

- Fixed macOS PHP setup when Homebrew has PHP installed but its formula is not linked into the current `PATH`.
- Resolved Composer's global binary directory directly before running Laravel Valet instead of guessing a platform-specific path.
- Added Composer's macOS global binary locations to the canonical Zsh `PATH` so `valet` remains available in new shells.

## \[v1.1.0] – 2026-09-26

### Added

- Added a one-command setup for installing every module and applying the same Git, Delta, and Zsh configuration on a new machine.
- Added `less` alongside `git-delta`. The Git module now installs both tools when the CLI module is not selected.

### Changed

- Re-running the Zsh module now backs up and replaces `~/.zshrc` with the canonical configuration so updates stay consistent across machines.
- The default Zsh plugin list now enables only `git` and `zsh-syntax-highlighting`. `zsh-autosuggestions` and `fzf-tab` are installed but left disabled.
- Expanded the Delta configuration and documentation for side-by-side diffs, line numbers, navigation, and hyperlinks.

### Fixed

- Fixed first-run setup on macOS when Homebrew installs successfully but is not yet available on the current shell's `PATH`.
- Fixed the Delta hunk line-number color, which Git previously parsed as an empty value.

## \[v1.0.0] – 2025-07-14

### Added

- Initial stable release 🎉
- Modular architecture with 8 modules
- `--all`, `--dry-run`, `--update`, `--name`, `--email`, `--signingkey` flags
- Support for macOS, Ubuntu/Debian, Fedora, Arch, and WSL
- Detects CI environments via `$CI`
- Backs up dotfiles with timestamp and SHA
- Opinionated Git config generator
- CLI toolkit: `fzf`, `ripgrep`, `delta`, `bat`, `eza`, etc.
- Laravel Valet support for macOS
- Node.js via NVM installer
- Nerd Font (Meslo) installer (skips in WSL)
- Auto-logs errors with timestamped logs

---

Older entries will be added here as new releases are made.

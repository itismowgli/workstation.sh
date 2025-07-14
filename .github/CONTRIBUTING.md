# Contributing to workstation.sh

Thanks for your interest in contributing to `workstation.sh`! Your ideas, fixes, and improvements are always welcome.

## 🧰 Ways to Contribute

- **Bug Reports** – Find something broken? Open an [issue](https://github.com/itismowgli/workstation.sh/issues).
- **Feature Requests** – Have an idea for a new module or flag? File an issue or start a discussion.
- **Pull Requests** – Want to add a module, refactor logic, or update docs? Read on!

## 🛠 Prerequisites

- Familiarity with Bash scripting
- Use of macOS or a major Linux distro for testing
- Git installed and working locally

## ✅ Pull Request Checklist

- One feature/fix per pull request
- Use feature branches: `git checkout -b fix/typo` or `feature/add-rust-module`
- Validate your changes with:

  - `./workstation.sh --dry-run` (test safely)
  - Module-specific test (e.g., run just `./workstation.sh 2`)

- If adding a new module:

  - Include it in the menu (inside the script)
  - Add description to README `Modules` section
  - Document any required packages or configuration

- Keep code readable: clear variable names, inline comments where helpful
- Avoid adding external dependencies unless justified

## 🔍 Style Guide

- Follow the format and structure of existing modules
- Prefer native Bash over unnecessary third-party tools
- Use `echo_info`, `echo_step`, `echo_dry` helpers for consistent output
- Use `install_pkgs` and `backup_file` helpers when possible

## 🧪 Testing Suggestions

If you're unable to test all platforms:

- Note what you tested in the PR description
- Ask for help testing other distros (especially Fedora, Arch, WSL)

## 📄 License

By contributing, you agree that your code will be licensed under the MIT License.

---

Thanks for helping improve `workstation.sh` 🙌

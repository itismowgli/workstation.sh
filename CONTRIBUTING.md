# Contributing to workstation.sh

Thank you for your interest in contributing to `workstation.sh`! This guide will help you get started.

## How to Contribute

### Reporting Issues

- Use the [GitHub issue tracker](https://github.com/itismowgli/workstation.sh/issues)
- Search existing issues before creating a new one
- Use the provided issue templates when available
- Include your OS, shell, and script version when reporting bugs

### Suggesting Features

- Open a feature request issue
- Describe the use case and benefits
- Consider if it fits the project's scope (developer workstation setup)

### Code Contributions

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/your-feature-name`
3. **Test your changes**: Run the script with `--dry-run` on different systems
4. **Follow the coding style**: 
   - Use 2-space indentation
   - Add comments for complex logic
   - Keep functions focused and small
   - Use descriptive variable names
5. **Update documentation**: Update README.md if needed
6. **Commit your changes**: Use clear, descriptive commit messages
7. **Push to your fork**: `git push origin feature/your-feature-name`
8. **Create a Pull Request**

### Testing

Before submitting:
- Test on macOS and Linux if possible
- Test both interactive and `--all` modes
- Test `--dry-run` mode
- Ensure idempotency (script can be run multiple times safely)

### Code Style

- Follow existing patterns in the codebase
- Use `echo_step`, `echo_info`, and `echo_dry` for consistent output
- Handle errors gracefully
- Support both dry-run and actual execution modes
- Make changes OS-agnostic when possible

### Adding New Modules

When adding a new module:
1. Add it to the `mods` array with a clear description
2. Implement the `choose X` block with proper error handling
3. Update the README.md module overview
4. Test on all supported platforms
5. Consider WSL compatibility

### Documentation

- Keep README.md up to date
- Update CHANGELOG.md for notable changes
- Use clear, concise language
- Include examples where helpful

## Development Setup

```bash
# Clone your fork
git clone https://github.com/yourusername/workstation.sh.git
cd workstation.sh

# Test your changes
./workstation.sh --dry-run --all --name "Test User" --email "test@example.com"
```

## Questions?

Feel free to open an issue for questions or join discussions in existing issues.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

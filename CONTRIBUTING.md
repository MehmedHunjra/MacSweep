# Contributing to MacSweep

Thank you for your interest in contributing. Here is how to get started.

## How to Contribute

### Reporting Bugs

1. Search [existing issues](../../issues) to avoid duplicates.
2. Open a new issue with the **Bug** label.
3. Include: macOS version, steps to reproduce, expected vs actual behavior, and any crash logs.

### Suggesting Features

1. Open an issue with the **Enhancement** label.
2. Describe the feature clearly and why it would benefit users.

### Submitting a Pull Request

1. Fork the repository and create a new branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes following the code style guidelines below.

3. Test your changes on macOS 13+ before submitting.

4. Open a pull request against `main` with a clear description of what changed and why.

## Code Style

- Swift 5.9+, SwiftUI-first
- Follow existing naming conventions (PascalCase for types, camelCase for properties/functions)
- Use the `DS` design system (colors, fonts) defined in `Models.swift` for all UI
- Use `SectionTheme.theme(for:)` for section-specific gradients and glow colors
- Keep engines (scan/clean logic) separate from views
- No force unwraps — use `guard let` or `if let`
- No third-party dependencies

## Architecture

- **Engines** live in dedicated files (`ScanEngine`, `CleanEngine`, `SecurityEngine`, etc.) and are `ObservableObject` classes
- **Views** are SwiftUI structs that receive engines via `@ObservedObject` or `@StateObject`
- **Navigation** is handled by `NavigationManager` (shared via `@EnvironmentObject`)
- **Settings** persist via `AppSettings` (`UserDefaults`-backed `@Published` properties)
- **AppSection** enum in `Models.swift` is the single source of truth for all navigation destinations

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

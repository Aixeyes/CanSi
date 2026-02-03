# AGENTS.md

This repository is a Flutter app for the CanSi frontend.
Use this guide for build/lint/test commands and local coding conventions.
If anything conflicts with repo files, follow the repo files.
너 flutter 개 잘하는 사람이야

## Quick Start
- Install Flutter SDK matching `pubspec.yaml` SDK constraint.
- Run `flutter pub get` after changing dependencies.
- Launch on a device or emulator with `flutter run`.

## Build, Lint, Test
- Install deps: `flutter pub get`
- Lint/analyze: `flutter analyze`
- Format: `dart format .`
- Run all tests: `flutter test`
- Run a single test file: `flutter test test/widget_test.dart`
- Run a single test by name (regex): `flutter test test/widget_test.dart --name "Login screen renders"`
- Run on a device: `flutter run -d <device_id>`
- Build Android APK: `flutter build apk`
- Build iOS (macOS only): `flutter build ios`
- Build web: `flutter build web`

## Repo Layout
- App source lives in `lib/`.
- Widget tests live in `test/`.
- Platform folders: `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`.

## Imports and File Structure
- Import order: `dart:` first, then `package:` imports, then relative `lib/` imports.
- Keep imports sorted and grouped with a blank line between groups.
- Prefer relative imports for local files (example: `import 'welcome_screen.dart';`).

## Formatting and Style
- Use `dart format` and keep the default 2-space indentation.
- Prefer trailing commas for multiline widget args and collections.
- Use single quotes for strings.
- Keep lines readable; `dart format` will wrap at ~80 chars.

## Naming Conventions
- Classes: `PascalCase` (e.g., `ResultViewModel`).
- Methods/vars: `lowerCamelCase` (e.g., `_handleSignup`).
- Constants: `lowerCamelCase` or `SCREAMING_SNAKE_CASE` only when required.
- Private members start with `_`.

## Types and State
- Use `final` for local variables and fields when possible.
- Use `late final` for values initialized in `initState`.
- Prefer `const` widgets and `const` constructors where possible.
- Keep `StatefulWidget` state minimal; compute derived values locally.

## Widget Composition
- Build UI with small private widgets (`_Header`, `_InputGroup`) per screen.
- Keep layout constrained for wide screens using `ConstrainedBox` and centered `Container`.
- Put reusable color sets in palette classes (e.g., `DashboardPalette`).
- Use Material 3 where applicable (`ThemeData(useMaterial3: true)`).

## Async and Lifecycle Safety
- After `await`, guard with `if (!mounted) return;` before using `context`.
- Use `FutureBuilder` for async data in widgets.
- Dispose controllers in `dispose()`.

## Error Handling and User Feedback
- Wrap API calls with `try/catch`.
- On failure, show user feedback via `ScaffoldMessenger` and snack bars.
- Close progress dialogs before showing error messages.
- Keep thrown exceptions descriptive and include status codes or snippets.

## Networking and JSON
- Use `http` with `Uri.parse`.
- Check response status codes explicitly and handle non-200s.
- Use `jsonDecode` into `Map<String, dynamic>`.
- Be defensive when reading API data; accept multiple field name variants.

## Testing
- Prefer widget tests with `flutter_test`.
- Use `pumpWidget(const App())` for top-level UI tests.
- Keep tests focused on user-visible text and widgets.

## Strings, Localization, and Copy
- Current UI strings are mostly Korean; keep new strings consistent with locale.
- Avoid mixing English/Korean in the same UI unless required.

## Cursor/Copilot Rules
- No `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md` found.

## Agent Behavior
- Do not add secrets or API keys to the repo.
- Avoid destructive git commands unless explicitly requested.
- If unsure, follow existing patterns in `lib/` and `analysis_options.yaml`.

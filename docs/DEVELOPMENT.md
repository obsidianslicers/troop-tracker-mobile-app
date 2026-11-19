# Development

## Requirements

- **Flutter 3.44.9** (Dart 3.12), the version CI uses. Using another version works, but
  `flutter pub get` may then change `pubspec.lock`; don't commit those changes.
- Android Studio (Android SDK, an emulator) and/or Xcode for iOS.
- A `.env` file: `cp .env.example .env`, then set `TRACKER_URL` (see the README).

## Everyday commands

```bash
flutter pub get                    # install dependencies
flutter run                        # run on a device or emulator

flutter test                       # unit and widget tests
flutter test --coverage && dart run tool/coverage_report.dart   # coverage report
flutter test integration_test      # e2e tests; see TESTING.md for the mock tracker

dart format .                      # format (100-character lines)
flutter analyze                    # lint and static analysis

dart run flutter_launcher_icons    # regenerate launcher icons
dart run flutter_native_splash:create   # regenerate the native splash
```

## Before opening a pull request

1. Tests for the change, and `flutter test` passes.
2. `dart format .` leaves no changes and `flutter analyze` finds no issues.
3. For a change to startup, the WebView, or notifications, the e2e tests pass on an emulator
   (CI runs them on every pull request).
4. The docs in `docs/` still describe the code.

## Coding conventions

- Lines up to 100 characters; `dart format` enforces it.
- Lints in `analysis_options.yaml` (Flutter's recommended set plus strict casts, single quotes,
  final locals, `unawaited_futures`, ...). Don't silence a lint without a comment saying why.
- Classes, enums and widgets in `UpperCamelCase`; members, variables and parameters in
  `lowerCamelCase`; files in `snake_case.dart`. (Dart's own conventions, which differ from the
  PHP repo's snake_case variables.)
- One public class per file, named after the file.
- Pass dependencies through the constructor, defaulting to the real one, so tests can fake it.
  Don't reach for a plugin's static API from deep inside a widget.
- Fire-and-forget futures are wrapped in `unawaited(...)` so it's clear they're not awaited.
- Comments only where the *why* isn't obvious; doc comments (`///`) on public classes and
  members whose purpose isn't clear from their name.
- Never edit `lib/firebase_options.dart` by hand; regenerate it with `flutterfire configure`
  and run `dart format .` afterwards.

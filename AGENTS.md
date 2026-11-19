# Troop Tracker Mobile — Agent Instructions

These rules apply to every AI coding agent (Codex, Copilot, Cursor, Claude, ...).
[CLAUDE.md](CLAUDE.md) has the full reference; read it before changing code.

## Non-negotiable

1. **Every change comes with tests in the same pull request.** Unit/widget tests in `test/`
   mirroring `lib/`; e2e tests in `integration_test/` for startup, WebView, notification and
   navigation changes. A bug fix starts with a failing test.
2. **No coverage target, but no untested changes.** Make code testable (inject dependencies)
   rather than leaving it without tests.
3. **Before calling a change done**, run and pass:
   ```bash
   flutter test
   dart format --output=none --set-exit-if-changed .
   flutter analyze
   ```
   Report anything you couldn't run (e.g. e2e tests without an emulator).

## Working here

- Read the surrounding code and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) first.
- Keep changes small and in the existing Services → Controllers → Views structure.
- Use the fakes in `test/support/` ([docs/TESTING.md](docs/TESTING.md)); tests never touch the
  network, Firebase or real platform channels.
- Don't edit `lib/firebase_options.dart` or commit `.env`.
- Keep `docs/` in step with the code.

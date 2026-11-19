# Testing

**Every change ships with tests.** A pull request that adds or changes behavior adds or updates
the tests for it. There's no coverage percentage to hit; the coverage report shows what's untested.

There are two kinds of tests:

| Kind | Where | Runs on | What it proves |
|------|-------|---------|----------------|
| Unit and widget | `test/` | The Dart VM (`flutter test`), in seconds | Each class and screen does what it should, with fake plugins |
| End to end (e2e) | `integration_test/` | An Android emulator or a device | The real app, with a real WebView, works against a tracker |

---

## Unit and widget tests

```bash
cp .env.example .env              # once; .env is an asset, so tests need one
flutter test                      # everything
flutter test test/views/settings_view_test.dart   # one file
flutter test --coverage && dart run tool/coverage_report.dart  # what's untested
```

### Layout

`test/` mirrors `lib/`: the tests for `lib/views/settings_view.dart` are in
`test/views/settings_view_test.dart`. Shared fakes and helpers live in `test/support/`.

| Component | Test type |
|-----------|-----------|
| `config/`, `models/`, `services/`, `controllers/` | Unit (`test(...)`) |
| `views/`, `widgets/`, `app.dart` | Widget (`testWidgets(...)`) |
| User journeys across screens | E2E (`integration_test/`) |

### Conventions

- The object under test is `subject` (as in the main Troop Tracker repo).
- Test names say what happens, in plain words: `'Clear all empties the inbox once confirmed'`.
- Load test settings with `loadTestEnv()` from `test/support/test_env.dart`; never depend on the
  developer's own `.env`.
- Never touch the network, Firebase, or a real platform channel. Use the fakes:

| Fake (`test/support/`) | Replaces | Install with |
|------------------------|----------|--------------|
| `FakeWebViewPlatform` | webview_flutter | `WebViewPlatform.instance = FakeWebViewPlatform()` |
| `FakeUrlLauncher` | url_launcher | `UrlLauncherPlatform.instance = FakeUrlLauncher()` |
| `FakeMessaging` | `FirebaseMessaging.instance` | `PushNotificationService.initialize(messaging: ...)` |
| `FakeNotificationApi` | `NotificationApiService` | `NotificationsController(api: ...)` |
| `MockClient` (package:http) | HTTP | `NotificationApiService(client: ...)` |

- `FakeWebViewController.finishPage(url)` plays a page load; set `authStateResult` first to
  choose the signed-in state. `fail()` plays a load error.
- Classes take their dependencies as optional constructor parameters with the real ones as
  defaults. When new code needs a plugin or the network, follow that pattern so it can be faked.
- `test/flutter_test_config.dart` silences `debugPrint` for every test.

### Coverage

`tool/coverage_report.dart` reads `coverage/lcov.info` and prints the line coverage, the
uncovered lines of each file, and any `lib/` file no test loads. It never fails the build;
use it to find untested code, not as a number to chase. Two files are left out, because unit
tests can't reach them: `lib/main.dart` (covered by the e2e tests) and `lib/firebase_options.dart` (generated).
Keep `main.dart` to the few lines that need a real device, and put everything else in `app.dart`.

---

## End-to-end tests

The e2e tests in `integration_test/app_test.dart` launch the real app (Firebase, the WebView,
HTTP) against `tool/mock_tracker.dart`, a small stand-in tracker that:

- serves pages that set `window.__authState` like the real tracker,
- serves the `/api/push-notifications` inbox API (signed-in only), and
- offers `/__test/sign-in`, `/__test/reset`, `/__test/reset-requests` and `/__test/requests`,
  so tests can sign in and check which requests the app made.

### Running them locally

You need an Android emulator (or device) and the mock tracker running on your machine.

```bash
dart run tool/mock_tracker.dart 8080       # in one terminal

# In another: point the app at the mock tracker. The Android emulator reaches
# your machine at 10.0.2.2; a physical device needs your machine's LAN IP.
echo 'TRACKER_URL=http://10.0.2.2:8080/' > .env
flutter test integration_test               # runs on the connected emulator/device
cp .env.example .env                        # put your normal .env back afterwards
```

### Writing one

- Start each test from `_openApp(tester)`; `setUp` resets the mock tracker.
- Wait with `_waitFor(tester, finder)` and `_waitForRequest(tester, 'GET /events/42')`, never
  with fixed sleeps or `pumpAndSettle` (the loading bar animates forever while a page loads).
- The WebView's own content can't be found with Flutter finders; check what the page caused
  instead (the sign-in state, requests the mock tracker saw).
- If the app starts using a new tracker endpoint, add it to `tool/mock_tracker.dart`.

---

## In CI

`.github/workflows/tests.yml` runs on every pull request to `main`:

- **Unit and widget tests**: `flutter test --coverage`, then the coverage report, posted
  on the run's summary page.
- **E2E tests (Android emulator)**: builds the app, boots an API 30 emulator, starts the mock
  tracker, and runs `flutter test integration_test`. The mock tracker's log is uploaded when it
  fails.

`.github/workflows/code-style.yml` checks `dart format` and `flutter analyze`.

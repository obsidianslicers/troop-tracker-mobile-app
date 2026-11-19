# Architecture

Troop Tracker Mobile is a Flutter app that follows a layered architecture:
**Services → Controllers → Views**. State is shared through the `provider` package.

---

## Directory Structure

```
lib/
├── main.dart                # App entry point, DI wiring, routing
├── firebase_options.dart    # Auto-generated Firebase config
├── models/                  # Plain Dart data classes (no Flutter deps)
├── services/                # Stateless infrastructure: HTTP, auth, storage, notifications
├── controllers/             # ChangeNotifier page-scoped state managers
├── views/                   # Stateful UI screens
├── widgets/                 # Shared reusable widgets
├── custom/                  # Custom widget extensions
├── tags/                    # BBCode tag renderers
└── utils/                   # Pure utility functions
```

---

## Layers

### Models (`lib/models/`)

Plain Dart data classes with no Flutter or service dependencies.
Deserialized directly from API JSON responses.

| File | Purpose |
|------|---------|
| `app_user.dart` | Currently authenticated trooper |
| `troop.dart` | A costuming event (troop) |
| `event_detail.dart` | Full detail for a single event |
| `trooper.dart` | Another trooper (for roster/friends) |
| `costume.dart` | An approved Star Wars costume |
| `chat_room.dart` | A XenForo chat thread linked to a troop |
| `roster_entry.dart` | A single row in an event roster |
| `app_organization.dart` | Club / garrison / squad hierarchy |
| `site_status.dart` | Server-side feature flags |

---

### Services (`lib/services/`)

Stateless classes with no ChangeNotifier. Responsible for I/O only.

#### `ApiClient`

Central HTTP client. All network calls go through here.

- `mobileApiUri()` — builds URIs for the Troop Tracker REST API
- `forumApiUri()` — builds URIs for the XenForo API
- `getJson(Uri, {headers})` — authenticated GET, returns decoded JSON
- `postJson(Uri, body, {headers})` — authenticated POST, returns decoded JSON
- Throws `ApiException` on non-2xx responses

#### `AuthService`

OAuth2 PKCE login flow and session management. No widget dependencies.

- `performOAuthLogin()` — full PKCE exchange via `flutter_web_auth_2`; saves session to storage
- `restoreSession()` — reads saved credentials from `StorageService`; returns user map or null

#### `StorageService`

Typed Hive wrapper. All key constants are defined here — no magic strings elsewhere.

- `saveLoginData()`, `getUserData()`, `getApiKey()` — session credentials
- `saveFcmToken()`, `getFcmToken()` — push notification token
- `clearAll()` — logout

#### `NotificationService`

Firebase Cloud Messaging + local notifications integration.

- `requestPermissions()` — asks the OS for notification permission
- `initialize()` — registers FCM token with the server; sets up foreground/background message handlers
- Uses injectable `FirebaseMessagingAdapter` and `LocalNotificationsAdapter` interfaces so the
  service is fully testable without a live Firebase project

---

### Controllers (`lib/controllers/`)

`ChangeNotifier` subclasses. Each is scoped to one page (created in `initState`, disposed in
`dispose`), except `AuthController` which lives for the app's lifetime.

#### `AuthController` — global, registered in `main.dart`

Owns the authenticated session for the entire app.

| Property / Method | Description |
|-------------------|-------------|
| `currentUser` | The currently logged-in `AppUser`, or null |
| `isLoggedIn` | true when a valid session is active |
| `isLoading` | true during async auth operations |
| `errorMessage` | Last auth error string, or null |
| `restoreSession()` | Called at startup to reload from storage |
| `login()` | Triggers OAuth flow via `AuthService` |
| `logout()` | Clears session and navigates to `/login` |
| `fetchSiteStatus()` | Checks server feature flags |
| `checkUserAccess()` | Verifies membership status |

#### `TroopController` — shared by `TroopListView` and `MyTroopsView`

Loads and filters troop lists.

- `fetchTroops([String? squad])` — loads upcoming troops, optionally filtered by squad
- `fetchMyTroops(String userId)` — loads the trooper's personal signup list
- `iconForTroop(Troop)` — returns the asset path for an organization icon

#### `EventController` — scoped to `EventView`

Owns all data for a single event detail page.

- `loadAll(int eventId, String userId)` — parallel fetch of detail, roster, and costume list
- `signUp()`, `withdraw()`, `confirmAttendance()` — mutating actions

#### `ConfirmController` — scoped to `ConfirmView`

Manages the attendance confirmation form.

- `loadCostumes()` — async loader for the costume dropdown

#### `HomeController` — scoped to `HomeView`

- `checkUnconfirmedTroops(int trooperId)` — sets `hasUnconfirmedTroops`

#### `ChatController` — scoped to `ChatListView` / `ChatScreenView`

- `loadRooms(String userId)` — fetches the list of active chat rooms
- `loadMessages()` / `sendMessage()` / `sendImageMessage()` — real-time message management

#### `AddFriendController` — scoped to `AddFriendView`

- `loadTroopers()` — fetches the member search results
- `addFriend(int troopId, String trooperId)` — submits the signup

---

### Views (`lib/views/`)

All views are `StatefulWidget`. They create their own page-scoped controller in `initState`
using `context.read<ApiClient>()` (and sometimes `context.read<AuthController>()`), then
dispose of it in `dispose()`.

| View | Route | Description |
|------|-------|-------------|
| `LoginView` | `/login` | XenForo OAuth entry point |
| `AccessGateView` | `/access-gate` | Membership verification gate |
| `HomeView` | `/home` | Tab shell: Troops, My Troops, Chat, Profile |
| `TroopListView` | (tab) | Upcoming troops with squad filter |
| `MyTroopsView` | (tab) | Troops the trooper has signed up for |
| `EventView` | (push) | Full event detail, roster, sign-up actions |
| `ConfirmView` | (push) | Attendance confirmation form |
| `AddFriendView` | (push) | Add another member to a troop |
| `AddGuestView` | (push) | Add a civilian guest to a troop |
| `ChatListView` | (tab) | List of active chat rooms |
| `ChatScreenView` | `/chat` | Real-time chat for a single troop |
| `SignUpView` | (push) | New account sign-up |
| `ClosedView` | `/closed` | Shown when the site is closed/maintenance |

---

### Provider Tree

Two providers are registered globally in `main.dart`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthController>.value(value: authController),
    Provider<ApiClient>.value(value: api),
  ],
  child: TroopTrackerApp(...),
)
```

Page-scoped controllers are created locally inside each view's `initState`:

```dart
@override
void initState() {
  super.initState();
  _controller = SomeController(context.read<ApiClient>());
  _controller.loadData();
}
```

---

### Routing

All routes are declared in `TroopTrackerApp.onGenerateRoute`:

| Route | Widget |
|-------|--------|
| `/` | `_AuthGate` (decides login vs home) |
| `/login` | `LoginView` |
| `/access-gate` | `AccessGateView` |
| `/home` | `HomeView` |
| `/closed` | `ClosedView` (accepts `String? message` argument) |
| `/chat` | `ChatScreenView` (accepts `Map<String, dynamic>` argument) |

---

### Widgets (`lib/widgets/`, `lib/custom/`, `lib/tags/`)

| File | Description |
|------|-------------|
| `tt_app_bar.dart` | Shared `AppBar` with logo and logout action |
| `widgets/info_row.dart` | Labelled key/value row used in event detail |
| `widgets/limit_row.dart` | Row showing a numeric limit with progress |
| `widgets/location_widget.dart` | Tappable address that opens Maps |
| `custom/info_row.dart` | Extended info row variant |
| `tags/` | Custom BBCode tag renderers for `flutter_bbcode` |

---

### Utils (`lib/utils/`)

| File | Description |
|------|-------------|
| `date_utils.dart` | `formatDate`, `formatTime`, `isUpcoming` — pure functions, no Flutter deps |

---

## Testing

All 43 `lib/` files have corresponding test files in `test/`. The suite runs fully in-memory
with no platform channels, real Firebase, or network calls needed.

```
test/
├── controllers/   # Unit tests for each ChangeNotifier
├── models/        # JSON deserialization and model logic
├── services/      # AuthService, ApiClient, StorageService, NotificationService
├── utils/         # Pure function tests
└── views/         # Widget tests using MultiProvider + fake implementations
```

### Key testing patterns

**Fake services** — each test file defines its own `_FakeStorage`, `_FakeApiClient`, etc.
that override only what the widget under test actually calls.

**Provider setup** — views read `ApiClient` and `AuthController` from context, so tests
provide them via `MultiProvider`:

```dart
Widget _buildSubject() => MultiProvider(
  providers: [
    Provider<ApiClient>.value(value: _FakeApiClient()),
    ChangeNotifierProvider<AuthController>.value(value: _MockAuthController()),
  ],
  child: MaterialApp(home: SomeView(...)),
);
```

**NotificationService** — uses injectable `FirebaseMessagingAdapter` and
`LocalNotificationsAdapter` interfaces, so tests pass fakes without touching Firebase or
platform channels.

**Dotenv** — tests that exercise `AuthService` call `dotenv.testLoad(fileInput: 'KEY=value')`
in `setUpAll` to prevent `NotInitializedError`.

### Running tests

```bash
# All tests
flutter test

# Single file
flutter test test/views/event_view_test.dart
```

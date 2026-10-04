# SalesRoot

A bilingual field-sales CRM for small and mid-size teams in Bangladesh. Bangla is the default language and English is the alternative. The app covers leads, tasks, contacts, quotations and invoices, collections, field visits with live tracking, team chat, HR (leave, expenses, payslips), billing, and growth tools such as lead inboxes and campaigns.

Built with Flutter for Android and iOS.

> **Current phase:** every screen runs end to end on realistic **fake data**. The backend API is connected one feature at a time, and only each feature's `data/` folder changes when it is. See [docs/STATUS.md](docs/STATUS.md) for progress and next steps.

---

## Quick start

```sh
cp secrets.example.json secrets.json   # Gemini and Maps keys, both optional
flutter pub get
tool/gen.sh                            # translations + code generation
flutter run --dart-define-from-file=secrets.json
```

- **Demo sign-in:** use any phone number with the SMS code `123456`. The number `01711000000` signs in as an existing user with data.
- **Developer menu:** in debug builds, at the bottom of **More**. Use it to switch role, plan, experience level and language; to simulate offline, errors, slow network or a full quota; and to reset the demo data.
- **Maps keys:** on Android, put `MAPS_API_KEY=…` in `android/local.properties`. On iOS, copy `ios/Flutter/Secrets.xcconfig.example` to `Secrets.xcconfig`.

---

## Architecture at a glance

The code is **feature-first**, with a **repository layer** between the UI and the data. **Riverpod** handles state and dependency injection.

```
View (screen / widget)
   │  ref.watch / ref.read
   ▼
Provider / Notifier (Riverpod)       ← screen state, loading, errors, paging
   │
   ▼
Repository (abstract interface)      ← the only thing notifiers know about
   │
   ├── FakeXRepository   → in-memory fake backend (today)
   └── ApiXRepository    → Dio + Retrofit → real server (per feature, later)
```

- **Views** only render state and send user actions to notifiers. They never call the network.
- **Notifiers** hold screen state as an `AsyncValue`: loading, data or error.
- **Repositories** are abstract interfaces. One provider per feature decides whether the fake or the real one is used, so screens never change when the API arrives.
- **Models** are plain immutable Dart classes with hand-written `fromJson` / `toJson`. They read PascalCase server JSON (`Id`, `StageId`, `CanEdit`). Even the fake data goes through `fromJson`, so JSON parsing is tested from day one.

### Folder structure

```
lib/
  main.dart              app start-up (ProviderScope, retry policy)
  app.dart               MaterialApp.router: theme, language, router
  core/                  shared app-wide code
    access/              permissions, plan limits, experience level
    config/              which features use the real API vs fake data
    fake/                in-memory fake backend and shared seed data
    format/              numbers, ৳ money (lakh/crore), dates, Bangla digits
    network/             Dio client, interceptors, error type, request wrapper
    routing/             go_router setup, route names, access guards
    session/             signed-in user, PIN lock, secure token storage
    shell/               bottom navigation bar and the "Add" sheet
    theme/               colours and text styles (light + dark)
    workspace/           current workspace (personal / team)
    …
  features/<name>/       one folder per area of the app
    data/                repository interface, fake implementation, sample data
    models/              data classes
    providers/           Riverpod providers and notifiers
    view/                screens (+ view/widget/ for screen-only widgets)
    <name>_routes.dart   the feature's routes
  widgets/               the design system: reusable Sr* widgets
  translations/          Bangla + English text (ARB files)
test/features/<name>/    tests for each feature
```

**Features:** `auth`, `home`, `leads`, `tasks`, `contacts`, `sales`, `team`, `settings`, `billing`, `support`, `field_force`, `growth`, `hr`.

---

## State management: Riverpod 3

All state uses **Riverpod 3 with code generation** (`@riverpod`). There are no hand-written `StateNotifier`, `ChangeNotifier` or `StateProvider` classes.

| Need | Pattern |
|---|---|
| Shared services (repositories, Dio, router) | `@Riverpod(keepAlive: true)`: created once, live for the whole app |
| Screen state | `AsyncNotifier`: `build()` loads, methods change the data |
| Detail screens | A provider *family* keyed by id, e.g. `leadProvider(id)` |
| Lists | Paged, 20 items per page, the next page loading on scroll; filters live in their own provider, so changing one reloads from page 1 |
| Rendering | `AsyncValue` is switched into skeleton / error / empty / data widgets; old data stays on screen while refreshing |
| Side effects | Snackbars and navigation run in `ref.listen` inside the widget, never inside a notifier |
| Workspace switch | Workspace-scoped providers watch `currentWorkspaceProvider`, so they rebuild by themselves |

Failed requests are **retried automatically** only when the failure can clear by itself: no internet, or a 502/503/504 gateway error, up to 3 times with back-off. Any other error is shown at once.

---

## Navigation: go_router

- One router provider, with every route name in `core/routing/routes.dart`. Paths are lowercase kebab-case, e.g. `/leads/:id/edit`.
- The bottom bar uses `StatefulShellRoute.indexedStack`, so each tab keeps its own history. Its tabs depend on the user's role and experience level, with a centre **＋ Add** button.
- **Guards** are `redirect`s. A route the user has no access to goes to a "no access" screen. The router refreshes when the session, workspace or permissions change, so revoking access takes effect immediately.

---

## Access control: three gates

Every module and every button checks all three:

1. **Role permissions:** Owner, Team lead, Member, or a custom role. Each module has view, add, edit, delete, approve and export rights.
2. **Plan:** the plan, add-ons (Field Force, Growth…) and quotas (users, records, storage, card scans, SMS). Hitting a quota opens an upgrade prompt instead of an error.
3. **Experience level:** Easy, Standard or Advanced. It decides which home screen, navigation and fields the user sees, and the owner can lock it.

---

## Networking

**Dio + Retrofit**, with one interceptor chain:

1. **Auth:** adds the `Bearer` token and the workspace header, and drops null query parameters.
2. **Log:** debug builds only, with tokens, passwords, OTPs and PINs redacted.
3. **Status:** unwraps the server envelope `{IsSuccess, Message, Result}`, turns any other response into an `ApiFailure`, and on a 401 shows a "session expired" dialog and sends the user back to sign-in.

Every repository call goes through one `apiRequest(...)` wrapper, so the UI only handles one error type, `ApiFailure`. It answers `isOffline`, `isValidation` (with per-field messages), `isForbidden`, `isNotFound`, `isConflict` and `isQuota`.

### Fake data now, real API later

- `core/config/data_mode.dart` lists which features are live; the rest use fakes.
- The fake backend behaves like the real one: it adds latency, pages, filters and sorts, and returns the same errors the server will (validation 400, duplicate 409, permission 403, quota, offline).
- The seed data is deterministic and Bangladeshi: Dhaka areas, `+880` numbers, ৳ amounts and bilingual names.
- Connecting a feature to the API means adding `<feature>_api.dart` (Retrofit) and `api_<feature>_repository.dart`, then switching the feature on in `data_mode.dart`. Screens and notifiers don't change.

---

## Design system

- **Sr\* widgets** live in `lib/widgets/`: `SrScaffold`, `SrPrimaryButton`, `SrTextField`, `SrSheet`, `SrListRow`, `SrChip`, the skeleton, empty and error states, `SrSnack`, `SrCharts` and more. Screens reuse them instead of building raw Material widgets.
- **Colours** come only from `SrColors`, a `ThemeExtension` with light and dark sets. **Text styles** come only from `AppText`. No hex codes or ad-hoc styles appear in screens.
- **Font:** Anek Bangla, bundled with the app, which covers both Bangla and English.
- **Gallery:** the developer menu has a widget gallery.

Full widget API: [docs/design_system.md](docs/design_system.md).

---

## Language and formatting

- All text lives in ARB files under `lib/translations/parts/`, as one Bangla and one English file per feature. `tool/gen.sh` merges them and generates the Dart code. In code, text is read with `context.l10n.someKey`.
- Numbers, money and dates all go through `context.fmt`:
  - Bangla shows **Bangla digits** and money in **lakh/crore**, e.g. `৳ ১৮.৬ লাখ`;
  - English shows Latin digits, e.g. `৳ 18.6 lakh`.

---

## Tech stack

| Area | Packages |
|---|---|
| State / DI | `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator` |
| Routing | `go_router` |
| Networking | `dio`, `retrofit`, `retrofit_generator` |
| Storage | `flutter_secure_storage` (token, PIN), `shared_preferences` (settings), `sqflite` |
| Language | `flutter_localizations`, `intl` (ARB / gen-l10n) |
| Maps and location | `google_maps_flutter`, `geolocator`, `geocoding` |
| Background tracking | `flutter_foreground_task`, `sensors_plus`, `battery_plus`, `device_info_plus` |
| Notifications | `firebase_core`, `firebase_messaging`, `flutter_local_notifications` |
| Files and media | `image_picker`, `file_picker`, `flutter_image_compress`, `cached_network_image`, `pdf`, `printing`, `share_plus` |
| Other | `speech_to_text` (voice leads), `url_launcher`, `connectivity_plus`, `permission_handler`, `flutter_svg` |

AI features (business-card scan, help guide) call Google Gemini when `GEMINI_API_KEY` is set, and fall back to fake results otherwise.

---

## Development

```sh
tool/gen.sh                         # after changing translations or @riverpod / Retrofit files
flutter analyze                     # must be clean
dart format .                       # must make no changes
flutter test --concurrency=2        # all tests must pass
flutter build apk --release --dart-define-from-file=secrets.json
```

- Notifiers are tested with a `ProviderContainer` over the fake repositories, with latency off. Each feature has its own folder under `test/features/`.
- Imports always use full `package:salesroot/...` paths.
- Keys go in `secrets.json` (git-ignored) and are read with `String.fromEnvironment`. Never commit real keys.

## Project docs

- [docs/STATUS.md](docs/STATUS.md): what's done, demo logins, and the prioritised next work.
- [docs/design_system.md](docs/design_system.md): the Sr* widgets and how to use them.

# SalesRoot — Flutter app — instructions for Claude

Bilingual (Bangla-first, English) field-sales CRM for small and mid-size Bangladeshi teams.
The screens are specified in the prototype: https://claude.ai/artifact/3qKdFkFDfr2A6RXAFd9sCc
(193 screens; read it with the Artifact tool, `action: "read"`, never WebFetch). Each screen has a slot id (`welcome`, `leads`, `quote1`…), and this file refers to screens as `#<n> <slotId>`.

**Current phase: the full app on fake data.** The backend exists but its API hasn't been handed over yet. Build every feature end to end against in-memory fake repositories (see *Data: fake now, API later*), so that wiring the real API later only changes the `data/` folder of each feature.

The architecture comes from the SaleBee app at `/Users/dml-user/Documents/salebee_new`. That is the **reference implementation**: when this file says "port X", open the SaleBee file, keep its behaviour and visual result, and replace GetX with Riverpod. Don't copy its legacy parts (listed under *Don't carry over*).

---

## Stack

| Concern | Package | Notes |
|---|---|---|
| State / DI | `flutter_riverpod`, `riverpod_annotation`; dev: `riverpod_generator` | Riverpod 3, code-gen `@riverpod` only |
| Routing | `go_router` | one router provider, guards = `redirect` |
| HTTP | `dio`, `retrofit`; dev: `retrofit_generator` | same interceptor chain as SaleBee |
| Codegen | dev: `build_runner` | `dart run build_runner build` (if it hangs at 0% CPU, `rm -rf .dart_tool/build` and rerun). Never `--build-filter` (it deletes the other `.g.dart`) |
| Secure storage | `flutter_secure_storage` | session token, PIN hash |
| Prefs | `shared_preferences` | language, experience level, last workspace. No `get_storage` |
| Local DB | `sqflite` | offline cache + outbox (see *Offline*) |
| i18n | `flutter_localizations`, `intl`, gen-l10n (ARB) | `lib/l10n/app_bn.arb` (template), `app_en.arb` |
| Firebase | `firebase_core`, `firebase_messaging`, `flutter_local_notifications` | push + local |
| Maps / location | `google_maps_flutter`, `geolocator`, `geocoding` | Field Force |
| Background tracking | `flutter_foreground_task`, `sensors_plus`, `battery_plus`, `device_info_plus` | port SaleBee `features/tracker` |
| Media / files | `image_picker`, `file_picker`, `flutter_image_compress`, `cached_network_image`, `pdf`, `printing`, `share_plus`, `path_provider` | |
| Misc | `url_launcher`, `connectivity_plus`, `package_info_plus`, `permission_handler`, `speech_to_text`, `flutter_svg`, `flutter_timezone`, `collection` | voice lead = `speech_to_text` |
| Lints | `flutter_lints` | + the analyzer errors below |

Add packages with `flutter pub add` so they resolve to current versions. Don't pin old versions from SaleBee's pubspec. Don't add a package that duplicates one above, such as `provider`, `get`, `velocity_x`, `flutter_screenutil`, `freezed` or a second chart or calendar lib, without asking.

## Project layout

Everything is **feature-first**. SaleBee's `features/tracker` is the model; there is no `modules/` folder.

```
lib/
  main.dart                 init → runApp(ProviderScope(child: App()))
  app.dart                  MaterialApp.router (theme, locale, router from providers)
  core/
    config/                 data_mode.dart (which features are live), fake_latency.dart
    fake/                   fake_store.dart (shared in-memory DB), fake_people.dart (shared seed names, companies, areas)
    network/                dio_providers.dart, interceptors.dart, api_failure.dart, api_request.dart, api_extras.dart
    session/                session.dart (model), session_provider.dart, secure_session_store.dart
    workspace/              workspace.dart, current_workspace_provider.dart
    access/                 app_module.dart, module_access.dart, access_providers.dart, experience_level.dart
    routing/                app_router.dart, routes.dart, guards.dart
    storage/                prefs_provider.dart, local_db.dart, outbox.dart
    theme/                  sr_colors.dart, app_text.dart, app_theme.dart
    format/                 money.dart (৳, lakh/crore), digits.dart (Bangla/Latin), app_date_utils.dart
    utils/                  debug_log.dart, json_fields.dart, contact_launcher.dart, file_opener.dart
  l10n/                     app_bn.arb, app_en.arb  (generated code: flutter gen-l10n)
  widgets/                  sr_*.dart — the design system
  features/<name>/
    data/                   <name>_repository.dart (abstract), fake_<name>_repository.dart, <name>_fixtures.dart
                            later: <name>_api.dart (+ .g.dart), api_<name>_repository.dart, <name>_local.dart
    models/                 plain immutable classes
    providers/              <name>_providers.dart (+ .g.dart) — notifiers and derived providers
    view/                   <name>_screen.dart …
    view/widget/            screen-local widgets
```

A new screen means a view in its feature, a route in `core/routing/routes.dart` and `app_router.dart`, a guard if the module is gated, and l10n keys in **both** ARB files.

## Riverpod rules

Riverpod replaces GetX's controllers, bindings, services, `Obx` and `Get.find`.

| SaleBee (GetX) | SalesRoot (Riverpod) |
|---|---|
| `GetxController` with `.obs` fields | `@riverpod class XNotifier extends _$XNotifier` returning an immutable state / `AsyncValue` |
| `Bindings` / `Get.lazyPut` | nothing: providers are lazy; `autoDispose` is the generator default |
| `GetxService` (permanent) | `@Riverpod(keepAlive: true)` |
| `Get.find<T>()` | `ref.watch(tProvider)` in build, `ref.read(...)` in callbacks |
| `Obx(() => …)` | `ConsumerWidget` / `Consumer` + `ref.watch` (use `select` for one field) |
| `Get.toNamed` / `Get.offAllNamed` | `context.push` / `context.go` (go_router) |
| `GetMiddleware` (`ModuleGuard`) | go_router `redirect` reading access providers |
| `Get.snackbar` / dialogs | `showSrSnack` / `showSrSheet` from widgets, triggered via `ref.listen` |

- Code-gen only (`@riverpod` / `@Riverpod(keepAlive: true)`). Don't write `StateNotifier`, `ChangeNotifier`, `StateProvider` or legacy providers by hand. Functional providers take a plain `Ref ref`.
- **Repositories are keepAlive providers**, which replaces SaleBee's inline `LeadRepository()`. The provider is the single place that chooses fake or live:
  ```dart
  @Riverpod(keepAlive: true)
  LeadRepository leadRepository(Ref ref) => FakeLeadRepository(ref.watch(fakeStoreProvider));
  ```
- **Screen state goes in `AsyncNotifier`s.** `build()` loads, and methods mutate. After every `await` in a notifier method, check `if (!ref.mounted) return;` before touching `state`.
- **Lists are paged.** A `PagedState<T>` (items, page, hasMore, isLoadingMore) lives in an `AsyncNotifier` with `loadMore()` and `refresh()`. Use 20 per page, loaded on scroll. Filters are a separate provider the list watches, so changing a filter rebuilds the list from page 1.
- **Detail screens** use a family: `@riverpod Future<Lead> lead(Ref ref, int id)`. After an edit, `ref.invalidate(leadProvider(id))` plus the list.
- **Render `AsyncValue`** with `switch` or `.when` into `SrSkeleton…` / `SrErrorState` / `SrEmptyState`. Never a bare `CircularProgressIndicator`. Keep previous data while refreshing (`skipLoadingOnRefresh`).
- **Side effects** (snackbars, navigation after save) happen in `ref.listen` inside the widget, never inside the notifier. Notifiers never take a `BuildContext` or `WidgetRef`.
- **Retry:** Riverpod 3 retries failed providers automatically. `main.dart` sets `ProviderScope(retry: …)` to retry only offline (0) and 502/503/504, up to 3 times; any other `ApiFailure` shows at once.
- **Tests:** notifiers are tested with `ProviderContainer(overrides: [...])` over the fake repository (latency off via `devSettingsProvider`). Each feature gets a test file for its notifier.

## Core building blocks (already built — use, don't re-create)

| Need | Use |
|---|---|
| Strings | `context.l10n.x` (`package:salesroot/l10n/l10n.dart`). Keys live in `lib/l10n/parts/<area>.bn.arb` + `<area>.en.arb`, one pair per feature, keys prefixed with the area (`leadsTitle`). Run `tool/gen.sh` (merge parts → gen-l10n → build_runner). Never edit `app_bn.arb`/`app_en.arb` directly. |
| Numbers, ৳, dates | `context.fmt` (`core/format/app_format.dart`): `number`, `money`, `moneyCompact` (lakh/crore), `percent`, `phone`, `date`, `dayMonth`, `weekdayDate`, `monthYear`, `time`, `dayTime`, `relative`, `digits`. |
| Bilingual server labels | `LocalizedName` (`Name` + `NameBn`) in `core/utils/json_fields.dart`, `.of(isBangla)`. |
| JSON readers | `jsonInt/jsonDouble/jsonBool/jsonDate/jsonUtc/jsonList/jsonInts/jsonStrings/jsonObject`. |
| Session | `sessionProvider` (AsyncNotifier: `signIn`, `replace`, `signOut`, `expire`), `pinLockProvider`, `sessionStoreProvider` (PIN hash). |
| Workspace | `workspacesProvider`, `currentWorkspaceProvider` (`.select(w)`), `currentRoleProvider` (`WorkspaceRole.owner/teamLead/member`). |
| Access | `moduleAccessProvider(AppModule.x)` → `ModuleAccess` (`canView/canAdd/canEdit/canDelete/canApprove/canExport`, `visible`, `lockedByPlan`, `hiddenByLevel`); `planProvider` (`Plan`: limits, usage, `has(AddOn.fieldForce)`); `experienceLevelProvider` (`ExperienceLevel.easy/standard/advanced`), `experienceLevelLockedProvider`. |
| Routes | `Routes.x` / `Routes.xFor(id)` in `core/routing/routes.dart` (every screen is pre-declared). Each feature owns `features/<f>/<f>_routes.dart`; guard with `redirect: requireAccess(AppModule.x, ModuleRight.add)`; read ids with `idParam(state)`. |
| Paging | `PageResult<T>.fromJson(json, Model.fromJson)` + `Paged<T>` (`first`, `append`, `loadingMore`, `failedMore`, `prepend`, `map`, `where`, `hasMore`, `facets`). |
| Fake server | `ref.watch(fakeBackendProvider)` → `FakeBackend`: `run(label, body, module:, right:, quota:)` (latency, dev-menu failures, 403 by role, 402 by quota), `table(name, (graph) => rows)` → `FakeTable` (`rows`, `byId`, `insert`, `update`, `delete`, `nextId`), `graph` (`SeedGraph`: members, companies, contacts, leads, products, stages, `daysAgo/daysAhead`, `random(salt)`), `meId`. Helpers: `fakePage`, `fakeRequire`, `fakeMatches`. |
| Errors | `ApiFailure` (`isOffline/isValidation/isQuota/isForbidden/isNotFound/isConflict`, `fieldErrors`, `quota`). |
| Dev menu | `Routes.dev` (debug only, bottom of More). `devSettingsProvider` drives the fake backend. |

Provider files import `package:riverpod_annotation/riverpod_annotation.dart`, plus `package:flutter_riverpod/flutter_riverpod.dart` when they use `select` or `AsyncValue` (riverpod_annotation doesn't export them). A notifier class `XNotifier` generates `xProvider`. Don't name a notifier method `update` (Riverpod reserves it).

## Data: fake now, API later

Notifiers and screens only ever see the **abstract repository**. Nothing outside a feature's `data/` folder knows whether the data is fake.

- **Repository contract:** `abstract interface class LeadRepository` with the methods the screens need, such as `Future<LeadPage> list(LeadQuery q)`, `Future<Lead> get(int id)`, `Future<Lead> create(LeadInput i)` and `Future<void> moveStage(int id, int stageId)`. Design it from the prototype screens, not from guessed endpoints.
- **Fake implementation:** `FakeLeadRepository` reads and writes `FakeStore`, a keepAlive in-memory DB seeded once per app start.
  - **Realistic behaviour:** it must page (20 per page, correct `TotalCount`), filter, search and sort. Creates get new ids, edits persist for the session, and deletes remove the record. Every call awaits `fakeLatency()` (300–700 ms).
  - **Real failures:** fakes throw the same `ApiFailure`s the API will, so error UI gets built:
    - 400 with field messages for validation;
    - 409 for duplicates (#27);
    - 403 when the role lacks the right;
    - a quota error for plan limits (#98);
    - 0 when the dev menu simulates offline.
- **Fixtures go through `fromJson`:** fixtures are **server-shaped JSON maps** (PascalCase keys) in `<name>_fixtures.dart`, and fakes return `Model.fromJson(map)`. That way the JSON parsing is exercised from day one, and the API swap is mostly key renames.
  - Where an entity exists in SaleBee (lead, prospect → company/contact, task, follow-up, visit, attendance, leave, expense, employee, permissions), port the SaleBee model **with its field names**.
  - New entities (quotation, invoice, collection, chat, plan, referral, campaign…) get best-guess PascalCase names, to be corrected when the API arrives.
- **Fixture data:** deterministic (seeded `Random`), Bangladeshi and bilingual. Use the prototype's people and companies (Karim Hossain, Rafiqul Islam, Karim Textiles, Delta Power, Meghna Group…), real Dhaka areas, `+880` numbers and ৳ amounts.
  - Volume: enough to exercise paging and charts, e.g. 230 leads, 120 contacts, 60 companies, 3 workspaces, 25 members.
  - Seed the whole graph so screens link up: a lead's company, contacts, tasks, visits, quotations, chat thread and timeline must all exist and agree with each other.
- **Fake auth:** any number is accepted, the SMS code is `123456`, and the PIN is stored hashed in secure storage. The session token is a fake string; everything else (expiry, PIN unlock, workspace switch) behaves for real.
- **Dev menu** (`kDebugMode` only, at the bottom of More). It drives every state a screen has to handle; switching any of these invalidates the providers that depend on it:
  - role (Owner / Team lead / Member);
  - experience level and level lock;
  - plan and add-ons;
  - "quota reached";
  - simulate offline;
  - inject errors;
  - latency on/off;
  - empty workspace (for `homenew`);
  - reset seed.

### Wiring a real API (one feature at a time)

1. Add `<name>_api.dart` (Retrofit, paths relative to the base) and run build_runner.
2. Add `api_<name>_repository.dart` implementing the same interface. Each method is `apiRequest(...)` → map to the model, fixing model keys to the real JSON as needed.
3. Add the feature to `liveFeatures` in `core/config/data_mode.dart`. Its repository provider then becomes:
   ```dart
   isLive(AppFeature.leads) ? ApiLeadRepository(ref.watch(leadApiProvider)) : FakeLeadRepository(ref.watch(fakeStoreProvider))
   ```
4. Run the feature against the server and fix what differs. Keep the fake: it stays the test double and the offline demo.

Views and notifiers should need **no changes** at this point. If one does, the repository interface leaked an implementation detail, so fix the interface instead.

## Networking

Build this in step 0 so it's ready, even though no feature uses it until its API arrives. Port SaleBee's `lib/api_provider/dio_client.dart`, `api_exception.dart` and `repository/v2_request.dart` into `core/network/`, keeping the behaviour and changing the plumbing:

- `@Riverpod(keepAlive: true) Dio dio(Ref ref)` builds the client, with the same 60s timeout, `validateStatus: (_) => true` and `FusedTransformer`. Every Retrofit API is a keepAlive provider: `LeadApi leadApi(Ref ref) => LeadApi(ref.watch(dioProvider));`.
- The interceptors run in the same order as SaleBee:
  1. **Auth:** strips null query params, sets `Authorization: Bearer …` from `sessionProvider`, and sets the workspace header from `currentWorkspaceProvider`. Interceptors read with `ref.read` lazily per request; they never `watch`.
  2. **Log:** debug only, through `debug_log.dart`. It redacts keys containing authorization, token, password, secret, apikey, otp or pin.
  3. **Status:** for 200/201 it unwraps the envelope `{IsSuccess, Message, Result}` to `Result` unless `@Extra({ApiExtras.keepEnvelope: true})`. For anything else it rejects with `ApiFailure(status, message)`. On a 401 that carried a token it calls `ref.read(sessionProvider.notifier).expire()`.
- `apiRequest<T>(label, () => api.x())` (port of `v2Request`) wraps **every** repository call and turns any failure into `ApiFailure`. Screens switch on `failure.isOffline / isValidation / isUnauthorised / isForbidden / isNotFound / isConflict`.
- A new endpoint is a method on the feature's `*Api` (path relative to the base) plus a repository method in `apiRequest`. For repeated multipart fields, build `FormData` in the repository and pass it as `@Body()`; `@Part() List<int>` is sent as bytes.
- Write bodies **omit null keys** (`..removeWhere((_, v) => v == null)`). SaleBee's server returned 500 on explicit nulls.
- Never compare server timestamps against the device's `now`, because the server clock drifts. Use server-provided state or relative server times.

## Models

These follow the SaleBee style; there is no freezed or json_serializable.

- Use `const` immutable classes with `final` nullable fields, a hand-written `factory X.fromJson(Map<String, dynamic>)`, `toJson()` and `copyWith` when edited.
- Server keys are **PascalCase** (`'Id'`, `'StageId'`, `'CanEdit'`); Dart fields are camelCase.
- Use the tolerant readers in `core/utils/json_fields.dart` (port SaleBee's `models/json_fields.dart`): `jsonInt`, `jsonDouble`, `jsonList`, `jsonDate`, …
- Use separate classes for reads (`Lead`), writes (`LeadInput.toJson()`), queries (`LeadQuery.toQuery()`) and pages (`LeadPage` / `RawPage`).
- A record's own edit and delete buttons follow its `CanEdit` / `CanDelete`.

## Sessions, workspaces, access

- **Sign-up and sign-in** (#1–12): mobile number → SMS code → set PIN → profile → optional industry template, or email sign-in. The app opens to a PIN unlock when a session exists. The session lives in secure storage; there is no refresh token unless the API adds one. Expiry shows the session-expired dialog and then sends the user to sign-in.
- **Workspaces** (#18 `wsswitch`): one user can have a Personal workspace plus several team workspaces, each with its own role. `currentWorkspaceProvider` (keepAlive, persisted) scopes every request. Switching invalidates all workspace-scoped providers: make them depend on `currentWorkspaceProvider`, so they rebuild by themselves.
- **Access combines three gates.** Each module and each button checks all of them:
  1. **Role permissions** come from the server (Owner / Team lead / Member plus custom roles, #66 `rolepick`). Port SaleBee's `AppModule` + `ModuleAccess` (`canView/canAdd/canEdit/canDelete/canApprove/canExport`, OR-merged across rows). Expose them as `@riverpod ModuleAccess moduleAccess(Ref ref, AppModule m)`. They are refetched on app resume and on workspace switch.
  2. **Plan entitlements:** the plan, add-ons (Field Force, Growth…) and quotas (users, records, storage, card scans, SMS credits), #96 `planusage`. Hitting a quota opens the upgrade sheet (#98 `limitprompt`); it is not an error.
  3. **Experience level:** Easy, Standard or Advanced (#86 `langlevel`). The owner can lock it. This decides which home and nav the user gets and which fields they see.
- **Guards:** a gated route gets a `redirect` to the no-access screen. The router has `refreshListenable` tied to session, workspace and access changes, so revoking a grant takes effect immediately.

## Navigation shell

- Use `StatefulShellRoute.indexedStack` with branches `home, leads, tasks, sales, team, more`. `shellTabsProvider` picks the visible four, with the centre **Add** button between the second and third:
  - Easy (#13): Home · Leads · ＋ · Tasks · More
  - Standard (#15): Home · Leads · ＋ · Sales · More
  - Team lead (#16): Home · Leads · ＋ · Team · More
- The **Add sheet** (#17 `addsheet`) shows only the actions the user can add: Lead, Contact, Company, Call log, Visit, Task, Note, Quotation, Collection, Scan card, By voice, Expense.
- Home variants: `home` (Easy), `homenew` (empty state for a new user), `homestd`, `hometl`, `ownerhome` (#155), `managerhome` (#156).
- Port SaleBee's `SbTabBar` and `SbTabStack` for the floating bottom bar (22px radius, 5-column grid).

## Design system — Root skin

Port SaleBee's `lib/widgets/sb_*.dart` to `lib/widgets/sr_*.dart` with the prefix `Sr`: SrScaffold, SrPageHeader, SrPrimaryButton/SrOutlinedButton, SrSheet + `showSrSheet`, SrTextField, SrListRow, SrChip/SrTone, SrStates (empty/error/skeleton with one shared shimmer ticker), SrSnack, SrSegmentedSwitch, SrPicker/SrLookupPicker, SrDatePicker, SrCharts, SrFileViewer, SrScroll (SbScrollPhysics), SrDeferred, SrKeyboardDismiss and SrLanguageToggle. **Always reuse these before writing a raw Material tree.**

Restyle them to the prototype's Root skin. The tokens below are verbatim from the prototype CSS:

```
canvas   #F4F6F4   surface #FFFFFF   ink #10231B   ink2 #5B6B63   ink3 #8A968F
line     #E2E8E4   accent  #0B5C3E   accent2 #158A5C   tint #E6F1EB   deep #0A3325
gold     #C9931E   goldTint #FBF3E0   danger #B42318   dangerTint #FCEBE9
warning  #B7791F   warningTint #FBF3E0   success = accent / tint   avatarBg #EEF2EF   track #E9EEEA
primary gradient: 160° accent → accent2
radius: card 14 · small 10 · button 12 · sheet 24 · chip pill
height: button 50 (sm 40, lg 56) · field 50 · list row min 60 · icon button 40
```

- Colours **only** from `SrColors`, a `ThemeExtension` with `light` and `dark`. The prototype is light-only, so derive dark values and keep the same token names. Text styles **only** from `core/theme/app_text.dart`.
- Never hard-code a hex value or an ad-hoc `TextStyle` in a screen.
- Font: **Anek Bangla** 400/500/600/700 for both scripts, bundled as an asset (not google_fonts at runtime). Port SaleBee's `AppText` presets (`pageTitle`, `sectionTitle`, `rowTitle`, `body`, `meta`, `fieldLabel`, `metric`, `button`, `input`) and its Bangla adjustments (weight step-down, no letter-spacing, taller line height).
- Bangla is the default locale. In Bangla, **digits are Bangla** and money uses **lakh/crore** (`৳ 18.6 lakh` / `৳ ১৮.৬ লাখ`). In English, digits are Latin. Every number, money amount and date shown goes through `core/format/`.

## Offline and sync

These screens are #92 `syncoffline` and #93 `conflict`.

- Read caches live in sqflite per workspace, covering the last 90 days, with media on Wi-Fi only (a setting).
- Writes made while offline go to an **outbox** table (operation, entity, payload, base version, created at). It is flushed on reconnect via `connectivity_plus`, in order, and failed items stay visible.
- When the server rejects a write because the record changed, the conflict is resolved **per field**: show both values, with who and when, and let the user keep one. The other value goes to the timeline.
- Port the queue and flush ideas from SaleBee's `features/offline` and `features/tracker/service/tracker_engine.dart`. The tracker keeps its own isolate-safe storage.

## Code style — non-negotiable

- Match the surrounding file exactly.
- **Comments: almost none.** A `///` doc comment of 1–2 lines is allowed on a public widget or helper whose name can't carry the meaning. No commented-out code, TODOs, step narration or comments that restate the code.
- No dead code, no unused imports, and no `print`; use `core/utils/debug_log.dart` (`logDebug`, `logPreview`).
- Imports always use full `package:salesroot/...` paths, never relative ones. Order them dart:, flutter, third-party, project.
- File names are lower_snake_case and match their imports exactly, because CI runs on a case-sensitive filesystem.
- Prefer structure over nesting: extract a named private widget or method instead of a 5+ level tree in one `build()`. One class per concern.
- No `!` without a guard on the line before it. Prefer `const`, `final` locals and early returns.
- Every user-visible string goes through `AppLocalizations` with a key in both ARB files. Never use a literal string in a widget.
- `analysis_options.yaml`:
  ```yaml
  include: package:flutter_lints/flutter.yaml
  analyzer:
    exclude: [build/**]
    errors:
      unnecessary_null_comparison: error
      dead_code: error
      unnecessary_non_null_assertion: error
  ```
  Generated `.g.dart` files are analysed too, so regenerate them after any change to an annotated file.

## Definition of done

1. `dart run build_runner build` has been run if any annotated file changed.
2. `flutter analyze` is clean.
3. `dart format .` makes no changes.
4. `flutter test` passes, and new notifiers and repositories have tests.
5. The screen matches its prototype slot in both languages, at phone width, light and dark.
6. Every state the screen can be in can be reached from the dev menu and renders correctly on fake data: loading, empty, error, offline, no permission and quota.

Change only what was asked. Don't reformat, reorder or "improve" untouched code.

## Secrets and config

- API keys such as `GEMINI_API_KEY` and the Maps key are passed with `--dart-define-from-file=secrets.json` and read with `String.fromEnvironment`. **No `defaultValue` holding a real key.**
- `secrets.json`, `ios/Flutter/Secrets.xcconfig`, `key.properties`, `google-services.json` and `GoogleService-Info.plist` are in `.gitignore` **from the first commit**. Commit a `secrets.example.json` instead. In SaleBee, `secrets.json` and a service-account file ended up tracked; don't repeat that.
- The Android Maps key comes from `manifestPlaceholders` fed by `local.properties`, not hard-coded in `AndroidManifest.xml`.
- Business-card scan (#39–42) calls Gemini through its own Dio with no session header. Port `api_provider/gemini_api.dart` + `repository/card_scan_rep.dart` and keep the model id from SaleBee.

## Module map and build order

Build **all** steps, in this order, on fake data. Each step should end runnable, with every step above complete and committed. Step 0 also builds `FakeStore`, the dev menu and the shared seed data that later steps extend.

| # | Feature folder | Prototype screens | Port from SaleBee |
|---|---|---|---|
| 0 | `core/*`, `widgets/`, `l10n/` | tokens, nav, sheets (#13, #17, #23) | dio_client, api_exception, v2_request, json_fields, sb_*.dart, app_text, debug_log, app_date_utils |
| 1 | `auth`, `onboarding` | #1–12 | auth flow, session store, session expiry |
| 2 | `shell`, `home`, `notifications`, `search`, `workspace` | #13–20, #155–156 | modules/shell, permitted_menu_service, module_guard |
| 3 | `leads` | #21–33 (list, board, filter, quick/voice/full form, duplicate, detail, stage, lost reason, call outcome, activity) | modules/lead, edit_lead, follow_up |
| 4 | `tasks`, `calendar`, `card_scan` | #34–42 | modules/task, edit_task, gemini card scan |
| 5 | `contacts`, `companies`, `customers` | #43–49 | modules/prospect, edit_prospect |
| 6 | `field_force` (visits, tracking, attendance) | #120–133 | modules/visit, attendance, **features/tracker** (whole) |
| 7 | `sales` (products, quotations, orders, invoices), `collection` | #50–63 | (new) |
| 8 | `team`, `chat`, `files` | #64–83 | modules/employee (members), sb_file_viewer |
| 9 | `settings`, `sync`, `reports` | #84–95 | modules/more, profile, reports, features/offline |
| 10 | `billing`, `referral` | #96–104, #183–190 | features/app_update (for the update prompt only) |
| 11 | `growth` (lead sources, inbox, distribution, campaigns, notices) | #134–150 | (new) |
| 12 | `hr` (leave, expense, approvals, payslip, ticket, employee card) | #151–154, #157–158 | modules/leave, expense |
| 13 | `support`, `academy`, `feedback`, `ai_guide` | #105–119 | (new) |

**Out of scope for this app:** #159–182 and #191–193 (marketing site, web admin console, manager desk, public customer pages, Nexzen operations console). Those are web products. Don't build them here unless asked.

Before building a screen, read its prototype slot. Build every state it shows (empty, loading, error, limit reached, no permission) as well as the happy path.

## Don't carry over from SaleBee

- GetX in every form (`get`, `get_storage`, `.tr`, `Get.*`), plus `provider`, `velocity_x`, `flutter_screenutil`, `shared_preferences` wrappers like `SharedPreff`, and `farhana_color_constant.dart` / `AppColors` legacy colours.
- Inconsistent route paths (`/ADDPROSPECT`, `/FOllWTAB`). Here routes are lowercase kebab-case, like `/leads/:id/edit`.
- Inline `ThemeData` in `main.dart`. The theme comes from `AppTheme` via providers.
- Per-repository private copies of the request wrapper (`prospect_rep.dart`'s `_call`). There is one `apiRequest`.
- Relative imports, `print` and `// ignore` in feature code. SaleBee's tracker has all three.

## Open decisions (ask before assuming)

- **Backend details:** the backend is ready, and the API will be handed over feature by feature. Until a feature's API arrives, don't invent endpoints or `*_api.dart` files for it. Keep the base URL, envelope shape and workspace header name as named constants in `core/network/api_extras.dart`, and assume the SaleBee v2 conventions (`{IsSuccess, Message, Result}`, PascalCase) until told otherwise.
- **Package id / org:** suggested `flutter create --org com.salesrootcrm --project-name salesroot --platforms android,ios .`
- **Local DB:** sqflite matches SaleBee. If offline sync grows complex, propose `drift` (reactive queries suit Riverpod) before switching.

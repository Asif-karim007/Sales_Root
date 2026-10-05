# SalesRoot: project status and next steps

Last updated: 2026-10-04. Read this together with `docs/design_system.md` (Sr* widget API).

## 1. Where things stand

- Every in-scope screen of the prototype (#1–158, #183–190, about 170 screens) is built on fake data. The code is 721 Dart files, about 123k lines, and no placeholder screens remain.
- **Verified on `main` at `acb9f33`:**
  - `flutter analyze`: 0 issues.
  - `flutter test`: 499 passing.
  - `flutter build apk --debug` succeeds, after the two Gradle fixes below.
- **Not verified yet:**
  - running on a real device or simulator (screens were checked in widget tests only);
  - an iOS build (`pod install` and `flutter build ios` have never been run).

### Uncommitted at the moment of writing
These changes are on disk but not committed, and tests haven't been re-run since:

| File | Change |
|---|---|
| `pubspec.yaml`, `pubspec.lock` | `permission_handler` pinned to `^12.0.3`, because 13 needs Android compileSdk 37. SaleBee pins it for the same reason. |
| `android/app/build.gradle.kts` | Core library desugaring enabled + `desugar_jdk_libs:2.1.5`, because `flutter_local_notifications` requires it. |

**First task:** run `flutter test --concurrency=2` (the full suite at default concurrency was killed for memory once), then commit.

**Then:** delete the leftover worktrees. Their 13 `feat/*` branches are already merged into main.
```sh
for f in ../Salesroot-worktrees/*; do git worktree remove --force "$f"; done
rmdir ../Salesroot-worktrees
git branch | grep feat/ | xargs git branch -d
```

## 2. Running it

```sh
cp secrets.example.json secrets.json     # GEMINI_API_KEY, GOOGLE_MAPS_API_KEY (both optional)
flutter pub get
tool/gen.sh                              # merge ARB parts → gen-l10n → clean build_runner
flutter run --dart-define-from-file=secrets.json
```

- **Maps on Android:** add `MAPS_API_KEY=…` to `android/local.properties`.
- **Maps on iOS:** copy `ios/Flutter/Secrets.xcconfig.example` to `Secrets.xcconfig` and fill it in.
- **build_runner:** `tool/gen.sh` deletes `.dart_tool/build` first, because incremental builds deadlocked (0% CPU) after big merges. If a manual `dart run build_runner build` hangs, do the same.

### Backend and test login
- **API:** `https://salesroot-api.salebee.net/v1/` (Swagger at `/docs`). Plain camelCase JSON, UUID string ids, `offset`/`limit` paging, errors `{code, message: {bn, en}, field}`, validation 422. Access tokens refresh through `auth/refresh` (refresh tokens rotate).
- **Test account:** `+8801711000002` (Rafi Ahmed, executive in "Dhaka Sales Ltd."). The dev server's OTP is `123456`.
- **Still fake (no endpoint):** chat, file folders, private calendar events, notices, lead distribution rules, academy, help articles, global search, and the phone-book reader (no contacts plugin).

### Developer menu (debug only, at the bottom of More)
It switches the workspace and experience level, and drives the screens that are still fake: quota reached, offline, random 500s, latency, empty data, reseeding. Plus the language, PIN lock and sign-out.

It also opens the design gallery. Use it to check every state of a screen.

## 3. Feature map

Routes are all in `lib/core/routing/routes.dart`. Each feature has its own `lib/features/<f>/<f>_routes.dart`, `data/` (abstract repository + `Fake…` + fixtures), `models/`, `providers/`, `view/`, and `test/features/<f>/`.

| Feature | Prototype | Repositories |
|---|---|---|
| auth | #1–12, #188, splash, unlock | `AuthRepository` |
| home | #13–20, #155–156 | `HomeRepository`, `NotificationRepository`, `SearchRepository` |
| leads | #21–33 | `LeadRepository` |
| tasks | #34–42 | `TaskRepository`, `TaskLookupRepository`, `CalendarRepository`, `CardScanRepository` (Gemini or fake) |
| contacts | #43–49 | `ContactsRepository`, `CustomerRepository`, `DeviceContactsSource` |
| sales | #50–63 | `ProductRepository`, `QuotationRepository`, `OrderRepository`, `CollectionRepository` |
| team | #64–83 | `TeamRepository`, `ChatRepository` (stream), `FilesRepository` |
| settings | #84–95 | `SettingsRepository`, `ConfigRepository`, `SyncRepository`, `ImportRepository`, `ReportRepository` |
| billing | #96–104, #183–190 | `BillingRepository`, `ReferralRepository` |
| support | #105–119 | `HelpRepository`, `SupportRepository`, `AcademyRepository`, `GuideRepository` (Gemini or fake) |
| field_force | #120–133 | `VisitRepository`, `AttendanceRepository`, `TrackingRepository`, plus the tracker engine in `service/` |
| growth | #134–150 | `LeadSourcesRepository`, `LeadInboxRepository`, `DistributionRepository`, `MessagesRepository`, `CampaignRepository`, `NoticeRepository` |
| hr | #151–154, #157–158 | `LeaveRepository`, `ExpenseRepository`, `ApprovalsRepository`, `PayrollRepository`, `TicketRepository` |

**Out of scope:** the web screens #159–182 and #191–193.

### Query parameters screens accept (cross-feature links)
- **Leads:**
  - `/leads?pick=call|note`
  - `leadNew?name=&phone=&email=&company=&designation=&source=`
  - `leadQuick?companyId=&contactId=`
  - `leadActivityFor(id)?type=call|meeting|visit|note|whatsapp|sms|email`
- **Tasks:** `taskNew?leadId=&title=&date=`, `calendarEventNew?date=|id=`
- **Sales:**
  - `quotationNew?leadId=` (also `?from=<id>&mode=revise`)
  - `collectionNew?customerId=&invoiceId=&orderId=`
- **Field force:** `/visits?new=1&leadId=`, `trackingMemberFor(id)?date=YYYY-MM-DD`
- **Contacts:** `contactNew?companyId=&name=&phone=&email=`, `companyNew?name=`
- **Team:** `chats?leadId=`, `teamInviteSent?id=`, `fileUpload?folderId=&fileId=&leadId=`
- **Billing:**
  - `planChoose?reason=quota&kind=cardScans|users|records|storage|smsCredits`
  - checkout and add-ons take `plan`, `seats`, `cycle`, `addOns`, `packs`
- **Support:** `/help?q=`, `/ai-guide?q=`, `/support/new?category=&from=`, `/enquiry?kind=`
- **HR:** `expenseNew?visitId=`, `payslip?memberId=`, `employeeCard?memberId=`
- **Auth:** `authPhone?mode=signin&invite=&ref=`

## 4. Next work, in priority order

### A. Finish and verify (small)
1. Run the tests, commit the four files above, and remove the worktrees (§1).
2. Run on the Android test device. Follow the user memory notes: wireless adb, only release-signed APKs install over Wi-Fi, and other sessions may be using the device. Walk every tab in Bangla and English, light and dark.
3. iOS:
   - `cd ios && pod install`;
   - add `PERMISSION_LOCATION=1` and `PERMISSION_NOTIFICATIONS=1` (plus `PERMISSION_CAMERA`, `PERMISSION_MICROPHONE`, `PERMISSION_SPEECH_RECOGNIZER`, `PERMISSION_PHOTOS`) to the Podfile `post_install` for permission_handler;
   - `flutter build ios --no-codesign`.
4. Android `speech_to_text`: the leads branch added the `android.speech.RecognitionService` query; confirm voice lead works on Android 11+.

### B. Consolidate duplicated helpers into core/widgets (medium, pure refactor)
Features couldn't import each other, so each built its own copy of the same helpers. Move one version into core/widgets, replace the copies, and keep the behaviour identical. The most-duplicated ones:
- **Paged list with load-more, refresh and footer:** `PagedScrollView` (contacts), `HrPagedList`, `GrowthPagedList`, `PagedCardList` (team), `LoadMoreListener`/`PagedFooter` (sales), the billing load-more. Goes to `widgets/sr_paged_list.dart`.
- **Language pill wired to `appLocaleProvider`:** a copy in nearly every feature (`HrLanguageToggle`, `GrowthLanguageAction`, `SupportLanguagePill`, `TeamLanguageToggle`, `FfLanguageToggle`, `LanguageAction`…). Goes to one `SrLocaleToggle`.
- **The prototype's `.line` and `.trow` rows:** `InfoLines`, `HrLine`, `GrowthInfoLine`, `FfInfoLine`, `InfoCard`; `ToggleRow`, `SwitchRow`, `FfToggleRow`, `GrowthToggleRow`, `SupportToggleRow`. Goes to `SrInfoLine` / `SrToggleRow`.
- **Failure → snackbar, with 402 → upgrade:** `failureText`, `showHrFailure`, `showSalesFailure`, `runGrowthAction`, `showFailure`. Goes to `core/` (needs l10n).
- **Launching contact apps:** `ContactLauncher`, `LeadLauncher`, `external_links.dart` (tel/sms/wa.me/mailto/maps). Goes to `core/utils/contact_launcher.dart`.
- **Bangladeshi phone handling:** `BdPhone`, `growthPhone`, `normalizePhone`. Goes to `core/format/bd_phone.dart`, plus grouped display in `AppFormat.phone`.
- **Speech-to-text:** `LeadDictation`, `DictationButton`, `FfVoiceButton`. Goes to `widgets/sr_dictation.dart`.
- **Gemini client:** tasks and support each have their own copy. Goes to one `core/ai/gemini_client.dart`.
- **Bangla text in PDFs:** billing's `PdfText` (draws Bangla lines with Flutter, embeds them as images). Adopt it in sales, HR and settings PDFs, which currently render Bangla poorly or fall back to English.
- **Other duplicates:** CSV share helpers, `Shake`, the big success tick sheet, the Google map card (`FfMap`), and the month grid.

**Fixes in the design system itself:**
- `SrKpiTile` labels should allow two lines (Bangla gets cut off at 360px).
- `SrAvatar.initialsOf` produces bad initials for Bangla names.
- `SrAsyncView` needs a keep-previous-data option.
- `showSrDatePicker` needs a time-only mode.

**Routes to add to core:** `Routes.taskEdit`, `contactEdit`, `companyEdit`. They are currently declared locally in tasks and contacts.

**Shared test helper:** a `test/helpers/container.dart` creating the `ProviderContainer` with prefs and secure storage mocks, `retry: (_, _) => null` and latency off. Every feature copied this setup.

### C. Make the fake world consistent (medium)
Each feature seeds its own tables, so data doesn't cross features yet. For example:
- a lead created in leads doesn't appear in the task, visit or search pickers;
- home's agenda tasks have their own ids;
- HR's collection approvals aren't sales collections;
- billing purchases go through a dev-settings override.

This all disappears when the real API arrives. If a coherent demo is needed before then:
- give `FakeStore` shared canonical tables (`leads`, `tasks`, `visits`, `collections`) that owning features write and others read through small core lookup providers;
- make `FakeAccessRepository.plan()` read billing's `billing_subscription` table.

### D. Real infrastructure still missing (larger)
- **Offline outbox** (`core/storage/outbox.dart`, sqflite). Settings has the model and UI (`OutboxItem`, `SyncConflict`, per-field resolution) on a fake; every feature's writes need to enqueue through it. Until then, saving offline shows the offline error, and the prototype's "saves without internet" notes are omitted.
- **Firebase / push:** add the config files and initialise in `main.dart`, register the token after sign-in, and route notification taps through `Routes`.
- **Tracker auto-start:** read `trackerProvider` at app start so tracking resumes after a reboot. iOS: port SaleBee's significant-change native plugin, which is needed for relaunch after termination.
- **Packages to decide on:** each slots in behind an existing interface.
  - `flutter_contacts` for phone-book import (#44) and the contact picker on quick lead;
  - `local_auth` (biometric unlock; the toggle is stored only);
  - `flutter_tts` (read screens aloud);
  - `mobile_scanner` (QR, currently via Gemini);
  - `android_intent_plus` (OEM battery screens);
  - an audio recorder (voice notes);
  - SMS autofill.
- **Pipelines:** settings owns the stage config but leads reads its own stages. Unify them when the API arrives.

### E. Wiring the real API (when you receive it)
One feature at a time:
1. `<name>_api.dart` (Retrofit).
2. `api_<name>_repository.dart` implementing the same interface, with `apiRequest`.
3. Add the feature to `liveFeatures` in `core/config/data_mode.dart`, and switch its repository provider.
4. Fix model keys against the real JSON.

Start with **auth + workspace + access**, because every other feature depends on them. Those are core repositories (`WorkspaceRepository`, `AccessRepository`) plus `AuthRepository`. Then confirm these and update `core/network/api_extras.dart`:
- the base URL;
- the envelope shape (`IsSuccess/Message/Result/Errors`);
- the workspace header name (currently `X-Workspace-Id`).

Lessons from SaleBee that apply:
- omit null keys on writes;
- never compare server timestamps to device time;
- list counts come from facets, not extra calls.

## 5. Prototype differences decided during the build
- **Duplicate lead sheet:** "Merge into that lead" became "Open the existing lead" plus "Keep as separate".
- **Pipelines (#89) and form fields (#90):** editable in the app for users with the edit right; the prototype says "edit on the web".
- **Billing VAT:** 5% on both #100 and #189 (the prototype shows 5% and 15%). The Personal Pro plan (৳199) was added because the prototype shows it.
- **Home variant rules** (`features/home/models/home_variant.dart`):
  - empty workspace → `homenew`;
  - owner at Standard or above → `ownerhome`;
  - team lead at Advanced → `managerhome`, other team leads → `hometl`;
  - members → Easy `home` or Standard `homestd`.
- **Experience level from sign-up:** "how you work" sets it. Solo → Easy, running a team → Standard, joining → Easy.
- **Placeholder links to replace:**
  - the privacy-policy URL and help-video links in `features/support/` (`support_links.dart`, `help_fixtures.dart`);
  - the support phone number `09611-000000`.

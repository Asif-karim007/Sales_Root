# SalesRoot

Bilingual (Bangla/English) field-sales CRM. Flutter + Riverpod 3 + go_router.

```sh
flutter pub get
tool/gen.sh            # merge ARB parts, gen-l10n, build_runner
flutter run --dart-define-from-file=secrets.json
```

Copy `secrets.example.json` to `secrets.json` first. All data is fake until each feature's API is wired; see `CLAUDE.md`. The developer menu is at the bottom of More in debug builds.

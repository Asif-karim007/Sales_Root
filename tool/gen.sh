#!/bin/sh
# Merge ARB parts, generate localizations, then run build_runner.
set -e
cd "$(dirname "$0")/.."
dart run tool/merge_arb.dart
flutter gen-l10n
dart run build_runner build

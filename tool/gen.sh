#!/bin/sh
# Merge ARB parts, generate localizations, then run build_runner from a clean
# cache (incremental builds can deadlock after large merges).
set -e
cd "$(dirname "$0")/.."
dart run tool/merge_arb.dart
flutter gen-l10n
rm -rf .dart_tool/build
dart run build_runner build

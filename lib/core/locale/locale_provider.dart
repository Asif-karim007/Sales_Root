import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/storage/prefs_provider.dart';

part 'locale_provider.g.dart';

const bangla = Locale('bn');
const english = Locale('en');

@Riverpod(keepAlive: true)
class AppLocaleNotifier extends _$AppLocaleNotifier {
  static const _key = 'language';

  @override
  Locale build() {
    final code = ref.watch(sharedPreferencesProvider).getString(_key);
    return code == english.languageCode ? english : bangla;
  }

  void set(Locale locale) {
    ref.read(sharedPreferencesProvider).setString(_key, locale.languageCode);
    state = locale;
  }

  void toggle() => set(state == bangla ? english : bangla);
}

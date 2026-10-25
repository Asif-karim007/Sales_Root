import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/theme/sr_colors.dart';

part 'theme_provider.g.dart';

@Riverpod(keepAlive: true)
class AppThemeNotifier extends _$AppThemeNotifier {
  static const _key = 'theme';

  @override
  SrThemeId build() {
    final name = ref.watch(sharedPreferencesProvider).getString(_key);
    return SrThemeId.values.asNameMap()[name] ?? SrThemeId.jamdani;
  }

  void set(SrThemeId theme) {
    ref.read(sharedPreferencesProvider).setString(_key, theme.name);
    state = theme;
  }
}

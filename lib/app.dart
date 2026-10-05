import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/routing/app_router.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/theme/app_theme.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(workspacesProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionExpiredProvider, (_, expired) {
      if (expired) _showSessionExpired();
    });
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      locale: ref.watch(appLocaleProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) =>
          SrKeyboardDismiss(child: child ?? const SizedBox.shrink()),
    );
  }

  void _showSessionExpired() {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => SrAlertDialog(
        icon: Icons.lock_clock_outlined,
        title: l10n.sessionExpiredTitle,
        message: l10n.errorSessionExpired,
        actionLabel: l10n.sessionExpiredAction,
        onAction: () {
          ref.read(sessionExpiredProvider.notifier).clear();
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }
}

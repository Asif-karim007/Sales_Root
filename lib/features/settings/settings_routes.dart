import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/guards.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/settings/view/conflict_screen.dart';
import 'package:salesroot/features/settings/view/csv_import_screen.dart';
import 'package:salesroot/features/settings/view/form_fields_screen.dart';
import 'package:salesroot/features/settings/view/language_level_screen.dart';
import 'package:salesroot/features/settings/view/more_screen.dart';
import 'package:salesroot/features/settings/view/notification_prefs_screen.dart';
import 'package:salesroot/features/settings/view/pipelines_screen.dart';
import 'package:salesroot/features/settings/view/reports_screen.dart';
import 'package:salesroot/features/settings/view/sales_report_screen.dart';
import 'package:salesroot/features/settings/view/security_screen.dart';
import 'package:salesroot/features/settings/view/settings_screen.dart';
import 'package:salesroot/features/settings/view/sync_screen.dart';

final settingsBranch = StatefulShellBranch(
  routes: [
    GoRoute(path: Routes.more, builder: (context, state) => const MoreScreen()),
  ],
);

final List<RouteBase> settingsRoutes = [
  GoRoute(
    path: Routes.settings,
    builder: (context, state) => const SettingsScreen(),
  ),
  GoRoute(
    path: Routes.settingsLanguage,
    builder: (context, state) => const LanguageLevelScreen(),
  ),
  GoRoute(
    path: Routes.settingsNotifications,
    builder: (context, state) => const NotificationPrefsScreen(),
  ),
  GoRoute(
    path: Routes.settingsSecurity,
    builder: (context, state) => const SecurityScreen(),
  ),
  GoRoute(
    path: Routes.settingsPipelines,
    redirect: requireAccess(AppModule.pipelines),
    builder: (context, state) => const PipelinesScreen(),
  ),
  GoRoute(
    path: Routes.settingsFormFields,
    redirect: requireAccess(AppModule.formFields),
    builder: (context, state) => const FormFieldsScreen(),
  ),
  GoRoute(
    path: Routes.settingsImport,
    redirect: requireAccess(AppModule.dataImport, ModuleRight.add),
    builder: (context, state) => const CsvImportScreen(),
  ),
  GoRoute(path: Routes.sync, builder: (context, state) => const SyncScreen()),
  GoRoute(
    path: Routes.syncConflict,
    builder: (context, state) => ConflictScreen(id: idParam(state)),
  ),
  GoRoute(
    path: Routes.reports,
    redirect: requireAccess(AppModule.reports),
    builder: (context, state) => const ReportsScreen(),
  ),
  GoRoute(
    path: Routes.reportSales,
    redirect: requireAccess(AppModule.reports),
    builder: (context, state) => const SalesReportScreen(),
  ),
];

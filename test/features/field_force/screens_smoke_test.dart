import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/theme/app_theme.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/field_force/data/visit_fixtures.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/providers/tracker_providers.dart';
import 'package:salesroot/features/field_force/providers/visit_providers.dart';
import 'package:salesroot/features/field_force/service/tracker_machine.dart';
import 'package:salesroot/features/field_force/view/attendance_calendar_screen.dart';
import 'package:salesroot/features/field_force/view/attendance_screen.dart';
import 'package:salesroot/features/field_force/view/team_attendance_screen.dart';
import 'package:salesroot/features/field_force/view/tracking_consent_screen.dart';
import 'package:salesroot/features/field_force/view/tracking_help_screen.dart';
import 'package:salesroot/features/field_force/view/tracking_settings_screen.dart';
import 'package:salesroot/features/field_force/view/visit_progress_screen.dart';
import 'package:salesroot/features/field_force/view/visit_report_screen.dart';
import 'package:salesroot/features/field_force/view/visits_screen.dart';
import 'package:salesroot/l10n/l10n.dart';

import 'field_force_harness.dart';

/// Tracking as a member sees it before agreeing, without the platform.
class _StillTracker extends TrackerNotifier {
  @override
  Future<TrackerStatus> build() async =>
      const TrackerStatus(state: TrackerState.available);
}

void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    ProviderContainer container,
    Widget screen,
    Locale locale,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<ProviderContainer> container(WidgetTester tester) async {
    final container = (await tester.runAsync(
      () => fieldForceContainer(
        role: WorkspaceRole.owner,
        overrides: [trackerProvider.overrideWith(_StillTracker.new)],
      ),
    ))!;
    addTearDown(container.dispose);
    return container;
  }

  for (final locale in const [Locale('en'), Locale('bn')]) {
    final screens = <String, (Widget Function(int visitId), String)>{
      'visits': ((_) => const VisitsScreen(), 'Visit list'),
      'visit in progress': (
        (id) => VisitProgressScreen(visitId: id),
        'Visit in progress',
      ),
      'consent': ((_) => const TrackingConsentScreen(), 'Share live location'),
      'tracking help': ((_) => const TrackingHelpScreen(), 'Check again'),
      'visit report': ((_) => const VisitReportScreen(), 'Planned'),
      'tracking settings': (
        (_) => const TrackingSettingsScreen(),
        'Who can see',
      ),
      'attendance': ((_) => const AttendanceScreen(), 'This week'),
      'attendance calendar': (
        (_) => const AttendanceCalendarScreen(),
        'Working days',
      ),
      'team attendance': ((_) => const TeamAttendanceScreen(), 'Present'),
    };
    for (final entry in screens.entries) {
      testWidgets('${entry.key} renders in ${locale.languageCode}', (
        tester,
      ) async {
        final c = await container(tester);
        final visitId = (await tester.runAsync(() async {
          final visit = await c
              .read(visitRepositoryProvider)
              .create(const VisitInput(leadId: 5, purpose: 'Show samples'));
          final (lat, lng) = offsetBy(
            visit.latitude ?? 0,
            visit.longitude ?? 0,
            20,
            0,
          );
          await c
              .read(visitRepositoryProvider)
              .checkIn(
                visit.id,
                VisitCheckInInput(
                  latitude: lat,
                  longitude: lng,
                  accuracy: 10,
                  distance: 20,
                ),
              );
          return visit.id;
        }))!;

        final (build, landmark) = entry.value;
        await pumpScreen(tester, c, build(visitId), locale);

        expect(tester.takeException(), isNull);
        if (locale.languageCode == 'en') {
          expect(find.text(landmark), findsWidgets);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}

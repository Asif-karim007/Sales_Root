import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/theme/app_theme.dart';
import 'package:salesroot/features/field_force/models/tracking.dart';
import 'package:salesroot/features/field_force/providers/tracker_providers.dart';
import 'package:salesroot/features/field_force/providers/tracking_providers.dart';
import 'package:salesroot/features/field_force/service/tracker_machine.dart';
import 'package:salesroot/features/field_force/view/attendance_calendar_screen.dart';
import 'package:salesroot/features/field_force/view/attendance_screen.dart';
import 'package:salesroot/features/field_force/view/check_in_screen.dart';
import 'package:salesroot/features/field_force/view/live_map_screen.dart';
import 'package:salesroot/features/field_force/view/member_day_screen.dart';
import 'package:salesroot/features/field_force/view/route_map_screen.dart';
import 'package:salesroot/features/field_force/view/team_attendance_screen.dart';
import 'package:salesroot/features/field_force/view/tracking_consent_screen.dart';
import 'package:salesroot/features/field_force/view/tracking_settings_screen.dart';
import 'package:salesroot/features/field_force/view/visit_progress_screen.dart';
import 'package:salesroot/features/field_force/view/visit_report_screen.dart';
import 'package:salesroot/features/field_force/view/visits_screen.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

import '../../helpers/api_stub.dart';
import 'field_force_harness.dart';

/// Tracking as a member sees it before agreeing, without the platform.
class _StillTracker extends TrackerNotifier {
  @override
  Future<TrackerStatus> build() async =>
      const TrackerStatus(state: TrackerState.available);
}

void main() {
  const english = Locale('en');
  const bangla = Locale('bn');

  Future<void> pump(
    WidgetTester tester,
    ProviderContainer container,
    Widget screen,
    Locale locale,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: screen,
        ),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  final screens = <String, (Widget, String?)>{
    'visits': (const VisitsScreen(), 'Visit list'),
    'route map': (const RouteMapScreen(), 'Start navigation'),
    'check-in': (const CheckInScreen(companyId: rahimId), 'Rahim Traders'),
    'visit in progress': (
      const VisitProgressScreen(visitId: visitId),
      'Visit in progress',
    ),
    'visit report': (const VisitReportScreen(), 'Productive'),
    'attendance': (const AttendanceScreen(), 'This week'),
    'attendance calendar': (const AttendanceCalendarScreen(), 'Working days'),
    'team attendance': (const TeamAttendanceScreen(), 'Rafi Ahmed'),
    'live map': (const LiveMapScreen(), 'Rafi Ahmed'),
    'member day': (const MemberDayScreen(memberId: rafiId), null),
    'tracking settings': (const TrackingSettingsScreen(), 'Selfie at check-in'),
    'consent': (const TrackingConsentScreen(), 'Share live location'),
  };

  for (final locale in [english, bangla]) {
    for (final MapEntry(key: name, value: (screen, text)) in screens.entries) {
      testWidgets('$name in ${locale.languageCode}', (tester) async {
        final container = await tester.runAsync(
          () => fieldContainer(
            fieldStub(),
            fullAccess: true,
            overrides: [
              trackerProvider.overrideWith(_StillTracker.new),
              trackingConsentProvider.overrideWith(
                (ref) async => const TrackingConsent(),
              ),
            ],
          ),
        );
        if (container == null) return;

        await pump(tester, container, screen, locale);

        expect(tester.takeException(), isNull);
        if (locale == english && text != null) {
          expect(find.textContaining(text), findsWidgets);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
      });
    }
  }

  testWidgets('an empty day invites the first visit', (tester) async {
    final stub = fieldStub()
      ..on('GET', 'attendance/today', fixture('field_today_empty'));
    final container = await tester.runAsync(
      () => fieldContainer(
        stub,
        overrides: [trackerProvider.overrideWith(_StillTracker.new)],
      ),
    );
    if (container == null) return;

    await pump(tester, container, const VisitsScreen(), english);

    expect(find.text('No visits today'), findsOneWidget);
    expect(find.text('Check in'), findsOneWidget);
  });

  testWidgets('a failed day shows the error with a retry', (tester) async {
    final stub = fieldStub();
    final container = await tester.runAsync(
      () => fieldContainer(
        stub,
        overrides: [trackerProvider.overrideWith(_StillTracker.new)],
      ),
    );
    if (container == null) return;
    stub.offline = true;

    await pump(tester, container, const AttendanceScreen(), english);

    expect(find.byType(SrErrorState), findsWidgets);
  });

  testWidgets('a member cannot open team attendance', (tester) async {
    final container = await tester.runAsync(() => fieldContainer(fieldStub()));
    if (container == null) return;

    await pump(tester, container, const TeamAttendanceScreen(), english);

    expect(find.byType(SrNoAccess), findsOneWidget);
  });

  testWidgets('without the Field Force add-on visits are upsold', (
    tester,
  ) async {
    final container = await tester.runAsync(
      () => fieldContainer(
        fieldStub(),
        overrides: [
          moduleAccessProvider.overrideWith(
            (ref, module) => const ModuleAccess(lockedByPlan: true),
          ),
        ],
      ),
    );
    if (container == null) return;

    await pump(tester, container, const VisitsScreen(), english);

    expect(find.byType(SrPlanLocked), findsOneWidget);
    expect(find.text('Visit list'), findsNothing);
  });
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/theme/app_theme.dart';
import 'package:salesroot/features/leads/models/lead_input.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';
import 'package:salesroot/features/leads/view/lead_activity_screen.dart';
import 'package:salesroot/features/leads/view/lead_detail_screen.dart';
import 'package:salesroot/features/leads/view/lead_form_screen.dart';
import 'package:salesroot/features/leads/view/lead_links_screen.dart';
import 'package:salesroot/features/leads/view/lead_quick_screen.dart';
import 'package:salesroot/features/leads/view/leads_screen.dart';
import 'package:salesroot/features/leads/view/widget/lead_card.dart';
import 'package:salesroot/features/leads/view/widget/lead_filter_sheet.dart';
import 'package:salesroot/features/leads/view/widget/lead_save_flow.dart';
import 'package:salesroot/features/leads/view/widget/lead_timeline.dart';
import 'package:salesroot/features/leads/view/widget/move_stage_sheet.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

import '../../helpers/api_stub.dart';
import 'lead_stub.dart';

Future<ProviderContainer> _container(Locale locale, ApiStub stub) async {
  final container = await leadContainer(stub, role: 'owner');
  container.read(appLocaleProvider.notifier).set(locale);
  return container;
}

Future<void> _show(
  WidgetTester tester,
  ProviderContainer container,
  Widget screen,
) async {
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          theme: AppTheme.light,
          locale: ref.watch(appLocaleProvider),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: screen,
        ),
      ),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  for (final locale in const [bangla, english]) {
    group('lead screens in ${locale.languageCode}', () {
      late ProviderContainer container;

      setUp(() async => container = await _container(locale, leadStub()));

      testWidgets('list, board and filter', (tester) async {
        await _show(tester, container, const LeadsScreen());
        expect(tester.takeException(), isNull);
        expect(find.byType(LeadCard), findsWidgets);

        await _show(tester, container, const LeadsScreen(board: true));
        expect(tester.takeException(), isNull);

        await _show(tester, container, const Scaffold(body: LeadFilterSheet()));
        expect(tester.takeException(), isNull);
      });

      testWidgets('detail, links and move stage', (tester) async {
        await _show(tester, container, const LeadDetailScreen(id: rahimId));
        expect(tester.takeException(), isNull);
        expect(find.byType(LeadTimeline), findsOneWidget);

        await _show(tester, container, const LeadLinksScreen(id: rahimId));
        expect(tester.takeException(), isNull);

        final lead = await tester.runAsync(
          () => container.read(leadProvider(rahimId).future),
        );
        if (lead == null) return;
        await _show(
          tester,
          container,
          Scaffold(body: MoveStageSheet(lead: lead)),
        );
        expect(tester.takeException(), isNull);

        await _show(
          tester,
          container,
          Scaffold(
            body: LeadDuplicateSheet(
              failure: LeadDuplicateFailure(existing: lead, message: ''),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('forms', (tester) async {
        await _show(tester, container, const LeadQuickScreen());
        expect(tester.takeException(), isNull);

        await _show(
          tester,
          container,
          const LeadFormScreen(
            prefill: LeadPrefill(
              name: 'Abdur Rahim',
              phone: '01912345678',
              company: 'Rahim Traders',
              source: 'Visiting card',
            ),
          ),
        );
        expect(tester.takeException(), isNull);

        await _show(tester, container, const LeadFormScreen(id: rahimId));
        expect(tester.takeException(), isNull);

        await _show(tester, container, const LeadActivityScreen(id: rahimId));
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('a lead that failed to load offers a retry', (tester) async {
    final stub = leadStub()..fail('GET', 'leads/{id}', 404, message: 'Gone');
    final container = await tester.runAsync(() => _container(english, stub));
    if (container == null) return;

    await _show(tester, container, const LeadDetailScreen(id: rahimId));
    expect(find.byType(SrErrorState), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('moving a stage from the detail offers undo', (tester) async {
    final stub = leadStub();
    stub.on('POST', 'leads/{id}/stage', (RequestOptions r) {
      final detail = fixtureMap('leads_detail');
      final body = r.data as Map<String, dynamic>;
      stub.on('GET', 'leads/{id}', {
        ...detail,
        'lead': {
          ...detail['lead'] as Map<String, dynamic>,
          'stageId': body['stageId'],
        },
      });
      return const <String, dynamic>{};
    });
    final container = await tester.runAsync(() => _container(english, stub));
    if (container == null) return;

    await _show(tester, container, const LeadDetailScreen(id: rahimId));
    await tester.tap(find.text('Move stage').last);
    await _settle(tester);
    await tester.tap(find.text('Visited').last);
    await _settle(tester);
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('Moved to Visited'),
      ),
      findsOneWidget,
    );
    expect(stub.lastBody('POST', 'leads/{id}/stage'), {
      'stageId': visitedStage,
    });

    await tester.tap(find.text('Undo'));
    await _settle(tester);
    expect(stub.lastBody('POST', 'leads/{id}/stage'), {'stageId': sampleStage});
    expect(tester.takeException(), isNull);
  });
}

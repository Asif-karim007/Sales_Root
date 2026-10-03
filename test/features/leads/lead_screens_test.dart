import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/theme/app_theme.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/leads/models/lead_query.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';
import 'package:salesroot/features/leads/view/lead_activity_screen.dart';
import 'package:salesroot/features/leads/view/lead_detail_screen.dart';
import 'package:salesroot/features/leads/view/lead_form_screen.dart';
import 'package:salesroot/features/leads/view/lead_links_screen.dart';
import 'package:salesroot/features/leads/view/lead_quick_screen.dart';
import 'package:salesroot/features/leads/view/leads_screen.dart';
import 'package:salesroot/features/leads/view/widget/lead_card.dart';
import 'package:salesroot/features/leads/view/widget/lead_filter_sheet.dart';
import 'package:salesroot/features/leads/view/widget/lead_timeline.dart';
import 'package:salesroot/features/leads/view/widget/move_stage_sheet.dart';
import 'package:salesroot/l10n/l10n.dart';

const _full = ModuleAccess(
  canView: true,
  canAdd: true,
  canEdit: true,
  canDelete: true,
);

Future<ProviderContainer> _container(Locale locale) async {
  SharedPreferences.setMockInitialValues({'language': locale.languageCode});
  FlutterSecureStorage.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      seedGraphProvider.overrideWithValue(
        SeedGraph.build(
          workspaceId: 200,
          kind: WorkspaceKind.team,
          memberCount: 21,
          leadCount: 230,
        ),
      ),
      for (final module in AppModule.values)
        moduleAccessProvider(module).overrideWithValue(_full),
    ],
  );
  container
      .read(devSettingsProvider.notifier)
      .update(
        (s) => s.copyWith(latency: false, role: () => WorkspaceRole.owner),
      );
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

void main() {
  for (final locale in const [bangla, english]) {
    group('lead screens in ${locale.languageCode}', () {
      late ProviderContainer container;
      late int leadId;

      setUp(() async {
        container = await _container(locale);
        final page = await container
            .read(leadRepositoryProvider)
            .list(const LeadQuery(stageIds: {3}, openOnly: false));
        leadId = page.items.first.id;
      });

      tearDown(() => container.dispose());

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
        await _show(tester, container, LeadDetailScreen(id: leadId));
        expect(tester.takeException(), isNull);
        expect(find.byType(LeadTimeline), findsOneWidget);

        await _show(tester, container, LeadLinksScreen(id: leadId));
        expect(tester.takeException(), isNull);

        final lead = await container.read(leadProvider(leadId).future);
        await _show(
          tester,
          container,
          Scaffold(body: MoveStageSheet(lead: lead)),
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
              company: 'Rahim Enterprise',
              source: 'Visiting card',
            ),
          ),
        );
        expect(tester.takeException(), isNull);

        await _show(tester, container, LeadFormScreen(id: leadId));
        expect(tester.takeException(), isNull);

        await _show(tester, container, LeadActivityScreen(id: leadId));
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('moving a stage from the detail offers undo', (tester) async {
    final container = await _container(english);
    addTearDown(container.dispose);
    final repository = container.read(leadRepositoryProvider);
    final lead = (await repository.list(
      const LeadQuery(stageIds: {1}, openOnly: false),
    )).items.first;

    await _show(tester, container, LeadDetailScreen(id: lead.id));
    await tester.tap(find.text('Move stage').last);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text('Interested').last);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('Moved to Interested'),
      ),
      findsOneWidget,
    );
    expect((await repository.get(lead.id)).stage?.id, 3);

    await tester.tap(find.text('Undo'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect((await repository.get(lead.id)).stage?.id, 1);
    expect(tester.takeException(), isNull);
  });
}

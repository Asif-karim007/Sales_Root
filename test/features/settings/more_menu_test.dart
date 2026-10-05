import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/features/settings/models/more_entry.dart';
import 'package:salesroot/features/settings/providers/more_providers.dart';

import 'settings_test_setup.dart';

const _allLayers = [
  'sales',
  'collection',
  'customer360',
  'fieldforce',
  'growth',
  'teamops',
  'support',
  'intelligence',
];
const _noAddOns = [
  'sales',
  'collection',
  'customer360',
  'teamops',
  'support',
  'intelligence',
];

Map<MoreEntry, bool> _menu(List<MoreSection> sections) => {
  for (final section in sections)
    for (final item in section.items) item.entry: item.locked,
};

void main() {
  test('a member on Easy sees field work but not sales tools', () async {
    final container = await settingsContainer(settingsStub(), level: 'easy');

    final menu = _menu(container.read(moreSectionsProvider));

    expect(container.read(experienceLevelProvider), ExperienceLevel.easy);
    expect(
      menu.keys,
      containsAll([
        MoreEntry.contacts,
        MoreEntry.visits,
        MoreEntry.attendance,
        MoreEntry.collection,
        MoreEntry.team,
        MoreEntry.leave,
        MoreEntry.payslip,
        MoreEntry.help,
        MoreEntry.settings,
        MoreEntry.sync,
      ]),
    );
    expect(menu.keys, isNot(contains(MoreEntry.quotations)));
    expect(menu.keys, isNot(contains(MoreEntry.reports)));
    expect(menu.keys, isNot(contains(MoreEntry.billing)));
    expect(menu.keys, isNot(contains(MoreEntry.liveTracking)));
    expect(menu.keys, isNot(contains(MoreEntry.campaigns)));
    expect(menu[MoreEntry.visits], isFalse);
  });

  test(
    'a module the plan lacks stays, locked, pointing at plan usage',
    () async {
      final container = await settingsContainer(
        settingsStub(),
        layers: _noAddOns,
      );

      final sections = container.read(moreSectionsProvider);
      final inbox = sections
          .expand((s) => s.items)
          .firstWhere((i) => i.entry == MoreEntry.newLeads);

      expect(inbox.locked, isTrue);
      expect(inbox.target, '/billing/plan');
    },
  );

  test('Standard level brings sales and reports to a member', () async {
    final stub = settingsStub()..on('PATCH', 'workspaces/members/me', const {});
    final container = await settingsContainer(stub, level: 'easy');

    await container
        .read(experienceLevelProvider.notifier)
        .set(ExperienceLevel.standard);
    final menu = _menu(container.read(moreSectionsProvider));

    expect(
      menu.keys,
      containsAll([
        MoreEntry.quotations,
        MoreEntry.products,
        MoreEntry.reports,
      ]),
    );
  });

  test(
    'an owner without add-ons sees every module, field force locked',
    () async {
      final container = await settingsContainer(
        settingsStub(),
        role: 'owner',
        level: 'advanced',
        layers: _noAddOns,
      );

      final menu = _menu(container.read(moreSectionsProvider));

      expect(menu[MoreEntry.billing], isFalse);
      expect(menu[MoreEntry.approvals], isFalse);
      expect(menu[MoreEntry.visits], isTrue);
      expect(menu[MoreEntry.liveTracking], isTrue);
      expect(menu[MoreEntry.campaigns], isTrue);
      expect(menu[MoreEntry.contacts], isFalse);
    },
  );

  test('both add-ons unlock field force and growth for an owner', () async {
    final container = await settingsContainer(
      settingsStub(),
      role: 'owner',
      level: 'advanced',
      layers: _allLayers,
    );

    final menu = _menu(container.read(moreSectionsProvider));

    expect(menu.values.where((locked) => locked), isEmpty);
    expect(menu.length, MoreEntry.values.length);
  });
}

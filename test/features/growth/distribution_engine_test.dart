import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/features/growth/data/distribution_engine.dart';
import 'package:salesroot/features/growth/models/distribution_rule.dart';
import 'package:salesroot/features/growth/providers/distribution_providers.dart';

import 'growth_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final members = {
    for (final member in const [
      GrowthMember(
        id: 1,
        name: 'Karim',
        nameBn: '',
        checkedIn: true,
        openLeads: 9,
      ),
      GrowthMember(
        id: 2,
        name: 'Kamal',
        nameBn: '',
        checkedIn: true,
        openLeads: 3,
      ),
      GrowthMember(
        id: 3,
        name: 'Rafiq',
        nameBn: '',
        checkedIn: false,
        openLeads: 1,
      ),
      GrowthMember(
        id: 4,
        name: 'Rumpa',
        nameBn: '',
        checkedIn: true,
        onLeave: true,
      ),
      GrowthMember(
        id: 5,
        name: 'Bushra',
        nameBn: '',
        checkedIn: true,
        openLeads: 5,
        assignedToday: 8,
      ),
    ])
      member.id: member,
  };
  final weekdayNoon = DateTime(2026, 10, 5, 12);

  RuleDecision decide(
    List<DistributionRule> rules,
    RuleSubject subject, {
    DateTime? at,
    bool enabled = true,
  }) => DistributionEngine.decide(
    enabled: enabled,
    rules: rules,
    subject: subject,
    members: members,
    at: at ?? weekdayNoon,
  );

  const dealer = DistributionRule(
    id: 1,
    position: 1,
    name: 'Dealers',
    mode: AssignMode.member,
    forms: ['Dealer application'],
    memberIds: [3],
    skipOnLeave: false,
  );
  const north = DistributionRule(
    id: 2,
    position: 2,
    name: 'North',
    mode: AssignMode.roundRobin,
    areas: ['Uttara', 'Mirpur'],
    memberIds: [3, 4, 2, 1],
    onlyCheckedIn: true,
    cursor: 0,
  );
  const website = DistributionRule(
    id: 3,
    position: 3,
    name: 'Website',
    mode: AssignMode.byLoad,
    sources: ['Website'],
    memberIds: [1, 2, 5],
  );
  const queue = DistributionRule(
    id: 4,
    position: 4,
    name: 'Rest',
    mode: AssignMode.queue,
  );
  const rules = [queue, website, north, dealer];

  test('an area rule round-robins over checked-in members not on leave', () {
    const uttara = RuleSubject(source: 'Facebook', area: 'Uttara');
    final first = decide(rules, uttara);
    expect(first.rule?.id, north.id);
    expect(first.memberId, 2);
    expect(first.cursor, 3);

    final moved = DistributionRule.fromJson({
      'Id': 2,
      'Position': 2,
      'Name': 'North',
      'Mode': 'RoundRobin',
      'Areas': ['Uttara', 'Mirpur'],
      'MemberIds': [3, 4, 2, 1],
      'OnlyCheckedIn': true,
      'Cursor': first.cursor,
    });
    final second = decide([queue, website, moved, dealer], uttara);
    expect(second.memberId, 1);
    expect(second.cursor, 0);
  });

  test('a form rule wins first, even for a matching area', () {
    final decision = decide(
      rules,
      const RuleSubject(
        source: 'Facebook',
        area: 'Mirpur',
        form: 'Dealer application',
      ),
    );
    expect(decision.rule?.id, dealer.id);
    expect(decision.memberId, 3);
  });

  test('a source rule by load picks the least busy member under the cap', () {
    final decision = decide(
      rules,
      const RuleSubject(source: 'Website', area: 'Gulshan'),
    );
    expect(decision.rule?.id, website.id);
    expect(decision.memberId, 2);

    final capped = DistributionRule.fromJson({
      'Id': 3,
      'Position': 3,
      'Name': 'Website',
      'Mode': 'ByLoad',
      'Sources': ['Website'],
      'MemberIds': [5],
      'DailyCap': 8,
      'FallbackMemberId': 1,
    });
    final fallback = decide([capped], const RuleSubject(source: 'Website'));
    expect(fallback.memberId, 1);
  });

  test('anything unmatched goes to the shared queue', () {
    final decision = decide(
      rules,
      const RuleSubject(source: 'WhatsApp', area: 'Banani'),
    );
    expect(decision.rule?.id, queue.id);
    expect(decision.toQueue, isTrue);

    final off = decide(
      rules,
      const RuleSubject(source: 'Website'),
      enabled: false,
    );
    expect(off.rule, isNull);
    expect(off.toQueue, isTrue);
  });

  test('a scheduled rule only runs inside its days and hours', () {
    final office = DistributionRule.fromJson({
      'Id': 9,
      'Name': 'Office',
      'Mode': 'Member',
      'MemberIds': [1],
      'Days': [6, 7, 1, 2, 3, 4],
      'FromHour': 9,
      'ToHour': 18,
    });
    const subject = RuleSubject(source: 'Website');
    expect(decide([office], subject).memberId, 1);
    expect(
      decide([office], subject, at: DateTime(2026, 10, 5, 20)).rule,
      isNull,
    );
    expect(
      decide([office], subject, at: DateTime(2026, 10, 9, 12)).rule,
      isNull,
    );
  });

  test('the rules test replays recent leads through every rule', () async {
    final container = await growthContainer();
    final result = await container.read(ruleTestProvider.future);
    final matched = result.byRule.fold<int>(0, (sum, row) => sum + row.count);
    expect(result.total, 50);
    expect(matched + result.queued, result.total);
  });
}

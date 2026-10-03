import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/data/fake_grants.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/growth/data/distribution_engine.dart';
import 'package:salesroot/features/growth/data/distribution_fixtures.dart';
import 'package:salesroot/features/growth/data/distribution_repository.dart';
import 'package:salesroot/features/growth/data/inbox_fixtures.dart';
import 'package:salesroot/features/growth/models/distribution_rule.dart';

/// The fake server's distribution desk, shared by the rules and the inbox.
class FakeDistributionDesk {
  FakeDistributionDesk(this._backend);

  final FakeBackend _backend;

  FakeTable get rules =>
      _backend.table(growthRulesTable, distributionRuleFixtures);

  FakeTable get members =>
      _backend.table(growthMembersTable, growthMemberFixtures);

  FakeTable get settings =>
      _backend.table(growthDistributionTable, distributionSettingsFixtures);

  bool get enabled =>
      settings.rows.isEmpty || settings.rows.first['Enabled'] != false;

  Map<int, GrowthMember> memberMap() => {
    for (final member in members.rows.map(GrowthMember.fromJson))
      member.id: member,
  };

  List<DistributionRule> ruleList() =>
      [for (final row in rules.rows) DistributionRule.fromJson(row)]
        ..sort((a, b) => a.position.compareTo(b.position));

  /// Runs the rules for [subject]; with [persist] the round-robin position
  /// and the member's load move on.
  RuleDecision decide(RuleSubject subject, {bool persist = false}) {
    final decision = DistributionEngine.decide(
      enabled: enabled,
      rules: ruleList(),
      subject: subject,
      members: memberMap(),
      at: DateTime.now(),
    );
    if (!persist) return decision;
    final rule = decision.rule;
    final cursor = decision.cursor;
    if (rule != null && cursor != null) {
      rules.update(rule.id, {'Cursor': cursor});
    }
    final memberId = decision.memberId;
    if (memberId != null) loadUp(memberId);
    return decision;
  }

  void loadUp(int memberId) {
    final row = members.byIdOrNull(memberId);
    if (row == null) return;
    members.update(memberId, {
      'OpenLeads': (jsonInt(row['OpenLeads']) ?? 0) + 1,
      'AssignedToday': (jsonInt(row['AssignedToday']) ?? 0) + 1,
    });
  }

  /// `<prefix>Id`, `<prefix>Name` and `<prefix>NameBn` for a member.
  Map<String, dynamic> memberFields(int? id, String prefix) {
    final row = id == null ? null : members.byIdOrNull(id);
    if (row == null) return const {};
    return {
      '${prefix}Id': row['Id'],
      '${prefix}Name': row['Name'],
      '${prefix}NameBn': row['NameBn'],
    };
  }
}

class FakeDistributionRepository implements DistributionRepository {
  FakeDistributionRepository(this._backend)
    : _desk = FakeDistributionDesk(_backend);

  final FakeBackend _backend;
  final FakeDistributionDesk _desk;

  ModuleAccess get _grant => ModuleAccess.fromPermission(
    fakeGrant(_backend.role, AppModule.distribution),
  );

  @override
  Future<DistributionSettings> settings() => _backend.run(
    'Distribution settings',
    () => DistributionSettings.fromJson({
      'Enabled': _desk.enabled,
      'Rules': [for (final rule in _sortedRows()) _shape(rule)],
    }),
    module: AppModule.distribution,
  );

  @override
  Future<void> setEnabled(bool enabled) => _backend.run(
    'Distribution on/off',
    () {
      if (_desk.settings.rows.isEmpty) {
        _desk.settings.insert({'Id': 1, 'Enabled': enabled});
      } else {
        _desk.settings.update(1, {'Enabled': enabled});
      }
    },
    module: AppModule.distribution,
    right: ModuleRight.edit,
  );

  @override
  Future<DistributionRule> rule(int id) => _backend.run(
    'Distribution rule',
    () => DistributionRule.fromJson(_shape(_desk.rules.byId(id))),
    module: AppModule.distribution,
  );

  @override
  Future<DistributionRule> create(RuleInput input) => _backend.run(
    'Distribution rule create',
    () {
      final body = input.toJson();
      _validate(body, null);
      final ordered = _sortedRows();
      final last = ordered.isEmpty ? null : ordered.last;
      final catchAllLast =
          last != null && DistributionRule.fromJson(last).isCatchAll;
      final position = catchAllLast
          ? jsonInt(last['Position']) ?? ordered.length
          : ordered.length + 1;
      if (catchAllLast) {
        _desk.rules.update(jsonInt(last['Id']) ?? 0, {
          'Position': position + 1,
        });
      }
      final row = _desk.rules.insert({
        ...body,
        'Position': position,
        'Cursor': 0,
      }, first: false);
      return DistributionRule.fromJson(_shape(row));
    },
    module: AppModule.distribution,
    right: ModuleRight.add,
  );

  @override
  Future<DistributionRule> save(int id, RuleInput input) => _backend.run(
    'Distribution rule save',
    () {
      final body = input.toJson();
      _validate(body, id);
      final current = _desk.rules.byId(id);
      final row = _desk.rules.update(id, {
        for (final key in const [
          'FallbackMemberId',
          'EscalateMinutes',
          'FromHour',
          'ToHour',
          'DailyCap',
        ])
          key: null,
        ...body,
        if (!_sameMembers(current, body)) 'Cursor': 0,
      });
      return DistributionRule.fromJson(_shape(row));
    },
    module: AppModule.distribution,
    right: ModuleRight.edit,
  );

  @override
  Future<void> setRuleEnabled(int id, bool enabled) => _backend.run(
    'Distribution rule on/off',
    () => _desk.rules.update(id, {'Enabled': enabled}),
    module: AppModule.distribution,
    right: ModuleRight.edit,
  );

  @override
  Future<void> delete(int id) => _backend.run(
    'Distribution rule delete',
    () {
      _desk.rules.delete(id);
      final ordered = _sortedRows();
      for (var i = 0; i < ordered.length; i++) {
        _desk.rules.update(jsonInt(ordered[i]['Id']) ?? 0, {'Position': i + 1});
      }
    },
    module: AppModule.distribution,
    right: ModuleRight.delete,
  );

  @override
  Future<RuleTestResult> test({int last = 50}) =>
      _backend.run('Distribution test', () {
        final subjects = _recentSubjects(last);
        final rules = [
          for (final row in _sortedRows()) Map<String, dynamic>.of(row),
        ];
        final members = _desk.memberMap();
        final counts = <int, int>{};
        var queued = 0;
        for (final subject in subjects) {
          final decision = DistributionEngine.decide(
            enabled: _desk.enabled,
            rules: [for (final row in rules) DistributionRule.fromJson(row)],
            subject: subject,
            members: members,
            at: DateTime.now(),
          );
          final rule = decision.rule;
          final memberId = decision.memberId;
          if (rule == null || memberId == null) {
            queued++;
          } else {
            counts[rule.id] = (counts[rule.id] ?? 0) + 1;
          }
          final cursor = decision.cursor;
          if (rule != null && cursor != null) {
            rules.firstWhere((r) => r['Id'] == rule.id)['Cursor'] = cursor;
          }
          final member = memberId == null ? null : members[memberId];
          if (member != null) members[member.id] = member.withAssigned();
        }
        return RuleTestResult.fromJson({
          'Total': subjects.length,
          'Queued': queued,
          'ByRule': [
            for (final row in rules)
              {
                'RuleId': row['Id'],
                'Position': row['Position'],
                'Count': counts[row['Id']] ?? 0,
              },
          ],
        });
      }, module: AppModule.distribution);

  @override
  Future<List<String>> forms() => _backend.run('Distribution forms', () {
    final names = <String>{};
    for (final row in _backend.table(growthInboxTable, inboxFixtures).rows) {
      final form = row['FormName'];
      final campaign = row['Campaign'];
      if (form is String) names.add(form);
      if (campaign is String) names.add(campaign);
    }
    return names.toList()..sort();
  }, module: AppModule.distribution);

  @override
  Future<List<LocalizedName>> areas() => _backend.run(
    'Distribution areas',
    () => [
      for (final area in SeedGraph.areas)
        LocalizedName.fromJson({'Name': area.name, 'NameBn': area.nameBn}),
    ],
    module: AppModule.distribution,
  );

  List<Map<String, dynamic>> _sortedRows() => [..._desk.rules.rows]
    ..sort(
      (a, b) =>
          (jsonInt(a['Position']) ?? 0).compareTo(jsonInt(b['Position']) ?? 0),
    );

  Map<String, dynamic> _shape(Map<String, dynamic> row) => {
    ...row,
    'CanEdit': _grant.canEdit,
    'CanDelete': _grant.canDelete,
  };

  void _validate(Map<String, dynamic> body, int? id) {
    fakeRequire(body, ['Name']);
    final mode = AssignMode.fromWire(body['Mode'] as String?);
    if (mode != AssignMode.queue && jsonInts(body['MemberIds']).isEmpty) {
      throw const ApiFailure(
        400,
        'Pick at least one member',
        fieldErrors: {'MemberIds': 'Pick at least one member'},
      );
    }
    final name = '${body['Name']}'.trim().toLowerCase();
    final taken = _desk.rules.rows.any(
      (row) => row['Id'] != id && '${row['Name']}'.trim().toLowerCase() == name,
    );
    if (taken) {
      throw const ApiFailure(409, 'A rule with this name already exists');
    }
  }

  bool _sameMembers(Map<String, dynamic> row, Map<String, dynamic> body) {
    final before = jsonInts(row['MemberIds']);
    final after = jsonInts(body['MemberIds']);
    if (before.length != after.length) return false;
    for (var i = 0; i < before.length; i++) {
      if (before[i] != after[i]) return false;
    }
    return true;
  }

  List<RuleSubject> _recentSubjects(int last) {
    final inbox = [..._backend.table(growthInboxTable, inboxFixtures).rows]
      ..sort((a, b) => '${b['ReceivedAt']}'.compareTo('${a['ReceivedAt']}'));
    final graph = _backend.graph;
    final leads = [...graph.leads]
      ..sort((a, b) => a.createdDaysAgo.compareTo(b.createdDaysAgo));
    return [
      for (final row in inbox)
        RuleSubject(
          source: '${row['Source']}',
          area: row['Area'] as String?,
          form: row['FormName'] as String?,
          campaign: row['Campaign'] as String?,
        ),
      for (final lead in leads)
        RuleSubject(
          source: lead.source,
          area: graph.company(lead.companyId).area.name,
        ),
    ].take(last).toList();
  }
}

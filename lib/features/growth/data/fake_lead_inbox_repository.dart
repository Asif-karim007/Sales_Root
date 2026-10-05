import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/role_grants.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/growth/data/distribution_engine.dart';
import 'package:salesroot/features/growth/data/fake_distribution_repository.dart';
import 'package:salesroot/features/growth/data/inbox_fixtures.dart';
import 'package:salesroot/features/growth/data/lead_inbox_repository.dart';
import 'package:salesroot/features/growth/models/distribution_rule.dart';
import 'package:salesroot/features/growth/models/inbox_lead.dart';

class FakeLeadInboxRepository implements LeadInboxRepository {
  FakeLeadInboxRepository(this._backend)
    : _desk = FakeDistributionDesk(_backend);

  static const slaMinutes = 15;

  final FakeBackend _backend;
  final FakeDistributionDesk _desk;

  FakeTable get _table => _backend.table(growthInboxTable, inboxFixtures);

  SeedGraph get _graph => _backend.graph;

  bool get _canEdit => ModuleAccess.fromPermission(
    roleGrant(_backend.role, AppModule.inbox),
  ).canEdit;

  @override
  Future<PageResult<InboxLead>> list(InboxFilter filter, {int page = 1}) =>
      _backend.run('Inbox list', () {
        final now = DateTime.now();
        final open = [
          for (final row in _table.rows)
            if (_isOpen(row)) _shape(row, now),
        ];
        final rows = open.where((row) => _matches(filter, row)).toList()
          ..sort(compareBySla);
        return PageResult.fromJson(
          fakePage(
            rows,
            page: page,
            extra: {
              'Counts': {
                for (final f in InboxFilter.values)
                  f.wire: open.where((row) => _matches(f, row)).length,
              },
              'Stats': {
                'AvgFirstResponseMinutes': _averageResponse(),
                'SlaMinutes': slaMinutes,
              },
            },
          ),
          InboxLead.fromJson,
        );
      }, module: AppModule.inbox);

  @override
  Future<InboxLead> get(int id) => _backend.run(
    'Inbox lead',
    () => InboxLead.fromJson(_shape(_table.byId(id), DateTime.now())),
    module: AppModule.inbox,
  );

  @override
  Future<AssigneeSuggestion> suggestAssignee(int id) =>
      _backend.run('Inbox suggest assignee', () {
        final decision = _desk.decide(_subject(_table.byId(id)));
        return AssigneeSuggestion.fromJson(_decisionJson(decision));
      }, module: AppModule.inbox);

  @override
  Future<InboxLead> accept(int id, AcceptInput input) => _backend.run(
    'Inbox accept',
    () {
      final row = _openRow(id);
      final now = DateTime.now();
      final memberId = input.assignToId;
      final patch = <String, dynamic>{
        'Status': InboxStatus.accepted.wire,
        'StageId': input.stageId,
        'ContactId': input.contactId,
        'FollowUp': input.followUp,
        'RespondedMinutes':
            row['RespondedMinutes'] ?? _waiting(row, now).inMinutes,
      };
      if (memberId != null) {
        if (_desk.members.byIdOrNull(memberId) == null) {
          throw const ApiFailure(400, 'Pick a team member');
        }
        _desk.loadUp(memberId);
        patch.addAll({'AssignedToId': memberId, 'AssignedByRule': null});
      } else if (row['AssignedToId'] == null) {
        final decision = _desk.decide(_subject(row), persist: true);
        patch.addAll({
          'AssignedToId': decision.memberId ?? SeedGraph.meId,
          'AssignedByRule': decision.rule?.name,
        });
      }
      return InboxLead.fromJson(_shape(_table.update(id, patch), now));
    },
    module: AppModule.inbox,
    right: ModuleRight.edit,
  );

  @override
  Future<InboxLead> assign(int id, int memberId) => _backend.run(
    'Inbox assign',
    () {
      final row = _openRow(id);
      if (_desk.members.byIdOrNull(memberId) == null) {
        throw const ApiFailure(400, 'Pick a team member');
      }
      final now = DateTime.now();
      _desk.loadUp(memberId);
      return InboxLead.fromJson(
        _shape(
          _table.update(id, {
            'Status': InboxStatus.assigned.wire,
            'AssignedToId': memberId,
            'AssignedByRule': null,
            'RespondedMinutes':
                row['RespondedMinutes'] ?? _waiting(row, now).inMinutes,
          }),
          now,
        ),
      );
    },
    module: AppModule.inbox,
    right: ModuleRight.edit,
  );

  @override
  Future<InboxLead> reject(int id, RejectReason reason) => _backend.run(
    'Inbox reject',
    () {
      _openRow(id);
      return InboxLead.fromJson(
        _shape(
          _table.update(id, {
            'Status': InboxStatus.rejected.wire,
            'RejectReason': reason.wire,
          }),
          DateTime.now(),
        ),
      );
    },
    module: AppModule.inbox,
    right: ModuleRight.edit,
  );

  @override
  Future<List<GrowthMember>> members() => _backend.run(
    'Growth members',
    () => [for (final row in _desk.members.rows) GrowthMember.fromJson(row)],
    module: AppModule.inbox,
  );

  @override
  Future<List<LeadStage>> stages() => _backend.run(
    'Lead stages',
    () => [
      for (final (id, name, nameBn, _) in SeedGraph.stages)
        if (id < 5)
          LeadStage.fromJson({'Id': id, 'Name': name, 'NameBn': nameBn}),
    ],
    module: AppModule.inbox,
  );

  /// Unanswered leads first, longest waiting on top; then assigned ones,
  /// newest first.
  static int compareBySla(Map<String, dynamic> a, Map<String, dynamic> b) {
    final rank = _rank(a).compareTo(_rank(b));
    if (rank != 0) return rank;
    final waited = (jsonInt(b['WaitingSeconds']) ?? 0).compareTo(
      jsonInt(a['WaitingSeconds']) ?? 0,
    );
    return _rank(a) == 0 ? waited : -waited;
  }

  static int _rank(Map<String, dynamic> row) =>
      row['Status'] == InboxStatus.fresh.wire ? 0 : 1;

  Map<String, dynamic> _openRow(int id) {
    final row = _table.byId(id);
    if (!_isOpen(row)) {
      throw const ApiFailure(409, 'Someone has already handled this lead');
    }
    return row;
  }

  bool _isOpen(Map<String, dynamic> row) =>
      row['Status'] == InboxStatus.fresh.wire ||
      row['Status'] == InboxStatus.assigned.wire;

  bool _matches(InboxFilter filter, Map<String, dynamic> row) =>
      switch (filter) {
        InboxFilter.all => true,
        InboxFilter.unassigned => row['Status'] == InboxStatus.fresh.wire,
        InboxFilter.mine => row['AssignedToId'] == _backend.meId,
        InboxFilter.late =>
          row['Status'] == InboxStatus.fresh.wire &&
              (jsonInt(row['WaitingSeconds']) ?? 0) >= slaMinutes * 60,
        InboxFilter.facebook => row['Source'] == InboxSource.facebook.wire,
        InboxFilter.website => row['Source'] == InboxSource.website.wire,
        InboxFilter.whatsapp => row['Source'] == InboxSource.whatsapp.wire,
      };

  Duration _waiting(Map<String, dynamic> row, DateTime now) {
    final received = jsonDate(row['ReceivedAt']);
    return received == null ? Duration.zero : now.difference(received);
  }

  Map<String, dynamic> _shape(Map<String, dynamic> row, DateTime now) => {
    ...row,
    'WaitingSeconds': _waiting(row, now).inSeconds,
    'SlaMinutes': slaMinutes,
    'CanEdit': _canEdit,
    'Duplicate': _duplicateOf('${row['Phone']}'),
    'AreaBn': SeedGraph.areas
        .where((a) => a.name == row['Area'])
        .firstOrNull
        ?.nameBn,
    ..._desk.memberFields(jsonInt(row['AssignedToId']), 'AssignedTo'),
  };

  RuleSubject _subject(Map<String, dynamic> row) => RuleSubject(
    source: '${row['Source']}',
    area: row['Area'] as String?,
    form: row['FormName'] as String?,
    campaign: row['Campaign'] as String?,
  );

  Map<String, dynamic> _decisionJson(RuleDecision decision) => {
    'RuleId': decision.rule?.id,
    'RuleName': decision.rule?.name,
    ..._desk.memberFields(decision.memberId, 'Member'),
  };

  int _averageResponse() {
    final minutes = [
      for (final row in _table.rows) ?jsonInt(row['RespondedMinutes']),
    ];
    if (minutes.isEmpty) return 0;
    return (minutes.reduce((a, b) => a + b) / minutes.length).round();
  }

  /// An open lead, customer or contact that already has [phone].
  Map<String, dynamic>? _duplicateOf(String phone) {
    for (final contact in _graph.contacts) {
      if (contact.phone != phone) continue;
      final company = _graph.company(contact.companyId);
      final lead = _graph.leads
          .where((l) => l.contactId == contact.id && l.isOpen)
          .firstOrNull;
      if (lead != null) {
        return {
          'Kind': DuplicateKind.lead.wire,
          'Id': lead.id,
          'Name': lead.title,
          'CompanyId': company.id,
          'CompanyName': company.name,
        };
      }
      return {
        'Kind': DuplicateKind.contact.wire,
        'Id': contact.id,
        'Name': contact.name,
        'CompanyId': company.id,
        'CompanyName': company.name,
      };
    }
    for (final company in _graph.companies) {
      if (company.phone != phone) continue;
      return {
        'Kind': DuplicateKind.customer.wire,
        'Id': company.id,
        'Name': company.name,
        'CompanyId': company.id,
        'CompanyName': company.name,
      };
    }
    return null;
  }
}

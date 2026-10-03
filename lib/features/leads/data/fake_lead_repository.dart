import 'package:collection/collection.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/leads/data/lead_fixtures.dart';
import 'package:salesroot/features/leads/data/lead_repository.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_input.dart';
import 'package:salesroot/features/leads/models/lead_lookups.dart';
import 'package:salesroot/features/leads/models/lead_query.dart';
import 'package:salesroot/features/leads/models/lead_stage.dart';

class FakeLeadRepository implements LeadRepository {
  FakeLeadRepository(this._backend);

  final FakeBackend _backend;

  FakeTable get _leads => _backend.table('leads', leadFixtures);
  FakeTable get _activities =>
      _backend.table('lead_activities', leadActivityFixtures);
  FakeTable get _stages => _backend.table('lead_stages', leadStageFixtures);

  SeedGraph get _graph => _backend.graph;
  int get _me => _backend.meId;
  bool get _isMember => _backend.role == WorkspaceRole.member;

  @override
  Future<PageResult<Lead>> list(LeadQuery query) => _backend.run(
    'Lead list',
    () => PageResult.fromJson(_page(query.toQuery()), Lead.fromJson),
    module: AppModule.lead,
  );

  @override
  Future<Lead> get(int id) => _backend.run(
    'Lead get',
    () => Lead.fromJson(_detail(_visibleRow(id))),
    module: AppModule.lead,
  );

  @override
  Future<List<LeadStage>> stages() => _backend.run(
    'Lead stages',
    () => [for (final row in _stages.rows) LeadStage.fromJson(row)],
    module: AppModule.lead,
  );

  @override
  Future<LeadLookups> lookups() => _backend.run(
    'Lead lookups',
    () => LeadLookups.fromJson(_lookups()),
    module: AppModule.lead,
  );

  @override
  Future<Lead> create(LeadInput input) => _backend.run(
    'Lead create',
    () {
      final body = input.toJson();
      _validate(body);
      if (body['AllowDuplicate'] != true) _rejectDuplicate(body);
      final now = DateTime.now();
      final id = _leads.nextId();
      final row = _leads.insert({
        ..._fields(body, now),
        'Id': id,
        'Code': 'L-${id.toString().padLeft(4, '0')}',
        'CreatedOn': jsonUtc(now),
        'CreatedBy': leadMemberJson(_graph.member(_me)),
        'Stage': leadStageJson(_stageIdOf(body), now),
        'DaysInStage': 0,
        'SharedWith': const <Map<String, dynamic>>[],
        ..._followUp(body, now),
      });
      _log(id, 'Created', now, description: row['Source']?['Name'] as String?);
      return Lead.fromJson(_detail(row));
    },
    module: AppModule.lead,
    right: ModuleRight.add,
    quota: QuotaKind.records,
  );

  @override
  Future<Lead> edit(int id, LeadInput input) => _backend.run(
    'Lead edit',
    () {
      final row = _editableRow(id);
      final body = input.toJson();
      _validate(body);
      final now = DateTime.now();
      final stageId = _stageIdOf(body);
      final moved = stageId != (row['Stage'] as Map)['Id'];
      _leads.update(id, {
        ..._fields(body, now),
        if (moved) ...{
          'Stage': leadStageJson(stageId, now),
          'DaysInStage': 0,
          'WinLoss': null,
        },
        if (body['FollowUp'] != null) ..._followUp(body, now),
      });
      if (moved) {
        _log(
          id,
          'StageChange',
          now,
          extra: {'Stage': leadStageJson(stageId, null)},
        );
      }
      return Lead.fromJson(_detail(_leads.byId(id)));
    },
    module: AppModule.lead,
    right: ModuleRight.edit,
  );

  @override
  Future<void> delete(int id) => _backend.run(
    'Lead delete',
    () {
      _visibleRow(id);
      _leads.delete(id);
      for (final row in _activities.rows.where((r) => r['LeadId'] == id)) {
        _activities.delete(row['Id'] as int);
      }
    },
    module: AppModule.lead,
    right: ModuleRight.delete,
  );

  @override
  Future<LeadStageMove> moveStage(int id, LeadStageInput input) => _backend.run(
    'Lead move stage',
    () {
      final row = _editableRow(id);
      final body = input.toJson();
      final stage = _stages.byIdOrNull(input.stageId);
      if (stage == null) {
        throw const ApiFailure(400, 'Unknown stage');
      }
      final from = (row['Stage'] as Map)['Id'] as int;
      if (from == input.stageId) {
        throw const ApiFailure(400, 'The lead is already in that stage');
      }
      final reason = leadLostReasonFixtures.firstWhereOrNull(
        (r) => r['Id'] == body['WinLossCauseId'],
      );
      if (stage['IsLost'] == true && reason == null) {
        throw const ApiFailure(
          400,
          'Pick why the lead was lost',
          fieldErrors: {'WinLossCauseId': 'Pick why the lead was lost'},
        );
      }
      final now = DateTime.now();
      final move = _log(
        id,
        'StageChange',
        now,
        description: body['Note'] as String?,
        extra: {
          'Stage': leadStageJson(input.stageId, null),
          'FromStage': row['Stage'],
          'FromWinLoss': row['WinLoss'],
          'FromDaysInStage': row['DaysInStage'],
        },
      );
      _leads.update(id, {
        'Stage': leadStageJson(input.stageId, now),
        'WinProbability': stage['WinProbability'],
        'DaysInStage': 0,
        'IsStalled': false,
        'UpdatedOn': jsonUtc(now),
        'LastActivityOn': jsonUtc(now),
        'WinLoss': reason == null
            ? null
            : {'CauseId': reason['Id'], 'Cause': reason, 'Note': body['Note']},
      });
      return LeadStageMove.fromJson({
        'MoveId': move['Id'],
        'FromStageId': from,
        'Lead': _detail(_leads.byId(id)),
      });
    },
    module: AppModule.lead,
    right: ModuleRight.edit,
  );

  @override
  Future<Lead> undoStageMove(int id, int moveId) => _backend.run(
    'Lead undo move',
    () {
      _editableRow(id);
      final move = _activities.byId(moveId);
      if (move['LeadId'] != id || move['Kind'] != 'StageChange') {
        throw const ApiFailure(404, 'Record not found');
      }
      final from = move['FromStage'] as Map<String, dynamic>;
      _leads.update(id, {
        'Stage': from,
        'WinProbability': leadStageProbability(from['Id'] as int),
        'WinLoss': move['FromWinLoss'],
        'DaysInStage': move['FromDaysInStage'],
      });
      _activities.delete(moveId);
      return Lead.fromJson(_detail(_leads.byId(id)));
    },
    module: AppModule.lead,
    right: ModuleRight.edit,
  );

  @override
  Future<Lead> completeNextTask(int id) => _backend.run(
    'Lead task done',
    () {
      final row = _editableRow(id);
      if (row['NextTaskId'] == null) {
        throw const ApiFailure(400, 'This lead has no open task');
      }
      final now = DateTime.now();
      _log(id, 'Task', now, extra: {'Reference': row['NextTaskTitle']});
      _leads.update(id, {
        ..._noTask,
        'IsStalled': false,
        'LastActivityOn': jsonUtc(now),
        'UpdatedOn': jsonUtc(now),
      });
      return Lead.fromJson(_detail(_leads.byId(id)));
    },
    module: AppModule.lead,
    right: ModuleRight.edit,
  );

  @override
  Future<Lead> logActivity(int id, LeadActivityInput input) => _backend.run(
    'Lead log activity',
    () {
      _editableRow(id);
      final body = input.toJson();
      fakeRequire(body, [
        'Kind',
        'OccurredOn',
        if (body['Kind'] == 'Note') 'Description',
      ]);
      final now = DateTime.now();
      final at = jsonDate(body['OccurredOn']) ?? now;
      _log(
        id,
        body['Kind'] as String,
        at,
        description: body['Description'] as String?,
        extra: {
          'DurationMinutes': body['DurationMinutes'],
          'ActivityOutcome': body['ActivityOutcome'],
          'PhotoCount': body['PhotoCount'],
        },
      );
      _leads.update(id, {
        'IsStalled': false,
        'LastActivityOn': jsonUtc(at),
        'UpdatedOn': jsonUtc(now),
        if (body['FollowUp'] != null) ..._followUp(body, now),
      });
      return Lead.fromJson(_detail(_leads.byId(id)));
    },
    module: AppModule.lead,
    right: ModuleRight.edit,
  );

  bool _visible(Map<String, dynamic> row) {
    if (!_isMember) return true;
    if (_ownerOf(row) == _me) return true;
    return jsonList(row['SharedWith'], (m) => m['Id']).contains(_me);
  }

  int? _ownerOf(Map<String, dynamic> row) =>
      jsonInt((row['AssignedTo'] as Map?)?['Id']);

  Map<String, dynamic> _visibleRow(int id) {
    final row = _leads.byId(id);
    if (!_visible(row)) throw const ApiFailure(404, 'Record not found');
    return row;
  }

  Map<String, dynamic> _editableRow(int id) {
    final row = _visibleRow(id);
    if (_isMember && _ownerOf(row) != _me) {
      throw const ApiFailure(403, 'Only the owner can change this lead.');
    }
    return row;
  }

  Map<String, dynamic> _out(Map<String, dynamic> row) => {
    ...row,
    'CanEdit': !_isMember || _ownerOf(row) == _me,
    'CanDelete': !_isMember,
  };

  Map<String, dynamic> _detail(Map<String, dynamic> row) {
    final timeline =
        _activities.rows.where((a) => a['LeadId'] == row['Id']).toList()..sort(
          (a, b) => _date(b['OccurredOn']).compareTo(_date(a['OccurredOn'])),
        );
    return {..._out(row), 'Timeline': timeline};
  }

  Map<String, dynamic> _page(Map<String, dynamic> query) {
    final page = jsonInt(query['page']) ?? 1;
    final pageSize = jsonInt(query['pageSize']) ?? 20;
    final stageIds = _ids(query['stageIds']);
    final openOnly = query['openOnly'] == true;
    final chip = LeadChip.fromWire(query['chip'] as String?);

    final base = _leads.rows
        .where(_visible)
        .where((row) => _matches(row, query))
        .toList();
    final scoped = base.where((row) {
      final stage = row['Stage'] as Map;
      if (stageIds.isNotEmpty) return stageIds.contains(stage['Id']);
      return !openOnly || (stage['IsWon'] != true && stage['IsLost'] != true);
    }).toList();
    final rows = scoped.where((row) => _chipHolds(chip, row)).toList()
      ..sort(_byNextTask);

    final open = base.where((r) => _isOpen(r)).toList();
    return fakePage(
      [for (final row in rows) _out(row)],
      page: page,
      pageSize: pageSize,
      extra: {
        'ChipCounts': {
          for (final c in LeadChip.values)
            c.wire: scoped.where((row) => _chipHolds(c, row)).length,
        },
        'StageCounts': {
          for (final stage in _stages.rows)
            '${stage['Id']}': base
                .where((row) => (row['Stage'] as Map)['Id'] == stage['Id'])
                .length,
        },
        'Summary': {
          'Open': open.length,
          'ClosingThisWeek': open.where((row) {
            final days = jsonInt(row['DaysToClose']) ?? -1;
            return days >= 0 && days <= 7;
          }).length,
        },
      },
    );
  }

  bool _matches(Map<String, dynamic> row, Map<String, dynamic> query) {
    final search = '${query['search'] ?? ''}'.trim().toLowerCase();
    if (search.isNotEmpty) {
      final digits = search.replaceAll(RegExp(r'\D'), '');
      final contact = row['PrimaryContact'] as Map? ?? const {};
      final haystack = [
        row['LeadName'],
        (row['Company'] as Map?)?['Name'],
        contact['Name'],
      ].join(' ').toLowerCase();
      final phone = '${contact['Mobile'] ?? ''}'.replaceAll(RegExp(r'\D'), '');
      final hit =
          haystack.contains(search) ||
          (digits.length >= 4 && phone.contains(digits));
      if (!hit) return false;
    }
    if (query['mine'] == true && _ownerOf(row) != _me) return false;
    final owner = jsonInt(query['assignedToEmployeeId']);
    if (owner != null && _ownerOf(row) != owner) return false;
    final sources = _ids(query['sourceIds']);
    if (sources.isNotEmpty &&
        !sources.contains((row['Source'] as Map?)?['Id'])) {
      return false;
    }
    final tags = _ids(query['tagIds']);
    if (tags.isNotEmpty &&
        !jsonList(row['Tags'], (t) => t['Id']).any(tags.contains)) {
      return false;
    }
    final temperatures = '${query['temperatures'] ?? ''}'
        .split(',')
        .where((t) => t.isNotEmpty)
        .toSet();
    if (temperatures.isNotEmpty && !temperatures.contains(row['Temperature'])) {
      return false;
    }
    final value = jsonDouble(row['EstimatedAmount']) ?? 0;
    final min = jsonDouble(query['minValue']);
    final max = jsonDouble(query['maxValue']);
    if (min != null && value < min) return false;
    if (max != null && value > max) return false;
    final from = DateTime.tryParse('${query['createdFrom'] ?? ''}');
    if (from != null && _date(row['CreatedOn']).isBefore(from)) return false;
    return true;
  }

  bool _chipHolds(LeadChip chip, Map<String, dynamic> row) => switch (chip) {
    LeadChip.all => true,
    LeadChip.dueToday => row['IsDueToday'] == true,
    LeadChip.overdue => row['IsOverdue'] == true,
    LeadChip.stalled => row['IsStalled'] == true,
    LeadChip.hot => row['Temperature'] == 'Hot',
  };

  bool _isOpen(Map<String, dynamic> row) {
    final stage = row['Stage'] as Map;
    return stage['IsWon'] != true && stage['IsLost'] != true;
  }

  int _byNextTask(Map<String, dynamic> a, Map<String, dynamic> b) {
    final ta = jsonDate(a['NextTaskAt']);
    final tb = jsonDate(b['NextTaskAt']);
    if (ta != null && tb != null) return ta.compareTo(tb);
    if (ta != null) return -1;
    if (tb != null) return 1;
    return _date(b['LastActivityOn']).compareTo(_date(a['LastActivityOn']));
  }

  Set<int> _ids(dynamic value) =>
      '${value ?? ''}'.split(',').map(int.tryParse).nonNulls.toSet();

  DateTime _date(dynamic value) =>
      jsonDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0);

  void _validate(Map<String, dynamic> body) {
    fakeRequire(body, ['LeadName']);
    final mobile = (body['NewContact'] as Map?)?['Mobile'] as String?;
    if (mobile != null && !isLeadMobile(mobile)) {
      throw const ApiFailure(
        400,
        'Enter a valid mobile number',
        fieldErrors: {'Mobile': 'Enter a valid mobile number'},
      );
    }
    final amount = jsonDouble(body['EstimatedAmount']);
    if (amount != null && amount < 0) {
      throw const ApiFailure(
        400,
        'The deal value cannot be negative',
        fieldErrors: {'EstimatedAmount': 'The deal value cannot be negative'},
      );
    }
  }

  static String _phoneKey(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.length < 10 ? '' : digits.substring(digits.length - 10);
  }

  void _rejectDuplicate(Map<String, dynamic> body) {
    final contact = body['NewContact'] as Map?;
    final phones = {
      _phoneKey(contact?['Mobile'] as String?),
      for (final id in jsonInts(body['ContactIds']))
        _phoneKey(_graph.contacts.firstWhereOrNull((c) => c.id == id)?.phone),
    }..remove('');
    final companyId = jsonInt(body['CompanyId']);
    final companyName = '${body['CompanyName'] ?? ''}'.trim().toLowerCase();
    for (final row in _leads.rows.where(_visible)) {
      final mobile = (row['PrimaryContact'] as Map?)?['Mobile'] as String?;
      if (phones.contains(_phoneKey(mobile))) {
        throw LeadDuplicateFailure(
          existing: Lead.fromJson(_out(row)),
          field: LeadDuplicateField.phone,
        );
      }
    }
    for (final row in _leads.rows.where(_visible).where(_isOpen)) {
      final company = row['Company'] as Map? ?? const {};
      final sameId = companyId != null && company['Id'] == companyId;
      final sameName =
          companyName.isNotEmpty &&
          '${company['Name'] ?? ''}'.toLowerCase() == companyName;
      if (sameId || sameName) {
        throw LeadDuplicateFailure(
          existing: Lead.fromJson(_out(row)),
          field: LeadDuplicateField.company,
        );
      }
    }
  }

  int _stageIdOf(Map<String, dynamic> body) {
    final id = jsonInt(body['StageId']);
    if (id != null && _stages.byIdOrNull(id) != null) return id;
    return _stages.rows.first['Id'] as int;
  }

  /// The row fields a create or edit body sets.
  Map<String, dynamic> _fields(Map<String, dynamic> body, DateTime now) {
    final companyId = jsonInt(body['CompanyId']);
    final company = _graph.companies.firstWhereOrNull((c) => c.id == companyId);
    final companyName = body['CompanyName'] as String?;
    final picked = [
      for (final id in jsonInts(body['ContactIds']))
        ?_graph.contacts.firstWhereOrNull((c) => c.id == id),
    ];
    final typed = body['NewContact'] as Map<String, dynamic>?;
    final contacts = [
      if (typed != null) {...typed, 'IsPrimary': true},
      for (final (i, contact) in picked.indexed)
        leadContactJson(contact, primary: typed == null && i == 0),
    ];
    final requested = jsonInt(body['AssignedToEmployeeId']);
    final owner = _graph.members.firstWhereOrNull(
      (m) => m.id == (_isMember ? _me : requested ?? _me),
    );
    final closing = jsonDate(body['EstimatedClosingDate']);
    final stageId = _stageIdOf(body);
    return {
      'LeadName': body['LeadName'],
      'Company': company != null
          ? leadCompanyJson(_graph, company)
          : (companyName == null ? null : {'Name': companyName}),
      'Contacts': contacts,
      'PrimaryContact': contacts.firstOrNull,
      'AssignedTo': leadMemberJson(owner ?? _graph.member(_me)),
      'EstimatedAmount': body['EstimatedAmount'],
      'EstimatedClosingDate': body['EstimatedClosingDate'],
      'DaysToClose': closing == null
          ? null
          : AppDateUtils.dateOnly(
              closing,
            ).difference(AppDateUtils.dateOnly(now)).inDays,
      'WinProbability': leadStageProbability(stageId),
      'Temperature': body['Temperature'],
      'Source': leadSourceFixtures.firstWhereOrNull(
        (s) => s['Id'] == body['SourceId'],
      ),
      'Tags': [
        for (final id in jsonInts(body['TagIds']))
          ?leadTagFixtures.firstWhereOrNull((t) => t['Id'] == id),
      ],
      'Interests': [
        for (final id in jsonInts(body['InterestIds']))
          ?leadInterestFixtures.firstWhereOrNull((t) => t['Id'] == id),
      ],
      'Comments': body['Comments'],
      'IsStalled': false,
      'UpdatedOn': jsonUtc(now),
      'LastActivityOn': jsonUtc(now),
    };
  }

  static const Map<String, dynamic> _noTask = {
    'NextTaskId': null,
    'NextTaskTitle': null,
    'NextTaskType': null,
    'NextTaskAt': null,
    'IsDueToday': false,
    'IsOverdue': false,
  };

  Map<String, dynamic> _followUp(Map<String, dynamic> body, DateTime now) {
    final followUp = body['FollowUp'] as Map<String, dynamic>?;
    final at = jsonDate(followUp?['At']);
    if (followUp == null || at == null) return _noTask;
    return {
      'NextTaskId': 5000 + _activities.nextId(),
      'NextTaskTitle': followUp['Title'],
      'NextTaskType': followUp['Type'],
      'NextTaskAt': followUp['At'],
      'IsDueToday': AppDateUtils.isSameDay(at, now),
      'IsOverdue': at.isBefore(now),
    };
  }

  Map<String, dynamic> _log(
    int leadId,
    String kind,
    DateTime at, {
    String? description,
    Map<String, dynamic> extra = const {},
  }) => _activities.insert(
    {
      'LeadId': leadId,
      'Kind': kind,
      'OccurredOn': jsonUtc(at),
      'ActorName': _graph.member(_me).name,
      'Description': description,
      ...extra,
    }..removeWhere((_, v) => v == null),
  );

  Map<String, dynamic> _lookups() => {
    'CurrentEmployeeId': _me,
    'Owners': [
      for (final member in _graph.members)
        {...leadMemberJson(member), 'Subtitle': member.designation},
    ],
    'Companies': [
      for (final company in _graph.companies)
        {
          'Id': company.id,
          'Name': company.name,
          'Industry': company.industry,
          'Area': {'Name': company.area.name, 'NameBn': company.area.nameBn},
        },
    ],
    'Contacts': [
      for (final contact in _graph.contacts)
        {
          'Id': contact.id,
          'CompanyId': contact.companyId,
          'Name': contact.name,
          'Designation': contact.designation,
          'Mobile': contact.phone,
          'Email': contact.email,
        },
    ],
    'Sources': leadSourceFixtures,
    'Tags': leadTagFixtures,
    'Interests': leadInterestFixtures,
    'LostReasons': leadLostReasonFixtures,
  };
}

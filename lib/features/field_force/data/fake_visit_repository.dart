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
import 'package:salesroot/features/field_force/data/fake_field_data.dart';
import 'package:salesroot/features/field_force/data/visit_fixtures.dart';
import 'package:salesroot/features/field_force/data/visit_repository.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/models/visit_report.dart';
import 'package:salesroot/features/field_force/service/geo.dart';

class FakeVisitRepository implements VisitRepository {
  FakeVisitRepository(this._backend) : _data = FakeFieldData(_backend);

  final FakeBackend _backend;
  final FakeFieldData _data;

  FakeTable get _visits => _data.visits;
  SeedGraph get _graph => _backend.graph;

  @override
  Future<PageResult<Visit>> list(VisitQuery query) => _backend.run(
    'Visit list',
    () => PageResult.fromJson(
      fakePage(
        _data.visitsOf(query.memberId ?? _backend.meId, query.day),
        page: query.page,
      ),
      Visit.fromJson,
    ),
    module: AppModule.visit,
  );

  @override
  Future<Visit> get(int id) => _backend.run(
    'Visit $id',
    () => Visit.fromJson(_visits.byId(id)),
    module: AppModule.visit,
  );

  @override
  Future<Visit> create(VisitInput input) => _backend.run(
    'Visit create',
    () {
      final body = input.toJson();
      fakeRequire(body, ['LeadId']);
      final lead = _graph.leads.where((l) => l.id == input.leadId).firstOrNull;
      if (lead == null) throw const ApiFailure(404, 'Lead not found');
      final company = _graph.company(lead.companyId);
      final plannedAt = input.plannedAt ?? DateTime.now();
      final (lat, lng) = companySpot(company);
      final row = _visits.insert(
        {
          'Employee': memberJson(_graph.me),
          'Lead': {'Id': lead.id, 'Name': lead.title},
          'Company': {'Id': company.id, 'Name': company.name},
          'ContactName': _graph.contact(lead.contactId).name,
          'Area': areaJson(company.area),
          'Address': '${company.area.name} Road ${1 + company.id % 27}',
          'Latitude': lat,
          'Longitude': lng,
          'PlannedAt': jsonUtc(plannedAt),
          'Purpose': body['Purpose'],
          'Order': _data.visitsOf(_backend.meId, plannedAt).length + 1,
          'Status': 'Planned',
          'Photos': const <Map<String, dynamic>>[],
          'Notes': const <Map<String, dynamic>>[],
          'SampleProductIds': const <int>[],
          'CanEdit': true,
          'CanDelete': false,
        }..removeWhere((_, value) => value == null),
      );
      return Visit.fromJson(row);
    },
    module: AppModule.visit,
    right: ModuleRight.add,
  );

  @override
  Future<void> reorder(List<int> ids) => _backend.run(
    'Visit reorder',
    () {
      for (var i = 0; i < ids.length; i++) {
        _visits.update(ids[i], {'Order': i + 1});
      }
    },
    module: AppModule.visit,
    right: ModuleRight.edit,
  );

  @override
  Future<Visit> checkIn(int id, VisitCheckInInput input) => _backend.run(
    'Visit $id check-in',
    () {
      final row = _visits.byId(id);
      if (row['Status'] != 'Planned' && row['Status'] != 'Missed') {
        throw const ApiFailure(409, 'This visit is already checked in.');
      }
      final open = _visits.rows.where(
        (r) =>
            r['Status'] == 'InProgress' &&
            (r['Employee'] as Map<String, dynamic>?)?['Id'] == _backend.meId,
      );
      if (open.isNotEmpty) {
        final company =
            (open.first['Company'] as Map<String, dynamic>?)?['Name'];
        throw ApiFailure(409, 'Check out of $company first.');
      }
      final distance = distanceMetres(
        input.latitude,
        input.longitude,
        jsonDouble(row['Latitude']) ?? input.latitude,
        jsonDouble(row['Longitude']) ?? input.longitude,
      ).round();
      final far = isFarCheckIn(distance, radius: _data.settings.checkInRadius);
      final body = input.toJson();
      if (far) fakeRequire(body, ['FarReason', 'PhotoPath']);
      final now = DateTime.now();
      final photo = input.photoPath;
      final note = body['Note'];
      return Visit.fromJson(
        _visits.update(id, {
          'Status': 'InProgress',
          'Start': {
            'Latitude': input.latitude,
            'Longitude': input.longitude,
            'Location': input.location ?? row['Address'],
            'Time': jsonUtc(now),
          },
          'CheckInDistance': distance,
          'IsFarCheckIn': far,
          'FarReason': far ? body['FarReason'] : null,
          if (photo != null)
            'Photos': [..._list(row['Photos']), _photo(row, photo, now)],
          if (note is String)
            'Notes': [..._list(row['Notes']), _note(row, note, now)],
        }),
      );
    },
    module: AppModule.visit,
    right: ModuleRight.add,
  );

  @override
  Future<Visit> addNote(int id, String text) => _backend.run(
    'Visit $id note',
    () {
      fakeRequire({'Text': text}, ['Text']);
      final row = _visits.byId(id);
      return Visit.fromJson(
        _visits.update(id, {
          'Notes': [
            ..._list(row['Notes']),
            _note(row, text.trim(), DateTime.now()),
          ],
        }),
      );
    },
    module: AppModule.visit,
    right: ModuleRight.edit,
  );

  @override
  Future<Visit> addPhoto(int id, String path) => _backend.run(
    'Visit $id photo',
    () {
      final row = _visits.byId(id);
      return Visit.fromJson(
        _visits.update(id, {
          'Photos': [
            ..._list(row['Photos']),
            _photo(row, path, DateTime.now()),
          ],
        }),
      );
    },
    module: AppModule.visit,
    right: ModuleRight.edit,
    quota: QuotaKind.storage,
  );

  @override
  Future<Visit> setSamples(int id, List<int> productIds) => _backend.run(
    'Visit $id samples',
    () => Visit.fromJson(_visits.update(id, {'SampleProductIds': productIds})),
    module: AppModule.visit,
    right: ModuleRight.edit,
  );

  @override
  Future<Visit> checkOut(int id, VisitEndInput input) => _backend.run(
    'Visit $id check-out',
    () {
      final row = _visits.byId(id);
      if (row['Status'] != 'InProgress') {
        throw const ApiFailure(409, 'This visit is not checked in.');
      }
      final body = input.toJson();
      final now = DateTime.now();
      final start = jsonDate((row['Start'] as Map<String, dynamic>?)?['Time']);
      return Visit.fromJson(
        _visits.update(id, {
          'Status': 'Done',
          'End': {
            'Latitude': body['Latitude'],
            'Longitude': body['Longitude'],
            'Location': body['Location'],
            'Time': jsonUtc(now),
          }..removeWhere((_, value) => value == null),
          'DurationMinutes': start == null
              ? 0
              : now.difference(start).inMinutes,
          'Outcome': body['Outcome'],
          'Note': body['Note'],
        }),
      );
    },
    module: AppModule.visit,
    right: ModuleRight.add,
  );

  @override
  Future<PageResult<VisitTarget>> targets(String term, int page) =>
      _backend.run('Visit targets', () {
        final mine = _graph.leadsOf(_backend.meId);
        final rows = [
          for (final lead in [
            ...mine,
            ..._graph.leads.where((l) => l.ownerId != _backend.meId),
          ])
            if (lead.isOpen) _targetJson(lead),
        ].where((row) => fakeMatches(row, term, ['LeadTitle', 'CompanyName']));
        return PageResult.fromJson(
          fakePage(rows.toList(), page: page),
          VisitTarget.fromJson,
        );
      }, module: AppModule.visit);

  @override
  Future<VisitTarget> target(int leadId) => _backend.run('Visit target', () {
    final lead = _graph.leads.where((l) => l.id == leadId).firstOrNull;
    if (lead == null) throw const ApiFailure(404, 'Lead not found');
    return VisitTarget.fromJson(_targetJson(lead));
  }, module: AppModule.visit);

  @override
  Future<List<VisitProduct>> products() => _backend.run(
    'Visit products',
    () => [
      for (final p in _graph.products)
        VisitProduct.fromJson({'Id': p.id, 'Code': p.code, 'Name': p.name}),
    ],
    module: AppModule.visit,
  );

  @override
  Future<VisitReport> report(VisitReportQuery query) => _backend.run(
    'Visit report',
    () => VisitReport.fromJson(_report(query, DateTime.now())),
    module: AppModule.visit,
  );

  @override
  Future<List<ReportMember>> members() => _backend.run(
    'Visit members',
    () => [
      for (final member in _visibleMembers())
        ReportMember.fromJson(memberJson(member)),
    ],
    module: AppModule.visit,
  );

  List<SeedMember> _visibleMembers() => _backend.role == WorkspaceRole.member
      ? [_graph.me]
      : fieldMembers(_graph);

  Map<String, dynamic> _report(VisitReportQuery query, DateTime now) {
    final today = AppDateUtils.dateOnly(now);
    final from = query.period == ReportPeriod.week
        ? today.subtract(Duration(days: (today.weekday + 1) % 7))
        : DateTime(today.year, today.month);
    final visible = {for (final m in _visibleMembers()) m.id: m};
    final rows = [
      for (final row in _visits.rows)
        if (_inReport(row, query, visible.keys.toSet(), from, now)) row,
    ];
    final byMember = <int, Map<String, int>>{};
    for (final row in rows) {
      final id = (row['Employee'] as Map<String, dynamic>?)?['Id'] as int? ?? 0;
      final stat = byMember.putIfAbsent(
        id,
        () => {'Planned': 0, 'Done': 0, 'Far': 0},
      );
      stat['Planned'] = (stat['Planned'] ?? 0) + 1;
      if (row['Status'] == 'Done') stat['Done'] = (stat['Done'] ?? 0) + 1;
      if (jsonBool(row['IsFarCheckIn'])) stat['Far'] = (stat['Far'] ?? 0) + 1;
    }
    final far = rows.where((r) => jsonBool(r['IsFarCheckIn'])).toList()
      ..sort((a, b) => '${b['PlannedAt']}'.compareTo('${a['PlannedAt']}'));
    final done = rows.where((r) => r['Status'] == 'Done').length;
    return {
      'From': jsonUtc(from),
      'To': jsonUtc(today),
      'Planned': rows.length,
      'Done': done,
      'Missed': rows.length - done,
      'Far': far.length,
      'ByMember': [
        for (final entry in byMember.entries)
          if (visible[entry.key] case final member?)
            {...memberJson(member), 'MemberId': member.id, ...entry.value},
      ]..sort((a, b) => (b['Planned'] as int).compareTo(a['Planned'] as int)),
      'FarCheckIns': [
        for (final row in far)
          if (visible[(row['Employee'] as Map<String, dynamic>?)?['Id']]
              case final member?)
            {
              'VisitId': row['Id'],
              'MemberId': member.id,
              'MemberName': member.name,
              'MemberNameBn': member.nameBn,
              'Company': (row['Company'] as Map<String, dynamic>?)?['Name'],
              'Distance': row['CheckInDistance'],
              'Date': (row['Start'] as Map<String, dynamic>?)?['Time'],
              'Reason': row['FarReason'],
            }..removeWhere((_, value) => value == null),
      ],
    };
  }

  bool _inReport(
    Map<String, dynamic> row,
    VisitReportQuery query,
    Set<int> visible,
    DateTime from,
    DateTime now,
  ) {
    final member = (row['Employee'] as Map<String, dynamic>?)?['Id'];
    if (!visible.contains(member)) return false;
    if (query.memberId != null && member != query.memberId) return false;
    final planned = jsonDate(row['PlannedAt']);
    if (planned == null || planned.isBefore(from) || planned.isAfter(now)) {
      return false;
    }
    final status = row['Status'];
    if (status != 'Done' && status != 'Missed') return false;
    return !query.farOnly || jsonBool(row['IsFarCheckIn']);
  }

  Map<String, dynamic> _targetJson(SeedLead lead) {
    final company = _graph.company(lead.companyId);
    return {
      'LeadId': lead.id,
      'LeadTitle': lead.title,
      'CompanyId': company.id,
      'CompanyName': company.name,
      'Area': areaJson(company.area),
    };
  }

  List<Map<String, dynamic>> _list(dynamic value) =>
      jsonList(value, (json) => json);

  Map<String, dynamic> _photo(
    Map<String, dynamic> row,
    String path,
    DateTime at,
  ) => {
    'Id': _list(row['Photos']).length + 1,
    'Path': path,
    'TakenAt': jsonUtc(at),
  };

  Map<String, dynamic> _note(
    Map<String, dynamic> row,
    String text,
    DateTime at,
  ) => {
    'Id': _list(row['Notes']).length + 1,
    'Text': text,
    'Time': jsonUtc(at),
  };
}

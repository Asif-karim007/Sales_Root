import 'package:collection/collection.dart';

import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/field_force/data/field_api.dart';
import 'package:salesroot/features/field_force/data/field_sources.dart';
import 'package:salesroot/features/field_force/data/visit_repository.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/models/visit_report.dart';

/// Visits over `/visits`. The API has no single-visit read, so [get] answers
/// from the rows already seen, or looks through the list.
class ApiVisitRepository implements VisitRepository {
  ApiVisitRepository(this._api, {this.me, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      _workspace = FieldWorkspaceSource(_api);

  static const _scanSize = 100;
  static const _scanPages = 10;

  final FieldApi _api;

  /// The user's membership id in the current workspace.
  final String? me;
  final DateTime Function() _clock;
  final FieldWorkspaceSource _workspace;
  final _seen = <String, Visit>{};

  @override
  Future<PageResult<Visit>> list(VisitQuery query) async {
    final json = await apiRequest(
      'Visit list',
      () => _api.visits(query.toQuery()),
    );
    final page = PageResult.fromJson(jsonMap(json), Visit.fromJson);
    for (final visit in page.items) {
      _seen[visit.id] = visit;
    }
    return page;
  }

  @override
  Future<Visit> get(String id) async => _seen[id] ?? await _find(id);

  @override
  Future<Visit> start(VisitStartInput input) async {
    final json = await apiRequest(
      'Visit start',
      () => _api.startVisit(input.toJson()),
    );
    return _find(jsonId(jsonMap(json)['id']) ?? '', member: me);
  }

  @override
  Future<Visit> end(
    String id,
    VisitEndInput input, {
    List<String> photoPaths = const [],
  }) async {
    final keys = [
      for (final path in photoPaths)
        await uploadPhoto(_api, entityType: 'visit', entityId: id, path: path),
    ];
    final body = VisitEndInput(
      outcome: input.outcome,
      latitude: input.latitude,
      longitude: input.longitude,
      note: input.note,
      photos: [...input.photos, ...keys],
    ).toJson();
    await apiRequest('Visit end', () => _api.endVisit(id, body));
    _seen.remove(id);
    return _find(id, member: me);
  }

  @override
  Future<PageResult<VisitTarget>> targets(String term, int page) async {
    final text = term.trim();
    final json = await apiRequest(
      'Visit targets',
      () =>
          _api.companies({if (text.isNotEmpty) 'q': text, ...pageQuery(page)}),
    );
    return PageResult.fromJson(jsonMap(json), VisitTarget.fromCompany);
  }

  @override
  Future<VisitTarget> target(String companyId) async {
    final json = await apiRequest(
      'Visit target',
      () => _api.company(companyId),
    );
    return VisitTarget.fromCompany(jsonMap(jsonMap(json)['company']));
  }

  @override
  Future<VisitTarget?> leadTarget(String leadId) async {
    final json = await apiRequest('Visit lead', () => _api.lead(leadId));
    final lead = jsonMap(jsonMap(json)['lead']);
    final companyId = jsonId(lead['companyId']);
    if (companyId == null) return null;
    final company = await target(companyId);
    return company.withLead(
      jsonId(lead['id']) ?? leadId,
      lead['title'] as String?,
    );
  }

  @override
  Future<List<VisitOutcomeOption>> outcomes() async =>
      (await _workspace.get()).outcomes;

  @override
  Future<VisitReport> report(VisitReportQuery query) async {
    final (from, to) = query.range(_clock());
    final loading = apiRequest(
      'Visit report',
      () => _api.report({
        'from': AppDateUtils.toApiDateOnly(from),
        'to': AppDateUtils.toApiDateOnly(to),
        'group': 'day',
        'ownerId': query.memberId,
      }),
    );
    final far = <Visit>[];
    final scanning = _scan(
      VisitQuery(from: from, to: to, memberId: query.memberId),
      (page) {
        far.addAll(page.items.where((visit) => visit.locationMismatch));
        return false;
      },
    );
    await Future.wait([loading, scanning]);
    return VisitReport.of(
      FieldReport.fromJson(jsonMap(await loading)),
      from: from,
      to: to,
      farVisits: far,
    );
  }

  @override
  Future<List<ReportMember>> members() async {
    final json = await apiRequest('Members', _api.members);
    return json is List
        ? [
            for (final row in json)
              if (row is Map<String, dynamic>) ReportMember.fromJson(row),
          ]
        : const [];
  }

  Future<Visit> _find(String id, {String? member}) async {
    Visit? found;
    await _scan(VisitQuery(memberId: member), (page) {
      found = page.items.firstWhereOrNull((visit) => visit.id == id);
      return found != null;
    });
    return found ?? (throw const ApiFailure(404, 'Record not found'));
  }

  /// Pages through `/visits` with [query] until [stop] says so or the list
  /// ends.
  Future<void> _scan(
    VisitQuery query,
    bool Function(PageResult<Visit> page) stop,
  ) async {
    for (var page = 1; page <= _scanPages; page++) {
      final result = await list(
        VisitQuery(
          from: query.from,
          to: query.to,
          memberId: query.memberId,
          page: page,
          size: _scanSize,
        ),
      );
      if (stop(result) || result.items.isEmpty) return;
      if (page * _scanSize >= result.totalCount) return;
    }
  }
}

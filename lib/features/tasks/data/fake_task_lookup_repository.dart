import 'package:collection/collection.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/tasks/data/task_lookup_repository.dart';
import 'package:salesroot/features/tasks/models/task_lookups.dart';

class FakeTaskLookupRepository implements TaskLookupRepository {
  FakeTaskLookupRepository(this._backend);

  final FakeBackend _backend;

  SeedGraph get _graph => _backend.graph;

  @override
  Future<PageResult<LeadOption>> searchLeads(String term, int page) =>
      _backend.run('Lead lookup "$term" p$page', () {
        final rows = [
          for (final lead in _ordered)
            if (fakeMatches(_leadRow(lead), term, const [
              'Title',
              'CompanyName',
              'ContactName',
            ]))
              _leadRow(lead),
        ];
        return PageResult.fromJson(
          fakePage(rows, page: page),
          LeadOption.fromJson,
        );
      }, module: AppModule.lead);

  @override
  Future<LeadOption> lead(int id) => _backend.run('Lead lookup $id', () {
    final lead =
        _graph.leads.firstWhereOrNull((l) => l.id == id) ??
        (throw const ApiFailure(404, 'Record not found'));
    return LeadOption.fromJson(_leadRow(lead));
  }, module: AppModule.lead);

  @override
  Future<List<MemberOption>> members() => _backend.run(
    'Member lookup',
    () => [
      for (final member in _graph.members)
        MemberOption.fromJson({
          'Id': member.id,
          'Name': member.name,
          'NameBn': member.nameBn,
          'Designation': member.designation,
          'IsMe': member.id == _backend.meId,
        }),
    ],
    module: AppModule.task,
  );

  @override
  Future<int?> findCompany(String name) => _backend.run('Company match', () {
    final wanted = _normalise(name);
    if (wanted.isEmpty) return null;
    return _graph.companies
        .firstWhereOrNull((c) => _normalise(c.name) == wanted)
        ?.id;
  });

  /// The user's own open leads first, then everyone's, newest first.
  Iterable<SeedLead> get _ordered => [
    ..._graph.leads.where((l) => l.ownerId == _backend.meId && l.isOpen),
    ..._graph.leads.reversed.where(
      (l) => l.ownerId != _backend.meId || !l.isOpen,
    ),
  ];

  Map<String, dynamic> _leadRow(SeedLead lead) => {
    'Id': lead.id,
    'Title': lead.title,
    'CompanyName': _graph.company(lead.companyId).name,
    'ContactName': _graph.contact(lead.contactId).name,
    'OwnerId': lead.ownerId,
  };

  static String _normalise(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'\b(ltd|limited|pvt|co)\b'), '')
      .replaceAll(RegExp('[^a-z0-9]'), '');
}

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/data/ticket_fixtures.dart';
import 'package:salesroot/features/hr/data/ticket_repository.dart';
import 'package:salesroot/features/hr/models/ticket.dart';

class FakeTicketRepository implements TicketRepository {
  FakeTicketRepository(this._backend);

  final FakeBackend _backend;

  FakeTable get _table => _backend.table('tickets', ticketFixtures);

  @override
  Future<PageResult<TicketCustomer>> searchCustomers(String term, int page) =>
      _backend.run('Ticket customers', () {
        final graph = _backend.graph;
        final rows = [
          for (final company in graph.companies) customerRow(graph, company),
        ].where((row) => fakeMatches(row, term, ['Name', 'Area', 'AreaBn']));
        return PageResult.fromJson(
          fakePage(rows.toList(), page: page),
          TicketCustomer.fromJson,
        );
      }, module: AppModule.support);

  @override
  Future<List<TicketProduct>> products() => _backend.run(
    'Ticket products',
    () => [
      for (final product in _backend.graph.products)
        TicketProduct(id: product.id, name: product.name, code: product.code),
    ],
    module: AppModule.support,
  );

  @override
  Future<Ticket> create(TicketInput input) => _backend.run(
    'Ticket create',
    () {
      final body = input.toJson();
      fakeRequire(body, ['CustomerId', 'Title', 'IssueType', 'Description']);
      final graph = _backend.graph;
      final customer = graph.companies
          .where((c) => c.id == input.customerId)
          .firstOrNull;
      if (customer == null) {
        throw const ApiFailure(
          400,
          'Customer not found.',
          fieldErrors: {'CustomerId': 'Customer not found.'},
        );
      }
      final productId = input.productId;
      final now = DateTime.now();
      final row = ticketRow(
        graph: graph,
        id: _table.nextId(),
        customer: customer,
        title: body['Title'] as String,
        issue: input.issue ?? TicketIssue.other,
        priority: input.priority,
        status: TicketStatus.open,
        openedAt: now,
        source: 'FieldVisit',
        product: productId == null
            ? null
            : graph.products.where((p) => p.id == productId).firstOrNull,
        photos: input.photos,
        messages: [
          ticketMessage(
            body['Description'] as String,
            at: now,
            fromTeam: false,
            author: customer.name,
          ),
        ],
      );
      return _read(_table.insert(row));
    },
    module: AppModule.support,
    right: ModuleRight.add,
    quota: input.photos.isEmpty ? null : QuotaKind.storage,
  );

  @override
  Future<Ticket> get(int id) => _backend.run(
    'Ticket $id',
    () => _read(_table.byId(id)),
    module: AppModule.support,
  );

  @override
  Future<Ticket> setStatus(int id, TicketStatus status) => _backend.run(
    'Ticket $id status',
    () => _read(
      _table.update(id, {
        'Status': status.wire,
        'ResolvedAt': status == TicketStatus.resolved
            ? jsonUtc(DateTime.now())
            : null,
      }),
    ),
    module: AppModule.support,
    right: ModuleRight.edit,
  );

  @override
  Future<Ticket> reply(int id, String text) => _backend.run(
    'Ticket $id reply',
    () {
      fakeRequire({'Text': text}, ['Text']);
      final row = _table.byId(id);
      final messages = [
        ...(row['Messages'] as List? ?? const []),
        ticketMessage(
          text.trim(),
          at: DateTime.now(),
          fromTeam: true,
          author: _backend.graph.me.name,
        ),
      ];
      return _read(_table.update(id, {'Messages': messages}));
    },
    module: AppModule.support,
    right: ModuleRight.edit,
  );

  Ticket _read(Map<String, dynamic> row) {
    final due = jsonDate(row['DueAt']);
    final open = row['Status'] != TicketStatus.resolved.wire;
    return Ticket.fromJson({
      ...row,
      if (open && due != null)
        'SlaMinutesLeft': due.difference(DateTime.now()).inMinutes,
    });
  }
}

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/data/fake_grants.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/data/quotation_repository.dart';
import 'package:salesroot/features/sales/data/sales_fixtures.dart';
import 'package:salesroot/features/sales/data/sales_ledger.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';
import 'package:salesroot/features/sales/models/sales_party.dart';

class FakeQuotationRepository implements QuotationRepository {
  FakeQuotationRepository(FakeBackend backend)
    : _backend = backend,
      _ledger = SalesLedger(backend);

  final FakeBackend _backend;
  final SalesLedger _ledger;

  FakeTable get _table => _ledger.quotations;

  @override
  Future<PageResult<Quotation>> list(QuotationQuery query) =>
      _backend.run('Quotation list', () {
        final matching = _table.rows
            .where(
              (r) => fakeMatches(r, query.search, [
                'Number',
                'CompanyName',
                'ContactName',
              ]),
            )
            .toList();
        final counts = <String, int>{'All': matching.length};
        for (final row in matching) {
          final key = '${row['Status']}';
          counts[key] = (counts[key] ?? 0) + 1;
        }
        final status = query.status;
        final rows = status == null
            ? matching
            : matching.where((r) => r['Status'] == status.wire).toList();
        return PageResult.fromJson(
          fakePage(rows, page: query.page, extra: {'StatusCounts': counts}),
          Quotation.fromJson,
        );
      }, module: AppModule.quotation);

  @override
  Future<Quotation> get(int id) => _backend.run(
    'Quotation $id',
    () => Quotation.fromJson(_table.byId(id)),
    module: AppModule.quotation,
  );

  @override
  Future<Quotation> create(QuotationInput input) => _backend.run(
    'Quotation create',
    () {
      final body = _validated(input);
      final customer = _customerRow(jsonInt(body['CompanyId']) ?? 0);
      final id = _table.nextId();
      final now = DateTime.now();
      final row = _table.insert(
        {
          ...body,
          'Id': id,
          'Number': quotationNumber(id),
          'Version': 1,
          'CompanyName': customer['Name'],
          'ContactId': body['ContactId'] ?? customer['ContactId'],
          'ContactName': customer['ContactName'],
          'ContactPhone': customer['ContactPhone'],
          'LeadId': body['LeadId'] ?? customer['LeadId'],
          'CreatedAt': jsonUtc(now),
          'ViewCount': 0,
          'OwnerId': _backend.meId,
          'OwnerName': _backend.graph.me.name,
          'CanEdit': true,
          ..._sending(body, now),
        }..remove('SendVia'),
      );
      return Quotation.fromJson(row);
    },
    module: AppModule.quotation,
    right: ModuleRight.add,
    quota: QuotaKind.records,
  );

  @override
  Future<Quotation> revise(int id, QuotationInput input) => _backend.run(
    'Quotation $id revise',
    () {
      final current = _table.byId(id);
      if (current['Status'] == QuotationStatus.accepted.wire) {
        throw const ApiFailure(409, 'This quotation is already accepted.');
      }
      final body = _validated(input);
      final now = DateTime.now();
      current
        ..remove('LastViewedAt')
        ..remove('SentVia')
        ..remove('SentAt');
      final row = _table.update(
        id,
        {
          ...body,
          'Version': (jsonInt(current['Version']) ?? 1) + 1,
          'ViewCount': 0,
          'CreatedAt': jsonUtc(now),
          ..._sending(body, now),
        }..remove('SendVia'),
      );
      return Quotation.fromJson(row);
    },
    module: AppModule.quotation,
    right: ModuleRight.edit,
  );

  @override
  Future<Quotation> send(int id, SendChannel channel) => _backend.run(
    'Quotation $id send',
    () {
      final current = _table.byId(id);
      final status = QuotationStatus.fromWire(current['Status'] as String?);
      if (status == QuotationStatus.accepted) {
        throw const ApiFailure(409, 'This quotation is already accepted.');
      }
      return Quotation.fromJson(
        _table.update(id, {
          'Status': status == QuotationStatus.viewed
              ? status.wire
              : QuotationStatus.sent.wire,
          'SentVia': channel.wire,
          'SentAt': jsonUtc(DateTime.now()),
          'CanDelete': false,
        }),
      );
    },
    module: AppModule.quotation,
    right: ModuleRight.edit,
  );

  @override
  Future<Quotation> markAccepted(int id) => _backend.run(
    'Quotation $id accept',
    () => Quotation.fromJson(_accept(id)),
    module: AppModule.quotation,
    right: ModuleRight.edit,
  );

  @override
  Future<Quotation> markRejected(int id) => _backend.run(
    'Quotation $id reject',
    () {
      final current = _table.byId(id);
      if (current['OrderId'] != null) {
        throw const ApiFailure(409, 'An order was already made from this.');
      }
      return Quotation.fromJson(
        _table.update(id, {
          'Status': QuotationStatus.rejected.wire,
          'CanDelete': false,
        }),
      );
    },
    module: AppModule.quotation,
    right: ModuleRight.edit,
  );

  @override
  Future<SalesOrder> convertToOrder(int id) => _backend.run(
    'Quotation $id to order',
    () {
      final quote = _table.byId(id);
      if (quote['OrderId'] != null) {
        throw const ApiFailure(409, 'An order was already made from this.');
      }
      final orderGrant = fakeGrant(_backend.role, AppModule.order);
      if (!ModuleAccess.fromPermission(orderGrant).canAdd) {
        throw const ApiFailure(403, 'You do not have permission to do that.');
      }
      _accept(id);
      final orders = _ledger.orders;
      final orderId = orders.nextId();
      final now = DateTime.now();
      final schedule = PaymentTerms.fromWire(quote['PaymentTerms'] as String?)
          .schedule(
            SalesLedger.totalOf(quote),
            now,
            jsonInt(quote['DeliveryDays']) ?? 14,
          );
      final order = orders.insert({
        'Id': orderId,
        'Number': orderNumber(orderId),
        'QuotationId': id,
        'QuotationNumber': quote['Number'],
        'CompanyId': quote['CompanyId'],
        'CompanyName': quote['CompanyName'],
        'ContactName': quote['ContactName'],
        'ContactPhone': quote['ContactPhone'],
        'Lines': quote['Lines'],
        'DiscountBps': quote['DiscountBps'],
        'VatBps': quote['VatBps'],
        'Status': OrderStatus.confirmed.wire,
        'Instalments': [for (final row in schedule) row.toJson()],
        'CreatedAt': jsonUtc(now),
        'OwnerId': quote['OwnerId'] ?? _backend.meId,
        'OwnerName': quote['OwnerName'] ?? _backend.graph.me.name,
        'CanEdit': true,
      });
      _table.update(id, {'OrderId': orderId, 'OrderNumber': order['Number']});
      return SalesOrder.fromJson(_ledger.orderJson(order));
    },
    module: AppModule.quotation,
    right: ModuleRight.edit,
  );

  @override
  Future<void> delete(int id) => _backend.run(
    'Quotation $id delete',
    () {
      final current = _table.byId(id);
      if (current['Status'] != QuotationStatus.draft.wire) {
        throw const ApiFailure(409, 'Only drafts can be deleted.');
      }
      _table.delete(id);
    },
    module: AppModule.quotation,
    right: ModuleRight.delete,
  );

  @override
  Future<List<SalesCustomer>> customers(String search, int page) =>
      _backend.run('Sales customers', () {
        final rows = _ledger.customers.rows
            .where((r) => fakeMatches(r, search, ['Name', 'ContactName']))
            .toList();
        return PageResult.fromJson(
          fakePage(rows, page: page),
          SalesCustomer.fromJson,
        ).items;
      }, module: AppModule.quotation);

  @override
  Future<SalesCustomer> customer(int companyId) => _backend.run(
    'Sales customer $companyId',
    () => SalesCustomer.fromJson(_customerRow(companyId)),
    module: AppModule.quotation,
  );

  @override
  Future<SalesCustomer> customerForLead(int leadId) =>
      _backend.run('Sales customer for lead $leadId', () {
        final lead = _backend.graph.leads.where((l) => l.id == leadId);
        if (lead.isEmpty) throw const ApiFailure(404, 'Record not found');
        final customer = _customerRow(lead.first.companyId);
        final contact = _backend.graph.contact(lead.first.contactId);
        return SalesCustomer.fromJson({
          ...customer,
          'LeadId': leadId,
          'ContactId': contact.id,
          'ContactName': contact.name,
          'ContactPhone': contact.phone,
        });
      }, module: AppModule.quotation);

  @override
  Future<SellerProfile> seller() => _backend.run(
    'Seller profile',
    () => SellerProfile.fromJson(sellerFixture(_backend.graph)),
  );

  Map<String, dynamic> _customerRow(int companyId) {
    for (final row in _ledger.customers.rows) {
      if (row['CompanyId'] == companyId) return row;
    }
    throw const ApiFailure(
      400,
      'Choose a customer',
      fieldErrors: {'CompanyId': 'Choose a customer'},
    );
  }

  Map<String, dynamic> _validated(QuotationInput input) {
    final body = input.toJson();
    fakeRequire(body, ['CompanyId', 'ValidUntil']);
    final lines = body['Lines'];
    if (lines is! List || lines.isEmpty) {
      throw const ApiFailure(
        400,
        'Add at least one item',
        fieldErrors: {'Lines': 'Add at least one item'},
      );
    }
    final discount = jsonInt(body['DiscountBps']) ?? 0;
    if (discount < 0 || discount > 5000) {
      throw const ApiFailure(
        400,
        'Discount can be at most 50%',
        fieldErrors: {'DiscountBps': 'Discount can be at most 50%'},
      );
    }
    return {...body, 'Note': body['Note'] ?? ''};
  }

  Map<String, dynamic> _sending(Map<String, dynamic> body, DateTime now) {
    final via = body['SendVia'];
    return via == null
        ? {'Status': QuotationStatus.draft.wire, 'CanDelete': true}
        : {
            'Status': QuotationStatus.sent.wire,
            'SentVia': via,
            'SentAt': jsonUtc(now),
            'CanDelete': false,
          };
  }

  Map<String, dynamic> _accept(int id) {
    final current = _table.byId(id);
    final status = QuotationStatus.fromWire(current['Status'] as String?);
    if (status == QuotationStatus.expired) {
      throw const ApiFailure(409, 'This quotation has expired.');
    }
    return _table.update(id, {
      'Status': QuotationStatus.accepted.wire,
      'CanEdit': false,
      'CanDelete': false,
    });
  }
}

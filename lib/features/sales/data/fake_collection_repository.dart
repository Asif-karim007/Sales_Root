import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/data/collection_repository.dart';
import 'package:salesroot/features/sales/data/sales_ledger.dart';
import 'package:salesroot/features/sales/models/collection.dart';
import 'package:salesroot/features/sales/models/outstanding.dart';

class FakeCollectionRepository implements CollectionRepository {
  FakeCollectionRepository(FakeBackend backend)
    : _backend = backend,
      _ledger = SalesLedger(backend);

  final FakeBackend _backend;
  final SalesLedger _ledger;

  FakeTable get _table => _ledger.collections;

  @override
  Future<CollectionSummary> summary() => _backend.run('Collection summary', () {
    final today = _ledger.today;
    var collectedToday = 0;
    var collectedYesterday = 0;
    var collectedThisMonth = 0;
    final byMethod = <PaymentMethod, int>{};
    for (final row in _table.rows) {
      final days = _ledger.daysSince(jsonDate(row['CollectedAt']));
      final at = jsonDate(row['CollectedAt']);
      final amount = jsonInt(row['Amount']) ?? 0;
      if (days == 0) {
        collectedToday += amount;
        final method = PaymentMethod.fromWire(row['Method'] as String?);
        byMethod[method] = (byMethod[method] ?? 0) + amount;
      }
      if (days == 1) collectedYesterday += amount;
      if (at != null && at.year == today.year && at.month == today.month) {
        collectedThisMonth += amount;
      }
    }
    final summary = _outstanding();
    var dueToday = 0;
    final dueTodayCustomers = <Object?>{};
    for (final row in _ledger.openInstalments()) {
      if (row['DaysOverdue'] != 0) continue;
      dueToday += _dueOf(row);
      dueTodayCustomers.add(row['CompanyId']);
    }
    return CollectionSummary.fromJson({
      'CollectedToday': collectedToday,
      'CollectedYesterday': collectedYesterday,
      'CollectedThisMonth': collectedThisMonth,
      'TodayCash': byMethod[PaymentMethod.cash] ?? 0,
      'TodayMobile':
          (byMethod[PaymentMethod.bkash] ?? 0) +
          (byMethod[PaymentMethod.nagad] ?? 0),
      'TodayBank':
          (byMethod[PaymentMethod.bank] ?? 0) +
          (byMethod[PaymentMethod.cheque] ?? 0),
      'Receivable': summary['Total'],
      'Overdue': summary['Overdue'],
      'DueToday': dueToday,
      'DueTodayCustomers': dueTodayCustomers.length,
    });
  }, module: AppModule.collection);

  @override
  Future<PageResult<DueRow>> dues(int page) => _backend.run('Dues', () {
    final rows =
        _ledger
            .openInstalments()
            .where((r) => (jsonInt(r['DaysOverdue']) ?? 0) >= -30)
            .toList()
          ..sort(
            (a, b) =>
                (jsonInt(b['DaysOverdue']) ?? 0) -
                (jsonInt(a['DaysOverdue']) ?? 0),
          );
    return PageResult.fromJson(fakePage(rows, page: page), DueRow.fromJson);
  }, module: AppModule.collection);

  @override
  Future<PageResult<Collection>> list(int page) => _backend.run(
    'Collection list',
    () => PageResult.fromJson(
      fakePage(_table.rows, page: page),
      Collection.fromJson,
    ),
    module: AppModule.collection,
  );

  @override
  Future<Collection> get(int id) => _backend.run(
    'Collection $id',
    () => _withBalance(_table.byId(id)),
    module: AppModule.collection,
  );

  @override
  Future<CustomerDues> customerDues(int companyId) =>
      _backend.run('Customer $companyId dues', () {
        final customer = _ledger.customers.rows.where(
          (r) => r['CompanyId'] == companyId,
        );
        if (customer.isEmpty) throw const ApiFailure(404, 'Record not found');
        final items = _ledger.openInstalments(companyId: companyId)
          ..sort((a, b) => '${a['DueDate']}'.compareTo('${b['DueDate']}'));
        return CustomerDues.fromJson({
          'CompanyId': companyId,
          'CompanyName': customer.first['Name'],
          'ContactName': customer.first['ContactName'],
          'ContactPhone': customer.first['ContactPhone'],
          'Items': items,
        });
      }, module: AppModule.collection);

  @override
  Future<Collection> record(CollectionInput input) => _backend.run(
    'Collection record',
    () {
      final body = input.toJson();
      fakeRequire(body, ['CompanyId', 'Method', 'CollectedAt']);
      final amount = jsonInt(body['Amount']) ?? 0;
      if (amount <= 0) {
        throw const ApiFailure(
          400,
          'Enter the amount',
          fieldErrors: {'Amount': 'Enter the amount'},
        );
      }
      _requireMethodFields(input.method, body);
      final companyId = jsonInt(body['CompanyId']) ?? 0;
      final open = {
        for (final row in _ledger.openInstalments(companyId: companyId))
          '${row['OrderId']}/${row['Seq']}': row,
      };
      var allocated = 0;
      final allocations = <Map<String, dynamic>>[];
      for (final allocation in input.allocations) {
        final row = open['${allocation.orderId}/${allocation.seq}'];
        if (row == null || allocation.amount > _dueOf(row)) {
          throw const ApiFailure(
            400,
            'That is more than what is due on the instalment',
            fieldErrors: {'Allocations': 'over'},
          );
        }
        allocated += allocation.amount;
        allocations.add(
          {
            'OrderId': allocation.orderId,
            'OrderNumber': row['OrderNumber'],
            'InvoiceId': row['InvoiceId'],
            'InvoiceNumber': row['InvoiceNumber'],
            'Seq': allocation.seq,
            'Kind': row['Kind'],
            'Amount': allocation.amount,
          }..removeWhere((_, value) => value == null),
        );
      }
      if (allocated != amount) {
        throw const ApiFailure(
          400,
          'Apply the whole amount to dues',
          fieldErrors: {'Allocations': 'unallocated'},
        );
      }
      final customer = _ledger.customers.rows.firstWhere(
        (r) => r['CompanyId'] == companyId,
      );
      final id = _table.nextId();
      final me = _backend.graph.me;
      final row = _table.insert(
        {
          ...body,
          'Id': id,
          'Number': receiptNumber(id),
          'CompanyName': customer['Name'],
          'HasPhoto': body['Photo'] != null,
          'Allocations': allocations,
          'ReceivedById': me.id,
          'ReceivedByName': me.name,
          'ReceivedByNameBn': me.nameBn,
          'SmsSent': customer['ContactPhone'] != null,
        }..remove('Photo'),
      );
      return _withBalance(row);
    },
    module: AppModule.collection,
    right: ModuleRight.add,
    quota: QuotaKind.records,
  );

  @override
  Future<OutstandingSummary> outstandingSummary() => _backend.run(
    'Outstanding summary',
    () => OutstandingSummary.fromJson(_outstanding()),
    module: AppModule.collection,
  );

  @override
  Future<PageResult<CustomerOutstanding>> outstanding(
    OutstandingFilter filter, {
    String search = '',
    int page = 1,
  }) => _backend.run('Outstanding list', () {
    final rows = [
      for (final row in _customerRows())
        if (fakeMatches(row, search, ['CompanyName']) &&
            switch (filter) {
              OutstandingFilter.overdue => row['Overdue'] == true,
              OutstandingFilter.mine => row['Mine'] == true,
              _ => true,
            })
          row,
    ];
    if (filter == OutstandingFilter.byCustomer) {
      rows.sort(
        (a, b) => '${a['CompanyName']}'.compareTo('${b['CompanyName']}'),
      );
    }
    return PageResult.fromJson(
      fakePage(rows, page: page),
      CustomerOutstanding.fromJson,
    );
  }, module: AppModule.collection);

  Collection _withBalance(Map<String, dynamic> row) => Collection.fromJson({
    ...row,
    'BalanceDue': _ledger.balanceOf(jsonInt(row['CompanyId']) ?? 0),
  });

  static int _dueOf(Map<String, dynamic> row) =>
      (jsonInt(row['Amount']) ?? 0) - (jsonInt(row['Paid']) ?? 0);

  void _requireMethodFields(PaymentMethod method, Map<String, dynamic> body) {
    final fields = switch (method) {
      PaymentMethod.cash => const <String>[],
      PaymentMethod.bkash || PaymentMethod.nagad => ['Reference'],
      PaymentMethod.bank => ['BankName'],
      PaymentMethod.cheque => ['BankName', 'ChequeNumber', 'ChequeDate'],
    };
    fakeRequire(body, fields);
  }

  /// One row per customer with unpaid bills: what is due, how old the oldest
  /// bill is, and the next instalment date. Sorted by amount due.
  List<Map<String, dynamic>> _customerRows() {
    final paid = _ledger.paidByInstalment();
    final open = _ledger.openInstalments();
    final byCustomer = <int, Map<String, dynamic>>{};
    for (final invoice in _ledger.invoices.rows) {
      final due = _ledger.invoiceDue(invoice, paid);
      if (due <= 0) continue;
      final companyId = jsonInt(invoice['CompanyId']) ?? 0;
      final age = _ledger.daysSince(jsonDate(invoice['IssuedAt']));
      final row = byCustomer.putIfAbsent(
        companyId,
        () => {
          'CompanyId': companyId,
          'CompanyName': invoice['CompanyName'],
          'Bills': 0,
          'OldestDays': 0,
          'Due': 0,
          'Overdue': false,
          'Mine': false,
          'InstalmentsLeft': 0,
        },
      );
      row['Bills'] = (row['Bills'] as int) + 1;
      row['Due'] = (row['Due'] as int) + due;
      if (age > (row['OldestDays'] as int)) row['OldestDays'] = age;
      if (invoice['OwnerId'] == _backend.meId) row['Mine'] = true;
    }
    for (final instalment in open) {
      final row = byCustomer[jsonInt(instalment['CompanyId'])];
      if (row == null || instalment['InvoiceId'] == null) continue;
      row['InstalmentsLeft'] = (row['InstalmentsLeft'] as int) + 1;
      if ((jsonInt(instalment['DaysOverdue']) ?? 0) > 0) row['Overdue'] = true;
      final next = '${instalment['DueDate']}';
      final current = row['NextDueDate'] as String?;
      if (current == null || next.compareTo(current) < 0) {
        row['NextDueDate'] = next;
        row['NextOrderNumber'] = instalment['OrderNumber'];
      }
    }
    return byCustomer.values.toList()
      ..sort((a, b) => (b['Due'] as int) - (a['Due'] as int));
  }

  Map<String, dynamic> _outstanding() {
    final paid = _ledger.paidByInstalment();
    final dues = <(int, int)>[];
    for (final invoice in _ledger.invoices.rows) {
      final due = _ledger.invoiceDue(invoice, paid);
      if (due <= 0) continue;
      dues.add((_ledger.daysSince(jsonDate(invoice['IssuedAt'])), due));
    }
    var overdue = 0;
    for (final row in _ledger.openInstalments()) {
      if (row['InvoiceId'] == null) continue;
      if ((jsonInt(row['DaysOverdue']) ?? 0) > 0) overdue += _dueOf(row);
    }
    final customers = _customerRows();
    return {
      'Total': dues.fold<int>(0, (sum, d) => sum + d.$2),
      'Overdue': overdue,
      'CustomerCount': customers.length,
      'Aging': {
        for (final entry in agingOf(dues).entries) entry.key.wire: entry.value,
      },
    };
  }
}

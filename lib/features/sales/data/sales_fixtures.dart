import 'dart:math';

import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/data/product_fixtures.dart';
import 'package:salesroot/features/sales/models/collection.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/models/sales_line.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';

List<Map<String, dynamic>> customerFixtures(SeedGraph graph) => [
  for (final company in graph.companies) _customer(graph, company),
];

List<Map<String, dynamic>> quotationFixtures(SeedGraph graph) =>
    _SalesSeed.of(graph).quotations;

List<Map<String, dynamic>> orderFixtures(SeedGraph graph) =>
    _SalesSeed.of(graph).orders;

List<Map<String, dynamic>> invoiceFixtures(SeedGraph graph) =>
    _SalesSeed.of(graph).invoices;

List<Map<String, dynamic>> collectionFixtures(SeedGraph graph) =>
    _SalesSeed.of(graph).collections;

/// The business that issues the documents in this workspace.
Map<String, dynamic> sellerFixture(SeedGraph graph) => {
  'Name': switch (graph.workspaceId) {
    100 => 'Karim Solar Solutions',
    200 => 'Dhaka Sales Ltd.',
    300 => 'Nexzen Partners Ltd.',
    _ => '${graph.me.name} Solar',
  },
  'Address': 'House 14, Road 7, Sector 4, Uttara, Dhaka 1230',
  'Phone': '+8801711000000',
  'TaxInvoices': false,
};

/// Every third company buys at the dealer price list.
String priceListOf(int companyId) => companyId % 3 == 1 ? 'Dealer' : 'List';

Map<String, dynamic> _customer(SeedGraph graph, SeedCompany company) {
  final contacts = graph.contactsOf(company.id);
  final contact = contacts.firstWhere(
    (c) => c.isPrimary,
    orElse: () => contacts.first,
  );
  final leads = graph.leads.where((l) => l.companyId == company.id && l.isOpen);
  return {
    'CompanyId': company.id,
    'Name': company.name,
    'ContactId': contact.id,
    'ContactName': contact.name,
    'ContactPhone': contact.phone,
    'PriceList': priceListOf(company.id),
    'LeadId': leads.isEmpty ? null : leads.first.id,
    'Area': company.area.name,
  }..removeWhere((_, value) => value == null);
}

/// Quotations for the leads at the Quotation and Won stages, the orders the
/// won ones became, their bills and what has been collected on them. Built
/// once per graph so the four tables agree.
class _SalesSeed {
  _SalesSeed(this.graph) : _random = graph.random('sales');

  final SeedGraph graph;
  final Random _random;

  final quotations = <Map<String, dynamic>>[];
  final orders = <Map<String, dynamic>>[];
  final invoices = <Map<String, dynamic>>[];
  final collections = <Map<String, dynamic>>[];

  static final _cache = Expando<_SalesSeed>();

  static _SalesSeed of(SeedGraph graph) =>
      _cache[graph] ??= (_SalesSeed(graph).._build());

  DateTime get _today => graph.daysAgo(0, hour: 0);

  void _build() {
    final leads = graph.leads.where((l) => l.stageId == 4 || l.stageId == 5);
    final drafts = [for (final lead in leads) _draft(lead)]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (var i = 0; i < drafts.length; i++) {
      final draft = drafts[i]..id = i + 1;
      quotations.add(draft.toJson());
    }
    final won = drafts
        .where((d) => d.status == QuotationStatus.accepted)
        .toList();
    for (var i = 0; i < won.length; i++) {
      final fromEnd = won.length - 1 - i;
      _order(won[i], i + 1, fromEnd < _recent.length ? _recent[fromEnd] : null);
    }
    _numberCollections();
    quotations.sort(_newestFirst);
    orders.sort(_newestFirst);
    invoices.sort((a, b) => '${b['IssuedAt']}'.compareTo('${a['IssuedAt']}'));
    collections.sort(
      (a, b) => '${b['CollectedAt']}'.compareTo('${a['CollectedAt']}'),
    );
  }

  static int _newestFirst(Map<String, dynamic> a, Map<String, dynamic> b) =>
      '${b['CreatedAt']}'.compareTo('${a['CreatedAt']}');

  /// The newest orders, placed so every order status is on show: days ago
  /// and status.
  static const _recent = [
    (1, OrderStatus.confirmed),
    (3, OrderStatus.confirmed),
    (6, OrderStatus.inProgress),
    (8, OrderStatus.inProgress),
    (14, OrderStatus.delivered),
  ];

  static const _awaitingCycle = [
    QuotationStatus.sent,
    QuotationStatus.viewed,
    QuotationStatus.sent,
    QuotationStatus.draft,
    QuotationStatus.viewed,
    QuotationStatus.expired,
    QuotationStatus.sent,
    QuotationStatus.rejected,
    QuotationStatus.viewed,
    QuotationStatus.sent,
  ];

  static const _notes = [
    '25-year panel warranty; net-metering application আমরা করব।',
    'দাম ১৫ দিনের জন্য প্রযোজ্য। Installation within 7 days of advance.',
    'Transport inside Dhaka included. ব্যাটারিতে ২ বছরের ওয়ারেন্টি।',
    'Site survey done on visit; structure as per roof drawing.',
    'Inverter warranty 5 years, panel performance warranty 25 years.',
    '',
  ];

  _QuoteDraft _draft(SeedLead lead) {
    final won = lead.stageId == 5;
    final status = won
        ? QuotationStatus.accepted
        : _awaitingCycle[lead.id % _awaitingCycle.length];
    final age = switch (status) {
      QuotationStatus.accepted => 8 + _random.nextInt(130),
      QuotationStatus.expired => 35 + _random.nextInt(30),
      QuotationStatus.rejected => 6 + _random.nextInt(25),
      QuotationStatus.draft => _random.nextInt(3),
      _ => _random.nextInt(12),
    };
    final createdAt = graph.daysAgo(
      age,
      hour: 9 + _random.nextInt(9),
      minute: _random.nextInt(60),
    );
    final company = graph.company(lead.companyId);
    final contact = graph.contact(lead.contactId);
    final priceList = priceListOf(company.id);
    final validity = status == QuotationStatus.expired ? 15 : 30;
    final viewed = status == QuotationStatus.viewed || won;
    return _QuoteDraft(
      lead: lead,
      company: company,
      contact: contact,
      owner: graph.member(lead.ownerId),
      priceList: priceList,
      lines: _linesFor(lead, priceList),
      discountBps: const [0, 0, 300, 500, 500, 750, 1000][_random.nextInt(7)],
      paymentTerms:
          PaymentTerms.values[_random.nextInt(PaymentTerms.values.length)],
      deliveryDays: const [7, 14, 14, 21, 30][_random.nextInt(5)],
      note: _notes[_random.nextInt(_notes.length)],
      status: status,
      version: _random.nextInt(5) == 0 ? 2 : 1,
      createdAt: createdAt,
      validUntil: createdAt.add(Duration(days: validity)),
      sentVia: status == QuotationStatus.draft
          ? null
          : SendChannel.values[_random.nextInt(3)],
      viewCount: viewed ? 1 + _random.nextInt(4) : 0,
      lastViewedAt: viewed
          ? createdAt.add(Duration(hours: 2 + _random.nextInt(40)))
          : null,
    );
  }

  List<SalesLine> _linesFor(SeedLead lead, String priceList) {
    final title = lead.title;
    final kind = title.contains('rooftop')
        ? 0
        : title.contains('backup')
        ? 1
        : title.contains('factory')
        ? 2
        : title.contains('maintenance')
        ? 3
        : title.contains('battery')
        ? 4
        : _random.nextInt(7);
    final lines = <(String, int)>[];
    switch (kind) {
      case 0 || 5:
        final panels = const [6, 8, 10, 12, 16, 20][_random.nextInt(6)];
        final kw = (panels * 550 / 1000).round();
        lines.addAll([
          ('SP-550', panels),
          (
            kw <= 3
                ? 'IV-3K'
                : kw <= 5
                ? 'IV-5K'
                : kw <= 8
                ? 'IV-8K'
                : 'IV-10K',
            1,
          ),
          ('MS-R', kw),
          ('SV-INS', kw),
          if (_random.nextBool()) ('SV-NM', 1),
        ]);
      case 1:
        final sets = 1 + _random.nextInt(3);
        lines.addAll([('IV-1K', sets), ('BT-200', sets * 2), ('EA-1', 1)]);
      case 2:
        lines.addAll([
          ('KT-10', 1 + _random.nextInt(2)),
          ('SV-NM', 1),
          ('SV-TRN', 1),
        ]);
      case 3:
        lines.addAll([
          ('SV-AMC', 1),
          ('SV-CLN', 4),
          if (_random.nextBool()) ('EM-1', 1),
        ]);
      case 4:
        lines.addAll([
          (_random.nextBool() ? 'BT-5' : 'BT-10', 1 + _random.nextInt(2)),
          ('BT-RK', 1),
          ('WF-1', 1),
        ]);
      default:
        lines.addAll(
          _random.nextBool()
              ? [('SL-60', 10 + _random.nextInt(20)), ('SV-SUR', 1)]
              : [
                  (_random.nextBool() ? 'PM-1' : 'PM-2', 1),
                  ('SP-450', 4 + _random.nextInt(5)),
                  ('MS-G', 3),
                  ('CC-60', 1),
                ],
        );
    }
    final dealer = priceList == 'Dealer';
    return [
      for (var i = 0; i < lines.length; i++)
        _line(
          lines[i].$1,
          lines[i].$2,
          dealer: dealer,
          discountBps: i == 0 && _random.nextInt(4) == 0 ? 300 : 0,
        ),
    ];
  }

  SalesLine _line(
    String code,
    int qty, {
    required bool dealer,
    int discountBps = 0,
  }) {
    final product = graph.products.firstWhere((p) => p.code == code);
    return SalesLine(
      productId: product.id,
      code: product.code,
      name: product.name,
      nameBn: productNameBn(product.code),
      unit: product.unit,
      qty: qty,
      unitPrice: dealer ? product.dealerPrice : product.price,
      discountBps: discountBps,
    );
  }

  void _order(_QuoteDraft quote, int id, (int, OrderStatus)? placed) {
    final quoteId = quote.id;
    final createdAt = placed == null
        ? _notAfterToday(
            quote.createdAt.add(
              Duration(days: 1 + _random.nextInt(4), hours: 2),
            ),
          )
        : graph.daysAgo(placed.$1, hour: 11);
    final age = _today.difference(_dateOnly(createdAt)).inDays;
    final status =
        placed?.$2 ??
        (age < 4
            ? OrderStatus.confirmed
            : age < 10
            ? OrderStatus.inProgress
            : _random.nextInt(5) == 0
            ? OrderStatus.delivered
            : OrderStatus.invoiced);
    final totals = computeTotals(
      quote.lines,
      discountBps: quote.discountBps,
      vatBps: standardVatBps,
    );
    final schedule = quote.paymentTerms.schedule(
      totals.total,
      createdAt,
      quote.deliveryDays,
    );
    final number = orderNumber(id);
    final delivered =
        status == OrderStatus.delivered || status == OrderStatus.invoiced;
    final deliveredAt = _notAfterToday(
      createdAt.add(Duration(days: min(quote.deliveryDays, age - 1))),
    );
    int? invoiceId;
    String? invoice;
    if (status == OrderStatus.invoiced) {
      invoiceId = invoices.length + 1;
      invoice = invoiceNumber(deliveredAt.year, 900 + invoiceId);
      invoices.add({
        'Id': invoiceId,
        'Number': invoice,
        'OrderId': id,
        'OrderNumber': number,
        'CompanyId': quote.company.id,
        'CompanyName': quote.company.name,
        'ContactName': quote.contact.name,
        'ContactPhone': quote.contact.phone,
        'Lines': [for (final line in quote.lines) line.toJson()],
        'DiscountBps': quote.discountBps,
        'VatBps': standardVatBps,
        'IssuedAt': jsonUtc(deliveredAt),
        'OwnerId': quote.owner.id,
      });
    }
    orders.add(
      {
        'Id': id,
        'Number': number,
        'QuotationId': quoteId,
        'QuotationNumber': quotationNumber(quoteId),
        'CompanyId': quote.company.id,
        'CompanyName': quote.company.name,
        'ContactName': quote.contact.name,
        'ContactPhone': quote.contact.phone,
        'Lines': [for (final line in quote.lines) line.toJson()],
        'DiscountBps': quote.discountBps,
        'VatBps': standardVatBps,
        'Status': status.wire,
        'Instalments': [for (final row in schedule) row.toJson()],
        'CreatedAt': jsonUtc(createdAt),
        'InvoiceId': invoiceId,
        'InvoiceNumber': invoice,
        'Delivery': delivered
            ? {
                'DeliveredAt': jsonUtc(deliveredAt),
                'ReceivedBy': quote.contact.name,
                'Note': 'সব ঠিক আছে; installation complete.',
                'DeliveredProductIds': [
                  for (final line in quote.lines) line.productId,
                ],
                'PhotoCount': 1 + _random.nextInt(3),
                'Signed': true,
              }
            : null,
        'OwnerId': quote.owner.id,
        'OwnerName': quote.owner.name,
        'CanEdit': true,
      }..removeWhere((_, value) => value == null),
    );
    final quoteRow = quotations.firstWhere((q) => q['Id'] == quoteId);
    quoteRow['OrderId'] = id;
    quoteRow['OrderNumber'] = number;
    _collect(quote, id, number, invoiceId, invoice, schedule);
  }

  /// Pays the order's instalments the way the customer tends to: most pay
  /// the advance, good payers keep up, slow ones pay part late, a few stop.
  void _collect(
    _QuoteDraft quote,
    int orderId,
    String orderNo,
    int? invoiceId,
    String? invoice,
    List<Instalment> schedule,
  ) {
    final profile = _random.nextInt(10);
    for (final row in schedule) {
      final due = _dateOnly(row.dueDate);
      if (due.isAfter(_today)) continue;
      final isAdvance = row.kind == InstalmentKind.advance;
      if (!isAdvance && invoiceId == null) continue;
      int amount;
      DateTime when;
      if (isAdvance) {
        if (profile >= 8) continue;
        amount = row.amount;
        when = row.dueDate;
      } else if (profile < 6) {
        amount = row.amount;
        final late = due.add(Duration(days: _random.nextInt(6)));
        if (late.isAfter(_today) && _random.nextInt(5) < 2) continue;
        when = late.isAfter(_today) ? _today : late;
      } else if (profile < 8 && _random.nextBool()) {
        amount = max(1000, roundDiv(row.amount, 2000) * 1000);
        final late = due.add(Duration(days: 10 + _random.nextInt(15)));
        if (late.isAfter(_today)) continue;
        when = late;
      } else {
        continue;
      }
      _addCollection(
        quote,
        Allocation(
          orderId: orderId,
          orderNumber: orderNo,
          invoiceId: isAdvance ? null : invoiceId,
          invoiceNumber: isAdvance ? null : invoice,
          seq: row.seq,
          kind: row.kind,
          amount: amount,
        ),
        DateTime(
          when.year,
          when.month,
          when.day,
          9 + _random.nextInt(9),
          _random.nextInt(60),
        ),
      );
    }
  }

  void _addCollection(_QuoteDraft quote, Allocation allocation, DateTime at) {
    final method = PaymentMethod
        .values[const [0, 0, 0, 1, 1, 1, 2, 3, 3, 4][_random.nextInt(10)]];
    final collector = graph.member(quote.owner.id);
    collections.add(
      {
        'CompanyId': quote.company.id,
        'CompanyName': quote.company.name,
        'Amount': allocation.amount,
        'Method': method.wire,
        'Reference': switch (method) {
          PaymentMethod.cash => null,
          PaymentMethod.bkash || PaymentMethod.nagad => _trxId(),
          PaymentMethod.bank => 'NPSB${100000 + _random.nextInt(899999)}',
          PaymentMethod.cheque => null,
        },
        'SenderNumber': method.isMobile ? quote.contact.phone : null,
        'BankName': method.needsBank
            ? const [
                'Dutch-Bangla Bank',
                'BRAC Bank',
                'City Bank',
                'Islami Bank',
                'Eastern Bank',
              ][_random.nextInt(5)]
            : null,
        'ChequeNumber': method == PaymentMethod.cheque
            ? '${4000000 + _random.nextInt(999999)}'
            : null,
        'ChequeDate': method == PaymentMethod.cheque ? jsonUtc(at) : null,
        'CollectedAt': jsonUtc(at),
        'HasPhoto': method == PaymentMethod.cheque,
        'Allocations': [
          {
            'OrderId': allocation.orderId,
            'OrderNumber': allocation.orderNumber,
            'InvoiceId': allocation.invoiceId,
            'InvoiceNumber': allocation.invoiceNumber,
            'Seq': allocation.seq,
            'Kind': allocation.kind.wire,
            'Amount': allocation.amount,
          }..removeWhere((_, value) => value == null),
        ],
        'ReceivedById': collector.id,
        'ReceivedByName': collector.name,
        'ReceivedByNameBn': collector.nameBn,
        'SmsSent': true,
      }..removeWhere((_, value) => value == null),
    );
  }

  void _numberCollections() {
    collections.sort(
      (a, b) => '${a['CollectedAt']}'.compareTo('${b['CollectedAt']}'),
    );
    for (var i = 0; i < collections.length; i++) {
      collections[i]['Id'] = i + 1;
      collections[i]['Number'] = receiptNumber(i + 1);
    }
  }

  String _trxId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ0123456789';
    return [
      for (var i = 0; i < 10; i++) chars[_random.nextInt(chars.length)],
    ].join();
  }

  DateTime _notAfterToday(DateTime date) {
    final now = graph.anchor;
    return date.isAfter(now) ? now : date;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

class _QuoteDraft {
  _QuoteDraft({
    required this.lead,
    required this.company,
    required this.contact,
    required this.owner,
    required this.priceList,
    required this.lines,
    required this.discountBps,
    required this.paymentTerms,
    required this.deliveryDays,
    required this.note,
    required this.status,
    required this.version,
    required this.createdAt,
    required this.validUntil,
    required this.sentVia,
    required this.viewCount,
    required this.lastViewedAt,
  });

  final SeedLead lead;
  final SeedCompany company;
  final SeedContact contact;
  final SeedMember owner;
  final String priceList;
  final List<SalesLine> lines;
  final int discountBps;
  final PaymentTerms paymentTerms;
  final int deliveryDays;
  final String note;
  final QuotationStatus status;
  final int version;
  final DateTime createdAt;
  final DateTime validUntil;
  final SendChannel? sentVia;
  final int viewCount;
  final DateTime? lastViewedAt;
  int id = 0;

  Map<String, dynamic> toJson() => {
    'Id': id,
    'Number': quotationNumber(id),
    'Version': version,
    'LeadId': lead.id,
    'CompanyId': company.id,
    'CompanyName': company.name,
    'ContactId': contact.id,
    'ContactName': contact.name,
    'ContactPhone': contact.phone,
    'PriceList': priceList,
    'Lines': [for (final line in lines) line.toJson()],
    'DiscountBps': discountBps,
    'VatBps': standardVatBps,
    'ValidUntil': jsonUtc(validUntil),
    'PaymentTerms': paymentTerms.wire,
    'DeliveryDays': deliveryDays,
    'Note': note,
    'Status': status.wire,
    'SentVia': sentVia?.wire,
    'CreatedAt': jsonUtc(createdAt),
    'SentAt': sentVia == null ? null : jsonUtc(createdAt),
    'ViewCount': viewCount,
    'LastViewedAt': jsonUtc(lastViewedAt),
    'OwnerId': owner.id,
    'OwnerName': owner.name,
    'CanEdit': status != QuotationStatus.accepted,
    'CanDelete': status == QuotationStatus.draft,
  }..removeWhere((_, value) => value == null);
}

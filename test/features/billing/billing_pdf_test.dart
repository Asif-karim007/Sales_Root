import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/billing/data/billing_fixtures.dart';
import 'package:salesroot/features/billing/models/invoice.dart';
import 'package:salesroot/features/billing/pdf/billing_pdf.dart';
import 'package:salesroot/features/billing/pdf/referral_card_pdf.dart';

void main() {
  testWidgets('invoices and the QR card render as PDFs in Anek Bangla', (
    tester,
  ) async {
    final graph = SeedGraph.build(
      workspaceId: 200,
      kind: WorkspaceKind.team,
      memberCount: 21,
      leadCount: 0,
    );
    final invoices = [
      for (final row in invoiceFixtures(graph).take(3)) Invoice.fromJson(row),
    ];
    final text = InvoicePdfText(
      brand: 'SalesRoot',
      title: 'ইনভয়েস',
      billedTo: 'বিল যার নামে',
      workspace: 'Dhaka Sales',
      date: (invoice) => invoice.number,
      status: (invoice) => invoice.status.wire,
      method: (invoice) => invoice.method?.kind.wire ?? '',
      item: 'বিবরণ',
      amount: 'টাকা',
      credits: 'রেফারেল ক্রেডিট',
      vat: (invoice) => 'ভ্যাট ৫%',
      total: 'মোট',
      thanks: 'ধন্যবাদ',
    );

    final (receipts, card) =
        await tester.runAsync(
          () async => (
            await buildInvoicesPdf(
              invoices: invoices,
              text: text,
              lineLabel: (line) => line.name.bn,
              money: (amount) => '৳ $amount',
            ),
            await buildReferralCardPdf(
              brand: 'SalesRoot',
              code: 'KH7R2M',
              link: 'https://q.salesrootcrm.com/r/KH7R2M',
              body: 'স্ক্যান করুন, রেজিস্টার করুন — দুজনেই পান ৳ ১০',
              tip: 'দোকানের কাউন্টারে দেখান',
            ),
          ),
        ) ??
        (null, null);

    for (final bytes in [receipts, card]) {
      expect(bytes, isNotNull);
      expect(String.fromCharCodes(bytes?.take(5) ?? const []), '%PDF-');
    }
    expect(receipts?.length, greaterThan(card?.length ?? 0));
  });
}

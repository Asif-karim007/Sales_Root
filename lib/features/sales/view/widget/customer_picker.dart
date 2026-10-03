import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/sales/data/sales_repositories.dart';
import 'package:salesroot/features/sales/models/outstanding.dart';
import 'package:salesroot/features/sales/models/sales_party.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Searches the customers a quotation can go to.
Future<SalesCustomer?> pickSalesCustomer(BuildContext context, WidgetRef ref) {
  final repository = ref.read(quotationRepositoryProvider);
  final l10n = context.l10n;
  return showSrSheet<SalesCustomer>(
    context: context,
    builder: (_) => SrSearchSheet<SalesCustomer>(
      title: l10n.salesPickCustomer,
      searchHint: l10n.salesSearchCustomer,
      search: repository.customers,
      labelOf: (c) => c.name,
      subtitleOf: (c) => '${c.contactName} · ${l10n.priceList(c.priceList)}',
      isSelected: (_) => false,
      withAvatar: true,
    ),
  );
}

/// Searches the customers who owe money, for a collection.
Future<CustomerOutstanding?> pickDebtor(BuildContext context, WidgetRef ref) {
  final repository = ref.read(collectionRepositoryProvider);
  final l10n = context.l10n;
  final fmt = context.fmt;
  return showSrSheet<CustomerOutstanding>(
    context: context,
    builder: (_) => SrSearchSheet<CustomerOutstanding>(
      title: l10n.salesPickCustomer,
      searchHint: l10n.salesSearchCustomer,
      search: (term, page) async => (await repository.outstanding(
        OutstandingFilter.byCustomer,
        search: term,
        page: page,
      )).items,
      labelOf: (c) => c.companyName,
      subtitleOf: (c) => l10n.salesDueAmountLabel(fmt.money(c.due)),
      isSelected: (_) => false,
      withAvatar: true,
    ),
  );
}

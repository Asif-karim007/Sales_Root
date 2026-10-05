import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/contacts/models/company.dart';
import 'package:salesroot/features/contacts/providers/companies_providers.dart';
import 'package:salesroot/features/contacts/view/widget/contact_rows.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_feedback.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_header.dart';
import 'package:salesroot/features/contacts/view/widget/paged_scroll_view.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #46: the companies the team sells to, with a customers filter.
class CompaniesScreen extends ConsumerStatefulWidget {
  const CompaniesScreen({super.key});

  @override
  ConsumerState<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends ConsumerState<CompaniesScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String term) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => ref.read(companiesFilterProvider.notifier).search(term),
    );
  }

  void _clearFilters() {
    _search.clear();
    ref.read(companiesFilterProvider.notifier)
      ..search('')
      ..customersOnly(false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final list = ref.watch(companiesListProvider);
    final notifier = ref.read(companiesListProvider.notifier);
    final filter = ref.watch(companiesFilterProvider);
    final canAdd = ref.watch(moduleAccessProvider(AppModule.company)).canAdd;
    final total = ref.watch(companyCountsProvider).value?.all;

    return SrScaffold(
      appBar: ContactsHeader(
        title: l10n.contactsCompaniesTitle,
        subtitle: total == null
            ? null
            : l10n.contactsCompanyCount(total, fmt.number(total)),
        companies: true,
        onAdd: canAdd ? () => context.push(Routes.companyNew) : null,
      ),
      body: SrKeyboardDismiss(
        child: PagedScrollView<Company>(
          value: list,
          onLoadMore: notifier.loadMore,
          onRefresh: notifier.refresh,
          onRetry: () => ref.invalidate(companiesListProvider),
          onUpgrade: () => context.push(upgradeRoute(QuotaKind.records)),
          header: [
            SrTextField(
              controller: _search,
              hint: l10n.contactsCompanySearchHint,
              prefixIcon: Icons.search_rounded,
              textInputAction: TextInputAction.search,
              onChanged: _onSearch,
            ),
            const _FilterChips(),
          ],
          itemBuilder: (context, company, last) =>
              CompanyRow(company: company, divider: !last),
          empty: _Empty(
            filtered: filter.search.isNotEmpty || filter.customersOnly,
            canAdd: canAdd,
            onClear: _clearFilters,
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final customersOnly = ref.watch(
      companiesFilterProvider.select((filter) => filter.customersOnly),
    );
    final notifier = ref.read(companiesFilterProvider.notifier);
    final counts = ref.watch(companyCountsProvider).value;

    return Row(
      spacing: 6,
      children: [
        SrChip(
          label: l10n.commonAll,
          count: counts?.all,
          selected: !customersOnly,
          onTap: () => notifier.customersOnly(false),
        ),
        SrChip(
          label: l10n.contactsCustomers,
          count: counts?.customers,
          selected: customersOnly,
          onTap: () => notifier.customersOnly(true),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.filtered,
    required this.canAdd,
    required this.onClear,
  });

  final bool filtered;
  final bool canAdd;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (filtered) {
      return SrEmptyState(
        icon: Icons.search_off_rounded,
        title: l10n.contactsNoMatchTitle,
        message: l10n.contactsNoMatchBody,
        actionLabel: l10n.contactsClearFilters,
        onAction: onClear,
      );
    }
    return SrEmptyState(
      icon: Icons.apartment_rounded,
      title: l10n.contactsCompaniesEmptyTitle,
      message: l10n.contactsCompaniesEmptyBody,
      actionLabel: canAdd ? l10n.contactsAddCompany : null,
      onAction: canAdd ? () => context.push(Routes.companyNew) : null,
    );
  }
}

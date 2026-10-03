import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/contacts/models/company.dart';
import 'package:salesroot/features/contacts/providers/companies_providers.dart';
import 'package:salesroot/features/contacts/view/widget/contact_rows.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_feedback.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_header.dart';
import 'package:salesroot/features/contacts/view/widget/paged_scroll_view.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #46: the companies the team sells to, with customer, industry and area
/// filters.
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
      ..customersOnly(false)
      ..industry(null)
      ..area(null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final list = ref.watch(companiesListProvider);
    final notifier = ref.read(companiesListProvider.notifier);
    final filter = ref.watch(companiesFilterProvider);
    final canAdd = ref.watch(moduleAccessProvider(AppModule.company)).canAdd;
    final total = list.value?.facets['Counts']?['All'];

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
            _FilterChips(counts: list.value?.facets['Counts'] ?? const {}),
          ],
          itemBuilder: (context, company, last) =>
              CompanyRow(company: company, divider: !last),
          empty: _Empty(
            filtered:
                filter.search.isNotEmpty ||
                filter.customersOnly ||
                filter.industry != null ||
                filter.area != null,
            canAdd: canAdd,
            onClear: _clearFilters,
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.counts});

  final Map<String, int> counts;

  Future<void> _pick(
    BuildContext context, {
    required String title,
    required String allLabel,
    required List<LocalizedName> options,
    required String? selected,
    required ValueChanged<String?> onPicked,
  }) async {
    final bangla = context.fmt.isBangla;
    final choices = [const LocalizedName('', ''), ...options];
    final picked = await showSrSheet<LocalizedName>(
      context: context,
      builder: (_) => SrOptionSheet<LocalizedName>(
        title: title,
        options: choices,
        labelOf: (option) => option.en.isEmpty ? allLabel : option.of(bangla),
        isSelected: (option) => option.en == (selected ?? ''),
      ),
    );
    if (picked == null) return;
    onPicked(picked.en.isEmpty ? null : picked.en);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bangla = context.fmt.isBangla;
    final filter = ref.watch(companiesFilterProvider);
    final notifier = ref.read(companiesFilterProvider.notifier);
    final lookups = ref.watch(companyLookupsProvider).value;
    String labelOf(List<LocalizedName> options, String value) =>
        options.where((o) => o.en == value).firstOrNull?.of(bangla) ?? value;
    final industry = filter.industry;
    final area = filter.area;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 6,
        children: [
          SrChip(
            label: l10n.commonAll,
            count: counts['All'],
            selected: !filter.customersOnly,
            onTap: () => notifier.customersOnly(false),
          ),
          SrChip(
            label: l10n.contactsCustomers,
            count: counts['Customers'],
            selected: filter.customersOnly,
            onTap: () => notifier.customersOnly(true),
          ),
          if (lookups != null) ...[
            SrChip(
              label: industry == null
                  ? l10n.contactsIndustry
                  : labelOf(lookups.industries, industry),
              icon: Icons.factory_outlined,
              tone: industry == null ? SrTone.neutral : SrTone.accent,
              onTap: () => _pick(
                context,
                title: l10n.contactsIndustry,
                allLabel: l10n.contactsAllIndustries,
                options: lookups.industries,
                selected: industry,
                onPicked: notifier.industry,
              ),
            ),
            SrChip(
              label: area == null
                  ? l10n.contactsArea
                  : labelOf(lookups.areas, area),
              icon: Icons.place_outlined,
              tone: area == null ? SrTone.neutral : SrTone.accent,
              onTap: () => _pick(
                context,
                title: l10n.contactsArea,
                allLabel: l10n.contactsAllAreas,
                options: lookups.areas,
                selected: area,
                onPicked: notifier.area,
              ),
            ),
          ],
        ],
      ),
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

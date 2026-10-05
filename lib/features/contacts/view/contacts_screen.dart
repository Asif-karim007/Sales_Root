import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/contacts/models/contact.dart';
import 'package:salesroot/features/contacts/providers/contacts_providers.dart';
import 'package:salesroot/features/contacts/view/widget/contact_rows.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_feedback.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_header.dart';
import 'package:salesroot/features/contacts/view/widget/paged_scroll_view.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #43: everyone the team talks to, searchable.
class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
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
      () => ref.read(contactsSearchProvider.notifier).search(term),
    );
  }

  void _clearSearch() {
    _search.clear();
    ref.read(contactsSearchProvider.notifier).search('');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final list = ref.watch(contactsListProvider);
    final notifier = ref.read(contactsListProvider.notifier);
    final search = ref.watch(contactsSearchProvider);
    final canAdd = ref.watch(moduleAccessProvider(AppModule.contact)).canAdd;
    final total = list.value?.totalCount;

    return SrScaffold(
      appBar: ContactsHeader(
        title: l10n.contactsTitle,
        subtitle: total == null
            ? null
            : l10n.contactsPeopleCount(total, fmt.number(total)),
        companies: false,
        onAdd: canAdd ? () => context.push(Routes.contactNew) : null,
      ),
      body: SrKeyboardDismiss(
        child: PagedScrollView<Contact>(
          value: list,
          onLoadMore: notifier.loadMore,
          onRefresh: notifier.refresh,
          onRetry: () => ref.invalidate(contactsListProvider),
          onUpgrade: () => context.push(upgradeRoute(QuotaKind.records)),
          header: [
            SrTextField(
              controller: _search,
              hint: l10n.contactsSearchHint,
              prefixIcon: Icons.search_rounded,
              textInputAction: TextInputAction.search,
              onChanged: _onSearch,
            ),
            const _ImportButtons(),
          ],
          itemBuilder: (context, contact, last) =>
              ContactRow(contact: contact, divider: !last),
          empty: _Empty(
            filtered: search.isNotEmpty,
            canAdd: canAdd,
            onClear: _clearSearch,
          ),
        ),
      ),
    );
  }
}

class _ImportButtons extends ConsumerWidget {
  const _ImportButtons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canImport = ref.watch(moduleAccessProvider(AppModule.contact)).canAdd;
    final scan = ref.watch(moduleAccessProvider(AppModule.cardScan));
    final canScan = scan.visible && scan.canAdd;
    if (!canImport && !canScan) return const SizedBox.shrink();

    return Row(
      children: [
        if (canImport)
          Expanded(
            child: SrButton(
              label: l10n.contactsImportFromPhone,
              icon: Icons.contact_phone_outlined,
              variant: SrButtonVariant.secondary,
              size: SrButtonSize.sm,
              expand: true,
              onPressed: () => context.push(Routes.contactsImport),
            ),
          ),
        if (canImport && canScan) const SizedBox(width: 10),
        if (canScan)
          Expanded(
            child: SrButton(
              label: l10n.contactsScanCard,
              icon: Icons.document_scanner_outlined,
              variant: SrButtonVariant.secondary,
              size: SrButtonSize.sm,
              expand: true,
              onPressed: () => context.push(Routes.scan),
            ),
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
      icon: Icons.people_outline_rounded,
      title: l10n.contactsEmptyTitle,
      message: l10n.contactsEmptyBody,
      actionLabel: canAdd ? l10n.contactsAddContact : null,
      onAction: canAdd ? () => context.push(Routes.contactNew) : null,
    );
  }
}

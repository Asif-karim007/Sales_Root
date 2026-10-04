import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/contacts/models/contact.dart';
import 'package:salesroot/features/contacts/providers/contacts_providers.dart';
import 'package:salesroot/features/contacts/view/widget/contact_rows.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_feedback.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_header.dart';
import 'package:salesroot/features/contacts/view/widget/paged_scroll_view.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #43: everyone the team talks to, searchable, with group and letter filters.
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
      () => ref.read(contactsFilterProvider.notifier).search(term),
    );
  }

  void _clearFilters() {
    _search.clear();
    ref.read(contactsFilterProvider.notifier)
      ..search('')
      ..group(ContactGroup.all)
      ..letter(null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final list = ref.watch(contactsListProvider);
    final notifier = ref.read(contactsListProvider.notifier);
    final filter = ref.watch(contactsFilterProvider);
    final canAdd = ref.watch(moduleAccessProvider(AppModule.contact)).canAdd;
    final total = list.value?.facets['GroupCounts']?['All'];

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
            _GroupChips(counts: list.value?.facets['GroupCounts'] ?? const {}),
          ],
          itemBuilder: (context, contact, last) =>
              ContactRow(contact: contact, divider: !last),
          empty: _Empty(
            filtered:
                filter.search.isNotEmpty ||
                filter.group != ContactGroup.all ||
                filter.letter != null,
            canAdd: canAdd,
            onClear: _clearFilters,
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

class _GroupChips extends ConsumerWidget {
  const _GroupChips({required this.counts});

  final Map<String, int> counts;

  String _label(AppLocalizations l10n, ContactGroup group) => switch (group) {
    ContactGroup.all => l10n.commonAll,
    ContactGroup.primary => l10n.contactsGroupPrimary,
    ContactGroup.independent => l10n.contactsIndependent,
    ContactGroup.recent => l10n.contactsGroupRecent,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(contactsFilterProvider);
    final notifier = ref.read(contactsFilterProvider.notifier);
    final letter = filter.letter;
    const groups = ContactGroup.values;

    return SrChipRow(
      padding: EdgeInsets.zero,
      chips: [
        for (final group in groups)
          SrChipItem(_label(l10n, group), count: counts[group.wire]),
        SrChipItem(
          letter ?? l10n.contactsLetterAll,
          tone: letter == null ? SrTone.neutral : SrTone.accent,
        ),
      ],
      index: filter.group.index,
      onChanged: (index) async {
        if (index < groups.length) {
          notifier.group(groups[index]);
          return;
        }
        final picked = await showSrSheet<String>(
          context: context,
          builder: (_) => _LetterSheet(selected: letter),
        );
        if (picked == null) return;
        notifier.letter(picked.isEmpty ? null : picked);
      },
    );
  }
}

class _LetterSheet extends StatelessWidget {
  const _LetterSheet({required this.selected});

  final String? selected;

  static final _letters = [
    for (var code = 65; code <= 90; code++) String.fromCharCode(code),
    '#',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrSheet(
      title: l10n.contactsLetterTitle,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final letter in _letters)
                  _LetterKey(
                    letter: letter,
                    selected: letter == selected,
                    onTap: () => Navigator.of(context).pop(letter),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SrButton(
              label: l10n.contactsLetterClear,
              variant: SrButtonVariant.secondary,
              expand: true,
              onPressed: () => Navigator.of(context).pop(''),
            ),
          ],
        ),
      ),
    );
  }
}

class _LetterKey extends StatelessWidget {
  const _LetterKey({
    required this.letter,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Material(
      color: selected ? c.accent : c.canvas,
      borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Text(
              letter,
              style: AppText.rowTitle(selected ? c.onAccent : c.ink),
            ),
          ),
        ),
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
      icon: Icons.people_outline_rounded,
      title: l10n.contactsEmptyTitle,
      message: l10n.contactsEmptyBody,
      actionLabel: canAdd ? l10n.contactsAddContact : null,
      onAction: canAdd ? () => context.push(Routes.contactNew) : null,
    );
  }
}

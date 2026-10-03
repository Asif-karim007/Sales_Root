import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/contacts/models/bd_phone.dart';
import 'package:salesroot/features/contacts/models/phone_book_entry.dart';
import 'package:salesroot/features/contacts/providers/import_providers.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_feedback.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_header.dart';
import 'package:salesroot/features/contacts/view/widget/paged_scroll_view.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #44: pick people from the phone book; numbers already saved are marked
/// and cannot be picked twice.
class ContactImportScreen extends ConsumerWidget {
  const ContactImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final state = ref.watch(contactImportProvider);
    final notifier = ref.read(contactImportProvider.notifier);
    final loaded = state.value;
    final picked = loaded?.selected.length ?? 0;

    ref.listen(contactImportProvider, (previous, next) {
      final before = previous?.value;
      final after = next.value;
      if (after == null) return;
      final imported = after.imported;
      if (imported != null && before?.imported == null) {
        showSrSuccess(
          context,
          l10n.contactsImported(imported, fmt.number(imported)),
        );
        context.pop();
      }
      final failure = after.failure;
      if (failure != null && before?.failure != failure) {
        showFailure(context, failure);
      }
    });

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.contactsImportFromPhone,
        subtitle: loaded == null || !loaded.granted
            ? null
            : l10n.contactsSelectedCount(fmt.number(picked)),
        actions: [
          const ContactsLanguageToggle(),
          if (loaded != null && loaded.newCount > 0)
            SrIconButton(
              icon: Icons.done_all_rounded,
              tooltip: l10n.contactsSelectAll,
              onTap: notifier.toggleAll,
            ),
        ],
      ),
      footer: loaded == null || !loaded.granted
          ? null
          : SrButton(
              label: l10n.contactsImportCount(fmt.number(picked)),
              expand: true,
              loading: loaded.importing,
              onPressed: picked == 0 ? null : notifier.import,
            ),
      body: SrAsyncView<ContactImportState>(
        value: state,
        onRetry: () => ref.invalidate(contactImportProvider),
        onUpgrade: () => context.push(upgradeRoute(QuotaKind.records)),
        data: (context, data) => data.granted
            ? _Picker(data: data)
            : Center(
                child: SrEmptyState(
                  icon: Icons.contacts_outlined,
                  title: l10n.contactsAccessTitle,
                  message: l10n.contactsAccessBody,
                  actionLabel: l10n.contactsAccessAction,
                  onAction: () => ref.invalidate(contactImportProvider),
                ),
              ),
      ),
    );
  }
}

class _Picker extends ConsumerStatefulWidget {
  const _Picker({required this.data});

  final ContactImportState data;

  @override
  ConsumerState<_Picker> createState() => _PickerState();
}

class _PickerState extends ConsumerState<_Picker> {
  late final _search = TextEditingController(text: widget.data.search);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = widget.data;
    final visible = data.visible;
    final notifier = ref.read(contactImportProvider.notifier);

    return SrKeyboardDismiss(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              SrMetrics.gutter,
              16,
              SrMetrics.gutter,
              12,
            ),
            sliver: SliverList.list(
              children: [
                SrNote(
                  message: l10n.contactsImportPrivacy,
                  icon: Icons.lock_outline_rounded,
                ),
                const SizedBox(height: 12),
                SrTextField(
                  controller: _search,
                  hint: l10n.contactsImportSearchHint,
                  prefixIcon: Icons.search_rounded,
                  onChanged: notifier.search,
                ),
              ],
            ),
          ),
          if (visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: SrEmptyState(
                  icon: Icons.search_off_rounded,
                  title: l10n.contactsNoMatchTitle,
                  message: l10n.contactsImportNoMatch,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                SrMetrics.gutter,
                0,
                SrMetrics.gutter,
                24,
              ),
              sliver: SliverList.builder(
                itemCount: visible.length,
                itemBuilder: (context, index) => CardSegment(
                  first: index == 0,
                  last: index == visible.length - 1,
                  child: _CandidateRow(
                    candidate: visible[index],
                    selected: data.selected.contains(
                      visible[index].entry.deviceId,
                    ),
                    divider: index < visible.length - 1,
                    onToggle: () => notifier.toggle(visible[index]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({
    required this.candidate,
    required this.selected,
    required this.divider,
    required this.onToggle,
  });

  final ImportCandidate candidate;
  final bool selected;
  final bool divider;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entry = candidate.entry;
    final existing = candidate.existingContactId;
    final phones = entry.phones
        .map((phone) => context.fmt.phone(BdPhone.display(phone)))
        .join(', ');

    return SrListRow(
      title: entry.name,
      subtitle: [phones, ?entry.company].join(' · '),
      divider: divider,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          _SelectDot(selected: selected, enabled: existing == null),
          SrAvatar(name: entry.name),
        ],
      ),
      trailing: existing == null
          ? null
          : SrTag(l10n.contactsExists, tone: SrTone.warn),
      onTap: existing == null
          ? onToggle
          : () => context.push(Routes.contactFor(existing)),
    );
  }
}

class _SelectDot extends StatelessWidget {
  const _SelectDot({required this.selected, required this.enabled});

  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? c.accent : c.surface,
        border: SrBorder.all(color: enabled ? c.accent : c.line, width: 2),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 16, color: c.onAccent)
          : null,
    );
  }
}

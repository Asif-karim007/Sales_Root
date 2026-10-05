import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/hr/data/hr_repositories.dart';
import 'package:salesroot/features/hr/models/ticket.dart';
import 'package:salesroot/features/hr/providers/ticket_providers.dart';
import 'package:salesroot/features/hr/view/widget/hr_feedback.dart';
import 'package:salesroot/features/hr/view/widget/hr_field_error.dart';
import 'package:salesroot/features/hr/view/widget/hr_labels.dart';
import 'package:salesroot/features/hr/view/widget/hr_language_toggle.dart';
import 'package:salesroot/features/hr/view/widget/hr_photos.dart';
import 'package:salesroot/features/hr/view/widget/ticket_summary.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #157 `ticket`: a field rep raises a support ticket for a customer, then
/// sees its summary with the SLA, thread and status.
class TicketScreen extends ConsumerWidget {
  const TicketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final form = ref.watch(ticketFormProvider);
    final created = form.submission.value;

    ref.listen(ticketFormProvider.select((s) => s.submission), (_, next) {
      switch (next) {
        case AsyncData(value: final Ticket ticket):
          showSrSuccess(context, l10n.hrTicketCreated(ticket.code));
        case AsyncError(:final error):
          showHrFailure(context, error);
        default:
      }
    });

    if (created != null) return TicketSummaryScreen(ticketId: created.id);

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.hrTicketNewTitle,
        actions: const [HrLanguageToggle()],
      ),
      body: SrKeyboardDismiss(child: _TicketForm(state: form)),
      footer: SrButton(
        label: l10n.hrTicketCreate,
        expand: true,
        loading: form.submission.isLoading,
        onPressed: () => ref.read(ticketFormProvider.notifier).submit(),
      ),
    );
  }
}

class _TicketForm extends ConsumerStatefulWidget {
  const _TicketForm({required this.state});

  final TicketFormState state;

  @override
  ConsumerState<_TicketForm> createState() => _TicketFormState();
}

class _TicketFormState extends ConsumerState<_TicketForm> {
  final _title = TextEditingController();
  final _description = TextEditingController();

  TicketFormNotifier get _form => ref.read(ticketFormProvider.notifier);

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickCustomer() async {
    final l10n = context.l10n;
    final repository = ref.read(ticketRepositoryProvider);
    final current = widget.state.draft.customer;
    final picked = await showSrSheet<TicketCustomer>(
      context: context,
      builder: (_) => SrSearchSheet<TicketCustomer>(
        title: l10n.hrTicketCustomerPick,
        searchHint: l10n.hrTicketCustomerSearchHint,
        withAvatar: true,
        search: (term, page) async =>
            (await repository.searchCustomers(term, page)).items,
        labelOf: (c) => c.name,
        subtitleOf: (c) => c.area,
        isSelected: (c) => c.id == current?.id,
      ),
    );
    if (picked == null) return;
    _form.edit((d) => d.copyWith(customer: picked));
  }

  Future<void> _addPhoto() async {
    final path = await pickHrPhoto(context);
    if (path == null) return;
    _form.edit((d) => d.copyWith(photos: [...d.photos, path]));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final draft = widget.state.draft;
    final errors = widget.state.showErrors
        ? draft.errors
        : const <TicketField>{};
    final customer = draft.customer;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        16,
        SrMetrics.gutter,
        24,
      ),
      children: [
        SrPickerField(
          label: l10n.hrTicketCustomer,
          value: customer == null
              ? null
              : [customer.name, ?customer.area].join(' · '),
          placeholder: l10n.hrTicketCustomerPick,
          icon: Icons.storefront_outlined,
          error: errors.contains(TicketField.customer)
              ? l10n.hrTicketCustomerError
              : null,
          onTap: _pickCustomer,
        ),
        const SizedBox(height: 14),
        SrTextField(
          controller: _title,
          label: l10n.hrTicketSubject,
          hint: l10n.hrTicketSubjectHint,
          maxLength: 80,
          textCapitalization: TextCapitalization.sentences,
          error: errors.contains(TicketField.title)
              ? l10n.hrTicketSubjectError
              : null,
          onChanged: (text) => _form.edit((d) => d.copyWith(title: text)),
        ),
        const SizedBox(height: 14),
        _IssueChips(
          selected: draft.issue,
          error: errors.contains(TicketField.issue)
              ? l10n.hrTicketIssueError
              : null,
          onSelect: (issue) => _form.edit((d) => d.copyWith(issue: issue)),
        ),
        const SizedBox(height: 14),
        _PriorityPicker(
          priority: draft.priority,
          onChanged: (p) => _form.edit((d) => d.copyWith(priority: p)),
        ),
        const SizedBox(height: 14),
        SrTextField(
          controller: _description,
          label: l10n.hrTicketDescription,
          hint: l10n.hrTicketDescriptionHint,
          multiline: true,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          error: errors.contains(TicketField.description)
              ? l10n.hrTicketDescriptionError
              : null,
          onChanged: (text) => _form.edit((d) => d.copyWith(description: text)),
        ),
        const SizedBox(height: 14),
        SrFieldLabel(l10n.hrTicketPhotos, optional: true),
        const SizedBox(height: 8),
        HrPhotoTiles(
          paths: draft.photos,
          onAdd: _addPhoto,
          onRemove: (path) => _form.edit(
            (d) => d.copyWith(
              photos: [
                for (final p in d.photos)
                  if (p != path) p,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IssueChips extends StatelessWidget {
  const _IssueChips({
    required this.selected,
    required this.error,
    required this.onSelect,
  });

  final TicketIssue? selected;
  final String? error;
  final ValueChanged<TicketIssue> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final error = this.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SrFieldLabel(l10n.hrTicketIssue),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final issue in TicketIssue.values)
              SrChip(
                label: l10n.ticketIssue(issue),
                selected: issue == selected,
                tone: SrTone.accent,
                onTap: () => onSelect(issue),
              ),
          ],
        ),
        if (error != null) HrFieldError(error),
      ],
    );
  }
}

class _PriorityPicker extends StatelessWidget {
  const _PriorityPicker({required this.priority, required this.onChanged});

  final TicketPriority priority;
  final ValueChanged<TicketPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    const priorities = TicketPriority.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrFieldLabel(l10n.hrTicketPriority),
        const SizedBox(height: 8),
        SrSegmented(
          segments: [
            for (final p in priorities) SrSegment(l10n.ticketPriority(p)),
          ],
          index: priorities.indexOf(priority),
          onChanged: (i) => onChanged(priorities[i]),
        ),
        const SizedBox(height: 10),
        SrNote(
          icon: Icons.timer_outlined,
          message: l10n.hrTicketSlaNote(
            l10n.hrHours(fmt.number(priority.slaHours)),
          ),
        ),
      ],
    );
  }
}

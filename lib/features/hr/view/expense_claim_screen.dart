import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/hr/models/expense.dart';
import 'package:salesroot/features/hr/providers/expense_providers.dart';
import 'package:salesroot/features/hr/view/widget/hr_feedback.dart';
import 'package:salesroot/features/hr/view/widget/hr_field_error.dart';
import 'package:salesroot/features/hr/view/widget/hr_labels.dart';
import 'package:salesroot/features/hr/view/widget/hr_language_toggle.dart';
import 'package:salesroot/features/hr/view/widget/hr_photos.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #152 `expenseclaim`: category, amount, date, visit, route, people, bill
/// photos and a note. A `visitId` links the visit and prefills the route.
class ExpenseClaimScreen extends ConsumerWidget {
  const ExpenseClaimScreen({super.key, this.visitId});

  final int? visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = expenseFormProvider(visitId);
    final form = ref.watch(provider);
    final saving = form.value?.submission.isLoading ?? false;

    ref.listen(provider.select((s) => s.value?.submission), (_, next) {
      switch (next) {
        case AsyncData(value: final ExpenseClaim _):
          showSrSuccess(context, l10n.hrExpenseSubmitted);
          closeHrForm(context, Routes.expenses);
        case AsyncError(:final error):
          showHrFailure(context, error);
        default:
      }
    });

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.hrExpenseClaimTitle,
        actions: const [HrLanguageToggle()],
      ),
      body: SrKeyboardDismiss(
        child: SrAsyncView(
          value: form,
          onRetry: () => ref.invalidate(provider),
          loading: (_) => const SrSkeletonList(count: 6),
          data: (context, state) =>
              _ExpenseForm(visitId: visitId, state: state),
        ),
      ),
      footer: SrButton(
        label: l10n.hrExpenseSubmit,
        expand: true,
        loading: saving,
        onPressed: form.hasValue
            ? () => ref.read(provider.notifier).submit()
            : null,
      ),
    );
  }
}

class _ExpenseForm extends ConsumerStatefulWidget {
  const _ExpenseForm({required this.visitId, required this.state});

  final int? visitId;
  final ExpenseFormState state;

  @override
  ConsumerState<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<_ExpenseForm> {
  late final ExpenseDraft _initial = widget.state.draft;
  late final _amount = TextEditingController(
    text: _initial.amount?.round().toString() ?? '',
  );
  late final _from = TextEditingController(text: _initial.from);
  late final _to = TextEditingController(text: _initial.to);
  late final _note = TextEditingController(text: _initial.note);
  bool _moreOpen = false;

  ExpenseFormNotifier get _form =>
      ref.read(expenseFormProvider(widget.visitId).notifier);

  @override
  void dispose() {
    _amount.dispose();
    _from.dispose();
    _to.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = AppDateUtils.dateOnly(DateTime.now());
    final picked = await showSrDatePicker(
      context: context,
      initial: widget.state.draft.date ?? today,
      first: today.subtract(
        Duration(days: widget.state.lookups.entryDaysLimit),
      ),
      last: today,
    );
    if (picked == null) return;
    _form.edit((d) => d.copyWith(date: picked));
  }

  Future<void> _pickVisit() async {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final current = widget.state.draft.visit;
    final options = [
      const _VisitOption(null),
      for (final visit in widget.state.lookups.visits) _VisitOption(visit),
    ];
    final picked = await showSrSheet<_VisitOption>(
      context: context,
      builder: (_) => SrOptionSheet<_VisitOption>(
        title: l10n.hrExpenseVisitPick,
        options: options,
        labelOf: (o) => o.visit?.prospectName ?? l10n.hrExpenseVisitNone,
        subtitleOf: (o) {
          final at = o.visit?.visitedAt;
          return at == null ? null : fmt.dayTime(at);
        },
        isSelected: (o) => o.visit?.id == current?.id,
      ),
    );
    if (picked == null) return;
    _form.linkVisit(picked.visit);
    final draft = ref.read(expenseFormProvider(widget.visitId)).value?.draft;
    if (draft == null) return;
    if (_from.text.isEmpty) _from.text = draft.from;
    if (_to.text.isEmpty) _to.text = draft.to;
  }

  Future<void> _addReceipt() async {
    final path = await pickHrPhoto(context);
    if (path == null) return;
    _form.edit((d) => d.copyWith(receipts: [...d.receipts, path]));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = widget.state;
    final draft = state.draft;
    final errors = state.showErrors
        ? state.errors(DateTime.now())
        : const <ExpenseField>{};
    final easy = ref.watch(experienceLevelProvider) == ExperienceLevel.easy;
    final type = state.lookups.types
        .where((t) => t.id == draft.typeId)
        .firstOrNull;
    final showRoute = !easy || _moreOpen || draft.visit != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        16,
        SrMetrics.gutter,
        24,
      ),
      children: [
        _CategoryChips(
          types: state.lookups.types,
          selected: draft.typeId,
          error: errors.contains(ExpenseField.type)
              ? l10n.hrExpenseCategoryError
              : null,
          onSelect: (id) => _form.edit((d) => d.copyWith(typeId: id)),
        ),
        const SizedBox(height: 14),
        SrTextField(
          controller: _amount,
          label: l10n.hrExpenseAmount,
          prefix: Text(
            l10n.hrTakaSign,
            style: AppText.metric(SrColors.of(context).ink2, size: 20),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(7),
          ],
          error: errors.contains(ExpenseField.amount)
              ? l10n.hrExpenseAmountError
              : null,
          onChanged: (text) => _form.edit(
            (d) => d.copyWith(amount: () => double.tryParse(text)),
          ),
        ),
        const SizedBox(height: 14),
        _DateAndVisit(
          state: state,
          dateError: errors.contains(ExpenseField.futureDate)
              ? l10n.hrExpenseFutureDate
              : null,
          onDate: _pickDate,
          onVisit: _pickVisit,
        ),
        const SizedBox(height: 14),
        if (showRoute)
          _RouteFields(
            from: _from,
            to: _to,
            people: draft.personCount,
            onFrom: (text) => _form.edit((d) => d.copyWith(from: text)),
            onTo: (text) => _form.edit((d) => d.copyWith(to: text)),
            onPeople: (count) =>
                _form.edit((d) => d.copyWith(personCount: count)),
          )
        else
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SrButton(
              label: l10n.hrExpenseMoreDetails,
              icon: Icons.add_road_outlined,
              variant: SrButtonVariant.ghost,
              size: SrButtonSize.sm,
              onPressed: () => setState(() => _moreOpen = true),
            ),
          ),
        const SizedBox(height: 14),
        SrFieldLabel(l10n.hrExpenseReceipt, optional: true),
        const SizedBox(height: 8),
        HrPhotoTiles(
          paths: draft.receipts,
          onAdd: _addReceipt,
          onRemove: (path) => _form.edit(
            (d) => d.copyWith(
              receipts: [
                for (final p in d.receipts)
                  if (p != path) p,
              ],
            ),
          ),
        ),
        if (type != null && errors.contains(ExpenseField.receipt))
          HrFieldError(
            l10n.hrExpenseReceiptError(
              context.fmt.money(type.receiptRequiredAbove ?? 0),
            ),
          ),
        const SizedBox(height: 14),
        SrTextField(
          controller: _note,
          label: l10n.hrExpenseNote,
          optional: true,
          hint: l10n.hrExpenseNoteHint,
          prefixIcon: Icons.notes_rounded,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 200,
          onChanged: (text) => _form.edit((d) => d.copyWith(note: text)),
        ),
        const SizedBox(height: 14),
        _ApproverNote(lookups: state.lookups),
      ],
    );
  }
}

class _VisitOption {
  const _VisitOption(this.visit);

  final ExpenseVisit? visit;
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.types,
    required this.selected,
    required this.error,
    required this.onSelect,
  });

  final List<ExpenseType> types;
  final int? selected;
  final String? error;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final fmt = context.fmt;
    final error = this.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SrFieldLabel(context.l10n.hrExpenseCategory),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in types)
              SrChip(
                label: type.name.of(fmt.isBangla),
                icon: type.code.expenseIcon,
                selected: type.id == selected,
                tone: SrTone.accent,
                onTap: () => onSelect(type.id),
              ),
          ],
        ),
        if (error != null) HrFieldError(error),
      ],
    );
  }
}

class _DateAndVisit extends StatelessWidget {
  const _DateAndVisit({
    required this.state,
    required this.dateError,
    required this.onDate,
    required this.onVisit,
  });

  final ExpenseFormState state;
  final String? dateError;
  final VoidCallback onDate;
  final VoidCallback onVisit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final date = state.draft.date;
    final visit = state.draft.visit;
    final dateText = date == null
        ? null
        : AppDateUtils.isSameDay(date, DateTime.now())
        ? l10n.commonToday
        : fmt.date(date);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SrPickerField(
            label: l10n.hrExpenseDate,
            value: dateText,
            placeholder: l10n.hrPickDate,
            icon: Icons.calendar_today_outlined,
            error: dateError,
            onTap: onDate,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SrDropdownField(
            label: l10n.hrExpenseVisit,
            optional: true,
            value: visit?.prospectName,
            placeholder: l10n.hrExpenseVisitNone,
            onTap: state.lookups.visits.isEmpty && visit == null
                ? null
                : onVisit,
          ),
        ),
      ],
    );
  }
}

class _RouteFields extends StatelessWidget {
  const _RouteFields({
    required this.from,
    required this.to,
    required this.people,
    required this.onFrom,
    required this.onTo,
    required this.onPeople,
  });

  final TextEditingController from;
  final TextEditingController to;
  final int people;
  final ValueChanged<String> onFrom;
  final ValueChanged<String> onTo;
  final ValueChanged<int> onPeople;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SrTextField(
                controller: from,
                label: l10n.hrExpenseFrom,
                optional: true,
                hint: l10n.hrExpenseFromHint,
                textCapitalization: TextCapitalization.words,
                onChanged: onFrom,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SrTextField(
                controller: to,
                label: l10n.hrExpenseTo,
                optional: true,
                hint: l10n.hrExpenseToHint,
                textCapitalization: TextCapitalization.words,
                onChanged: onTo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _PeopleStepper(count: people, onChanged: onPeople),
      ],
    );
  }
}

class _PeopleStepper extends StatelessWidget {
  const _PeopleStepper({required this.count, required this.onChanged});

  final int count;
  final ValueChanged<int> onChanged;

  static const int _max = 20;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.hrExpensePeople,
            style: AppText.body(c.ink, size: 14),
          ),
        ),
        SrIconButton(
          icon: Icons.remove_rounded,
          tooltip: l10n.hrExpensePeopleLess,
          onTap: count > 1 ? () => onChanged(count - 1) : null,
        ),
        SizedBox(
          width: 40,
          child: Text(
            context.fmt.number(count),
            textAlign: TextAlign.center,
            style: AppText.metric(c.ink, size: 18),
          ),
        ),
        SrIconButton(
          icon: Icons.add_rounded,
          tooltip: l10n.hrExpensePeopleMore,
          onTap: count < _max ? () => onChanged(count + 1) : null,
        ),
      ],
    );
  }
}

class _ApproverNote extends StatelessWidget {
  const _ApproverNote({required this.lookups});

  final ExpenseLookups lookups;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final approver = lookups.approverName;
    final limit = lookups.managerApprovalAbove;
    final message = switch (approver) {
      null => l10n.hrExpenseAutoApproved,
      _ when lookups.managerName != null && limit != null =>
        l10n.hrExpenseApproverManager(
          approver.of(fmt.isBangla),
          fmt.money(limit),
        ),
      _ => l10n.hrExpenseApproverOnly(approver.of(fmt.isBangla)),
    };
    return SrNote(message: message);
  }
}

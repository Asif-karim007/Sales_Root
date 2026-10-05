import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/hr/models/leave.dart';
import 'package:salesroot/features/hr/providers/leave_providers.dart';
import 'package:salesroot/features/hr/view/widget/hr_feedback.dart';
import 'package:salesroot/features/hr/view/widget/hr_field_error.dart';
import 'package:salesroot/features/hr/view/widget/hr_labels.dart';
import 'package:salesroot/features/hr/view/widget/hr_language_toggle.dart';
import 'package:salesroot/features/hr/view/widget/hr_photos.dart';
import 'package:salesroot/features/hr/view/widget/leave_widgets.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #151 `leaverequest`: balances, type, dates with a half day, reason and an
/// attachment.
class LeaveRequestScreen extends ConsumerWidget {
  const LeaveRequestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final form = ref.watch(leaveFormProvider);
    final saving = form.value?.submission.isLoading ?? false;

    ref.listen(leaveFormProvider.select((s) => s.value?.submission), (_, next) {
      switch (next) {
        case AsyncData(value: final String _):
          showSrSuccess(context, l10n.hrLeaveSubmitted);
          closeHrForm(context, Routes.leave);
        case AsyncError(:final error):
          showHrFailure(context, error);
        default:
      }
    });

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.hrLeaveRequestTitle,
        actions: const [HrLanguageToggle()],
      ),
      body: SrKeyboardDismiss(
        child: SrAsyncView(
          value: form,
          onRetry: () => ref.invalidate(leaveFormProvider),
          loading: (_) => const SrSkeletonList(count: 5),
          data: (context, state) => _LeaveForm(state: state),
        ),
      ),
      footer: SrButton(
        label: l10n.hrLeaveSubmit,
        expand: true,
        loading: saving,
        onPressed: form.hasValue
            ? () => ref.read(leaveFormProvider.notifier).submit()
            : null,
      ),
    );
  }
}

class _LeaveForm extends ConsumerStatefulWidget {
  const _LeaveForm({required this.state});

  final LeaveFormState state;

  @override
  ConsumerState<_LeaveForm> createState() => _LeaveFormState();
}

class _LeaveFormState extends ConsumerState<_LeaveForm> {
  late final _reason = TextEditingController(text: widget.state.draft.reason);

  LeaveFormNotifier get _form => ref.read(leaveFormProvider.notifier);

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickType() async {
    final state = widget.state;
    final picked = await showSrSheet<LeaveType>(
      context: context,
      builder: (_) => SrOptionSheet<LeaveType>(
        title: context.l10n.hrLeaveType,
        options: state.data.lookups.leaveTypes,
        labelOf: (t) => t.name.of(context.fmt.isBangla),
        subtitleOf: (t) => _balanceText(t, state.data.balances),
        isSelected: (t) => t.id == state.draft.leaveTypeId,
      ),
    );
    if (picked == null) return;
    _form.edit((d) => d.copyWith(leaveTypeId: picked.id));
  }

  String? _balanceText(LeaveType type, List<LeaveBalance> balances) {
    final balance = balances.where((b) => b.leaveTypeId == type.id).firstOrNull;
    if (balance == null) return null;
    final fmt = context.fmt;
    return context.l10n.hrLeaveFree(
      fmt.days(balance.remainingAfterPending),
      fmt.days(balance.entitlement),
    );
  }

  Future<void> _pickDate({required bool start}) async {
    final draft = widget.state.draft;
    final today = AppDateUtils.dateOnly(DateTime.now());
    final initial = (start ? draft.start : draft.end ?? draft.start) ?? today;
    final picked = await showSrDatePicker(
      context: context,
      initial: initial,
      first: start ? today.subtract(const Duration(days: 30)) : draft.start,
      last: today.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    _form.edit((d) {
      if (!start) return d.copyWith(end: picked);
      final end = d.end;
      return end == null || end.isBefore(picked)
          ? d.copyWith(start: picked, end: picked)
          : d.copyWith(start: picked);
    });
  }

  Future<void> _attach() async {
    final path = await pickHrPhoto(context);
    if (path == null) return;
    _form.edit((d) => d.copyWith(attachmentPath: () => path));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final state = widget.state;
    final draft = state.draft;
    final errors = state.showErrors ? state.errors : const <LeaveField>{};
    final easy = ref.watch(experienceLevelProvider) == ExperienceLevel.easy;
    final type = state.data.lookups.leaveTypes
        .where((t) => t.id == draft.leaveTypeId)
        .firstOrNull;
    final start = draft.start;
    final end = draft.end;
    final attachment = draft.attachmentPath;
    final needsDocument = type?.docRequiredFromDays != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        16,
        SrMetrics.gutter,
        24,
      ),
      children: [
        LeaveBalanceGrid(balances: state.data.balances),
        const SizedBox(height: 16),
        SrDropdownField(
          label: l10n.hrLeaveType,
          value: type?.name.of(fmt.isBangla),
          placeholder: l10n.hrLeaveTypePick,
          error: errors.contains(LeaveField.type) ? l10n.hrLeaveTypePick : null,
          onTap: _pickType,
        ),
        const SizedBox(height: 14),
        _DateRow(
          start: start == null ? null : fmt.dayMonth(start),
          end: end == null ? null : fmt.dayMonth(end),
          error: errors.contains(LeaveField.dates)
              ? l10n.hrLeaveDatesError
              : null,
          onStart: () => _pickDate(start: true),
          onEnd: start == null ? null : () => _pickDate(start: false),
        ),
        if (!easy) ...[
          const SizedBox(height: 12),
          _HalfDaySwitch(
            value: draft.halfDay,
            onChanged: (value) => _form.edit((d) => d.copyWith(halfDay: value)),
          ),
        ],
        const SizedBox(height: 14),
        SrTextField(
          controller: _reason,
          label: l10n.hrLeaveReason,
          optional: true,
          hint: l10n.hrLeaveReasonHint,
          multiline: true,
          maxLength: 300,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (text) => _form.edit((d) => d.copyWith(reason: text)),
        ),
        if (!easy || needsDocument) ...[
          const SizedBox(height: 14),
          SrFieldLabel(l10n.hrLeaveAttachment, optional: true),
          const SizedBox(height: 8),
          HrPhotoTiles(
            paths: [?attachment],
            max: 1,
            onAdd: _attach,
            onRemove: (_) =>
                _form.edit((d) => d.copyWith(attachmentPath: () => null)),
          ),
          if (type != null && errors.contains(LeaveField.document))
            HrFieldError(
              l10n.hrLeaveDocumentError(
                fmt.days(type.docRequiredFromDays ?? 0),
              ),
            ),
        ],
        const SizedBox(height: 16),
        _SummaryNote(state: state, type: type),
        const SizedBox(height: 20),
        SrSectionHeader(
          title: l10n.hrLeavePrevious,
          actionLabel: l10n.commonSeeAll,
          onAction: () => context.push(Routes.leave),
        ),
        const SizedBox(height: 10),
        _RecentRequests(requests: state.data.recent),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.start,
    required this.end,
    required this.error,
    required this.onStart,
    required this.onEnd,
  });

  final String? start;
  final String? end;
  final String? error;
  final VoidCallback onStart;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final error = this.error;
    final onEnd = this.onEnd;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SrPickerField(
                label: l10n.hrLeaveFrom,
                value: start,
                placeholder: l10n.hrPickDate,
                icon: Icons.calendar_today_outlined,
                onTap: onStart,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SrPickerField(
                label: l10n.hrLeaveTo,
                value: end,
                placeholder: l10n.hrPickDate,
                icon: Icons.event_outlined,
                enabled: onEnd != null,
                onTap: onEnd ?? () {},
              ),
            ),
          ],
        ),
        if (error != null) HrFieldError(error),
      ],
    );
  }
}

class _HalfDaySwitch extends StatelessWidget {
  const _HalfDaySwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.hrLeaveHalfDay,
            style: AppText.body(c.ink, size: 14),
          ),
        ),
        SrSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}

/// "2 days · approver Rafiqul Islam", or what stops the request.
class _SummaryNote extends StatelessWidget {
  const _SummaryNote({required this.state, required this.type});

  final LeaveFormState state;
  final LeaveType? type;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final lookups = state.data.lookups;
    final days = state.noOfDays;
    final type = this.type;

    if (type != null && state.errors.contains(LeaveField.balance)) {
      final free = state.data.balances
          .where((b) => b.leaveTypeId == type.id)
          .firstOrNull
          ?.remainingAfterPending;
      return SrNote(
        tone: SrNoteTone.err,
        message: l10n.hrLeaveBalanceError(
          fmt.days(free ?? 0),
          type.name.of(fmt.isBangla),
        ),
      );
    }
    if (days <= 0) return const SizedBox.shrink();

    final approver = lookups.approverName;
    return SrNote(
      message: [
        fmt.days(days),
        approver == null
            ? l10n.hrLeaveAutoApproved
            : l10n.hrLeaveApprover(approver),
      ].join(' · '),
    );
  }
}

class _RecentRequests extends StatelessWidget {
  const _RecentRequests({required this.requests});

  final List<LeaveRequest> requests;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return SrCard(
        child: Text(
          context.l10n.hrLeaveEmptyTitle,
          style: AppText.meta(SrColors.of(context).ink2),
        ),
      );
    }
    return SrCard(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        children: [
          for (var i = 0; i < requests.length; i++)
            LeaveRequestRow(
              request: requests[i],
              divider: i < requests.length - 1,
            ),
        ],
      ),
    );
  }
}

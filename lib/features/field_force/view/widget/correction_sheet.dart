import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/features/field_force/providers/attendance_providers.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Asks the team lead to correct a day marked absent. Pops true when sent.
Future<bool?> showCorrectionRequestSheet(BuildContext context, DateTime date) =>
    showSrSheet<bool>(
      context: context,
      builder: (_) => _CorrectionRequestSheet(date: date),
    );

class _CorrectionRequestSheet extends ConsumerStatefulWidget {
  const _CorrectionRequestSheet({required this.date});

  final DateTime date;

  @override
  ConsumerState<_CorrectionRequestSheet> createState() =>
      _CorrectionRequestSheetState();
}

class _CorrectionRequestSheetState
    extends ConsumerState<_CorrectionRequestSheet> {
  final _reason = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = context.l10n;
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = l10n.ffCorrectionReasonRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(attendanceMonthProvider.notifier)
          .requestCorrection(widget.date, _reason.text);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = failure.fieldError('Reason');
      });
      if (failure.fieldErrors.isEmpty) showSrError(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrSheet(
      title: l10n.ffCorrectionTitle,
      subtitle: context.fmt.weekdayDate(widget.date),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SrTextField(
              controller: _reason,
              label: l10n.ffCorrectionReason,
              hint: l10n.ffCorrectionReasonHint,
              error: _error,
              multiline: true,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            SrButton(
              label: l10n.ffCorrectionSend,
              expand: true,
              loading: _saving,
              onPressed: _saving ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}

/// The team lead approves or rejects a member's correction request.
Future<void> showCorrectionReviewSheet(
  BuildContext context,
  TeamAttendanceRow row,
) => showSrSheet<void>(
  context: context,
  builder: (_) => _CorrectionReviewSheet(row: row),
);

class _CorrectionReviewSheet extends ConsumerStatefulWidget {
  const _CorrectionReviewSheet({required this.row});

  final TeamAttendanceRow row;

  @override
  ConsumerState<_CorrectionReviewSheet> createState() =>
      _CorrectionReviewSheetState();
}

class _CorrectionReviewSheetState
    extends ConsumerState<_CorrectionReviewSheet> {
  bool _saving = false;

  Future<void> _resolve({required bool approve}) async {
    final l10n = context.l10n;
    setState(() => _saving = true);
    try {
      await ref
          .read(teamAttendanceProvider.notifier)
          .resolve(widget.row, approve: approve);
      if (!mounted) return;
      showSrSuccess(
        context,
        approve ? l10n.ffCorrectionApproved : l10n.ffCorrectionRejected,
      );
      Navigator.of(context).pop();
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSrError(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final row = widget.row;
    final date = row.correctionDate;
    return SrSheet(
      title: l10n.ffCorrectionReviewTitle(row.name.of(fmt.isBangla)),
      subtitle: date == null ? null : fmt.weekdayDate(date),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrCard(
            tone: SrCardTone.tint,
            child: Text(
              row.correctionReason ?? l10n.ffNoReason,
              style: AppText.body(c.ink, size: 14),
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.ffCorrectionReviewBody, style: AppText.meta(c.ink2)),
          const SizedBox(height: 16),
          SrButton(
            label: l10n.ffCorrectionApprove,
            icon: Icons.check_rounded,
            expand: true,
            loading: _saving,
            onPressed: _saving ? null : () => _resolve(approve: true),
          ),
          const SizedBox(height: 8),
          SrButton(
            label: l10n.ffCorrectionReject,
            variant: SrButtonVariant.secondary,
            expand: true,
            onPressed: _saving ? null : () => _resolve(approve: false),
          ),
        ],
      ),
    );
  }
}

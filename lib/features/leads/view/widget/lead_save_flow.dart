import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_input.dart';
import 'package:salesroot/features/leads/view/widget/lead_events.dart';
import 'package:salesroot/features/leads/view/widget/lead_labels.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Reacts to a lead form's save: opens the saved lead, offers the duplicate
/// sheet on a 409 (saving again with [retry] when kept), the upgrade sheet on
/// a 402, and a snackbar for anything else. A 400 is left to the form, which
/// shows the field errors.
void onLeadSaved(
  BuildContext context,
  AsyncValue<Lead?> next, {
  required LeadInput? input,
  required void Function(LeadInput) retry,
  bool created = true,
}) {
  if (next.isLoading) return;
  final l10n = context.l10n;
  final lead = next.value;
  if (lead != null && !next.hasError) {
    showSrSuccess(context, created ? l10n.leadsAdded : l10n.leadsSaved);
    if (created) {
      context.pushReplacement(Routes.leadFor(lead.id));
    } else {
      context.pop();
    }
    return;
  }
  final error = next.error;
  if (error == null) return;
  if (error is LeadDuplicateFailure && input != null) {
    _offerDuplicate(context, error, () => retry(input.allowingDuplicate()));
    return;
  }
  if (error is ApiFailure && error.isQuota) {
    showSrSheet<void>(
      context: context,
      builder: (sheet) => SrSheet(
        child: SrPlanLocked(
          message: l10n.leadsQuotaBody,
          onAction: () {
            Navigator.of(sheet).pop();
            context.push('${Routes.planChoose}?reason=quota&kind=records');
          },
        ),
      ),
    );
    return;
  }
  if (error is ApiFailure && error.isValidation) return;
  showSrError(context, leadFailureText(l10n, error));
}

/// The text to show under a field for a 400's field errors.
String? leadFieldError(AsyncValue<Lead?> state, String field) {
  final error = state.error;
  return error is ApiFailure ? error.fieldError(field) : null;
}

enum _DuplicateChoice { open, keep }

Future<void> _offerDuplicate(
  BuildContext context,
  LeadDuplicateFailure failure,
  VoidCallback keep,
) async {
  final choice = await showSrSheet<_DuplicateChoice>(
    context: context,
    builder: (_) => LeadDuplicateSheet(failure: failure),
  );
  if (choice == null || !context.mounted) return;
  switch (choice) {
    case _DuplicateChoice.open:
      context.pushReplacement(Routes.leadFor(failure.existing.id));
    case _DuplicateChoice.keep:
      keep();
  }
}

/// #27: the lead that already has this number or company.
class LeadDuplicateSheet extends StatelessWidget {
  const LeadDuplicateSheet({super.key, required this.failure});

  final LeadDuplicateFailure failure;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final existing = failure.existing;
    final created = existing.createdOn;
    final byPhone = failure.field == LeadDuplicateField.phone;
    return SrSheet(
      title: byPhone
          ? l10n.leadsDuplicatePhoneTitle
          : l10n.leadsDuplicateCompanyTitle,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              byPhone
                  ? l10n.leadsDuplicatePhoneBody
                  : l10n.leadsDuplicateCompanyBody,
              style: AppText.lead(c.ink2),
            ),
            const SizedBox(height: 12),
            SrCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: SrListRow(
                title: existing.leadName,
                subtitle: leadMeta([
                  existing.stageName(fmt.isBangla),
                  existing.assignedTo?.name.of(fmt.isBangla),
                  created == null
                      ? null
                      : l10n.leadsCreatedOn(fmt.dayMonth(created)),
                ]),
                leading: SrAvatar(name: existing.leadName),
                trailing: SrTag(l10n.leadsLeadTag, tone: SrTone.accent),
              ),
            ),
            const SizedBox(height: 16),
            SrButton(
              label: l10n.leadsDuplicateOpen,
              expand: true,
              onPressed: () => Navigator.of(context).pop(_DuplicateChoice.open),
            ),
            const SizedBox(height: 10),
            SrButton(
              label: l10n.leadsDuplicateKeep,
              variant: SrButtonVariant.secondary,
              expand: true,
              onPressed: () => Navigator.of(context).pop(_DuplicateChoice.keep),
            ),
            const SizedBox(height: 4),
            SrButton(
              label: l10n.commonCancel,
              variant: SrButtonVariant.ghost,
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

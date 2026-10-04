import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/contacts/models/bd_phone.dart';
import 'package:salesroot/features/contacts/models/linked_records.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// What the user chose on the duplicate sheet.
sealed class DuplicateChoice {
  const DuplicateChoice();
}

class OpenExisting extends DuplicateChoice {
  const OpenExisting(this.match);

  final DuplicateMatch match;
}

class SaveAnyway extends DuplicateChoice {
  const SaveAnyway();
}

/// The 409 sheet: the saved records this one clashes with, to open one of
/// them or save as a separate record.
Future<DuplicateChoice?> showDuplicateSheet(
  BuildContext context, {
  required List<DuplicateMatch> matches,
  required bool company,
}) => showSrSheet<DuplicateChoice>(
  context: context,
  builder: (_) => _DuplicateSheet(matches: matches, company: company),
);

class _DuplicateSheet extends StatelessWidget {
  const _DuplicateSheet({required this.matches, required this.company});

  final List<DuplicateMatch> matches;
  final bool company;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final first = matches.firstOrNull;

    return SrSheet(
      title: l10n.contactsDuplicateTitle,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              company
                  ? l10n.contactsDuplicateCompanyBody
                  : l10n.contactsDuplicateContactBody,
              style: AppText.lead(c.ink2),
            ),
            const SizedBox(height: 12),
            if (matches.isNotEmpty)
              SrRowGroup(
                rows: [
                  for (final match in matches.take(4))
                    _MatchRow(match: match, company: company),
                ],
              ),
            const SizedBox(height: 16),
            if (first != null) ...[
              SrButton(
                label: company
                    ? l10n.contactsDuplicateOpenCompany
                    : l10n.contactsDuplicateOpenContact,
                expand: true,
                onPressed: () => Navigator.of(context).pop(OpenExisting(first)),
              ),
              const SizedBox(height: 8),
            ],
            SrButton(
              label: l10n.contactsDuplicateKeepSeparate,
              expand: true,
              variant: SrButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(const SaveAnyway()),
            ),
            const SizedBox(height: 4),
            SrButton(
              label: l10n.commonCancel,
              expand: true,
              variant: SrButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.match, required this.company});

  final DuplicateMatch match;
  final bool company;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final phone = match.phone;
    final subtitle = [
      if (match.subtitle case final text? when text.isNotEmpty) text,
      if (phone != null) context.fmt.phone(BdPhone.display(phone)),
    ].join(' · ');
    return SrListRow(
      title: match.name,
      subtitle: subtitle,
      leading: SrAvatar(name: match.name, square: company),
      trailing: SrTag(
        company ? l10n.contactsCompany : l10n.contactsContact,
        tone: SrTone.accent,
      ),
      onTap: () => Navigator.of(context).pop(OpenExisting(match)),
    );
  }
}

/// One choice in an action sheet.
class SheetAction {
  const SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
}

/// A list of actions in a sheet; the sheet closes before the action runs.
Future<void> showActionSheet(
  BuildContext context, {
  required String title,
  required List<SheetAction> actions,
}) => showSrSheet<void>(
  context: context,
  builder: (sheetContext) => SrSheet(
    title: title,
    child: SingleChildScrollView(
      child: SrRowGroup(
        dividerIndent: 56,
        rows: [
          for (final action in actions)
            _ActionRow(
              action: action,
              onTap: () {
                Navigator.of(sheetContext).pop();
                action.onTap();
              },
            ),
        ],
      ),
    ),
  ),
);

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action, required this.onTap});

  final SheetAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final color = action.destructive ? c.danger : c.ink;
    return SrListRow(
      title: action.label,
      leading: Icon(action.icon, size: 22, color: color),
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/view/widget/voice_button.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #123 farcheckin: a check-in away from the office needs a reason, and is
/// flagged for the team lead. Pops with the reason.
Future<String?> showFarCheckInSheet(BuildContext context) =>
    showSrSheet<String>(
      context: context,
      builder: (_) => const _FarCheckInSheet(),
    );

class _FarCheckInSheet extends StatefulWidget {
  const _FarCheckInSheet();

  @override
  State<_FarCheckInSheet> createState() => _FarCheckInSheetState();
}

class _FarCheckInSheetState extends State<_FarCheckInSheet> {
  final _reason = TextEditingController();
  bool _tried = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      setState(() => _tried = true);
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;

    return SrSheet(
      title: l10n.ffFarTitle,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.wrong_location_outlined, size: 40, color: c.warning),
            const SizedBox(height: 8),
            Text(
              l10n.ffFarReasonBody,
              textAlign: TextAlign.center,
              style: AppText.lead(c.ink2),
            ),
            const SizedBox(height: 16),
            SrTextField(
              controller: _reason,
              label: l10n.ffFarReason,
              hint: l10n.ffFarReasonHint,
              error: _tried ? l10n.ffFarReasonRequired : null,
              multiline: true,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              suffix: FfVoiceButton(controller: _reason),
            ),
            const SizedBox(height: 18),
            SrButton(
              label: l10n.ffFarConfirm,
              expand: true,
              onPressed: _confirm,
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

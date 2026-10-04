import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/providers/visit_providers.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/features/field_force/view/widget/photo_capture.dart';
import 'package:salesroot/features/field_force/view/widget/voice_button.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #123 farcheckin: beyond the radius the check-in needs a reason and a
/// photo, and is flagged for the team lead. Pops with the reason.
Future<String?> showFarCheckInSheet(
  BuildContext context, {
  required int visitId,
}) => showSrSheet<String>(
  context: context,
  builder: (_) => _FarCheckInSheet(visitId: visitId),
);

class _FarCheckInSheet extends ConsumerStatefulWidget {
  const _FarCheckInSheet({required this.visitId});

  final int visitId;

  @override
  ConsumerState<_FarCheckInSheet> createState() => _FarCheckInSheetState();
}

class _FarCheckInSheetState extends ConsumerState<_FarCheckInSheet> {
  final _reason = TextEditingController();
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    _reason.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final path = await takeVisitPhoto(context);
    if (path == null) return;
    ref.read(checkInProvider(widget.visitId).notifier).setPhoto(path);
  }

  void _confirm(String? photo) {
    final reason = _reason.text.trim();
    if (reason.isEmpty || photo == null) {
      setState(() => _tried = true);
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final state = ref.watch(checkInProvider(widget.visitId)).value;
    final photo = state?.photoPath;
    final distance = state?.distance ?? 0;
    final missingReason = _tried && _reason.text.trim().isEmpty;
    final missingPhoto = _tried && photo == null;

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
              l10n.ffFarDistance(context.ffDistance(distance)),
              textAlign: TextAlign.center,
              style: AppText.sectionTitle(c.ink, size: 16),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.ffFarBody,
              textAlign: TextAlign.center,
              style: AppText.lead(c.ink2),
            ),
            const SizedBox(height: 16),
            SrTextField(
              controller: _reason,
              label: l10n.ffFarReason,
              hint: l10n.ffFarReasonHint,
              error: missingReason ? l10n.ffFarReasonRequired : null,
              multiline: true,
              textCapitalization: TextCapitalization.sentences,
              suffix: FfVoiceButton(controller: _reason),
            ),
            const SizedBox(height: 12),
            SrFieldLabel(l10n.ffFarPhoto),
            const SizedBox(height: 6),
            Row(
              children: [
                if (photo != null) ...[
                  FfPhotoThumb(path: photo, size: 56),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: SrButton(
                    label: photo == null
                        ? l10n.ffTakePhoto
                        : l10n.ffRetakePhoto,
                    icon: Icons.photo_camera_outlined,
                    variant: SrButtonVariant.secondary,
                    size: SrButtonSize.sm,
                    expand: true,
                    onPressed: _takePhoto,
                  ),
                ),
              ],
            ),
            if (missingPhoto) ...[
              const SizedBox(height: 6),
              Text(l10n.ffFarPhotoRequired, style: AppText.meta(c.danger)),
            ],
            const SizedBox(height: 18),
            SrButton(
              label: l10n.ffFarConfirm,
              expand: true,
              onPressed: () => _confirm(photo),
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

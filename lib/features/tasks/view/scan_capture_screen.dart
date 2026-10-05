import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/tasks/data/card_scan_repository.dart';
import 'package:salesroot/features/tasks/models/scanned_card.dart';
import 'package:salesroot/features/tasks/providers/scan_providers.dart';
import 'package:salesroot/features/tasks/view/widget/card_frame.dart';
import 'package:salesroot/features/tasks/view/widget/scan_beam.dart';
import 'package:salesroot/features/tasks/view/widget/scan_limit_sheet.dart';
import 'package:salesroot/features/tasks/view/widget/task_feedback.dart';
import 'package:salesroot/features/tasks/view/widget/tasks_language_toggle.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #39 `scancapture`: photograph a visiting card (or pick one), or a QR code.
class ScanCaptureScreen extends ConsumerStatefulWidget {
  const ScanCaptureScreen({super.key});

  @override
  ConsumerState<ScanCaptureScreen> createState() => _ScanCaptureScreenState();
}

class _ScanCaptureScreenState extends ConsumerState<ScanCaptureScreen> {
  final _picker = ImagePicker();
  Uint8List? _photo;
  ScanMode _mode = ScanMode.card;

  Future<void> _capture(ImageSource source, ScanMode mode) async {
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
    } on PlatformException {
      if (mounted) showSrError(context, context.l10n.tasksScanCameraFailed);
      return;
    }
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photo = bytes;
      _mode = mode;
    });
    await ref.read(scanSessionProvider.notifier).scan(bytes, mode);
  }

  void _onSession(
    AsyncValue<ScanCapture?>? previous,
    AsyncValue<ScanCapture?> next,
  ) {
    if (previous?.isLoading != true || next.isLoading) return;
    final error = next.error;
    if (error != null) {
      if (error is ApiFailure && error.isQuota) {
        showScanLimitSheet(context);
      } else if (error is ApiFailure &&
          error.statusCode == unreadableScan.statusCode) {
        showSrError(context, context.l10n.tasksScanUnreadable);
      } else if (error is ApiFailure &&
          error.statusCode == scanUnavailable.statusCode) {
        showSrError(context, context.l10n.tasksScanUnavailableTitle);
      } else {
        showSrError(context, failureText(context, error));
      }
      return;
    }
    final capture = next.value;
    if (capture == null) return;
    context.push(switch (capture.result) {
      CardScanResult() => Routes.scanReview,
      QrScanResult() => Routes.scanQr,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = SrColors.of(context);
    ref.listen(scanSessionProvider, _onSession);
    final reading = ref.watch(scanSessionProvider).isLoading;
    final available = ref.watch(cardScanRepositoryProvider) != null;
    final photo = _photo;

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.tasksScanTitle,
        actions: const [TasksLanguageToggle()],
      ),
      body: !available
          ? SrEmptyState(
              icon: Icons.no_photography_outlined,
              title: l10n.tasksScanUnavailableTitle,
              message: l10n.tasksScanUnavailableBody,
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                SrMetrics.gutter,
                16,
                SrMetrics.gutter,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.tasksScanHint,
                    textAlign: TextAlign.center,
                    style: AppText.lead(c.ink2),
                  ),
                  const SizedBox(height: 16),
                  CardFrame(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (photo == null)
                          const _FramePlaceholder()
                        else
                          Image.memory(photo, fit: BoxFit.contain),
                        if (reading)
                          ScanBeam(
                            label: _mode == ScanMode.qr
                                ? l10n.tasksScanReadingQr
                                : l10n.tasksScanReading,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _UsageNote(),
                  const Spacer(),
                  _Controls(
                    enabled: !reading,
                    onGallery: () =>
                        _capture(ImageSource.gallery, ScanMode.card),
                    onShutter: () =>
                        _capture(ImageSource.camera, ScanMode.card),
                    onQr: () => _capture(ImageSource.camera, ScanMode.qr),
                  ),
                ],
              ),
            ),
    );
  }
}

class _FramePlaceholder extends StatelessWidget {
  const _FramePlaceholder();

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.badge_outlined, size: 40, color: c.onDeepMuted),
        const SizedBox(height: 10),
        Text(
          context.l10n.tasksScanFrameHint,
          textAlign: TextAlign.center,
          style: AppText.meta(c.onDeepMuted),
        ),
      ],
    );
  }
}

class _UsageNote extends ConsumerWidget {
  const _UsageNote();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planProvider).value;
    if (plan == null || plan.cardScans <= 0) return const SizedBox.shrink();
    final fmt = context.fmt;
    final full = plan.cardScansUsed >= plan.cardScans;
    return SrNote(
      tone: full ? SrNoteTone.err : SrNoteTone.gold,
      icon: Icons.workspace_premium_outlined,
      message: context.l10n.tasksScanUsage(
        fmt.number(plan.cardScansUsed),
        fmt.number(plan.cardScans),
        plan.name,
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.enabled,
    required this.onGallery,
    required this.onShutter,
    required this.onQr,
  });

  final bool enabled;
  final VoidCallback onGallery;
  final VoidCallback onShutter;
  final VoidCallback onQr;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _RoundButton(
            icon: Icons.photo_library_outlined,
            tooltip: l10n.tasksScanGallery,
            onTap: enabled ? onGallery : null,
          ),
          const SizedBox(width: 16),
          _RoundButton(
            icon: Icons.camera_alt_rounded,
            tooltip: l10n.tasksScanShutter,
            size: 72,
            primary: true,
            onTap: enabled ? onShutter : null,
          ),
          const SizedBox(width: 16),
          _RoundButton(
            icon: Icons.qr_code_scanner_rounded,
            tooltip: l10n.tasksScanQr,
            onTap: enabled ? onQr : null,
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 52,
    this.primary = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final double size;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Material(
          color: primary ? c.accent : c.surface,
          shape: CircleBorder(
            side: primary ? BorderSide.none : BorderSide(color: c.line),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                icon,
                size: size * 0.42,
                color: primary ? c.onAccent : c.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

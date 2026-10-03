import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Shown when a scan screen opens without a scan, e.g. after a restart.
class ScanEmpty extends StatelessWidget {
  const ScanEmpty({super.key, this.qr = false});

  final bool qr;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: SingleChildScrollView(
        child: SrEmptyState(
          icon: qr ? Icons.qr_code_2_rounded : Icons.badge_outlined,
          title: qr ? l10n.tasksQrEmptyTitle : l10n.tasksReviewEmptyTitle,
          message: l10n.tasksReviewEmptyBody,
          actionLabel: l10n.tasksScanTitle,
          onAction: () => context.pushReplacement(Routes.scan),
        ),
      ),
    );
  }
}

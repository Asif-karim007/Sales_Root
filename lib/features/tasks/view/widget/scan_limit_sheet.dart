import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

const scanUpgradeLocation = '${Routes.planChoose}?reason=quota&kind=cardScans';

/// The lead source a scanned card is filed under.
const visitingCardSource = 'Visiting card';

/// The #98 limit prompt for card scans: upgrade, or type the card in.
Future<void> showScanLimitSheet(BuildContext context) async {
  final router = GoRouter.of(context);
  final location = await showSrSheet<String>(
    context: context,
    builder: (_) => const _ScanLimitSheet(),
  );
  if (location != null) router.push(location);
}

class _ScanLimitSheet extends StatelessWidget {
  const _ScanLimitSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    final manual = Uri(
      path: Routes.leadNew,
      queryParameters: {'source': visitingCardSource},
    ).toString();
    return SrSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrPlanLocked(
            title: l10n.tasksScanLimitTitle,
            message: l10n.tasksScanLimitBody,
            onAction: () => navigator.pop(scanUpgradeLocation),
          ),
          SrButton(
            label: l10n.tasksScanLimitManual,
            variant: SrButtonVariant.ghost,
            expand: true,
            onPressed: () => navigator.pop(manual),
          ),
        ],
      ),
    );
  }
}

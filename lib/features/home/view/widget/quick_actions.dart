import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// New lead, by voice and card scan, as far as the user may add them.
class HomeQuickActions extends ConsumerWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final canAddLead = ref.watch(
      moduleAccessProvider(AppModule.lead).select((a) => a.canAdd),
    );
    final canScan = ref.watch(
      moduleAccessProvider(AppModule.cardScan).select((a) => a.canAdd),
    );
    if (!canAddLead && !canScan) return const SizedBox.shrink();
    return Row(
      children: [
        if (canAddLead) ...[
          Expanded(
            child: SrButton(
              label: l10n.homeNewLead,
              icon: Icons.person_add_alt_1_rounded,
              expand: true,
              onPressed: () => context.push(Routes.leadQuick),
            ),
          ),
          const SizedBox(width: 8),
          _SquareAction(
            icon: Icons.mic_none_rounded,
            tooltip: l10n.homeByVoice,
            color: c.accent,
            onTap: () => context.push(Routes.leadVoice),
          ),
        ],
        if (canScan) ...[
          if (canAddLead) const SizedBox(width: 8),
          if (!canAddLead) const Spacer(),
          _SquareAction(
            icon: Icons.document_scanner_outlined,
            tooltip: l10n.homeScanCard,
            color: c.accent,
            onTap: () => context.push(Routes.scan),
          ),
        ],
      ],
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final shape = BorderRadius.circular(SrMetrics.radiusButton);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: shape,
          side: BorderSide(color: c.line),
        ),
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: SizedBox.square(
            dimension: SrMetrics.buttonHeight,
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }
}

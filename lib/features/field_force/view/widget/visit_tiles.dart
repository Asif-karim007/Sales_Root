import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/providers/visit_providers.dart';
import 'package:salesroot/features/field_force/view/widget/photo_capture.dart';
import 'package:salesroot/features/field_force/view/widget/visit_note_sheet.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// "During this visit": a note and photos kept for the check-out, and
/// quotation, collection and expense in their own features.
class VisitTiles extends ConsumerWidget {
  const VisitTiles({super.key, required this.visit});

  final Visit visit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(visitDetailProvider(visit.id).notifier);
    bool canAdd(AppModule module) =>
        ref.watch(moduleAccessProvider(module).select((a) => a.canAdd));
    final leadId = visit.leadId;
    final companyId = visit.companyId;

    final tiles = [
      _Tile(
        icon: Icons.edit_note_rounded,
        label: l10n.ffNote,
        onTap: () async {
          final text = await showVisitNoteSheet(context);
          if (text != null) notifier.addNote(text);
        },
      ),
      _Tile(
        icon: Icons.photo_camera_outlined,
        label: l10n.ffPhoto,
        onTap: () async {
          final path = await takeVisitPhoto(context);
          if (path != null) notifier.addPhoto(path);
        },
      ),
      if (leadId != null && canAdd(AppModule.quotation))
        _Tile(
          icon: Icons.request_quote_outlined,
          label: l10n.ffQuotation,
          onTap: () => context.push('${Routes.quotationNew}?leadId=$leadId'),
        ),
      if (companyId != null && canAdd(AppModule.collection))
        _Tile(
          icon: Icons.payments_outlined,
          label: l10n.ffCollection,
          onTap: () =>
              context.push('${Routes.collectionNew}?customerId=$companyId'),
        ),
      if (canAdd(AppModule.expense))
        _Tile(
          icon: Icons.receipt_long_outlined,
          label: l10n.ffExpense,
          onTap: () => context.push('${Routes.expenseNew}?visitId=${visit.id}'),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final width = (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return SrCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Column(
        children: [
          Icon(icon, color: c.accent, size: 22),
          const SizedBox(height: 5),
          Text(
            label,
            style: AppText.label(c.ink, size: 11.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

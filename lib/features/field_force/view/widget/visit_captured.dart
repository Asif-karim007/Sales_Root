import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/providers/visit_providers.dart';
import 'package:salesroot/features/field_force/view/widget/photo_capture.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// What was recorded on a visit: notes, photos and the samples shown.
class VisitCaptured extends ConsumerWidget {
  const VisitCaptured({super.key, required this.visit});

  final Visit visit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final samples = visit.sampleProductIds;
    if (visit.notes.isEmpty && visit.photos.isEmpty && samples.isEmpty) {
      return const SizedBox.shrink();
    }
    final products = ref.watch(visitProductsProvider).value ?? const [];
    final names = {for (final p in products) p.id: p.name};

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SrCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final note in visit.notes) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded, size: 16, color: c.ink3),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.text,
                      style: AppText.body(c.ink, size: 14),
                    ),
                  ),
                  if (note.time case final time?)
                    Text(fmt.time(time), style: AppText.meta(c.ink3)),
                ],
              ),
              const SizedBox(height: 10),
            ],
            if (visit.photos.isNotEmpty) ...[
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: visit.photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) =>
                      FfPhotoThumb(path: visit.photos[i].path),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (samples.isNotEmpty) ...[
              Text(l10n.ffSamplesShown, style: AppText.fieldLabel(c.ink2)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final id in samples)
                    SrTag(
                      names[id] ?? '#$id',
                      icon: Icons.inventory_2_outlined,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

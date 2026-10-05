import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/view/widget/photo_capture.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The notes and photos taken on this phone during a visit, sent with the
/// check-out.
class VisitCaptured extends StatelessWidget {
  const VisitCaptured({super.key, required this.draft});

  final VisitDraft draft;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final fmt = context.fmt;
    final photos = draft.photoPaths;
    if (draft.notes.isEmpty && photos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SrCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final note in draft.notes) ...[
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
                  Text(fmt.time(note.time), style: AppText.meta(c.ink3)),
                ],
              ),
              const SizedBox(height: 10),
            ],
            if (photos.isNotEmpty)
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => FfPhotoThumb(path: photos[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

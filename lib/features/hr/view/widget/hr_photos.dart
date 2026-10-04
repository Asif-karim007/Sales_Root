import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Asks for the camera or the gallery and returns the picked photo's path.
Future<String?> pickHrPhoto(BuildContext context) async {
  final l10n = context.l10n;
  final source = await showSrSheet<ImageSource>(
    context: context,
    builder: (sheet) => SrSheet(
      title: l10n.hrPhotoSourceTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SrListRow(
            leading: const SrAvatar(icon: Icons.photo_camera_outlined),
            title: l10n.hrPhotoCamera,
            onTap: () => Navigator.of(sheet).pop(ImageSource.camera),
          ),
          SrListRow(
            leading: const SrAvatar(icon: Icons.photo_library_outlined),
            title: l10n.hrPhotoGallery,
            onTap: () => Navigator.of(sheet).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  try {
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1600,
    );
    return file?.path;
  } on PlatformException {
    if (context.mounted) showSrError(context, l10n.hrPhotoFailed);
    return null;
  }
}

/// Square photo tiles with a remove button, and a dashed tile that adds one
/// until [max] is reached.
class HrPhotoTiles extends StatelessWidget {
  const HrPhotoTiles({
    super.key,
    required this.paths,
    required this.onAdd,
    required this.onRemove,
    this.max = 4,
  });

  final List<String> paths;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final int max;

  static const double _size = 96;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final path in paths)
          _PhotoTile(path: path, size: _size, onRemove: () => onRemove(path)),
        if (paths.length < max)
          _AddTile(
            size: _size,
            label: paths.isEmpty
                ? context.l10n.hrPhotoAdd
                : context.l10n.hrPhotoMore,
            onTap: onAdd,
          ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.path,
    required this.size,
    required this.onRemove,
  });

  final String path;
  final double size;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              cacheWidth: (size * 3).round(),
              errorBuilder: (_, _, _) => _FileName(path: path),
            ),
          ),
          PositionedDirectional(
            top: 4,
            end: 4,
            child: SrIconButton(
              icon: Icons.close_rounded,
              compact: true,
              color: c.danger,
              tooltip: context.l10n.hrPhotoRemove,
              onTap: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

class _FileName extends StatelessWidget {
  const _FileName({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return ColoredBox(
      color: c.avatarBg,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, color: c.ink2),
            const SizedBox(height: 4),
            Text(
              path.split('/').last,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppText.caption(c.ink, size: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.size,
    required this.label,
    required this.onTap,
  });

  final double size;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return SizedBox.square(
      dimension: size,
      child: SrCard(
        tone: SrCardTone.dashed,
        radius: SrMetrics.radiusSmall,
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: c.accent),
            const SizedBox(height: 6),
            Text(label, style: AppText.caption(c.ink, size: 11)),
          ],
        ),
      ),
    );
  }
}

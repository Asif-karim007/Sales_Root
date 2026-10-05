import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Asks selfie or site photo, opens the camera, and returns the file path.
Future<String?> takeVisitPhoto(BuildContext context) async {
  final l10n = context.l10n;
  final camera = await showSrSheet<CameraDevice>(
    context: context,
    builder: (sheet) => SrSheet(
      title: l10n.ffPhotoTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SrListRow(
            leading: const SrAvatar(icon: Icons.face_outlined),
            title: l10n.ffPhotoSelfie,
            subtitle: l10n.ffPhotoSelfieHint,
            onTap: () => Navigator.of(sheet).pop(CameraDevice.front),
            padding: EdgeInsets.zero,
            divider: true,
          ),
          SrListRow(
            leading: const SrAvatar(icon: Icons.storefront_outlined),
            title: l10n.ffPhotoSite,
            subtitle: l10n.ffPhotoSiteHint,
            onTap: () => Navigator.of(sheet).pop(CameraDevice.rear),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    ),
  );
  if (camera == null || !context.mounted) return null;
  return _shoot(context, camera);
}

/// Opens the front camera for the check-in selfie and returns the path.
Future<String?> takeSelfie(BuildContext context) =>
    _shoot(context, CameraDevice.front);

Future<String?> _shoot(BuildContext context, CameraDevice camera) async {
  final denied = context.l10n.ffPhotoCameraDenied;
  try {
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: camera,
      maxWidth: 1600,
      imageQuality: 80,
    );
    return file?.path;
  } on PlatformException {
    if (context.mounted) showSrError(context, denied);
    return null;
  }
}

/// A square thumbnail of a photo on this phone.
class FfPhotoThumb extends StatelessWidget {
  const FfPhotoThumb({super.key, required this.path, this.size = 64});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
      child: SizedBox.square(
        dimension: size,
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          cacheWidth: (size * 3).round(),
          errorBuilder: (_, _, _) => ColoredBox(
            color: c.avatarBg,
            child: Icon(Icons.image_outlined, color: c.ink3),
          ),
        ),
      ),
    );
  }
}

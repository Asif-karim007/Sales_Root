import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';

/// An inline text action, the prototype's `<a>` in the auth screens. A null
/// [onTap] greys it out.
class AuthLink extends StatelessWidget {
  const AuthLink({
    super.key,
    required this.label,
    required this.onTap,
    this.size = 13.5,
  });

  final String label;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text(
            label,
            style: AppText.style(
              size: size,
              weight: FontWeight.w600,
              color: onTap == null ? c.ink3 : c.accent,
            ),
          ),
        ),
      ),
    );
  }
}

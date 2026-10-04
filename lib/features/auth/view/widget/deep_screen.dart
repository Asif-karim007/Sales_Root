import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/auth/view/widget/brand.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The prototype's `.splash`: deep green, the roots drawing, the brand and
/// the tagline, with [bottom] resting on the roots.
class DeepScreen extends StatelessWidget {
  const DeepScreen({super.key, this.bottom});

  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final bottom = this.bottom;
    final padding = MediaQuery.paddingOf(context);
    return SrScaffold(
      safeArea: false,
      backgroundColor: c.deep,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Stack(
          children: [
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RootsBackdrop(),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                28,
                padding.top + 48,
                28,
                padding.bottom + 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AuthBrand(onDark: true),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    context.l10n.authTagline,
                    style: AppText.hero(c.onDeep, size: 32),
                  ),
                  const Spacer(),
                  ?bottom,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The white rounded sheet that sits at the bottom of a [DeepScreen].
class DeepScreenSheet extends StatelessWidget {
  const DeepScreenSheet({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(SrMetrics.radiusSheet),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

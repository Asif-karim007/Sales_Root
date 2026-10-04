import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/auth/auth_links.dart';
import 'package:salesroot/features/auth/view/widget/deep_screen.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #1: tagline, language choice, and the way into sign-up or sign-in.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final locale = ref.watch(appLocaleProvider);
    void choose(Locale value) =>
        ref.read(appLocaleProvider.notifier).set(value);

    return DeepScreen(
      bottom: DeepScreenSheet(
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            children: [
              Text(
                l10n.authWelcomeChooseBn,
                style: AppText.style(
                  size: 13.5,
                  weight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
              Text(
                l10n.authWelcomeChooseEn,
                style: AppText.style(
                  size: 13.5,
                  weight: FontWeight.w600,
                  color: c.ink2,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _LanguageOption(
                  label: l10n.authLanguageBangla,
                  selected: locale == bangla,
                  onTap: () => choose(bangla),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LanguageOption(
                  label: l10n.authLanguageEnglish,
                  selected: locale == english,
                  onTap: () => choose(english),
                ),
              ),
            ],
          ),
          SrButton(
            label: l10n.authWelcomeCreate,
            expand: true,
            onPressed: () => context.push(Routes.authPhone),
          ),
          SrButton(
            label: l10n.authWelcomeSignIn,
            variant: SrButtonVariant.secondary,
            expand: true,
            onPressed: () => context.push(AuthLinks.phone(signIn: true)),
          ),
          Text(
            l10n.authWelcomeTerms,
            textAlign: TextAlign.center,
            style: AppText.meta(c.ink2, size: 11.5),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final shape = BorderRadius.circular(SrMetrics.radiusButton);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: SrMetrics.buttonHeight,
          decoration: BoxDecoration(
            color: selected ? c.tint : c.surface,
            borderRadius: shape,
            border: SrBorder.all(
              color: selected ? c.accent : c.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: shape,
            child: Center(child: Text(label, style: AppText.button(c.ink))),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/auth/models/sign_up_profile.dart';
import 'package:salesroot/features/auth/providers/auth_providers.dart';
import 'package:salesroot/features/auth/view/widget/auth_failure.dart';
import 'package:salesroot/features/auth/view/widget/auth_intro.dart';
import 'package:salesroot/features/auth/view/widget/auth_language_toggle.dart';
import 'package:salesroot/features/auth/view/widget/industry_labels.dart';
import 'package:salesroot/features/auth/view/widget/sign_up_steps.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #6: an optional industry template that shapes forms and stages.
class IndustryScreen extends ConsumerStatefulWidget {
  const IndustryScreen({super.key});

  @override
  ConsumerState<IndustryScreen> createState() => _IndustryScreenState();
}

class _IndustryScreenState extends ConsumerState<IndustryScreen> {
  IndustryTemplate _selected = IndustryTemplate.trading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final applying = ref.watch(industrySubmitProvider).isLoading;
    ref.listen(industrySubmitProvider, (previous, next) {
      switch (next) {
        case AsyncData(value: _?) when previous is AsyncLoading:
          finishSignUp(context, ref);
        case AsyncError(:final error):
          showSrError(context, authFailureText(l10n, error));
        default:
      }
    });

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.authIndustryAppBar,
        subtitle: l10n.commonOptional,
        actions: const [AuthLanguageToggle()],
      ),
      footer: Row(
        children: [
          Expanded(
            child: SrButton(
              label: l10n.commonSkip,
              variant: SrButtonVariant.secondary,
              expand: true,
              onPressed: applying ? null : () => finishSignUp(context, ref),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SrButton(
              label: l10n.authIndustryUse,
              expand: true,
              loading: applying,
              onPressed: () =>
                  ref.read(industrySubmitProvider.notifier).apply(_selected),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthIntro(
              title: l10n.authIndustryTitle,
              lead: Text(l10n.authIndustryLead),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final template in IndustryTemplate.values)
                  _IndustryTile(
                    template: template,
                    selected: template == _selected,
                    onTap: () => setState(() => _selected = template),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IndustryTile extends StatelessWidget {
  const _IndustryTile({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final IndustryTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final shape = BorderRadius.circular(SrMetrics.radiusCard);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: Ink(
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
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(template.icon, size: 24, color: c.accent),
                  Text(
                    template.label(context.l10n),
                    style: AppText.rowTitle(c.ink, size: 14),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/auth/models/pin_entry.dart';
import 'package:salesroot/features/auth/providers/pin_providers.dart';
import 'package:salesroot/features/auth/view/widget/auth_intro.dart';
import 'package:salesroot/features/auth/view/widget/auth_language_toggle.dart';
import 'package:salesroot/features/auth/view/widget/shake.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #4: choose a 4-digit PIN, then type it again to confirm.
class PinScreen extends ConsumerWidget {
  const PinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final setup = ref.watch(pinSetupProvider);
    final notifier = ref.read(pinSetupProvider.notifier);
    ref.listen(pinSetupProvider.select((s) => s.saved), (_, saved) {
      if (saved) context.go(Routes.authProfile);
    });
    final error = switch (setup.error) {
      PinSetupError.weak => l10n.authPinWeak,
      PinSetupError.mismatch => l10n.authPinMismatch,
      null => null,
    };

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.authSignUpTitle,
        subtitle: l10n.authStep(fmt.number(3), fmt.number(4)),
        actions: const [AuthLanguageToggle()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _LockBadge(),
                  const SizedBox(height: 14),
                  AuthIntro(
                    center: true,
                    title: setup.confirming
                        ? l10n.authPinConfirmTitle
                        : l10n.authPinTitle,
                    lead: Text(
                      setup.confirming
                          ? l10n.authPinConfirmLead
                          : l10n.authPinLead,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Shake(
                    trigger: setup.mistakes,
                    child: SrPinDots(
                      filled: setup.entry.length,
                      error: error != null && setup.entry.isEmpty,
                    ),
                  ),
                  if (error != null)
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: AppText.meta(c.danger),
                    ),
                  const SizedBox(height: 16),
                  SrButton(
                    label: l10n.commonNext,
                    expand: true,
                    loading: setup.saving,
                    onPressed: setup.complete ? notifier.submit : null,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SrKeypad(
              onDigit: notifier.digit,
              onBackspace: notifier.backspace,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockBadge extends StatelessWidget {
  const _LockBadge();

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(color: c.tint, shape: BoxShape.circle),
        child: Icon(Icons.lock_outline_rounded, size: 30, color: c.accent),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/session/auth_session.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/auth/auth_links.dart';
import 'package:salesroot/features/auth/models/bd_phone.dart';
import 'package:salesroot/features/auth/models/pin_entry.dart';
import 'package:salesroot/features/auth/providers/pin_providers.dart';
import 'package:salesroot/features/auth/view/widget/auth_language_toggle.dart';
import 'package:salesroot/features/auth/view/widget/auth_link.dart';
import 'package:salesroot/features/auth/view/widget/brand.dart';
import 'package:salesroot/features/auth/view/widget/shake.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #11: the PIN in front of a restored session. Five wrong tries sign out.
class UnlockScreen extends ConsumerWidget {
  const UnlockScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref, String to) async {
    final router = GoRouter.of(context);
    await ref.read(pinUnlockProvider.notifier).signOut();
    router.go(to);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final unlock = ref.watch(pinUnlockProvider);
    final notifier = ref.read(pinUnlockProvider.notifier);
    final session = ref.watch(sessionProvider).value;
    ref.listen(pinUnlockProvider.select((s) => s.lockedOut), (_, lockedOut) {
      if (lockedOut) showSrError(context, l10n.authUnlockLockedOut);
    });
    final wrong = unlock.attempts > 0 && unlock.entry.isEmpty;

    return SrScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 16, 0),
            child: Row(
              children: [AuthBrand(size: 16), Spacer(), AuthLanguageToggle()],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (session != null)
                    _Account(
                      session: session,
                      onOtherAccount: () =>
                          _signOut(context, ref, AuthLinks.phone(signIn: true)),
                    ),
                  Shake(
                    trigger: unlock.attempts,
                    child: SrPinDots(filled: unlock.entry.length, error: wrong),
                  ),
                  if (unlock.attempts > 0)
                    Text(
                      l10n.authUnlockWrong(
                        context.fmt.number(unlock.triesLeft),
                      ),
                      textAlign: TextAlign.center,
                      style: AppText.meta(c.danger),
                    ),
                  const SizedBox(height: 14),
                  SrButton(
                    label: l10n.authUnlockAction,
                    expand: true,
                    loading: unlock.checking,
                    onPressed: unlock.entry.length == pinLength
                        ? notifier.submit
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: AuthLink(
                      label: l10n.authUnlockForgot,
                      size: 13,
                      onTap: () =>
                          _signOut(context, ref, AuthLinks.phone(signIn: true)),
                    ),
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
              enabled: !unlock.checking && !unlock.lockedOut,
            ),
          ),
        ],
      ),
    );
  }
}

class _Account extends StatelessWidget {
  const _Account({required this.session, required this.onOtherAccount});

  final AuthSession session;
  final VoidCallback onOtherAccount;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final phone = session.phone;
    return Column(
      children: [
        SrAvatar(name: session.name, size: 64),
        const SizedBox(height: 10),
        Text(session.name, style: AppText.pageTitle(c.ink)),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.center,
          children: [
            if (phone != null) ...[
              Text(
                context.fmt.phone(BdPhone.display(phone)),
                style: AppText.meta(c.ink2, size: 13),
              ),
              Container(
                width: 3,
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: c.ink3,
                  shape: BoxShape.circle,
                ),
              ),
            ],
            AuthLink(
              label: l10n.authUnlockOtherAccount,
              size: 13,
              onTap: onOtherAccount,
            ),
          ],
        ),
      ],
    );
  }
}

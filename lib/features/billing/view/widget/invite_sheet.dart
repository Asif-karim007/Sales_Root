import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/billing/data/billing_repositories.dart';
import 'package:salesroot/features/billing/models/referral.dart';
import 'package:salesroot/features/billing/providers/referral_providers.dart';
import 'package:salesroot/features/billing/view/widget/billing_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Opens #184 and reports the server's answer to the invite.
Future<void> showInviteSheet(BuildContext context) async {
  final result = await showSrSheet<InviteResult>(
    context: context,
    builder: (_) => const InviteSheet(),
  );
  if (result == null || !context.mounted) return;
  final message = result.message.of(context.isBangla);
  showSrSuccess(
    context,
    message.isEmpty ? context.l10n.billingInviteSent : message,
  );
}

/// #184 Invite a contact, checking eligibility as the number is typed.
class InviteSheet extends ConsumerStatefulWidget {
  const InviteSheet({super.key});

  @override
  ConsumerState<InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends ConsumerState<InviteSheet> {
  static const _debounce = Duration(milliseconds: 450);

  final _controller = TextEditingController();
  Timer? _timer;
  String _query = '';

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  Future<void> _pickContact() async {
    final repository = ref.read(referralRepositoryProvider);
    final l10n = context.l10n;
    final contact = await showSrSheet<InviteContact>(
      context: context,
      builder: (_) => SrSearchSheet<InviteContact>(
        title: l10n.billingPickContact,
        searchHint: l10n.billingPickContactHint,
        search: repository.contacts,
        labelOf: (c) => c.name,
        subtitleOf: (c) => joinDot([c.phone, c.company ?? '']),
        isSelected: (_) => false,
        withAvatar: true,
      ),
    );
    if (contact == null || !mounted) return;
    _controller.text = contact.phone;
    _timer?.cancel();
    setState(() => _query = contact.phone);
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final sending = ref.watch(inviteProvider).isLoading;
    ref.listen(inviteProvider, (previous, next) {
      final saved = next.value;
      if (saved != null) Navigator.of(context).pop(saved);
      final error = next.error;
      if (error is ApiFailure && !next.isLoading) {
        showSrError(context, error.message);
      }
    });
    final check = _query.isEmpty
        ? null
        : ref.watch(inviteCheckProvider(_query));
    final eligible =
        check?.value == InviteEligibility.eligible &&
        !(check?.isLoading ?? true);

    return SrSheet(
      title: l10n.billingInviteTitle,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SrTextField(
              controller: _controller,
              label: l10n.billingInviteField,
              hint: l10n.billingInviteHint,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              onChanged: _onChanged,
              suffix: TextButton(
                onPressed: _pickContact,
                child: Text(
                  l10n.billingContacts,
                  style: AppText.chip(c.accent, size: 12.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (check != null) ...[
              _Eligibility(value: check),
              const SizedBox(height: 14),
            ],
            Row(
              children: [
                Expanded(
                  child: SrButton(
                    label: l10n.billingSendSms,
                    icon: Icons.sms_outlined,
                    expand: true,
                    loading: sending,
                    onPressed: eligible
                        ? () => ref
                              .read(inviteProvider.notifier)
                              .send(_query, sms: true)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SrButton(
                    label: l10n.billingJustRecord,
                    variant: SrButtonVariant.secondary,
                    expand: true,
                    onPressed: eligible && !sending
                        ? () => ref
                              .read(inviteProvider.notifier)
                              .send(_query, sms: false)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.billingRecordTip,
              textAlign: TextAlign.center,
              style: AppText.meta(c.ink2, size: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _Eligibility extends ConsumerWidget {
  const _Eligibility({required this.value});

  final AsyncValue<InviteEligibility> value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reward = ref.watch(
      referralOverviewProvider.select((o) => o.value?.registerReward ?? 0),
    );
    return switch (value) {
      AsyncData(:final value) => _note(context, value, reward),
      AsyncError(:final error) => SrErrorState(error: error, compact: true),
      _ => const SrSkeletonBox(height: 48, radius: 10),
    };
  }

  Widget _note(BuildContext context, InviteEligibility check, int reward) {
    final l10n = context.l10n;
    return switch (check) {
      InviteEligibility.eligible => SrNote(
        title: l10n.billingEligible,
        message: l10n.billingEligibleBody(context.fmt.money(reward)),
      ),
      InviteEligibility.alreadyUser => SrNote(
        tone: SrNoteTone.neutral,
        message: l10n.billingAlreadyUser,
      ),
      InviteEligibility.alreadyInvited => SrNote(
        tone: SrNoteTone.gold,
        message: l10n.billingAlreadyInvited,
      ),
      InviteEligibility.invalid => SrNote(
        tone: SrNoteTone.err,
        message: l10n.billingInvalidContact,
      ),
    };
  }
}

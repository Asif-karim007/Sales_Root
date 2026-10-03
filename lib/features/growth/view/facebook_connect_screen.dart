import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/growth/models/lead_channel.dart';
import 'package:salesroot/features/growth/providers/sources_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #135 Connect a Facebook Page's lead forms: sign in, pick the Page, pick
/// the forms, map their questions, save.
class FacebookConnectScreen extends ConsumerWidget {
  const FacebookConnectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final setup = ref.watch(facebookSetupProvider);
    final draft = setup.value;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.growthFacebookTitle,
        actions: const [GrowthLanguageAction()],
      ),
      body: SrAsyncView(
        value: setup,
        onRetry: () => ref.invalidate(facebookSetupProvider),
        onUpgrade: () => context.push(Routes.planUsage),
        loading: (_) => const SrSkeletonList(count: 5, cards: true),
        data: (context, draft) => _StepBody(draft: draft),
      ),
      footer: draft == null ? null : _Footer(draft: draft),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.draft});

  final FacebookDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final step = draft.step;
    final children = switch (step) {
      FacebookStep.signIn => [const _SignInCard()],
      FacebookStep.page => [_PagePicker(draft: draft)],
      FacebookStep.forms => [_PageCard(draft: draft), _FormsCard(draft: draft)],
      FacebookStep.mapping => [
        _PageCard(draft: draft),
        _MappingCard(draft: draft),
        _DestinationField(draft: draft),
      ],
      FacebookStep.connected => [
        _PageCard(draft: draft),
        _FormsCard(draft: draft),
        _MappingCard(draft: draft),
        _DestinationField(draft: draft),
        const _DisconnectButton(),
      ],
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      children: [
        if (!draft.connected) ...[
          SrSteps(
            steps: [
              l10n.growthFacebookStepSignIn,
              l10n.growthFacebookStepPage,
              l10n.growthFacebookStepForms,
              l10n.growthFacebookStepFields,
            ],
            current: step.index.clamp(0, 3),
          ),
          const SizedBox(height: 16),
        ],
        for (final child in children) ...[child, const SizedBox(height: 12)],
      ],
    );
  }
}

class _SignInCard extends StatelessWidget {
  const _SignInCard();

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    return SrCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SrAvatar(
            icon: Icons.facebook_rounded,
            tone: SrAvatarTone.accent,
            square: true,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.growthFacebookSignInTitle,
            style: AppText.sectionTitle(c.ink, size: 17),
          ),
          const SizedBox(height: 6),
          Text(l10n.growthFacebookSignInBody, style: AppText.lead(c.ink2)),
          const SizedBox(height: 12),
          for (final line in [
            l10n.growthFacebookSignInPoint1,
            l10n.growthFacebookSignInPoint2,
            l10n.growthFacebookSignInPoint3,
          ])
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: c.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(line, style: AppText.body(c.ink, size: 14)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PagePicker extends ConsumerWidget {
  const _PagePicker({required this.draft});

  final FacebookDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    return SrRowGroup(
      title: l10n.growthFacebookPickPage,
      rows: [
        for (final page in draft.pages)
          SrListRow(
            leading: SrAvatar(name: page.name, square: true),
            title: page.name,
            subtitle: l10n.growthFacebookPageMeta(
              page.adminName,
              fmt.number(page.followers),
            ),
            chevron: true,
            onTap: draft.busy
                ? null
                : () => _guard(
                    context,
                    ref.read(facebookSetupProvider.notifier).pickPage(page),
                  ),
          ),
      ],
    );
  }
}

class _PageCard extends StatelessWidget {
  const _PageCard({required this.draft});

  final FacebookDraft draft;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final page = draft.page;
    if (page == null) return const SizedBox.shrink();
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const SrAvatar(
            icon: Icons.facebook_rounded,
            tone: SrAvatarTone.accent,
            square: true,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(page.name, style: AppText.rowTitle(c.ink)),
                Text(
                  page.tokenOk
                      ? l10n.growthFacebookPageAdmin(page.adminName)
                      : l10n.growthFacebookTokenExpired,
                  style: AppText.meta(page.tokenOk ? c.ink2 : c.danger),
                ),
              ],
            ),
          ),
          if (draft.connected)
            SrTag(l10n.growthChannelConnected, tone: SrTone.ok),
        ],
      ),
    );
  }
}

class _FormsCard extends ConsumerWidget {
  const _FormsCard({required this.draft});

  final FacebookDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final notifier = ref.read(facebookSetupProvider.notifier);
    if (draft.forms.isEmpty) {
      return SrEmptyState(
        icon: Icons.dynamic_form_outlined,
        title: l10n.growthFacebookNoForms,
        message: l10n.growthFacebookNoFormsBody,
      );
    }
    return SrRowGroup(
      title: l10n.growthFacebookForms,
      rows: [
        for (final form in draft.forms)
          GrowthToggleRow(
            title: form.name,
            subtitle: [
              if (form.campaign case final campaign?)
                l10n.growthFacebookCampaign(campaign),
              if (form.leadCount > 0)
                l10n.growthChannelLeads(fmt.number(form.leadCount)),
            ].join(' · '),
            value: draft.enabled.contains(form.id),
            onChanged: draft.busy ? null : (_) => notifier.toggleForm(form.id),
          ),
      ],
    );
  }
}

class _MappingCard extends ConsumerWidget {
  const _MappingCard({required this.draft});

  final FacebookDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final mappings = draft.visibleMappings;
    if (mappings.isEmpty) {
      return SrNote(
        message: l10n.growthFacebookTurnOnForm,
        tone: SrNoteTone.gold,
      );
    }
    return SrRowGroup(
      title: l10n.growthFacebookMapFields,
      rows: [
        for (final mapping in mappings)
          SrListRow(
            title: mapping.field,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_forward_rounded, size: 16, color: c.ink3),
                const SizedBox(width: 8),
                SrTag(
                  mapping.target.label(l10n),
                  tone: mapping.target == LeadField.skip
                      ? SrTone.neutral
                      : SrTone.accent,
                ),
              ],
            ),
            onTap: draft.busy ? null : () => _pick(context, ref, mapping),
          ),
      ],
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    FieldMapping mapping,
  ) async {
    final l10n = context.l10n;
    final picked = await showSrSheet<LeadField>(
      context: context,
      builder: (_) => SrOptionSheet<LeadField>(
        title: mapping.field,
        options: LeadField.values,
        labelOf: (field) => field.label(l10n),
        isSelected: (field) => field == mapping.target,
      ),
    );
    if (picked == null) return;
    ref.read(facebookSetupProvider.notifier).map(mapping.field, picked);
  }
}

class _DestinationField extends ConsumerWidget {
  const _DestinationField({required this.draft});

  final FacebookDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SrDropdownField(
      label: l10n.growthFacebookDestination,
      value: draft.destination.label(l10n),
      onTap: draft.busy
          ? null
          : () async {
              final picked = await showSrSheet<LeadDestination>(
                context: context,
                builder: (_) => SrOptionSheet<LeadDestination>(
                  title: l10n.growthFacebookDestination,
                  options: LeadDestination.values,
                  labelOf: (d) => d.label(l10n),
                  isSelected: (d) => d == draft.destination,
                ),
              );
              if (picked == null) return;
              ref.read(facebookSetupProvider.notifier).setDestination(picked);
            },
    );
  }
}

class _DisconnectButton extends ConsumerWidget {
  const _DisconnectButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SrButton(
      label: l10n.growthFacebookDisconnect,
      variant: SrButtonVariant.ghost,
      icon: Icons.link_off_rounded,
      onPressed: () async {
        final confirmed = await showSrConfirm(
          context,
          title: l10n.growthFacebookDisconnectTitle,
          message: l10n.growthFacebookDisconnectBody,
          confirmLabel: l10n.growthChannelDisconnect,
          icon: Icons.link_off_rounded,
          destructive: true,
        );
        if (!confirmed || !context.mounted) return;
        final channels = await ref.read(leadChannelsProvider.future);
        final page = channels
            .where((c) => c.kind == ChannelKind.facebook)
            .firstOrNull;
        if (page == null || !context.mounted) return;
        final done = await runGrowthAction(
          context,
          ref.read(channelActionsProvider.notifier).disconnect(page.id),
        );
        if (done != null && context.mounted) {
          showSrSuccess(context, l10n.growthChannelDisconnected);
        }
      },
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.draft});

  final FacebookDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(facebookSetupProvider.notifier);
    return switch (draft.step) {
      FacebookStep.signIn => SrButton(
        label: l10n.growthFacebookContinue,
        icon: Icons.facebook_rounded,
        expand: true,
        loading: draft.busy,
        onPressed: () => _guard(context, notifier.signIn()),
      ),
      FacebookStep.page => SrButton(
        label: l10n.commonBack,
        variant: SrButtonVariant.secondary,
        expand: true,
        loading: draft.busy,
        onPressed: () => notifier.goTo(FacebookStep.signIn),
      ),
      FacebookStep.forms => _TwoButtons(
        back: () => notifier.goTo(FacebookStep.page),
        label: l10n.commonNext,
        onPressed: draft.enabled.isEmpty
            ? null
            : () => notifier.goTo(FacebookStep.mapping),
      ),
      FacebookStep.mapping => _TwoButtons(
        back: () => notifier.goTo(FacebookStep.forms),
        label: l10n.growthFacebookConnect,
        loading: draft.busy,
        onPressed: () => _save(context, ref, l10n.growthFacebookConnectedDone),
      ),
      FacebookStep.connected => SrButton(
        label: l10n.commonSave,
        expand: true,
        loading: draft.busy,
        onPressed: () => _save(context, ref, l10n.growthFacebookSaved),
      ),
    };
  }

  Future<void> _save(BuildContext context, WidgetRef ref, String done) async {
    try {
      await ref.read(facebookSetupProvider.notifier).save();
      if (!context.mounted) return;
      showSrSuccess(context, done);
      if (draft.connected && context.canPop()) context.pop();
    } catch (error) {
      if (!context.mounted) return;
      showSrError(context, growthFailureText(context, error));
    }
  }
}

class _TwoButtons extends StatelessWidget {
  const _TwoButtons({
    required this.back,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final VoidCallback back;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: SrButton(
          label: context.l10n.commonBack,
          variant: SrButtonVariant.secondary,
          onPressed: loading ? null : back,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: SrButton(label: label, loading: loading, onPressed: onPressed),
      ),
    ],
  );
}

Future<void> _guard(BuildContext context, Future<void> work) async {
  try {
    await work;
  } catch (error) {
    if (!context.mounted) return;
    showSrError(context, growthFailureText(context, error));
  }
}

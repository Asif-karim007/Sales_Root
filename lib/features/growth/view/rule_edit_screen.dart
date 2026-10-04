import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/growth/models/distribution_rule.dart';
import 'package:salesroot/features/growth/providers/distribution_providers.dart';
import 'package:salesroot/features/growth/providers/inbox_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/rule_fields.dart';
import 'package:salesroot/features/growth/view/widget/rule_text.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #140 One distribution rule: conditions, who gets the lead, schedule and
/// caps. Id 0 makes a new rule.
class RuleEditScreen extends ConsumerStatefulWidget {
  const RuleEditScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<RuleEditScreen> createState() => _RuleEditScreenState();
}

class _RuleEditScreenState extends ConsumerState<RuleEditScreen> {
  final _name = TextEditingController();
  RuleInput? _draft;
  DistributionRule? _rule;

  static const _blank = RuleInput(
    name: '',
    mode: AssignMode.roundRobin,
    enabled: true,
    sources: [],
    areas: [],
    forms: [],
    memberIds: [],
    onlyCheckedIn: false,
    skipOnLeave: true,
    days: [],
    escalateMinutes: 15,
  );

  @override
  void initState() {
    super.initState();
    ref.listenManual(distributionRuleProvider(widget.id), (_, next) {
      if (_draft != null || !next.hasValue) return;
      final rule = next.value;
      setState(() {
        _rule = rule;
        _draft = rule == null ? _blank : RuleInput.of(rule);
        _name.text = rule?.name ?? '';
      });
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _change(RuleInput Function(RuleInput draft) edit) {
    final draft = _draft;
    if (draft == null) return;
    setState(() => _draft = edit(draft));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final submit = ref.watch(ruleSubmitProvider(widget.id));
    ref.listen(ruleSubmitProvider(widget.id), _onSubmit);
    final access = ref.watch(moduleAccessProvider(AppModule.distribution));
    final rule = _rule;
    final draft = _draft;
    final canSave = widget.id == 0
        ? access.canAdd
        : access.canEdit && (rule?.canEdit ?? false);
    final canDelete =
        widget.id != 0 && access.canDelete && (rule?.canDelete ?? false);
    final failure = switch (submit) {
      AsyncError(:final ApiFailure error) => error,
      _ => null,
    };
    return SrScaffold(
      appBar: SrAppBar(
        title: widget.id == 0 ? l10n.growthRuleNew : l10n.growthRuleTitle,
        actions: const [GrowthLanguageAction()],
      ),
      body: SrAsyncView(
        value: ref.watch(distributionRuleProvider(widget.id)),
        onRetry: () => ref.invalidate(distributionRuleProvider(widget.id)),
        onUpgrade: () => context.push(Routes.planUsage),
        loading: (_) => const SrSkeletonList(count: 6, cards: true),
        data: (context, _) => draft == null
            ? const SrSkeletonList(count: 6, cards: true)
            : SrKeyboardDismiss(
                child: _Form(
                  name: _name,
                  draft: draft,
                  enabled: canSave && !submit.isLoading,
                  vocabulary: _vocabulary(),
                  failure: failure,
                  onChange: _change,
                ),
              ),
      ),
      footer: draft == null || !(canSave || canDelete)
          ? null
          : Row(
              children: [
                if (canDelete) ...[
                  Expanded(
                    child: SrButton(
                      label: l10n.commonDelete,
                      variant: SrButtonVariant.danger,
                      onPressed: submit.isLoading ? null : _delete,
                    ),
                  ),
                  if (canSave) const SizedBox(width: 10),
                ],
                if (canSave)
                  Expanded(
                    child: SrButton(
                      label: l10n.commonSave,
                      loading: submit.isLoading,
                      onPressed: () => ref
                          .read(ruleSubmitProvider(widget.id).notifier)
                          .save(draft.copyWith(name: _name.text)),
                    ),
                  ),
              ],
            ),
    );
  }

  RuleVocabulary _vocabulary() {
    final members = ref.watch(growthMembersProvider).value ?? const [];
    final areas = ref.watch(ruleAreasProvider).value ?? const [];
    return RuleVocabulary(
      members: {for (final m in members) m.id: m},
      areas: {for (final a in areas) a.en: a},
    );
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await showSrConfirm(
      context,
      title: l10n.growthRuleDeleteTitle,
      message: l10n.growthRuleDeleteBody,
      confirmLabel: l10n.commonDelete,
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await ref.read(ruleSubmitProvider(widget.id).notifier).delete();
  }

  void _onSubmit(AsyncValue<RuleOutcome?>? _, AsyncValue<RuleOutcome?> next) {
    final l10n = context.l10n;
    switch (next) {
      case AsyncError(:final ApiFailure error)
          when error.fieldError('Name') != null ||
              error.fieldError('MemberIds') != null ||
              error.isConflict:
        return;
      case AsyncError(:final error):
        showSrError(context, growthFailureText(context, error));
      case AsyncData(value: RuleOutcome.saved):
        showSrSuccess(context, l10n.growthRuleSaved);
        context.pop();
      case AsyncData(value: RuleOutcome.deleted):
        showSrInfo(context, l10n.growthRuleDeleted);
        context.pop();
      default:
        return;
    }
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.name,
    required this.draft,
    required this.enabled,
    required this.vocabulary,
    required this.failure,
    required this.onChange,
  });

  final TextEditingController name;
  final RuleInput draft;
  final bool enabled;
  final RuleVocabulary vocabulary;
  final ApiFailure? failure;
  final void Function(RuleInput Function(RuleInput draft) edit) onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = this.failure;
    final nameError = failure == null
        ? null
        : failure.isConflict
        ? l10n.growthRuleNameTaken
        : failure.fieldError('Name') == null
        ? null
        : l10n.commonRequired;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      children: [
        SrTextField(
          controller: name,
          label: l10n.growthRuleName,
          hint: l10n.growthRuleNameHint,
          error: nameError,
          enabled: enabled,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),
        SrSectionHeader(title: l10n.growthRuleIf),
        const SizedBox(height: 8),
        RuleConditions(
          draft: draft,
          enabled: enabled,
          vocabulary: vocabulary,
          onChange: onChange,
        ),
        const SizedBox(height: 16),
        SrSectionHeader(title: l10n.growthRuleThen),
        const SizedBox(height: 8),
        RuleAssignment(
          draft: draft,
          enabled: enabled,
          vocabulary: vocabulary,
          membersError: failure?.fieldError('MemberIds') == null
              ? null
              : l10n.growthRuleMembersRequired,
          onChange: onChange,
        ),
        const SizedBox(height: 16),
        SrSectionHeader(title: l10n.growthRuleSchedule),
        const SizedBox(height: 8),
        RuleSchedule(draft: draft, enabled: enabled, onChange: onChange),
        const SizedBox(height: 12),
        SrRowGroup(
          rows: [
            GrowthToggleRow(
              title: l10n.growthRuleEnabled,
              value: draft.enabled,
              onChanged: enabled
                  ? (value) => onChange((d) => d.copyWith(enabled: value))
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

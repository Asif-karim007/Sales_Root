import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/auth/models/sign_up_profile.dart';
import 'package:salesroot/features/auth/models/team_setup.dart';
import 'package:salesroot/features/auth/providers/invite_providers.dart';
import 'package:salesroot/features/auth/view/widget/auth_failure.dart';
import 'package:salesroot/features/auth/view/widget/auth_language_toggle.dart';
import 'package:salesroot/features/auth/view/widget/industry_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #9: a new team workspace with the user as owner, then switched to.
class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _name = TextEditingController();
  IndustryTemplate _industry = IndustryTemplate.trading;
  TeamCurrency _currency = TeamCurrency.bdt;
  final Set<AddOn> _addOns = {};
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickIndustry() async {
    final l10n = context.l10n;
    final picked = await showSrSheet<IndustryTemplate>(
      context: context,
      builder: (_) => SrOptionSheet<IndustryTemplate>(
        title: l10n.authTeamIndustryLabel,
        options: IndustryTemplate.values,
        labelOf: (t) => t.label(l10n),
        isSelected: (t) => t == _industry,
      ),
    );
    if (picked != null) setState(() => _industry = picked);
  }

  Future<void> _pickCurrency() async {
    final l10n = context.l10n;
    final picked = await showSrSheet<TeamCurrency>(
      context: context,
      builder: (_) => SrOptionSheet<TeamCurrency>(
        title: l10n.authTeamCurrencyLabel,
        options: TeamCurrency.values,
        labelOf: (currency) => _currencyLabel(l10n, currency),
        isSelected: (currency) => currency == _currency,
      ),
    );
    if (picked != null) setState(() => _currency = picked);
  }

  Widget _addOnRow(
    AddOn addOn,
    String title,
    String subtitle, {
    bool divider = false,
  }) => SrListRow(
    title: title,
    subtitle: subtitle,
    divider: divider,
    padding: const EdgeInsets.symmetric(vertical: 8),
    trailing: SrSwitch(
      value: _addOns.contains(addOn),
      onChanged: (on) =>
          setState(() => on ? _addOns.add(addOn) : _addOns.remove(addOn)),
    ),
  );

  void _create() {
    if (_name.text.trim().length < 2) {
      setState(() => _nameError = context.l10n.authTeamNameRequired);
      return;
    }
    FocusScope.of(context).unfocus();
    ref
        .read(createTeamProvider.notifier)
        .create(
          _name.text,
          TeamSetup(
            industry: _industry,
            currency: _currency,
            addOns: {..._addOns},
          ),
        );
  }

  void _onCreated(
    AsyncValue<Workspace?>? previous,
    AsyncValue<Workspace?> next,
  ) {
    final l10n = context.l10n;
    switch (next) {
      case AsyncData(:final value?) when previous is AsyncLoading:
        showSrSuccess(context, l10n.authTeamCreated(value.name));
        context.go(Routes.home);
      case AsyncError(:final error):
        if (authFieldError(error, 'name') != null) {
          setState(() => _nameError = l10n.authTeamNameRequired);
        } else {
          showSrError(context, authFailureText(l10n, error));
        }
      default:
    }
  }

  static String _currencyLabel(AppLocalizations l10n, TeamCurrency currency) =>
      l10n.authCurrency(currency.wire, currency.symbol);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final creating = ref.watch(createTeamProvider).isLoading;
    ref.listen(createTeamProvider, _onCreated);

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.authTeamAppBar,
        actions: const [AuthLanguageToggle()],
      ),
      footer: SrButton(
        label: l10n.authTeamCreate,
        expand: true,
        loading: creating,
        onPressed: _create,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SrTextField(
              controller: _name,
              label: l10n.authTeamNameLabel,
              hint: l10n.authTeamNameHint,
              error: _nameError,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() => _nameError = null),
            ),
            const SizedBox(height: 14),
            SrDropdownField(
              label: l10n.authTeamIndustryLabel,
              value: _industry.label(l10n),
              onTap: _pickIndustry,
            ),
            const SizedBox(height: 14),
            SrDropdownField(
              label: l10n.authTeamCurrencyLabel,
              value: _currencyLabel(l10n, _currency),
              onTap: _pickCurrency,
            ),
            const SizedBox(height: 14),
            SrCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  _addOnRow(
                    AddOn.fieldForce,
                    l10n.authTeamFieldForce,
                    l10n.authTeamFieldForceSub,
                    divider: true,
                  ),
                  _addOnRow(
                    AddOn.growth,
                    l10n.authTeamGrowth,
                    l10n.authTeamGrowthSub,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SrNote(
              message: l10n.authTeamOwnerNote,
              icon: Icons.info_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

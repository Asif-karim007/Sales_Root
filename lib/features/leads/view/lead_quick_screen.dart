import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/leads/models/lead_input.dart';
import 'package:salesroot/features/leads/models/lead_lookups.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';
import 'package:salesroot/features/leads/view/widget/lead_save_flow.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #24: a lead from just a name and a number. [companyId] and [contactId]
/// prefill it from a company or contact screen.
class LeadQuickScreen extends ConsumerStatefulWidget {
  const LeadQuickScreen({super.key, this.companyId, this.contactId});

  final int? companyId;
  final int? contactId;

  @override
  ConsumerState<LeadQuickScreen> createState() => _LeadQuickScreenState();
}

class _LeadQuickScreenState extends ConsumerState<LeadQuickScreen> {
  static const _slot = 'quick';
  static const _shownInterests = 3;

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final Set<int> _interests = {};
  String? _nameError;
  String? _phoneError;
  LeadInput? _input;
  LeadLookupCompany? _company;
  LeadLookupContact? _contact;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    if (widget.companyId == null && widget.contactId == null) return;
    final lookups = await ref.read(leadLookupsProvider.future);
    if (!mounted) return;
    final contact = lookups.contact(widget.contactId);
    final company = lookups.company(widget.companyId ?? contact?.companyId);
    setState(() {
      _company = company;
      _contact = contact;
      if (_name.text.isEmpty) _name.text = company?.name ?? contact?.name ?? '';
      if (_phone.text.isEmpty) _phone.text = contact?.mobile ?? '';
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = context.l10n;
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    setState(() {
      _nameError = name.isEmpty ? l10n.leadsErrorName : null;
      _phoneError = phone.isNotEmpty && !isLeadMobile(phone)
          ? l10n.leadsErrorMobile
          : null;
    });
    if (_nameError != null || _phoneError != null) return;
    final company = _company;
    final contact = _contact;
    final input = LeadInput(
      leadName: name,
      companyId: company != null && company.name == name ? company.id : null,
      contactIds: [?contact?.id],
      newContact: contact == null && phone.isNotEmpty
          ? LeadNewContact(name: name, mobile: phone)
          : null,
      interestIds: _interests.toList(),
    );
    _input = input;
    ref.read(leadSaveProvider(_slot).notifier).create(input);
  }

  void _fullForm() {
    final query = {
      if (_name.text.trim().isNotEmpty) 'name': _name.text.trim(),
      if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
      if (_company case final company?) 'company': company.name,
    };
    context.pushReplacement(
      Uri(path: Routes.leadNew, queryParameters: query).toString(),
    );
  }

  Future<void> _moreInterests(List<LeadOption> all) async {
    final bangla = context.fmt.isBangla;
    final picked = await showSrSheet<List<LeadOption>>(
      context: context,
      builder: (context) => SrMultiOptionSheet<LeadOption>(
        title: context.l10n.leadsInterestedIn,
        options: all,
        labelOf: (o) => o.name.of(bangla),
        isSelected: (o) => _interests.contains(o.id),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _interests
        ..clear()
        ..addAll(picked.map((o) => o.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final save = ref.watch(leadSaveProvider(_slot));
    final locale = ref.watch(appLocaleProvider);
    final canScan = ref.watch(moduleAccessProvider(AppModule.cardScan)).canAdd;
    ref.listen(
      leadSaveProvider(_slot),
      (_, next) => onLeadSaved(
        context,
        next,
        input: _input,
        retry: ref.read(leadSaveProvider(_slot).notifier).create,
      ),
    );
    return SrKeyboardDismiss(
      child: SrScaffold(
        appBar: SrAppBar(
          title: l10n.leadsNewLead,
          actions: [
            SrLanguageToggle(
              isBangla: locale == bangla,
              onChanged: (isBangla) => ref
                  .read(appLocaleProvider.notifier)
                  .set(isBangla ? bangla : english),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(SrMetrics.gutter),
          children: [
            SrTextField(
              controller: _name,
              label: l10n.leadsNameOrCompany,
              hint: l10n.leadsNameOrCompanyHint,
              prefixIcon: Icons.person_outline_rounded,
              error: _nameError ?? leadFieldError(save, 'LeadName'),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofocus: widget.companyId == null && widget.contactId == null,
            ),
            const SizedBox(height: 14),
            SrTextField(
              controller: _phone,
              label: l10n.leadsMobile,
              hint: l10n.leadsMobileHint,
              prefixIcon: Icons.call_outlined,
              error: _phoneError ?? leadFieldError(save, 'Mobile'),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ \-]')),
              ],
            ),
            const SizedBox(height: 14),
            SrFieldLabel(l10n.leadsInterestedIn, optional: true),
            const SizedBox(height: 8),
            _Interests(
              selected: _interests,
              shown: _shownInterests,
              onToggle: (id) => setState(() {
                if (!_interests.remove(id)) _interests.add(id);
              }),
              onMore: _moreInterests,
            ),
            const SizedBox(height: 16),
            SrNote(message: l10n.leadsQuickNote),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SrButton(
                    label: l10n.leadsSpeak,
                    icon: Icons.mic_none_rounded,
                    variant: SrButtonVariant.secondary,
                    expand: true,
                    onPressed: () => context.pushReplacement(Routes.leadVoice),
                  ),
                ),
                if (canScan) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: SrButton(
                      label: l10n.leadsScanCard,
                      icon: Icons.document_scanner_outlined,
                      variant: SrButtonVariant.secondary,
                      expand: true,
                      onPressed: () => context.pushReplacement(Routes.scan),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        footer: Row(
          children: [
            Expanded(
              child: SrButton(
                label: l10n.leadsFullForm,
                variant: SrButtonVariant.secondary,
                expand: true,
                onPressed: _fullForm,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SrButton(
                label: l10n.commonSave,
                expand: true,
                loading: save.isLoading,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Interests extends ConsumerWidget {
  const _Interests({
    required this.selected,
    required this.shown,
    required this.onToggle,
    required this.onMore,
  });

  final Set<int> selected;
  final int shown;
  final ValueChanged<int> onToggle;
  final ValueChanged<List<LeadOption>> onMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bangla = context.fmt.isBangla;
    final all = ref.watch(leadLookupsProvider).value?.interests ?? const [];
    final visible = [
      for (final (i, o) in all.indexed)
        if (i < shown || selected.contains(o.id)) o,
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final option in visible)
          SrChip(
            label: option.name.of(bangla),
            selected: selected.contains(option.id),
            onTap: () => onToggle(option.id),
          ),
        if (all.length > visible.length)
          SrChip(
            label: context.l10n.leadsMoreInterests,
            icon: Icons.add_rounded,
            tone: SrTone.accent,
            onTap: () => onMore(all),
          ),
        if (all.isEmpty)
          const SrSkeletonBox(width: 180, height: 30, radius: 15),
      ],
    );
  }
}

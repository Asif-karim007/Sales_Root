import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/leads/models/lead_input.dart';
import 'package:salesroot/features/leads/models/lead_lookups.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';
import 'package:salesroot/features/leads/view/widget/lead_save_flow.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #24: a lead from just a name and a number. [companyId] and [contactId]
/// prefill it from a company or contact screen.
class LeadQuickScreen extends ConsumerStatefulWidget {
  const LeadQuickScreen({super.key, this.companyId, this.contactId});

  final String? companyId;
  final String? contactId;

  @override
  ConsumerState<LeadQuickScreen> createState() => _LeadQuickScreenState();
}

class _LeadQuickScreenState extends ConsumerState<LeadQuickScreen> {
  static const _slot = 'quick';

  final _name = TextEditingController();
  final _phone = TextEditingController();
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
    final repository = ref.read(leadRepositoryProvider);
    final contactId = widget.contactId;
    final LeadLookupContact? contact;
    final LeadLookupCompany? company;
    try {
      contact = contactId == null ? null : await repository.contact(contactId);
      final companyId = widget.companyId ?? contact?.companyId;
      company = companyId == null ? null : await repository.company(companyId);
    } on ApiFailure {
      return;
    }
    if (!mounted) return;
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
      phone: phone,
      companyId: company?.id,
      contactId: contact?.id,
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
              error: _nameError ?? leadFieldError(save, 'name'),
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
              error: _phoneError ?? leadFieldError(save, 'phone'),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ \-]')),
              ],
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

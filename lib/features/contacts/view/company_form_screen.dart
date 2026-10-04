import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/contacts/models/bd_phone.dart';
import 'package:salesroot/features/contacts/models/company.dart';
import 'package:salesroot/features/contacts/models/linked_records.dart';
import 'package:salesroot/features/contacts/providers/companies_providers.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_feedback.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_header.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_sheets.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// New and edit company, in the lead form's style. [id] 0 creates.
class CompanyFormScreen extends ConsumerWidget {
  const CompanyFormScreen({super.key, this.id = 0, this.name});

  final int id;

  /// Prefills the name of a new company.
  final String? name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (id == 0) return _CompanyForm(id: 0, name: name);
    final company = ref.watch(companyProvider(id));
    final loaded = company.value;
    if (loaded != null) return _CompanyForm(id: id, initial: loaded);
    return SrScaffold(
      appBar: SrAppBar(title: context.l10n.contactsEditCompany),
      body: SrAsyncView<Company>(
        value: company,
        onRetry: () => ref.invalidate(companyProvider(id)),
        loading: (_) => const SrSkeletonList(count: 5, cards: true),
        data: (_, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _CompanyForm extends ConsumerStatefulWidget {
  const _CompanyForm({required this.id, this.initial, this.name});

  final int id;
  final Company? initial;
  final String? name;

  @override
  ConsumerState<_CompanyForm> createState() => _CompanyFormState();
}

class _CompanyFormState extends ConsumerState<_CompanyForm> {
  late final _name = TextEditingController(
    text: widget.initial?.name ?? widget.name,
  );
  late final _phone = TextEditingController(
    text: switch (widget.initial?.contactNumber) {
      final phone? => BdPhone.display(phone),
      null => null,
    },
  );
  late final _address = TextEditingController(text: widget.initial?.address);
  late final _website = TextEditingController(
    text: widget.initial?.websiteProspect,
  );
  late final _email = TextEditingController(text: widget.initial?.email);
  late final _creditLimit = TextEditingController(
    text: widget.initial?.creditLimit?.toString(),
  );
  late final _creditDays = TextEditingController(
    text: widget.initial?.creditDays?.toString(),
  );
  late final _note = TextEditingController(text: widget.initial?.note);
  late String? _industry = widget.initial?.industryType;
  late String? _area = widget.initial?.zoneName;
  Map<String, String> _errors = const {};

  @override
  void dispose() {
    for (final controller in [
      _name,
      _phone,
      _address,
      _website,
      _email,
      _creditLimit,
      _creditDays,
      _note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, String> _validate(AppLocalizations l10n) {
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    return {
      if (_name.text.trim().isEmpty) 'name': l10n.contactsCompanyNameRequired,
      if (phone.isNotEmpty && BdPhone.any(phone) == null)
        'phone': l10n.contactsPhoneInvalid,
      if (email.isNotEmpty && !RegExp(r'^\S+@\S+\.\S+$').hasMatch(email))
        'email': l10n.contactsEmailInvalid,
    };
  }

  void _save({bool allowDuplicate = false}) {
    final errors = _validate(context.l10n);
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    final base = widget.initial;
    final phone = _phone.text.trim();
    final area = _area;
    final keepPin = base != null && base.zoneName == area;
    final input = CompanyInput(
      name: _name.text,
      industryType: _industry,
      zoneName: area,
      contactNumber: phone.isEmpty ? null : BdPhone.any(phone),
      email: _email.text,
      websiteProspect: _website.text,
      address: _address.text,
      latitude: keepPin ? base.latitude : null,
      longitude: keepPin ? base.longitude : null,
      note: _note.text,
      tags: base?.tags ?? const [],
      creditLimit: int.tryParse(_creditLimit.text.trim()),
      creditDays: int.tryParse(_creditDays.text.trim()),
    );
    ref
        .read(companySaveProvider(widget.id).notifier)
        .save(input, allowDuplicate: allowDuplicate);
  }

  Future<void> _pick({
    required String title,
    required List<LocalizedName> options,
    required String? selected,
    required ValueChanged<String> onPicked,
  }) async {
    final bangla = context.fmt.isBangla;
    final picked = await showSrSheet<LocalizedName>(
      context: context,
      builder: (_) => SrOptionSheet<LocalizedName>(
        title: title,
        options: options,
        labelOf: (option) => option.of(bangla),
        isSelected: (option) => option.en == selected,
      ),
    );
    if (picked == null) return;
    setState(() => onPicked(picked.en));
  }

  Future<void> _onDuplicates(List<DuplicateMatch> matches) async {
    final choice = await showDuplicateSheet(
      context,
      matches: matches,
      company: true,
    );
    if (!mounted) return;
    switch (choice) {
      case OpenExisting(:final match):
        context.pushReplacement(Routes.companyFor(match.id));
      case SaveAnyway():
        _save(allowDuplicate: true);
      case null:
    }
  }

  void _onFailure(Object error) {
    final l10n = context.l10n;
    if (error is ApiFailure && error.isValidation) {
      setState(
        () => _errors = {
          if (error.fieldError('Name') != null)
            'name': l10n.contactsCompanyNameRequired,
          if (error.fieldError('ContactNumber') != null)
            'phone': l10n.contactsPhoneInvalid,
        },
      );
      if (_errors.isNotEmpty) return;
    }
    showFailure(context, error);
  }

  String? _labelOf(List<LocalizedName>? options, String? value) {
    if (value == null) return null;
    final match = options?.where((o) => o.en == value).firstOrNull;
    return match?.of(context.fmt.isBangla) ?? value;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final saving = ref.watch(companySaveProvider(widget.id)).isLoading;
    final easy = ref.watch(experienceLevelProvider) == ExperienceLevel.easy;
    final lookups = ref.watch(companyLookupsProvider).value;

    ref.listen(companySaveProvider(widget.id), (_, next) {
      switch (next) {
        case AsyncData(value: Saved(:final value)):
          showSrSuccess(context, l10n.contactsCompanySaved);
          widget.id == 0
              ? context.pushReplacement(Routes.companyFor(value.id))
              : context.pop();
        case AsyncData(value: Duplicates(:final matches)):
          _onDuplicates(matches);
        case AsyncError(:final error):
          _onFailure(error);
        default:
      }
    });

    return SrScaffold(
      appBar: SrAppBar(
        title: widget.id == 0
            ? l10n.contactsNewCompany
            : l10n.contactsEditCompany,
        subtitle: easy ? null : l10n.contactsFullForm,
        actions: const [ContactsLanguageToggle()],
      ),
      footer: SrButton(
        label: l10n.commonSave,
        expand: true,
        loading: saving,
        onPressed: _save,
      ),
      body: SrKeyboardDismiss(
        child: ListView(
          padding: const EdgeInsets.all(SrMetrics.gutter),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: [
                SrTextField(
                  controller: _name,
                  label: l10n.contactsCompanyName,
                  hint: l10n.contactsCompanyNameHint,
                  error: _errors['name'],
                  textCapitalization: TextCapitalization.words,
                  autofocus: widget.id == 0 && widget.name == null,
                ),
                SrTextField(
                  controller: _phone,
                  label: l10n.contactsPhone,
                  optional: true,
                  hint: l10n.contactsCompanyPhoneHint,
                  error: _errors['phone'],
                  prefixIcon: Icons.call_outlined,
                  keyboardType: TextInputType.phone,
                ),
                Row(
                  spacing: 10,
                  children: [
                    if (!easy)
                      Expanded(
                        child: SrDropdownField(
                          label: l10n.contactsIndustry,
                          optional: true,
                          placeholder: l10n.contactsPick,
                          value: _labelOf(lookups?.industries, _industry),
                          onTap: lookups == null
                              ? null
                              : () => _pick(
                                  title: l10n.contactsIndustry,
                                  options: lookups.industries,
                                  selected: _industry,
                                  onPicked: (value) => _industry = value,
                                ),
                        ),
                      ),
                    Expanded(
                      child: SrDropdownField(
                        label: l10n.contactsArea,
                        optional: true,
                        placeholder: l10n.contactsPick,
                        value: _labelOf(lookups?.areas, _area),
                        onTap: lookups == null
                            ? null
                            : () => _pick(
                                title: l10n.contactsArea,
                                options: lookups.areas,
                                selected: _area,
                                onPicked: (value) => _area = value,
                              ),
                      ),
                    ),
                  ],
                ),
                SrTextField(
                  controller: _address,
                  label: l10n.contactsAddress,
                  optional: true,
                  hint: l10n.contactsCompanyAddressHint,
                  prefixIcon: Icons.place_outlined,
                ),
                if (!easy) ..._moreFields(l10n),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _moreFields(AppLocalizations l10n) => [
    SrTextField(
      controller: _website,
      label: l10n.contactsWebsite,
      optional: true,
      hint: l10n.contactsWebsiteHint,
      prefixIcon: Icons.language_rounded,
      keyboardType: TextInputType.url,
    ),
    SrTextField(
      controller: _email,
      label: l10n.contactsEmail,
      optional: true,
      hint: l10n.contactsCompanyEmailHint,
      error: _errors['email'],
      prefixIcon: Icons.mail_outline_rounded,
      keyboardType: TextInputType.emailAddress,
    ),
    Row(
      spacing: 10,
      children: [
        Expanded(
          child: SrTextField(
            controller: _creditLimit,
            label: l10n.contactsCreditLimit,
            optional: true,
            hint: l10n.contactsCreditLimitHint,
            suffixText: l10n.contactsCurrency,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        Expanded(
          child: SrTextField(
            controller: _creditDays,
            label: l10n.contactsCreditDays,
            optional: true,
            hint: l10n.contactsCreditDaysHint,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      ],
    ),
    SrTextField(
      controller: _note,
      label: l10n.contactsNote,
      optional: true,
      hint: l10n.contactsCompanyNoteHint,
      multiline: true,
    ),
  ];
}

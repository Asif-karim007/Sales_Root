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
import 'package:salesroot/features/contacts/models/bd_phone.dart';
import 'package:salesroot/features/contacts/models/company.dart';
import 'package:salesroot/features/contacts/models/linked_records.dart';
import 'package:salesroot/features/contacts/providers/companies_providers.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_feedback.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_header.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_sheets.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// New and edit company, in the lead form's style. An empty [id] creates.
class CompanyFormScreen extends ConsumerWidget {
  const CompanyFormScreen({super.key, this.id = '', this.name});

  final String id;

  /// Prefills the name of a new company.
  final String? name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (id.isEmpty) return _CompanyForm(id: id, name: name);
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

  final String id;
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
  late final _area = TextEditingController(text: widget.initial?.area);
  late final _website = TextEditingController(text: widget.initial?.website);
  late final _email = TextEditingController(text: widget.initial?.email);
  late final _creditLimit = TextEditingController(
    text: widget.initial?.creditLimit?.round().toString(),
  );
  late final _creditDays = TextEditingController(
    text: widget.initial?.creditDays?.toString(),
  );
  late final _note = TextEditingController(text: widget.initial?.note);
  late final Map<String, String> _custom = {
    for (final MapEntry(:key, :value) in (widget.initial?.custom ?? {}).entries)
      if (value != null) key: '$value',
  };
  Map<String, String> _errors = const {};

  @override
  void dispose() {
    for (final controller in [
      _name,
      _phone,
      _address,
      _area,
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
    final phone = _phone.text.trim();
    final input = CompanyInput(
      name: _name.text,
      area: _area.text,
      contactNumber: phone.isEmpty ? null : BdPhone.any(phone),
      email: _email.text,
      website: _website.text,
      address: _address.text,
      note: _note.text,
      creditLimit: double.tryParse(_creditLimit.text.trim()),
      creditDays: int.tryParse(_creditDays.text.trim()),
      custom: _custom,
    );
    ref
        .read(companySaveProvider(widget.id).notifier)
        .save(input, allowDuplicate: allowDuplicate);
  }

  Future<void> _pick(CompanyField field) async {
    final picked = await showSrSheet<String>(
      context: context,
      builder: (_) => SrOptionSheet<String>(
        title: field.label.of(context.fmt.isBangla),
        options: field.options,
        labelOf: (option) => option,
        isSelected: (option) => option == _custom[field.key],
      ),
    );
    if (picked == null) return;
    setState(() => _custom[field.key] = picked);
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
    if (error is ApiFailure && error.isValidation) {
      setState(
        () => _errors = {
          'name': ?error.fieldError('name'),
          'phone': ?error.fieldError('phone'),
          'email': ?error.fieldError('email'),
        },
      );
      if (_errors.isNotEmpty) return;
    }
    showFailure(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final saving = ref.watch(companySaveProvider(widget.id)).isLoading;
    final easy = ref.watch(experienceLevelProvider) == ExperienceLevel.easy;
    final fields = ref.watch(contactsPackProvider).value?.companyFields;

    ref.listen(companySaveProvider(widget.id), (_, next) {
      switch (next) {
        case AsyncData(value: Saved(:final value)):
          showSrSuccess(context, l10n.contactsCompanySaved);
          widget.id.isEmpty
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
        title: widget.id.isEmpty
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
                  autofocus: widget.id.isEmpty && widget.name == null,
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
                SrTextField(
                  controller: _area,
                  label: l10n.contactsArea,
                  optional: true,
                  hint: l10n.contactsAreaHint,
                  textCapitalization: TextCapitalization.words,
                ),
                SrTextField(
                  controller: _address,
                  label: l10n.contactsAddress,
                  optional: true,
                  hint: l10n.contactsCompanyAddressHint,
                  prefixIcon: Icons.place_outlined,
                ),
                for (final field in fields ?? const <CompanyField>[])
                  _CustomField(
                    field: field,
                    value: _custom[field.key],
                    onChanged: (value) => _custom[field.key] = value,
                    onPick: () => _pick(field),
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

/// One of the workspace's company fields: a picker for a `select` field,
/// otherwise free text.
class _CustomField extends StatefulWidget {
  const _CustomField({
    required this.field,
    required this.value,
    required this.onChanged,
    required this.onPick,
  });

  final CompanyField field;
  final String? value;
  final ValueChanged<String> onChanged;
  final VoidCallback onPick;

  @override
  State<_CustomField> createState() => _CustomFieldState();
}

class _CustomFieldState extends State<_CustomField> {
  late final _text = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final field = widget.field;
    final label = field.label.of(context.fmt.isBangla);
    if (field.options.isNotEmpty) {
      return SrDropdownField(
        label: label,
        optional: true,
        placeholder: l10n.contactsPick,
        value: widget.value,
        onTap: widget.onPick,
      );
    }
    return SrTextField(
      controller: _text,
      label: label,
      optional: true,
      onChanged: widget.onChanged,
    );
  }
}

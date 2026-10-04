import 'package:flutter/material.dart';
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
import 'package:salesroot/features/contacts/models/contact.dart';
import 'package:salesroot/features/contacts/models/linked_records.dart';
import 'package:salesroot/features/contacts/providers/companies_providers.dart';
import 'package:salesroot/features/contacts/providers/contacts_providers.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_feedback.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_header.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_sheets.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Values a new contact starts with, from the route's query.
class ContactPrefill {
  const ContactPrefill({this.companyId, this.name, this.phone, this.email});

  final int? companyId;
  final String? name;
  final String? phone;
  final String? email;
}

/// New and edit contact, in the lead form's style. [id] 0 creates.
class ContactFormScreen extends ConsumerWidget {
  const ContactFormScreen({
    super.key,
    this.id = 0,
    this.prefill = const ContactPrefill(),
  });

  final int id;
  final ContactPrefill prefill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (id == 0) return _ContactForm(id: 0, prefill: prefill);
    final contact = ref.watch(contactProvider(id));
    final loaded = contact.value;
    if (loaded != null) {
      return _ContactForm(id: id, initial: loaded, prefill: prefill);
    }
    return SrScaffold(
      appBar: SrAppBar(title: context.l10n.contactsEditContact),
      body: SrAsyncView<Contact>(
        value: contact,
        onRetry: () => ref.invalidate(contactProvider(id)),
        loading: (_) => const SrSkeletonList(count: 5, cards: true),
        data: (_, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _ContactForm extends ConsumerStatefulWidget {
  const _ContactForm({required this.id, required this.prefill, this.initial});

  final int id;
  final ContactPrefill prefill;
  final Contact? initial;

  @override
  ConsumerState<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends ConsumerState<_ContactForm> {
  late final _name = TextEditingController(
    text: widget.initial?.name ?? widget.prefill.name,
  );
  late final _mobile = TextEditingController(
    text: _local(widget.initial?.phone ?? widget.prefill.phone),
  );
  late final _mobile2 = TextEditingController(
    text: _local(widget.initial?.mobiles.skip(1).firstOrNull),
  );
  late final _designation = TextEditingController(
    text: widget.initial?.designation,
  );
  late final _email = TextEditingController(
    text: widget.initial?.email ?? widget.prefill.email,
  );
  late final _address = TextEditingController(text: widget.initial?.address);
  late final _note = TextEditingController(text: widget.initial?.note);
  late int? _companyId = widget.initial == null
      ? widget.prefill.companyId
      : widget.initial?.companyId;
  late String? _companyName = widget.initial?.companyName;
  late DateTime? _birthday = widget.initial?.dateOfBirth;
  Map<String, String> _errors = const {};

  static String? _local(String? phone) =>
      phone == null ? null : BdPhone.display(phone);

  @override
  void dispose() {
    for (final controller in [
      _name,
      _mobile,
      _mobile2,
      _designation,
      _email,
      _address,
      _note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, String> _validate(AppLocalizations l10n) {
    final email = _email.text.trim();
    final second = _mobile2.text.trim();
    return {
      if (_name.text.trim().isEmpty) 'name': l10n.contactsNameRequired,
      if (_mobile.text.trim().isEmpty)
        'mobile': l10n.contactsMobileRequired
      else if (BdPhone.mobile(_mobile.text) == null)
        'mobile': l10n.contactsMobileInvalid,
      if (second.isNotEmpty && BdPhone.mobile(second) == null)
        'mobile2': l10n.contactsMobileInvalid,
      if (email.isNotEmpty && !RegExp(r'^\S+@\S+\.\S+$').hasMatch(email))
        'email': l10n.contactsEmailInvalid,
    };
  }

  void _save({bool allowDuplicate = false}) {
    final errors = _validate(context.l10n);
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    final base = widget.initial;
    final email = _email.text.trim();
    final input = ContactInput(
      name: _name.text,
      designation: _designation.text,
      companyId: _companyId,
      mobiles: [
        ?BdPhone.mobile(_mobile.text),
        ?BdPhone.mobile(_mobile2.text),
        ...?base?.mobiles.skip(2),
      ],
      emails: [if (email.isNotEmpty) email, ...?base?.emails.skip(1)],
      address: _address.text,
      dateOfBirth: _birthday,
      note: _note.text,
      tags: base?.tags ?? const [],
      source: base?.source,
    );
    ref
        .read(contactSaveProvider(widget.id).notifier)
        .save(input, allowDuplicate: allowDuplicate);
  }

  Future<void> _pickCompany() async {
    final l10n = context.l10n;
    final repository = ref.read(contactsRepositoryProvider);
    final picked = await showSrSheet<Company>(
      context: context,
      builder: (_) => SrSearchSheet<Company>(
        title: l10n.contactsPickCompany,
        searchHint: l10n.contactsCompanySearchHint,
        withAvatar: true,
        search: (term, page) async => (await repository.companies(
          CompanyQuery(search: term, page: page),
        )).items,
        labelOf: (company) => company.name,
        subtitleOf: (company) => company.zoneName,
        isSelected: (company) => company.id == _companyId,
      ),
    );
    if (picked == null) return;
    setState(() {
      _companyId = picked.id;
      _companyName = picked.name;
    });
  }

  Future<void> _pickBirthday() async {
    final picked = await showSrDatePicker(
      context: context,
      initial: _birthday ?? DateTime(1990),
      first: DateTime(1930),
      last: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _birthday = picked);
  }

  Future<void> _onDuplicates(List<DuplicateMatch> matches) async {
    final choice = await showDuplicateSheet(
      context,
      matches: matches,
      company: false,
    );
    if (!mounted) return;
    switch (choice) {
      case OpenExisting(:final match):
        context.pushReplacement(Routes.contactFor(match.id));
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
            'name': l10n.contactsNameRequired,
          if (error.fieldError('Mobiles') != null)
            'mobile': l10n.contactsMobileInvalid,
        },
      );
      if (_errors.isNotEmpty) return;
    }
    showFailure(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final saving = ref.watch(contactSaveProvider(widget.id)).isLoading;
    final easy = ref.watch(experienceLevelProvider) == ExperienceLevel.easy;
    final companyId = _companyId;
    final companyName =
        _companyName ??
        (companyId == null
            ? null
            : ref.watch(companyProvider(companyId)).value?.name);

    ref.listen(contactSaveProvider(widget.id), (_, next) {
      switch (next) {
        case AsyncData(value: Saved(:final value)):
          showSrSuccess(context, l10n.contactsSaved);
          widget.id == 0
              ? context.pushReplacement(Routes.contactFor(value.id))
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
            ? l10n.contactsNewContact
            : l10n.contactsEditContact,
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
                  label: l10n.contactsName,
                  hint: l10n.contactsNameHint,
                  error: _errors['name'],
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofocus: widget.id == 0 && widget.prefill.name == null,
                ),
                SrTextField(
                  controller: _mobile,
                  label: l10n.contactsMobile,
                  hint: l10n.contactsMobileHint,
                  error: _errors['mobile'],
                  prefixIcon: Icons.call_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                _CompanyField(
                  name: companyName,
                  onPick: _pickCompany,
                  onClear: () => setState(() {
                    _companyId = null;
                    _companyName = null;
                  }),
                ),
                SrTextField(
                  controller: _designation,
                  label: l10n.contactsDesignation,
                  optional: true,
                  hint: l10n.contactsDesignationHint,
                  textCapitalization: TextCapitalization.words,
                ),
                if (!easy) ..._moreFields(l10n),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _moreFields(AppLocalizations l10n) {
    final birthday = _birthday;
    return [
      SrTextField(
        controller: _mobile2,
        label: l10n.contactsSecondMobile,
        optional: true,
        hint: l10n.contactsMobileHint,
        error: _errors['mobile2'],
        keyboardType: TextInputType.phone,
      ),
      SrTextField(
        controller: _email,
        label: l10n.contactsEmail,
        optional: true,
        hint: l10n.contactsEmailHint,
        error: _errors['email'],
        prefixIcon: Icons.mail_outline_rounded,
        keyboardType: TextInputType.emailAddress,
      ),
      SrTextField(
        controller: _address,
        label: l10n.contactsAddress,
        optional: true,
        hint: l10n.contactsAddressHint,
      ),
      SrDropdownField(
        label: l10n.contactsBirthday,
        optional: true,
        icon: Icons.cake_outlined,
        placeholder: l10n.contactsPickDate,
        value: birthday == null ? null : context.fmt.date(birthday),
        onTap: _pickBirthday,
      ),
      SrTextField(
        controller: _note,
        label: l10n.contactsNote,
        optional: true,
        hint: l10n.contactsNoteHint,
        multiline: true,
      ),
    ];
  }
}

class _CompanyField extends StatelessWidget {
  const _CompanyField({
    required this.name,
    required this.onPick,
    required this.onClear,
  });

  final String? name;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 8,
      children: [
        Expanded(
          child: SrDropdownField(
            label: l10n.contactsCompany,
            optional: true,
            icon: Icons.apartment_rounded,
            placeholder: l10n.contactsPickCompany,
            value: name,
            onTap: onPick,
          ),
        ),
        if (name != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: SrIconButton(
              icon: Icons.close_rounded,
              tooltip: l10n.contactsRemoveCompany,
              onTap: onClear,
            ),
          ),
      ],
    );
  }
}

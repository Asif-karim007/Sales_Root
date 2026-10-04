import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_input.dart';
import 'package:salesroot/features/leads/models/lead_lookups.dart';
import 'package:salesroot/features/leads/models/lead_stage.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';
import 'package:salesroot/features/leads/view/widget/lead_labels.dart';
import 'package:salesroot/features/leads/view/widget/lead_save_flow.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// What a card scan or another screen hands the new-lead form.
class LeadPrefill {
  const LeadPrefill({
    this.name,
    this.phone,
    this.email,
    this.company,
    this.designation,
    this.source,
  });

  factory LeadPrefill.fromQuery(Map<String, String> query) => LeadPrefill(
    name: query['name'],
    phone: query['phone'],
    email: query['email'],
    company: query['company'],
    designation: query['designation'],
    source: query['source'],
  );

  final String? name;
  final String? phone;
  final String? email;
  final String? company;
  final String? designation;
  final String? source;
}

/// #26: the full lead form, for a new lead ([id] null) or an edit.
class LeadFormScreen extends ConsumerWidget {
  const LeadFormScreen({
    super.key,
    this.id,
    this.prefill = const LeadPrefill(),
  });

  final int? id;
  final LeadPrefill prefill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = this.id;
    final locale = ref.watch(appLocaleProvider);
    final lookups = ref.watch(leadLookupsProvider);
    final stages = ref.watch(visibleLeadStagesProvider);
    final lead = id == null ? null : ref.watch(leadProvider(id));
    final ready = switch ((lookups, stages, lead)) {
      (AsyncData(value: final l), AsyncData(value: final s), null) =>
        AsyncData<(LeadLookups, List<LeadStage>, Lead?)>((l, s, null)),
      (
        AsyncData(value: final l),
        AsyncData(value: final s),
        AsyncData(value: final d),
      ) =>
        AsyncData<(LeadLookups, List<LeadStage>, Lead?)>((l, s, d)),
      (AsyncError(:final error, :final stackTrace), _, _) ||
      (_, AsyncError(:final error, :final stackTrace), _) ||
      (
        _,
        _,
        AsyncError(:final error, :final stackTrace),
      ) => AsyncError<(LeadLookups, List<LeadStage>, Lead?)>(error, stackTrace),
      _ => const AsyncLoading<(LeadLookups, List<LeadStage>, Lead?)>(),
    };
    return SrKeyboardDismiss(
      child: SrScaffold(
        appBar: SrAppBar(
          title: id == null ? l10n.leadsNewLead : l10n.leadsEditLead,
          subtitle: l10n.leadsFullForm,
          actions: [
            SrLanguageToggle(
              isBangla: locale == bangla,
              onChanged: (isBangla) => ref
                  .read(appLocaleProvider.notifier)
                  .set(isBangla ? bangla : english),
            ),
          ],
        ),
        body: SrAsyncView(
          value: ready,
          onRetry: () {
            ref.invalidate(leadLookupsProvider);
            ref.invalidate(leadStagesProvider);
            if (id != null) ref.invalidate(leadProvider(id));
          },
          data: (context, data) => _LeadForm(
            lookups: data.$1,
            stages: data.$2,
            lead: data.$3,
            prefill: prefill,
          ),
        ),
      ),
    );
  }
}

class _LeadForm extends ConsumerStatefulWidget {
  const _LeadForm({
    required this.lookups,
    required this.stages,
    required this.lead,
    required this.prefill,
  });

  final LeadLookups lookups;
  final List<LeadStage> stages;
  final Lead? lead;
  final LeadPrefill prefill;

  @override
  ConsumerState<_LeadForm> createState() => _LeadFormState();
}

class _LeadFormState extends ConsumerState<_LeadForm> {
  final _title = TextEditingController();
  final _contactName = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _designation = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  int? _companyId;
  String? _companyName;
  List<int> _contactIds = [];
  DateTime? _closing;
  int? _sourceId;
  int? _stageId;
  int? _ownerId;
  LeadTemperature? _temperature;
  List<int> _tagIds = [];
  List<int> _interestIds = [];
  String? _titleError;
  String? _mobileError;
  String? _amountError;
  LeadInput? _input;

  String get _slot => widget.lead == null ? 'form' : 'edit';

  @override
  void initState() {
    super.initState();
    final lead = widget.lead;
    if (lead != null) {
      _seedFromLead(lead);
    } else {
      _seedFromPrefill(widget.prefill);
    }
  }

  void _seedFromLead(Lead lead) {
    final input = LeadInput.fromLead(lead);
    final typed = input.newContact;
    _title.text = input.leadName;
    _companyId = input.companyId;
    _companyName = input.companyName;
    _contactIds = [...input.contactIds];
    _contactName.text = typed?.name ?? '';
    _mobile.text = typed?.mobile ?? '';
    _email.text = typed?.email ?? '';
    _designation.text = typed?.designation ?? '';
    final amount = input.estimatedAmount;
    _amount.text = amount == null ? '' : amount.round().toString();
    _closing = input.estimatedClosingDate;
    _sourceId = input.sourceId;
    _stageId = input.stageId;
    _ownerId = input.assignedToEmployeeId;
    _temperature = input.temperature;
    _tagIds = [...input.tagIds];
    _interestIds = [...input.interestIds];
    _note.text = input.comments ?? '';
  }

  void _seedFromPrefill(LeadPrefill prefill) {
    final known = widget.lookups.companyNamed(prefill.company);
    final company = prefill.company?.trim() ?? '';
    _title.text = company.isNotEmpty ? company : prefill.name ?? '';
    _companyId = known?.id;
    _companyName = known == null && company.isNotEmpty ? company : null;
    _contactName.text = prefill.name ?? '';
    _mobile.text = prefill.phone ?? '';
    _email.text = prefill.email ?? '';
    _designation.text = prefill.designation ?? '';
    _sourceId = widget.lookups.sourceNamed(prefill.source)?.id;
    _stageId = widget.stages.firstOrNull?.id;
    _ownerId = widget.lookups.currentEmployeeId;
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _contactName,
      _mobile,
      _email,
      _designation,
      _amount,
      _note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _fromCard {
    final source = widget.lookups.sourceNamed(widget.prefill.source);
    return widget.lead == null && source?.name.en == 'Visiting card';
  }

  void _save() {
    final l10n = context.l10n;
    final title = _title.text.trim();
    final mobile = _mobile.text.trim();
    final amountText = _amount.text.trim();
    final amount = double.tryParse(amountText);
    setState(() {
      _titleError = title.isEmpty ? l10n.leadsErrorTitle : null;
      _mobileError = mobile.isNotEmpty && !isLeadMobile(mobile)
          ? l10n.leadsErrorMobile
          : null;
      _amountError = amountText.isNotEmpty && amount == null
          ? l10n.leadsErrorAmount
          : null;
    });
    if (_titleError != null || _mobileError != null || _amountError != null) {
      return;
    }
    final contactName = _contactName.text.trim();
    final typed = LeadNewContact(
      name: contactName.isEmpty ? title : contactName,
      mobile: mobile,
      email: _email.text,
      designation: _designation.text,
    );
    final input = LeadInput(
      leadName: title,
      companyId: _companyId,
      companyName: _companyId == null ? _companyName : null,
      contactIds: _contactIds,
      newContact: contactName.isEmpty && mobile.isEmpty && _email.text.isEmpty
          ? null
          : typed,
      estimatedAmount: amount,
      estimatedClosingDate: _closing,
      sourceId: _sourceId,
      stageId: _stageId,
      assignedToEmployeeId: _ownerId,
      temperature: _temperature,
      tagIds: _tagIds,
      interestIds: _interestIds,
      comments: _note.text,
    );
    _input = input;
    final save = ref.read(leadSaveProvider(_slot).notifier);
    final lead = widget.lead;
    if (lead == null) {
      save.create(input);
    } else {
      save.edit(lead.id, input);
    }
  }

  Future<T?> _pick<T>(Widget sheet) =>
      showSrSheet<T>(context: context, builder: (_) => sheet);

  Future<void> _pickCompany() async {
    final l10n = context.l10n;
    final bangla = context.fmt.isBangla;
    final none = LeadLookupCompany(id: 0, name: l10n.leadsNoCompany);
    final picked = await _pick<LeadLookupCompany>(
      SrOptionSheet<LeadLookupCompany>(
        title: l10n.leadsCompany,
        options: [none, ...widget.lookups.companies],
        labelOf: (c) => c.name,
        subtitleOf: (c) => c.area?.of(bangla),
        isSelected: (c) => c.id == (_companyId ?? 0),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _companyId = picked.id == 0 ? null : picked.id;
      _companyName = null;
      _contactIds = [];
    });
  }

  Future<void> _pickContacts() async {
    final picked = await _pick<List<LeadLookupContact>>(
      SrMultiOptionSheet<LeadLookupContact>(
        title: context.l10n.leadsContacts,
        options: widget.lookups.contactsOf(_companyId),
        labelOf: (c) => c.name,
        subtitleOf: (c) => c.designation,
        withAvatar: true,
        isSelected: (c) => _contactIds.contains(c.id),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _contactIds = [for (final c in picked) c.id]);
  }

  Future<void> _pickOne(
    String title,
    List<LeadOption> options,
    int? selected,
    ValueChanged<int> onPicked,
  ) async {
    final bangla = context.fmt.isBangla;
    final picked = await _pick<LeadOption>(
      SrOptionSheet<LeadOption>(
        title: title,
        options: options,
        labelOf: (o) => o.name.of(bangla),
        subtitleOf: (o) => o.subtitle,
        isSelected: (o) => o.id == selected,
      ),
    );
    if (picked != null && mounted) setState(() => onPicked(picked.id));
  }

  Future<void> _pickMany(
    String title,
    List<LeadOption> options,
    List<int> selected,
    ValueChanged<List<int>> onPicked,
  ) async {
    final bangla = context.fmt.isBangla;
    final picked = await _pick<List<LeadOption>>(
      SrMultiOptionSheet<LeadOption>(
        title: title,
        options: options,
        labelOf: (o) => o.name.of(bangla),
        isSelected: (o) => selected.contains(o.id),
      ),
    );
    if (picked != null && mounted) {
      setState(() => onPicked([for (final o in picked) o.id]));
    }
  }

  Future<void> _pickStage() async {
    final bangla = context.fmt.isBangla;
    final picked = await _pick<LeadStage>(
      SrOptionSheet<LeadStage>(
        title: context.l10n.leadsStage,
        options: widget.stages,
        labelOf: (s) => s.name.of(bangla),
        isSelected: (s) => s.id == _stageId,
      ),
    );
    if (picked != null && mounted) setState(() => _stageId = picked.id);
  }

  Future<void> _pickClosing() async {
    final now = DateTime.now();
    final picked = await showSrDatePicker(
      context: context,
      initial: _closing ?? DateTime(now.year, now.month, now.day + 30),
    );
    if (picked != null && mounted) setState(() => _closing = picked);
  }

  String? _names(List<LeadOption> options, List<int> ids) {
    final bangla = context.fmt.isBangla;
    final names = [
      for (final o in options)
        if (ids.contains(o.id)) o.name.of(bangla),
    ];
    if (names.isEmpty) return null;
    if (names.length == 1) return names.first;
    return context.l10n.leadsAndMore(
      names.first,
      context.fmt.number(names.length - 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final save = ref.watch(leadSaveProvider(_slot));
    final easy = ref.watch(experienceLevelProvider) == ExperienceLevel.easy;
    ref.listen(
      leadSaveProvider(_slot),
      (_, next) => onLeadSaved(
        context,
        next,
        input: _input,
        created: widget.lead == null,
        retry: ref.read(leadSaveProvider(_slot).notifier).create,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(SrMetrics.gutter),
            children: [
              if (_fromCard) ...[
                SrNote(
                  tone: SrNoteTone.gold,
                  icon: Icons.document_scanner_outlined,
                  title: l10n.leadsScanBannerTitle,
                  message: l10n.leadsScanBanner,
                ),
                const SizedBox(height: 16),
              ],
              SrTextField(
                controller: _title,
                label: l10n.leadsLeadTitle,
                hint: l10n.leadsLeadTitleHint,
                error: _titleError ?? leadFieldError(save, 'LeadName'),
                textCapitalization: TextCapitalization.sentences,
              ),
              if (!easy) ..._companyFields(l10n),
              ..._contactFields(l10n, easy, save),
              const SizedBox(height: 14),
              _valueAndClose(l10n, save),
              if (!easy) ..._pickerFields(l10n),
              const SizedBox(height: 14),
              SrDropdownField(
                label: l10n.leadsStage,
                value: widget.stages
                    .byId(_stageId)
                    ?.name
                    .of(context.fmt.isBangla),
                onTap: _pickStage,
              ),
              const SizedBox(height: 14),
              SrTextField(
                controller: _note,
                label: l10n.leadsNote,
                optional: true,
                hint: l10n.leadsNoteHint,
                multiline: true,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        SrFooter(
          child: SrButton(
            label: l10n.commonSave,
            expand: true,
            loading: save.isLoading,
            onPressed: _save,
          ),
        ),
      ],
    );
  }

  List<Widget> _companyFields(AppLocalizations l10n) {
    final company = widget.lookups.company(_companyId);
    final companyName = _companyName;
    final contacts = [
      for (final id in _contactIds) ?widget.lookups.contact(id)?.name,
    ];
    return [
      const SizedBox(height: 14),
      SrDropdownField(
        label: l10n.leadsCompany,
        optional: true,
        value:
            company?.name ??
            (companyName == null ? null : l10n.leadsNewCompany(companyName)),
        placeholder: l10n.leadsPickCompany,
        icon: Icons.apartment_rounded,
        onTap: _pickCompany,
      ),
      const SizedBox(height: 14),
      SrDropdownField(
        label: l10n.leadsContacts,
        optional: true,
        value: contacts.isEmpty
            ? null
            : contacts.length == 1
            ? contacts.first
            : l10n.leadsAndMore(
                contacts.first,
                context.fmt.number(contacts.length - 1),
              ),
        placeholder: company == null
            ? l10n.leadsPickCompanyFirst
            : l10n.leadsPickContacts,
        icon: Icons.people_outline_rounded,
        enabled: company != null,
        onTap: company == null ? null : _pickContacts,
      ),
    ];
  }

  List<Widget> _contactFields(
    AppLocalizations l10n,
    bool easy,
    AsyncValue<Lead?> save,
  ) {
    if (_contactIds.isNotEmpty) return const [];
    return [
      const SizedBox(height: 18),
      SrFieldLabel(l10n.leadsContactPerson, optional: true),
      const SizedBox(height: 8),
      if (!easy) ...[
        SrTextField(
          controller: _contactName,
          hint: l10n.leadsContactName,
          prefixIcon: Icons.person_outline_rounded,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 10),
      ],
      SrTextField(
        controller: _mobile,
        hint: l10n.leadsMobile,
        prefixIcon: Icons.call_outlined,
        error: _mobileError ?? leadFieldError(save, 'Mobile'),
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9+ \-]')),
        ],
      ),
      if (!easy) ...[
        const SizedBox(height: 10),
        SrTextField(
          controller: _email,
          hint: l10n.leadsKindEmail,
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        SrTextField(
          controller: _designation,
          hint: l10n.leadsDesignation,
          prefixIcon: Icons.badge_outlined,
          textCapitalization: TextCapitalization.words,
        ),
      ],
    ];
  }

  Widget _valueAndClose(AppLocalizations l10n, AsyncValue<Lead?> save) {
    final closing = _closing;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SrTextField(
            controller: _amount,
            label: l10n.leadsDealValue,
            suffixText: '৳',
            error: _amountError ?? leadFieldError(save, 'EstimatedAmount'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SrDropdownField(
            label: l10n.leadsExpectedClose,
            value: closing == null ? null : context.fmt.dayMonth(closing),
            placeholder: l10n.leadsPickDate,
            icon: Icons.event_outlined,
            onTap: _pickClosing,
          ),
        ),
      ],
    );
  }

  List<Widget> _pickerFields(AppLocalizations l10n) {
    final bangla = context.fmt.isBangla;
    final lookups = widget.lookups;
    final assigns = ref.watch(currentRoleProvider) != WorkspaceRole.member;
    return [
      const SizedBox(height: 14),
      SrDropdownField(
        label: l10n.leadsSource,
        optional: true,
        value: lookups.sources
            .where((s) => s.id == _sourceId)
            .firstOrNull
            ?.name
            .of(bangla),
        onTap: () => _pickOne(
          l10n.leadsSource,
          lookups.sources,
          _sourceId,
          (id) => _sourceId = id,
        ),
      ),
      if (assigns) ...[
        const SizedBox(height: 14),
        SrDropdownField(
          label: l10n.leadsOwner,
          value: lookups.owners
              .where((o) => o.id == _ownerId)
              .firstOrNull
              ?.name
              .of(bangla),
          icon: Icons.person_pin_outlined,
          onTap: () => _pickOne(
            l10n.leadsOwner,
            lookups.owners,
            _ownerId,
            (id) => _ownerId = id,
          ),
        ),
      ],
      const SizedBox(height: 14),
      SrFieldLabel(l10n.leadsTemperature, optional: true),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        children: [
          for (final t in LeadTemperature.values)
            SrChip(
              label: t.label(l10n),
              selected: _temperature == t,
              tone: _temperature == t ? t.tone : SrTone.neutral,
              onTap: () =>
                  setState(() => _temperature = _temperature == t ? null : t),
            ),
        ],
      ),
      const SizedBox(height: 14),
      SrDropdownField(
        label: l10n.leadsInterests,
        optional: true,
        value: _names(lookups.interests, _interestIds),
        icon: Icons.solar_power_outlined,
        onTap: () => _pickMany(
          l10n.leadsInterests,
          lookups.interests,
          _interestIds,
          (ids) => _interestIds = ids,
        ),
      ),
      const SizedBox(height: 14),
      SrDropdownField(
        label: l10n.leadsTags,
        optional: true,
        value: _names(lookups.tags, _tagIds),
        icon: Icons.sell_outlined,
        onTap: () => _pickMany(
          l10n.leadsTags,
          lookups.tags,
          _tagIds,
          (ids) => _tagIds = ids,
        ),
      ),
    ];
  }
}

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
    this.company,
    this.title,
    this.value,
    this.source,
  });

  factory LeadPrefill.fromQuery(Map<String, String> query) => LeadPrefill(
    name: query['name'],
    phone: query['phone'],
    company: query['company'],
    title: query['title'],
    value: query['value'],
    source: query['source'],
  );

  final String? name;
  final String? phone;
  final String? company;
  final String? title;
  final String? value;
  final String? source;
}

typedef _FormData = (LeadLookups, List<LeadStage>, Lead?);

/// #26: the full lead form, for a new lead ([id] null) or an edit.
class LeadFormScreen extends ConsumerWidget {
  const LeadFormScreen({
    super.key,
    this.id,
    this.prefill = const LeadPrefill(),
  });

  final String? id;
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
        AsyncData<_FormData>((l, s, null)),
      (
        AsyncData(value: final l),
        AsyncData(value: final s),
        AsyncData(value: final d),
      ) =>
        AsyncData<_FormData>((l, s, d)),
      (AsyncError(:final error, :final stackTrace), _, _) ||
      (_, AsyncError(:final error, :final stackTrace), _) ||
      (
        _,
        _,
        AsyncError(:final error, :final stackTrace),
      ) => AsyncError<_FormData>(error, stackTrace),
      _ => const AsyncLoading<_FormData>(),
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
            stages: [
              for (final stage in data.$2)
                if (stage.isOpen) stage,
            ],
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
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late final _custom = {
    for (final field in widget.lookups.fields)
      field.key: TextEditingController(),
  };

  String? _companyId;
  String? _companyName;
  bool _newCompany = false;
  String? _contactId;
  String? _contactName;
  DateTime? _closing;
  String? _source;
  String? _stageId;
  String? _ownerId;
  LeadTemperature? _temperature;
  String? _nameError;
  String? _phoneError;
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
    _name.text = input.leadName;
    _phone.text = input.phone ?? '';
    _title.text = input.title == input.leadName ? '' : input.title ?? '';
    _companyId = input.companyId;
    _companyName = lead.company?.name;
    _contactId = input.contactId;
    _contactName = lead.contact?.name;
    final amount = input.estimatedAmount;
    _amount.text = amount == null ? '' : amount.round().toString();
    _closing = input.estimatedClosingDate;
    _source = input.source;
    _stageId = input.stageId;
    _ownerId = input.ownerId;
    _temperature = input.temperature;
    for (final entry in _custom.entries) {
      entry.value.text = input.custom[entry.key] ?? '';
    }
  }

  void _seedFromPrefill(LeadPrefill prefill) {
    final company = prefill.company?.trim() ?? '';
    _name.text = prefill.name ?? company;
    _phone.text = prefill.phone ?? '';
    _title.text = prefill.title ?? '';
    _amount.text = prefill.value ?? '';
    _source =
        LeadSource.fromAny(prefill.source)?.wire ?? prefill.source?.trim();
    _stageId = widget.stages.firstOrNull?.id;
    _ownerId = widget.lookups.currentMemberId;
    if (company.isNotEmpty) _matchCompany(company);
  }

  /// Links the prefilled company when it is already on the list, and offers
  /// it as a new one otherwise.
  Future<void> _matchCompany(String name) async {
    setState(() {
      _companyName = name;
      _newCompany = true;
    });
    try {
      final hits = await ref.read(leadRepositoryProvider).companies(name, 1);
      final match = hits
          .where((c) => c.name.toLowerCase() == name.toLowerCase())
          .firstOrNull;
      if (match == null || !mounted || _companyName != name) return;
      setState(() {
        _companyId = match.id;
        _newCompany = false;
      });
    } on Exception {
      return;
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _phone,
      _title,
      _amount,
      _note,
      ..._custom.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _fromCard =>
      widget.lead == null &&
      LeadSource.fromAny(widget.prefill.source) == LeadSource.card;

  void _save() {
    final l10n = context.l10n;
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final amountText = _amount.text.trim();
    final amount = double.tryParse(amountText);
    setState(() {
      _nameError = name.isEmpty ? l10n.leadsErrorName : null;
      _phoneError = phone.isNotEmpty && !isLeadMobile(phone)
          ? l10n.leadsErrorMobile
          : null;
      _amountError = amountText.isNotEmpty && amount == null
          ? l10n.leadsErrorAmount
          : null;
    });
    if (_nameError != null || _phoneError != null || _amountError != null) {
      return;
    }
    final lead = widget.lead;
    final input = LeadInput(
      leadName: name,
      phone: phone,
      title: _title.text,
      companyId: _newCompany ? null : _companyId,
      companyName: _newCompany ? _companyName : null,
      contactId: _contactId,
      estimatedAmount: amount,
      estimatedClosingDate: _closing,
      source: _source,
      stageId: _stageId,
      ownerId: _ownerId,
      temperature: _temperature,
      tags: lead?.tags ?? const [],
      custom: {
        ...?(lead == null ? null : LeadInput.fromLead(lead).custom),
        for (final entry in _custom.entries)
          if (entry.value.text.trim().isNotEmpty)
            entry.key: entry.value.text.trim(),
      },
      note: lead == null ? _note.text : null,
    );
    _input = input;
    final save = ref.read(leadSaveProvider(_slot).notifier);
    if (lead == null) {
      save.create(input);
    } else {
      save.edit(lead, input);
    }
  }

  Future<T?> _pick<T>(Widget sheet) =>
      showSrSheet<T>(context: context, builder: (_) => sheet);

  Future<void> _pickCompany() async {
    final repository = ref.read(leadRepositoryProvider);
    final picked = await _pick<LeadLookupCompany>(
      SrSearchSheet<LeadLookupCompany>(
        title: context.l10n.leadsCompany,
        search: repository.companies,
        labelOf: (c) => c.name,
        subtitleOf: (c) => c.area,
        withAvatar: true,
        isSelected: (c) => c.id == _companyId,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (picked.id != _companyId) {
        _contactId = null;
        _contactName = null;
      }
      _companyId = picked.id;
      _companyName = picked.name;
      _newCompany = false;
    });
  }

  Future<void> _pickContact() async {
    final repository = ref.read(leadRepositoryProvider);
    final companyId = _newCompany ? null : _companyId;
    final picked = await _pick<LeadLookupContact>(
      SrSearchSheet<LeadLookupContact>(
        title: context.l10n.leadsContactPerson,
        search: (term, page) =>
            repository.contacts(term, page, companyId: companyId),
        labelOf: (c) => c.name,
        subtitleOf: (c) => leadMeta([c.designation, c.companyName]),
        withAvatar: true,
        isSelected: (c) => c.id == _contactId,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _contactId = picked.id;
      _contactName = picked.name;
      if (_phone.text.trim().isEmpty) _phone.text = picked.mobile ?? '';
    });
  }

  Future<void> _pickSource() async {
    final l10n = context.l10n;
    final picked = await _pick<LeadSource>(
      SrOptionSheet<LeadSource>(
        title: l10n.leadsSource,
        options: LeadSource.values,
        labelOf: (s) => s.label(l10n),
        isSelected: (s) => s.wire == _source,
      ),
    );
    if (picked != null && mounted) setState(() => _source = picked.wire);
  }

  Future<void> _pickOwner() async {
    final bangla = context.fmt.isBangla;
    final picked = await _pick<LeadOption>(
      SrOptionSheet<LeadOption>(
        title: context.l10n.leadsOwner,
        options: widget.lookups.owners,
        labelOf: (o) => o.name.of(bangla),
        subtitleOf: (o) => o.subtitle,
        withAvatar: true,
        isSelected: (o) => o.id == _ownerId,
      ),
    );
    if (picked != null && mounted) setState(() => _ownerId = picked.id);
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final save = ref.watch(leadSaveProvider(_slot));
    final easy = ref.watch(experienceLevelProvider) == ExperienceLevel.easy;
    final stage = widget.stages.byId(_stageId);
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
                controller: _name,
                label: l10n.leadsNameOrCompany,
                hint: l10n.leadsNameOrCompanyHint,
                prefixIcon: Icons.person_outline_rounded,
                error: _nameError ?? leadFieldError(save, 'name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
              SrTextField(
                controller: _phone,
                label: l10n.leadsMobile,
                optional: true,
                hint: l10n.leadsMobileHint,
                prefixIcon: Icons.call_outlined,
                error: _phoneError ?? leadFieldError(save, 'phone'),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+ \-]')),
                ],
              ),
              if (!easy) ..._linkFields(l10n, save),
              const SizedBox(height: 14),
              _valueAndClose(l10n, save),
              if (!easy) ..._pickerFields(l10n),
              const SizedBox(height: 14),
              SrDropdownField(
                label: l10n.leadsStage,
                value: stage?.name.of(context.fmt.isBangla),
                error: leadFieldError(save, 'stageId'),
                onTap: _pickStage,
              ),
              if (widget.lead == null) ...[
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

  List<Widget> _linkFields(AppLocalizations l10n, AsyncValue<Lead?> save) {
    final companyName = _companyName;
    return [
      const SizedBox(height: 14),
      SrTextField(
        controller: _title,
        label: l10n.leadsLeadTitle,
        optional: true,
        hint: l10n.leadsLeadTitleHint,
        error: leadFieldError(save, 'title'),
        textCapitalization: TextCapitalization.sentences,
      ),
      const SizedBox(height: 14),
      SrDropdownField(
        label: l10n.leadsCompany,
        optional: true,
        value: companyName == null
            ? null
            : _newCompany
            ? l10n.leadsNewCompany(companyName)
            : companyName,
        placeholder: l10n.leadsPickCompany,
        icon: Icons.apartment_rounded,
        onTap: _pickCompany,
      ),
      const SizedBox(height: 14),
      SrDropdownField(
        label: l10n.leadsContactPerson,
        optional: true,
        value: _contactName,
        placeholder: l10n.leadsPickContact,
        icon: Icons.person_outline_rounded,
        onTap: _pickContact,
      ),
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
            error: _amountError ?? leadFieldError(save, 'amount'),
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
      if (widget.lead == null) ...[
        const SizedBox(height: 14),
        SrDropdownField(
          label: l10n.leadsSource,
          optional: true,
          value: leadSourceLabel(l10n, _source),
          onTap: _pickSource,
        ),
      ],
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
          onTap: _pickOwner,
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
      for (final field in lookups.fields)
        if (_custom[field.key] case final controller?) ...[
          const SizedBox(height: 14),
          SrTextField(
            controller: controller,
            label: field.label.of(bangla),
            optional: true,
            keyboardType: field.type == LeadFieldType.number
                ? TextInputType.number
                : null,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
    ];
  }
}

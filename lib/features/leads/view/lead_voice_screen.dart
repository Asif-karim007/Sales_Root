import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/leads/models/lead_activity.dart';
import 'package:salesroot/features/leads/models/lead_input.dart';
import 'package:salesroot/features/leads/models/lead_lookups.dart';
import 'package:salesroot/features/leads/models/lead_transcript.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';
import 'package:salesroot/features/leads/view/widget/lead_dictation.dart';
import 'package:salesroot/features/leads/view/widget/lead_labels.dart';
import 'package:salesroot/features/leads/view/widget/lead_save_flow.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

enum _Phase { listening, unheard, unavailable, confirm }

/// #25: say the lead in Bangla or English, check what was understood, save.
class LeadVoiceScreen extends ConsumerStatefulWidget {
  const LeadVoiceScreen({super.key});

  @override
  ConsumerState<LeadVoiceScreen> createState() => _LeadVoiceScreenState();
}

class _LeadVoiceScreenState extends ConsumerState<LeadVoiceScreen> {
  static const _slot = 'voice';

  late bool _bangla = ref.read(appLocaleProvider) == bangla;
  _Phase _phase = _Phase.listening;
  String _words = '';
  LeadTranscript _heard = const LeadTranscript(text: '');
  LeadInput? _input;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _listen());
  }

  @override
  void dispose() {
    LeadDictation.instance.cancel();
    super.dispose();
  }

  Future<void> _listen() async {
    await LeadDictation.instance.cancel();
    if (!mounted) return;
    setState(() {
      _phase = _Phase.listening;
      _words = '';
    });
    final started = await LeadDictation.instance.start(
      bangla: _bangla,
      onResult: _onResult,
      onDone: _finish,
      onError: _finish,
    );
    if (!started && mounted) setState(() => _phase = _Phase.unavailable);
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!mounted || _phase != _Phase.listening) return;
    setState(() => _words = result.recognizedWords);
    if (result.finalResult) _finish();
  }

  void _finish() {
    if (!mounted || _phase != _Phase.listening) return;
    final heard = LeadTranscript.parse(_words, now: DateTime.now());
    setState(() {
      _heard = heard;
      _phase = _words.trim().isEmpty ? _Phase.unheard : _Phase.confirm;
    });
  }

  void _language(bool bangla) {
    if (bangla == _bangla) return;
    _bangla = bangla;
    _listen();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final heard = _heard;
    final title = heard.name ?? heard.company;
    final phone = heard.phone;
    if (title == null) {
      showSrWarning(context, l10n.leadsErrorName);
      return;
    }
    if (phone != null && !isLeadMobile(phone)) {
      showSrWarning(context, l10n.leadsErrorMobile);
      return;
    }
    final lookups = await ref.read(leadLookupsProvider.future);
    final company = lookups.companyNamed(heard.company);
    final input = LeadInput(
      leadName: title,
      companyId: company?.id,
      companyName: company == null ? heard.company : null,
      newContact: phone == null
          ? null
          : LeadNewContact(name: heard.name ?? title, mobile: phone),
      interestIds: [
        for (final interest in lookups.interests)
          if (heard.interests.contains(interest.name.en)) interest.id,
      ],
      sourceId: lookups.sourceNamed('Phone call')?.id,
      followUp: heard.followUp,
    );
    _input = input;
    if (!mounted) return;
    await ref.read(leadSaveProvider(_slot).notifier).create(input);
  }

  void _update(LeadTranscript heard) => setState(() => _heard = heard);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = ref.watch(appLocaleProvider);
    final save = ref.watch(leadSaveProvider(_slot));
    ref.listen(
      leadSaveProvider(_slot),
      (_, next) => onLeadSaved(
        context,
        next,
        input: _input,
        retry: ref.read(leadSaveProvider(_slot).notifier).create,
      ),
    );
    final confirm = _phase == _Phase.confirm;
    return SrScaffold(
      appBar: SrAppBar(
        title: confirm ? l10n.leadsVoiceConfirm : l10n.leadsVoiceTitle,
        actions: [
          SrLanguageToggle(
            isBangla: locale == bangla,
            onChanged: (isBangla) => ref
                .read(appLocaleProvider.notifier)
                .set(isBangla ? bangla : english),
          ),
        ],
      ),
      body: switch (_phase) {
        _Phase.listening => _Listening(
          words: _words,
          bangla: _bangla,
          onLanguage: _language,
        ),
        _Phase.unheard => _Retry(
          title: l10n.leadsVoiceNothing,
          onRetry: _listen,
        ),
        _Phase.unavailable => _Retry(
          title: l10n.leadsVoiceUnavailable,
          message: l10n.leadsVoiceUnavailableBody,
          onRetry: _listen,
        ),
        _Phase.confirm => _Confirm(heard: _heard, onChanged: _update),
      },
      footer: switch (_phase) {
        _Phase.listening => SrButton(
          label: l10n.commonDone,
          expand: true,
          onPressed: LeadDictation.instance.stop,
        ),
        _Phase.confirm => Row(
          children: [
            Expanded(
              child: SrButton(
                label: l10n.leadsVoiceAgain,
                icon: Icons.mic_none_rounded,
                variant: SrButtonVariant.secondary,
                expand: true,
                onPressed: _listen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SrButton(
                label: l10n.leadsVoiceSave,
                expand: true,
                loading: save.isLoading,
                onPressed: _save,
              ),
            ),
          ],
        ),
        _ => SrButton(
          label: l10n.leadsVoiceType,
          variant: SrButtonVariant.secondary,
          expand: true,
          onPressed: () => context.pushReplacement(Routes.leadQuick),
        ),
      },
    );
  }
}

class _MicDisc extends StatelessWidget {
  const _MicDisc({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: c.deep,
          shape: BoxShape.circle,
          boxShadow: active
              ? [BoxShadow(color: c.accent2, blurRadius: 18, spreadRadius: 2)]
              : null,
        ),
        child: Icon(Icons.mic_none_rounded, color: c.onDeep, size: 32),
      ),
    );
  }
}

class _Listening extends StatelessWidget {
  const _Listening({
    required this.words,
    required this.bangla,
    required this.onLanguage,
  });

  final String words;
  final bool bangla;
  final ValueChanged<bool> onLanguage;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(SrMetrics.gutter),
      children: [
        SrSegmented(
          segments: [
            SrSegment(l10n.languageBangla),
            SrSegment(l10n.languageEnglish),
          ],
          index: bangla ? 0 : 1,
          onChanged: (i) => onLanguage(i == 0),
        ),
        const SizedBox(height: 28),
        const _MicDisc(active: true),
        const SizedBox(height: 14),
        Text(
          l10n.leadsVoiceListening,
          textAlign: TextAlign.center,
          style: AppText.meta(c.ink2, size: 13),
        ),
        const SizedBox(height: 10),
        Text(
          words.isEmpty ? '' : l10n.leadsQuoted(words),
          textAlign: TextAlign.center,
          style: AppText.sectionTitle(c.ink, size: 16),
        ),
        const SizedBox(height: 24),
        SrNote(
          icon: Icons.record_voice_over_outlined,
          message: l10n.leadsVoiceHint,
        ),
      ],
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.title, required this.onRetry, this.message});

  final String title;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: SrEmptyState(
        icon: Icons.mic_off_outlined,
        title: title,
        message: message,
        actionLabel: context.l10n.leadsVoiceAgain,
        onAction: onRetry,
      ),
    ),
  );
}

class _Confirm extends ConsumerWidget {
  const _Confirm({required this.heard, required this.onChanged});

  final LeadTranscript heard;
  final ValueChanged<LeadTranscript> onChanged;

  LeadTranscript _with({
    String? Function()? name,
    String? Function()? company,
    String? Function()? phone,
    List<String>? interests,
    LeadFollowUp? Function()? followUp,
  }) => LeadTranscript(
    text: heard.text,
    name: name == null ? heard.name : name(),
    company: company == null ? heard.company : company(),
    phone: phone == null ? heard.phone : phone(),
    interests: interests ?? heard.interests,
    followUp: followUp == null ? heard.followUp : followUp(),
  );

  Future<void> _editText(
    BuildContext context,
    String label,
    String? value,
    ValueChanged<String?> onSaved, {
    TextInputType? keyboard,
  }) async {
    final text = await showSrSheet<String>(
      context: context,
      builder: (_) =>
          _TextSheet(label: label, value: value ?? '', keyboard: keyboard),
    );
    if (text != null) onSaved(text.trim().isEmpty ? null : text.trim());
  }

  Future<void> _editInterests(
    BuildContext context,
    List<LeadOption> all,
  ) async {
    final bangla = context.fmt.isBangla;
    final picked = await showSrSheet<List<LeadOption>>(
      context: context,
      builder: (context) => SrMultiOptionSheet<LeadOption>(
        title: context.l10n.leadsInterest,
        options: all,
        labelOf: (o) => o.name.of(bangla),
        isSelected: (o) => heard.interests.contains(o.name.en),
      ),
    );
    if (picked == null) return;
    onChanged(_with(interests: [for (final o in picked) o.name.en]));
  }

  Future<void> _editFollowUp(BuildContext context) async {
    final now = DateTime.now();
    final current = heard.followUp;
    final at = current?.at;
    final picked = await showSrDatePicker(
      context: context,
      initial: at != null && at.isAfter(now)
          ? at
          : DateTime(now.year, now.month, now.day + 1, 10),
      withTime: true,
      first: now,
    );
    if (picked == null) return;
    onChanged(
      _with(
        followUp: () => LeadFollowUp(
          kind: current?.kind ?? LeadActivityKind.call,
          at: picked,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final all = ref.watch(leadLookupsProvider).value?.interests ?? const [];
    final followUp = heard.followUp;
    final phone = heard.phone;
    final interests = [
      for (final o in all)
        if (heard.interests.contains(o.name.en)) o.name.of(fmt.isBangla),
    ];
    final rows = [
      (
        l10n.leadsName,
        heard.name,
        () => _editText(
          context,
          l10n.leadsName,
          heard.name,
          (v) => onChanged(_with(name: () => v)),
        ),
      ),
      (
        l10n.leadsCompany,
        heard.company,
        () => _editText(
          context,
          l10n.leadsCompany,
          heard.company,
          (v) => onChanged(_with(company: () => v)),
        ),
      ),
      (
        l10n.leadsNumber,
        phone == null ? null : fmt.phone(phone),
        () => _editText(
          context,
          l10n.leadsNumber,
          phone,
          (v) => onChanged(_with(phone: () => v)),
          keyboard: TextInputType.phone,
        ),
      ),
      (
        l10n.leadsInterest,
        interests.isEmpty ? null : interests.join(', '),
        () => _editInterests(context, all),
      ),
      (
        l10n.leadsFollowUp,
        followUp == null
            ? null
            : leadMeta([
                leadDayTime(context, followUp.at),
                followUp.kind.label(l10n),
              ]),
        () => _editFollowUp(context),
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(SrMetrics.gutter),
      children: [
        const SizedBox(height: 8),
        const _MicDisc(),
        const SizedBox(height: 12),
        Text(
          l10n.leadsVoiceYouSaid,
          textAlign: TextAlign.center,
          style: AppText.meta(c.ink2, size: 13),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.leadsQuoted(heard.text),
          textAlign: TextAlign.center,
          style: AppText.sectionTitle(c.ink, size: 16),
        ),
        const SizedBox(height: 18),
        SrCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (final (i, (label, value, onTap)) in rows.indexed)
                _ConfirmRow(
                  label: label,
                  value: value,
                  divider: i < rows.length - 1,
                  onTap: onTap,
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SrNote(icon: Icons.edit_outlined, message: l10n.leadsVoiceTapToFix),
      ],
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({
    required this.label,
    required this.value,
    required this.divider,
    required this.onTap,
  });

  final String label;
  final String? value;
  final bool divider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final value = this.value;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: divider ? Border(bottom: BorderSide(color: c.line)) : null,
        ),
        child: Row(
          children: [
            Text(label, style: AppText.body(c.ink2, size: 14)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? context.l10n.leadsNotHeard,
                textAlign: TextAlign.end,
                style: value == null
                    ? AppText.meta(c.ink3, size: 14)
                    : AppText.rowTitle(c.ink, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextSheet extends StatefulWidget {
  const _TextSheet({required this.label, required this.value, this.keyboard});

  final String label;
  final String value;
  final TextInputType? keyboard;

  @override
  State<_TextSheet> createState() => _TextSheetState();
}

class _TextSheetState extends State<_TextSheet> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SrSheet(
    title: widget.label,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrTextField(
          controller: _controller,
          autofocus: true,
          keyboardType: widget.keyboard,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (text) => Navigator.of(context).pop(text),
        ),
        const SizedBox(height: 14),
        SrButton(
          label: context.l10n.commonSave,
          expand: true,
          onPressed: () => Navigator.of(context).pop(_controller.text),
        ),
      ],
    ),
  );
}

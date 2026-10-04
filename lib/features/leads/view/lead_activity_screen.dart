import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/utils/debug_log.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_activity.dart';
import 'package:salesroot/features/leads/models/lead_input.dart';
import 'package:salesroot/features/leads/models/lead_query.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';
import 'package:salesroot/features/leads/view/widget/lead_dictation.dart';
import 'package:salesroot/features/leads/view/widget/lead_events.dart';
import 'package:salesroot/features/leads/view/widget/lead_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #33: log a call, meeting, visit, note or message on a lead, optionally
/// setting the next follow-up. Pops with true once saved.
class LeadActivityScreen extends ConsumerStatefulWidget {
  const LeadActivityScreen({super.key, required this.id, this.kind});

  final int id;
  final LeadActivityKind? kind;

  @override
  ConsumerState<LeadActivityScreen> createState() => _LeadActivityScreenState();
}

class _LeadActivityScreenState extends ConsumerState<LeadActivityScreen> {
  static const _slot = 'activity';
  static const _durations = [5, 10, 15, 20, 30, 45, 60, 90, 120];
  static const _followUpKinds = [
    LeadActivityKind.call,
    LeadActivityKind.visit,
    LeadActivityKind.meeting,
    LeadActivityKind.whatsapp,
  ];

  final _note = TextEditingController();
  final _photos = <XFile>[];
  late LeadActivityKind _kind = widget.kind ?? LeadActivityKind.call;
  late int _leadId = widget.id;
  String? _leadName;
  DateTime _when = DateTime.now();
  int? _minutes;
  bool _followUp = true;
  LeadActivityKind _followUpKind = LeadActivityKind.call;
  DateTime _followUpAt = _tomorrowAtTen();
  String? _noteError;

  static DateTime _tomorrowAtTen() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 10);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickLead() async {
    final repository = ref.read(leadRepositoryProvider);
    final picked = await showSrSheet<Lead>(
      context: context,
      builder: (context) => SrSearchSheet<Lead>(
        title: context.l10n.leadsLead,
        searchHint: context.l10n.leadsSearchHint,
        search: (term, page) async => (await repository.list(
          LeadQuery(search: term, page: page, openOnly: false),
        )).items,
        labelOf: (l) => l.leadName,
        subtitleOf: (l) => l.primaryContact?.name,
        withAvatar: true,
        isSelected: (l) => l.id == _leadId,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _leadId = picked.id;
      _leadName = picked.leadName;
    });
  }

  Future<void> _pickWhen() async {
    final picked = await showSrDatePicker(
      context: context,
      initial: _when,
      withTime: true,
      last: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _when = picked);
  }

  Future<void> _pickDuration() async {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final picked = await showSrSheet<int>(
      context: context,
      builder: (_) => SrOptionSheet<int>(
        title: l10n.leadsDuration,
        options: _durations,
        labelOf: (m) => l10n.leadsMinutes(fmt.number(m)),
        isSelected: (m) => m == _minutes,
      ),
    );
    if (picked != null && mounted) setState(() => _minutes = picked);
  }

  Future<void> _pickFollowUp() async {
    final now = DateTime.now();
    final picked = await showSrDatePicker(
      context: context,
      initial: _followUpAt.isAfter(now) ? _followUpAt : _tomorrowAtTen(),
      withTime: true,
      first: now,
    );
    if (picked != null && mounted) setState(() => _followUpAt = picked);
  }

  Future<void> _addPhoto() async {
    final l10n = context.l10n;
    final source = await showSrSheet<ImageSource>(
      context: context,
      builder: (context) => SrSheet(
        title: l10n.leadsPhoto,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SrListRow(
              title: l10n.leadsPhotoCamera,
              leading: const SrAvatar(icon: Icons.photo_camera_outlined),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            SrListRow(
              title: l10n.leadsPhotoGallery,
              leading: const SrAvatar(icon: Icons.photo_library_outlined),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final photo = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (photo != null && mounted) setState(() => _photos.add(photo));
    } on Exception catch (error) {
      logDebug('Photo pick failed: $error');
      if (mounted) showSrError(context, l10n.leadsPhotoFailed);
    }
  }

  void _save() {
    final l10n = context.l10n;
    final text = _note.text.trim();
    setState(() {
      _noteError = _kind == LeadActivityKind.note && text.isEmpty
          ? l10n.leadsErrorWhatHappened
          : null;
    });
    if (_noteError != null) return;
    ref
        .read(leadActivitySaveProvider(_slot).notifier)
        .log(
          _leadId,
          LeadActivityInput(
            kind: _kind,
            occurredOn: _when,
            durationMinutes: _kind.timed ? _minutes : null,
            description: text,
            photoCount: _photos.length,
            followUp: _followUp
                ? LeadFollowUp(kind: _followUpKind, at: _followUpAt)
                : null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final locale = ref.watch(appLocaleProvider);
    final save = ref.watch(leadActivitySaveProvider(_slot));
    final leadName =
        _leadName ?? ref.watch(leadProvider(widget.id)).value?.leadName;
    final minutes = _minutes;
    final serverError = switch (save.error) {
      final ApiFailure f => f.fieldError('Description'),
      _ => null,
    };
    ref.listen(leadActivitySaveProvider(_slot), (_, next) {
      if (next.isLoading) return;
      if (next.hasError) {
        final error = next.error;
        if (error is ApiFailure && error.isValidation) return;
        showSrError(context, leadFailureText(l10n, error ?? ''));
        return;
      }
      if (next.value == null) return;
      showSrSuccess(context, l10n.leadsActivityLogged);
      context.pop(true);
    });
    return SrKeyboardDismiss(
      child: SrScaffold(
        appBar: SrAppBar(
          title: l10n.leadsLogActivity,
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
          padding: const EdgeInsets.symmetric(vertical: SrMetrics.gutter),
          children: [
            SrChipRow(
              chips: [
                for (final kind in LeadActivityKind.loggable)
                  SrChipItem(kind.label(l10n)),
              ],
              index: LeadActivityKind.loggable.indexOf(_kind),
              onChanged: (i) =>
                  setState(() => _kind = LeadActivityKind.loggable[i]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SrMetrics.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 14),
                  SrDropdownField(
                    label: l10n.leadsLead,
                    value: leadName,
                    icon: Icons.person_outline_rounded,
                    onTap: _pickLead,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SrDropdownField(
                          label: l10n.leadsWhen,
                          value: leadDayTime(context, _when),
                          icon: Icons.event_outlined,
                          onTap: _pickWhen,
                        ),
                      ),
                      if (_kind.timed) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: SrDropdownField(
                            label: l10n.leadsDuration,
                            value: minutes == null
                                ? null
                                : l10n.leadsMinutes(fmt.number(minutes)),
                            placeholder: l10n.leadsPickDuration,
                            icon: Icons.schedule_rounded,
                            onTap: _pickDuration,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  SrTextField(
                    controller: _note,
                    label: l10n.leadsWhatHappened,
                    optional: _kind != LeadActivityKind.note,
                    hint: l10n.leadsWhatHappenedHint,
                    error: _noteError ?? serverError,
                    multiline: true,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SrButton(
                          label: l10n.leadsPhoto,
                          icon: Icons.photo_camera_outlined,
                          variant: SrButtonVariant.secondary,
                          expand: true,
                          onPressed: _addPhoto,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LeadDictateButton(
                          controller: _note,
                          label: l10n.leadsVoiceNote,
                        ),
                      ),
                    ],
                  ),
                  if (_photos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _Photos(
                      photos: _photos,
                      onRemove: (photo) =>
                          setState(() => _photos.remove(photo)),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SrListRow(
                    title: l10n.leadsSetFollowUp,
                    subtitle: _followUp
                        ? leadMeta([
                            leadDayTime(context, _followUpAt),
                            _followUpKind.label(l10n),
                          ])
                        : null,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    trailing: SrSwitch(
                      value: _followUp,
                      onChanged: (on) => setState(() => _followUp = on),
                    ),
                    onTap: _followUp ? _pickFollowUp : null,
                  ),
                  if (_followUp)
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final kind in _followUpKinds)
                          SrChip(
                            label: kind.label(l10n),
                            icon: kind.icon,
                            selected: kind == _followUpKind,
                            onTap: () => setState(() => _followUpKind = kind),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        footer: SrButton(
          label: l10n.commonSave,
          expand: true,
          loading: save.isLoading,
          onPressed: _save,
        ),
      ),
    );
  }
}

class _Photos extends StatelessWidget {
  const _Photos({required this.photos, required this.onRemove});

  final List<XFile> photos;
  final ValueChanged<XFile> onRemove;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final photo in photos)
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
                child: Image.file(
                  File(photo.path),
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  cacheWidth: 192,
                  errorBuilder: (_, _, _) => Container(
                    width: 64,
                    height: 64,
                    color: c.avatarBg,
                    child: Icon(Icons.image_outlined, color: c.ink3),
                  ),
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: () => onRemove(photo),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: c.ink,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: c.surface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        Text(
          context.l10n.leadsPhotoCount(context.fmt.number(photos.length)),
          style: AppText.meta(c.ink2),
        ),
      ],
    );
  }
}

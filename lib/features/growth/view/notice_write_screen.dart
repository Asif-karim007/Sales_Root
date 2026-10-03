import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/growth/models/notice.dart';
import 'package:salesroot/features/growth/providers/notice_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #149 Write a notice: audience, acknowledgement, push, SMS, pin and files.
class NoticeWriteScreen extends ConsumerStatefulWidget {
  const NoticeWriteScreen({super.key});

  @override
  ConsumerState<NoticeWriteScreen> createState() => _NoticeWriteScreenState();
}

class _NoticeWriteScreenState extends ConsumerState<NoticeWriteScreen> {
  static const _pinDays = 7;

  final _title = TextEditingController();
  final _body = TextEditingController();
  NoticeAudience _audience = NoticeAudience.everyone;
  bool _requiresAck = true;
  bool _push = true;
  bool _sms = false;
  bool _pin = true;
  final _files = <NoticeAttachment>[];

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final submit = ref.watch(noticeSubmitProvider);
    ref.listen(noticeSubmitProvider, _onSubmit);
    final counts = ref.watch(noticeAudienceCountsProvider).value;
    final reach = counts?[_audience];
    final easy = ref.watch(experienceLevelProvider) == ExperienceLevel.easy;
    final failure = switch (submit) {
      AsyncError(:final ApiFailure error) => error,
      _ => null,
    };
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.growthNoticeNew,
        actions: const [GrowthLanguageAction()],
      ),
      body: SrKeyboardDismiss(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          children: [
            SrTextField(
              controller: _title,
              label: l10n.growthNoticeTitleField,
              hint: l10n.growthNoticeTitleHint,
              error: failure?.fieldError('Title') == null
                  ? null
                  : l10n.commonRequired,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            SrTextField(
              controller: _body,
              label: l10n.growthNoticeBody,
              hint: l10n.growthNoticeBodyHint,
              multiline: true,
              error: failure?.fieldError('Body') == null
                  ? null
                  : l10n.commonRequired,
            ),
            const SizedBox(height: 12),
            SrDropdownField(
              label: l10n.growthNoticeAudience,
              icon: Icons.group_outlined,
              value: reach == null
                  ? _audience.label(l10n)
                  : l10n.growthNoticeAudienceCount(
                      _audience.label(l10n),
                      fmt.number(reach),
                    ),
              onTap: () => _pickAudience(counts),
            ),
            const SizedBox(height: 12),
            SrCard(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                children: [
                  GrowthToggleRow(
                    title: l10n.growthNoticeRequiresAck,
                    value: _requiresAck,
                    onChanged: (v) => setState(() => _requiresAck = v),
                  ),
                  if (!easy) ...[
                    GrowthToggleRow(
                      title: l10n.growthNoticePush,
                      value: _push,
                      onChanged: (v) => setState(() => _push = v),
                    ),
                    GrowthToggleRow(
                      title: l10n.growthNoticeSms,
                      subtitle: reach == null
                          ? null
                          : l10n.growthCreditsAverageValue(fmt.number(reach)),
                      value: _sms,
                      onChanged: (v) => setState(() => _sms = v),
                    ),
                  ],
                  GrowthToggleRow(
                    title: l10n.growthNoticePin,
                    subtitle: l10n.growthNoticePinDays(fmt.number(_pinDays)),
                    value: _pin,
                    onChanged: (v) => setState(() => _pin = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final file in _files) ...[
              _FileRow(
                file: file,
                onRemove: () => setState(() => _files.remove(file)),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: SrButton(
                    label: l10n.growthNoticeAttach,
                    icon: Icons.attach_file_rounded,
                    size: SrButtonSize.sm,
                    variant: SrButtonVariant.secondary,
                    onPressed: () => _pick(photo: false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SrButton(
                    label: l10n.growthNoticePhoto,
                    icon: Icons.image_outlined,
                    size: SrButtonSize.sm,
                    variant: SrButtonVariant.secondary,
                    onPressed: () => _pick(photo: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      footer: SrButton(
        label: l10n.growthNoticePublish,
        expand: true,
        loading: submit.isLoading,
        onPressed: _publish,
      ),
    );
  }

  void _publish() => ref
      .read(noticeSubmitProvider.notifier)
      .submit(
        NoticeInput(
          title: _title.text,
          body: _body.text,
          audience: _audience,
          requiresAck: _requiresAck,
          push: _push,
          sms: _sms,
          pinDays: _pin ? _pinDays : null,
          attachments: List.of(_files),
        ),
      );

  Future<void> _pickAudience(Map<NoticeAudience, int>? counts) async {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final picked = await showSrSheet<NoticeAudience>(
      context: context,
      builder: (_) => SrOptionSheet<NoticeAudience>(
        title: l10n.growthNoticeAudience,
        options: NoticeAudience.values,
        labelOf: (a) => a.label(l10n),
        subtitleOf: (a) => switch (counts?[a]) {
          final count? => l10n.growthCampaignCount(fmt.number(count)),
          null => null,
        },
        isSelected: (a) => a == _audience,
      ),
    );
    if (picked != null && mounted) setState(() => _audience = picked);
  }

  Future<void> _pick({required bool photo}) async {
    final file = await FilePicker.pickFile(
      type: photo ? FileType.image : FileType.any,
    );
    if (file == null || !mounted) return;
    final bytes = await file.length() ?? 0;
    if (!mounted) return;
    setState(
      () => _files.add(
        NoticeAttachment(
          name: file.name,
          sizeKb: (bytes / 1024).ceil(),
          photo: photo,
        ),
      ),
    );
  }

  void _onSubmit(AsyncValue<Notice?>? _, AsyncValue<Notice?> next) {
    final l10n = context.l10n;
    switch (next) {
      case AsyncError(:final ApiFailure error) when error.isQuota:
        showSrWarning(context, l10n.growthNoticeSmsShort);
        final campaigns = ref.read(moduleAccessProvider(AppModule.campaign));
        if (campaigns.canView) context.push(Routes.campaignCredits);
      case AsyncError(:final ApiFailure error)
          when error.fieldErrors.isNotEmpty:
        return;
      case AsyncError(:final error):
        showSrError(context, growthFailureText(context, error));
      case AsyncData(:final value?):
        showSrSuccess(context, l10n.growthNoticePublished);
        context.pushReplacement(Routes.noticeFor(value.id));
      default:
        return;
    }
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.onRemove});

  final NoticeAttachment file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrCard(
      padding: EdgeInsets.zero,
      child: SrListRow(
        leading: Icon(
          file.photo ? Icons.image_outlined : Icons.description_outlined,
        ),
        title: file.name,
        subtitle: l10n.growthNoticeFileSize(context.fmt.number(file.sizeKb)),
        trailing: SrIconButton(
          icon: Icons.close_rounded,
          tooltip: l10n.commonClear,
          compact: true,
          onTap: onRemove,
        ),
      ),
    );
  }
}

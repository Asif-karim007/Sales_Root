import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/support/models/support_forms.dart';
import 'package:salesroot/features/support/models/support_ticket.dart';
import 'package:salesroot/features/support/providers/support_form_providers.dart';
import 'package:salesroot/features/support/view/widget/attachment_picker.dart';
import 'package:salesroot/features/support/view/widget/emoji_choice.dart';
import 'package:salesroot/features/support/view/widget/support_done_sheet.dart';
import 'package:salesroot/features/support/view/widget/support_failure.dart';
import 'package:salesroot/features/support/view/widget/support_labels.dart';
import 'package:salesroot/features/support/view/widget/support_language_pill.dart';
import 'package:salesroot/features/support/view/widget/support_rows.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #105 feedback: a face, the areas that hurt, a note and a screenshot.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _text = TextEditingController();
  FeedbackRating? _rating;
  final Set<FeedbackArea> _areas = {};
  bool _wantsReply = true;
  SupportAttachment? _screenshot;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _toggleArea(FeedbackArea area) => setState(() {
    if (_areas.remove(area)) return;
    if (area == FeedbackArea.nothing) {
      _areas.clear();
    } else {
      _areas.remove(FeedbackArea.nothing);
    }
    _areas.add(area);
  });

  Future<void> _toggleScreenshot(bool on) async {
    if (!on) {
      setState(() => _screenshot = null);
      return;
    }
    try {
      final picked = await pickSupportAttachment(AttachmentKind.image);
      if (!mounted || picked == null) return;
      setState(() => _screenshot = picked);
    } on PlatformException {
      if (!mounted) return;
      showSrError(context, context.l10n.supportPickFailed);
    }
  }

  void _send() {
    final rating = _rating;
    if (rating == null) return;
    ref
        .read(feedbackSubmitProvider.notifier)
        .submit(
          FeedbackInput(
            rating: rating,
            areas: _areas,
            text: _text.text,
            wantsReply: _wantsReply,
            screenshot: _screenshot,
          ),
        );
  }

  Future<void> _done(FeedbackReceipt receipt) async {
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    await showSupportDoneSheet(
      context,
      title: l10n.supportFeedbackDoneTitle,
      message: l10n.supportFeedbackDoneBody(receipt.number),
    );
    if (router.canPop()) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final submit = ref.watch(feedbackSubmitProvider);
    ref.listen(feedbackSubmitProvider, (_, next) {
      final receipt = next.value;
      if (receipt != null) {
        _done(receipt);
      } else if (next.hasError) {
        showSrError(context, supportFailureText(context, next.error));
      }
    });

    return SrKeyboardDismiss(
      child: SrScaffold(
        appBar: SrAppBar(
          title: l10n.supportFeedbackTitle,
          actions: const [SupportLanguagePill()],
        ),
        footer: SrButton(
          label: l10n.commonSend,
          expand: true,
          loading: submit.isLoading,
          onPressed: _rating == null ? null : _send,
        ),
        body: ListView(
          padding: const EdgeInsets.all(SrMetrics.gutter),
          children: [
            Text(
              l10n.supportFeedbackQuestion,
              style: AppText.hero(SrColors.of(context).ink, size: 22),
            ),
            const SizedBox(height: 16),
            _RatingRow(
              selected: _rating,
              onChanged: (rating) => setState(() => _rating = rating),
            ),
            const SizedBox(height: 20),
            SrFieldLabel(l10n.supportFeedbackStruggle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                for (final area in FeedbackArea.values)
                  SrChip(
                    label: l10n.feedbackArea(area),
                    selected: _areas.contains(area),
                    onTap: () => _toggleArea(area),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SrTextField(
              controller: _text,
              label: l10n.supportFeedbackMore,
              optional: true,
              hint: l10n.supportFeedbackMoreHint,
              multiline: true,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            SrCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  SupportToggleRow(
                    title: l10n.supportFeedbackWantReply,
                    subtitle: l10n.supportFeedbackWantReplyBody,
                    value: _wantsReply,
                    onChanged: (on) => setState(() => _wantsReply = on),
                  ),
                  SupportToggleRow(
                    title: l10n.supportFeedbackScreenshot,
                    subtitle: _screenshot?.name,
                    value: _screenshot != null,
                    onChanged: _toggleScreenshot,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.selected, required this.onChanged});

  final FeedbackRating? selected;
  final ValueChanged<FeedbackRating> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final rating in FeedbackRating.values)
            EmojiChoice(
              emoji: rating.emoji,
              label: l10n.feedbackRating(rating),
              selected: rating == selected,
              onTap: () => onChanged(rating),
            ),
        ],
      ),
    );
  }
}

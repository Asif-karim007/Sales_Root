import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/support/models/guide.dart';
import 'package:salesroot/features/support/providers/guide_providers.dart';
import 'package:salesroot/features/support/view/widget/support_labels.dart';
import 'package:salesroot/features/support/view/widget/support_language_pill.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #112 the AI guide: a chat that answers in Bangla or English and links to
/// the right screen. It never writes anything without the user's tap.
class AiGuideScreen extends ConsumerStatefulWidget {
  const AiGuideScreen({super.key, this.initialQuestion});

  final String? initialQuestion;

  @override
  ConsumerState<AiGuideScreen> createState() => _AiGuideScreenState();
}

class _AiGuideScreenState extends ConsumerState<AiGuideScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
    final question = widget.initialQuestion;
    if (question != null && question.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ask(question);
      });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _ask(String text) => ref.read(guideChatProvider.notifier).ask(text);

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    _ask(text);
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  });

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final chat = ref.watch(guideChatProvider);
    ref.listen(guideChatProvider, (_, _) => _toBottom());

    return SrKeyboardDismiss(
      child: SrScaffold(
        appBar: const SrAppBar(
          titleWidget: _GuideTitle(),
          actions: [SupportLanguagePill()],
        ),
        footer: Row(
          children: [
            Expanded(
              child: SrTextField(
                controller: _input,
                hint: l10n.supportGuideInputHint,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            SrIconButton(
              icon: Icons.send_rounded,
              color: c.accent,
              tooltip: l10n.commonSend,
              onTap: _input.text.trim().isEmpty || chat.thinking ? null : _send,
            ),
          ],
        ),
        body: ListView(
          controller: _scroll,
          padding: const EdgeInsets.all(SrMetrics.gutter),
          children: [
            for (final message in chat.messages) ...[
              _MessageView(message: message),
              const SizedBox(height: 10),
            ],
            if (chat.isFresh) _Suggestions(onTap: _ask),
            if (chat.thinking) const _Thinking(),
            if (chat.failure case final failure?)
              SrErrorState(
                error: failure,
                compact: true,
                onRetry: () => ref.read(guideChatProvider.notifier).retry(),
              ),
            if (chat.conversationId != null &&
                !chat.thinking &&
                chat.failure == null)
              _RateRow(rated: chat.rated),
            const SizedBox(height: 12),
            Text(
              l10n.supportGuideSafety,
              textAlign: TextAlign.center,
              style: AppText.meta(c.ink3, size: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideTitle extends ConsumerWidget {
  const _GuideTitle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final rules = ref.watch(guideStatusProvider).value?.enabled == false;

    return Row(
      children: [
        const SrAvatar(
          icon: Icons.auto_awesome_rounded,
          tone: SrAvatarTone.dark,
          size: 36,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.supportGuideTitle,
                style: AppText.pageTitle(c.ink, size: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                rules ? l10n.supportGuideRulesMode : l10n.supportGuideSubtitle,
                style: AppText.meta(c.ink2, size: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.message});

  final GuideMessage message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final answer = message.answer;

    return switch (message.kind) {
      GuideMessageKind.greeting => SrChatBubble(
        text: l10n.supportGuideGreeting,
      ),
      GuideMessageKind.mine => SrChatBubble(text: message.text, mine: true),
      GuideMessageKind.declined => SrChatBubble(
        text: l10n.supportGuideDeclined,
      ),
      GuideMessageKind.answer when answer != null => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrChatBubble(text: answer.text),
          if (!message.settled) ...[
            const SizedBox(height: 8),
            _AnswerActions(messageId: message.id, answer: answer),
          ],
        ],
      ),
      GuideMessageKind.answer => const SizedBox.shrink(),
    };
  }
}

class _AnswerActions extends ConsumerWidget {
  const _AnswerActions({required this.messageId, required this.answer});

  final int messageId;
  final GuideAnswer answer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(guideChatProvider.notifier);
    final buttons = <Widget>[
      if (answer.kind == GuideAnswerKind.confirm) ...[
        for (final action in answer.actions)
          SrButton(
            label: l10n.supportGuideConfirm,
            icon: Icons.check_rounded,
            size: SrButtonSize.sm,
            onPressed: () {
              notifier.settle(messageId, accepted: true);
              context.push(action.location);
            },
          ),
        SrButton(
          label: l10n.supportGuideDecline,
          variant: SrButtonVariant.secondary,
          size: SrButtonSize.sm,
          onPressed: () => notifier.settle(messageId, accepted: false),
        ),
      ] else ...[
        for (final (i, action) in answer.actions.indexed)
          SrButton(
            label: l10n.destination(action.destination),
            icon: Icons.arrow_forward_rounded,
            variant: i == 0
                ? SrButtonVariant.primary
                : SrButtonVariant.secondary,
            size: SrButtonSize.sm,
            onPressed: () => context.push(action.location),
          ),
      ],
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: buttons,
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final prompts = [
      l10n.supportGuidePromptAddLead,
      l10n.supportGuidePromptScan,
      l10n.supportGuidePromptStage,
      l10n.supportGuidePromptCollection,
      l10n.supportGuidePromptOffline,
      l10n.supportGuidePromptTask,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.supportGuideTry, style: AppText.label(c.ink2)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          children: [
            for (final prompt in prompts)
              _Prompt(text: prompt, onTap: () => onTap(prompt)),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

/// A suggested question; wraps onto two lines when it is long.
class _Prompt extends StatelessWidget {
  const _Prompt({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
        side: BorderSide(color: c.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            text,
            style: AppText.chip(c.ink, size: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// "Did this help?" with a thumb up and down, then a thank-you.
class _RateRow extends ConsumerWidget {
  const _RateRow({required this.rated});

  final bool rated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final notifier = ref.read(guideChatProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          rated ? l10n.supportGuideRated : l10n.supportGuideRateAsk,
          style: AppText.meta(c.ink2, size: 12),
        ),
        if (!rated) ...[
          const SizedBox(width: 4),
          SrIconButton(
            icon: Icons.thumb_up_outlined,
            tooltip: l10n.supportGuideRateUp,
            onTap: () => notifier.rate(helpful: true),
          ),
          SrIconButton(
            icon: Icons.thumb_down_outlined,
            tooltip: l10n.supportGuideRateDown,
            onTap: () => notifier.rate(helpful: false),
          ),
        ],
      ],
    );
  }
}

class _Thinking extends StatelessWidget {
  const _Thinking();

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.more_horiz_rounded, size: 20, color: c.accent),
          const SizedBox(width: 8),
          Text(context.l10n.supportGuideThinking, style: AppText.meta(c.ink2)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/support/models/support_forms.dart';
import 'package:salesroot/features/support/providers/support_form_providers.dart';
import 'package:salesroot/features/support/view/widget/emoji_choice.dart';
import 'package:salesroot/features/support/view/widget/support_failure.dart';
import 'package:salesroot/features/support/view/widget/support_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The moments other features pass to [showMomentSurvey].
abstract final class SurveyMoments {
  static const quotationSent = 'quotationSent';
  static const leadCreated = 'leadCreated';
  static const cardScanned = 'cardScanned';
  static const collectionRecorded = 'collectionRecorded';
  static const visitCheckedIn = 'visitCheckedIn';
  static const helpArticle = 'helpArticle';
}

/// #107: asks one easy-or-not question after [moment], at most once every
/// 14 days across all moments. True when the sheet was shown.
Future<bool> showMomentSurvey(
  BuildContext context, {
  required String moment,
}) async {
  final gate = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(surveyGateProvider.notifier);
  if (!gate.tryAsk()) return false;
  await showSrSheet<void>(
    context: context,
    builder: (_) => MomentSurveySheet(moment: moment),
  );
  return true;
}

class MomentSurveySheet extends ConsumerWidget {
  const MomentSurveySheet({super.key, required this.moment});

  final String moment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final provider = momentSurveyProvider(moment);
    final answer = ref.watch(provider);
    ref.listen(provider, (_, next) {
      if (next.value != null) {
        showSrSuccess(context, l10n.supportSurveyThanks);
        Navigator.of(context).pop();
      } else if (next.hasError) {
        showSrError(context, supportFailureText(context, next.error));
      }
    });

    return SrSheet(
      title: l10n.supportSurveyTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_question(l10n), style: AppText.lead(c.ink)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final score in SurveyScore.values)
                EmojiChoice(
                  emoji: score.emoji,
                  label: l10n.surveyScore(score),
                  size: 56,
                  onTap: answer.isLoading
                      ? null
                      : () => ref.read(provider.notifier).answer(score),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            l10n.supportSurveyLimit,
            textAlign: TextAlign.center,
            style: AppText.meta(c.ink3, size: 12),
          ),
        ],
      ),
    );
  }

  String _question(AppLocalizations l10n) => switch (moment) {
    SurveyMoments.quotationSent => l10n.supportSurveyQuotation,
    SurveyMoments.leadCreated => l10n.supportSurveyLead,
    SurveyMoments.cardScanned => l10n.supportSurveyScan,
    SurveyMoments.collectionRecorded => l10n.supportSurveyCollection,
    SurveyMoments.visitCheckedIn => l10n.supportSurveyVisit,
    SurveyMoments.helpArticle => l10n.supportSurveyHelp,
    _ => l10n.supportSurveyGeneric,
  };
}

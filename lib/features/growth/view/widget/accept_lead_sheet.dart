import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/growth/models/conversation.dart';
import 'package:salesroot/features/growth/providers/inbox_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #138 Accept an enquiry: take the conversation, then finish the lead,
/// prefilled from it.
Future<void> showAcceptLeadSheet(
  BuildContext context,
  Conversation conversation,
) => showSrSheet<void>(
  context: context,
  builder: (_) => AcceptLeadSheet(conversation: conversation),
);

class AcceptLeadSheet extends ConsumerWidget {
  const AcceptLeadSheet({super.key, required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = acceptLeadSubmitProvider(conversation.id);
    final submit = ref.watch(provider);
    ref.listen(provider, (_, next) => _onSubmit(context, next));
    final phone = conversation.phone;
    return SrSheet(
      title: l10n.growthInboxAccept,
      subtitle: conversation.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GrowthInfoCard(
            lines: [
              (l10n.growthFieldName, conversation.name),
              if (phone != null)
                (l10n.growthFieldMobile, growthPhone(context, phone)),
              (l10n.growthInboxSource, conversation.channel.label(l10n)),
            ],
          ),
          const SizedBox(height: 12),
          SrNote(message: l10n.growthAcceptTakeHint),
          const SizedBox(height: 12),
          SrButton(
            label: l10n.growthAcceptConfirm,
            expand: true,
            loading: submit.isLoading,
            onPressed: () => ref.read(provider.notifier).submit(),
          ),
        ],
      ),
    );
  }

  void _onSubmit(BuildContext context, AsyncValue<Conversation?> next) {
    if (next case AsyncError(:final error)) {
      showSrError(context, growthFailureText(context, error));
      return;
    }
    final taken = next.value;
    if (taken == null) return;
    final router = GoRouter.of(context);
    showSrSuccess(context, context.l10n.growthAcceptDone(taken.name));
    Navigator.of(context).pop();
    final leadId = taken.leadId;
    final phone = taken.phone;
    router.pushReplacement(
      leadId != null
          ? Routes.leadFor(leadId)
          : Uri(
              path: Routes.leadNew,
              queryParameters: {
                'name': taken.name,
                'phone': ?phone,
                'source': taken.channel.wire,
              },
            ).toString(),
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/team/providers/chat_providers.dart';
import 'package:salesroot/features/team/view/widget/failure_text.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Opens (or starts) the one-to-one chat with [memberId].
Future<void> openDirectChat(
  BuildContext context,
  WidgetRef ref,
  int memberId,
) async {
  try {
    final thread = await showSrLoader(
      context,
      ref.read(chatRepositoryProvider).direct(memberId),
    );
    if (!context.mounted) return;
    context.push(Routes.chatFor(thread.id));
  } on ApiFailure catch (failure) {
    if (!context.mounted) return;
    showSrError(context, failureText(context, failure));
  }
}

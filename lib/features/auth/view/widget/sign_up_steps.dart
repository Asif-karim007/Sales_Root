import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/auth/providers/auth_providers.dart';

/// Ends sign-up: the tour first, so the router keeps the user there once
/// the session appears, then the sign-in.
void finishSignUp(BuildContext context, WidgetRef ref) {
  final flow = ref.read(signUpFlowProvider.notifier);
  context.go(Routes.tour);
  flow.signIn();
}

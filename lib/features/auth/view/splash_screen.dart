import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/auth/view/widget/deep_screen.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Shown while the session, PIN lock and grants load; the router leaves it
/// on its own. A failed workspace or grants load is offered a retry.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaces = ref.watch(workspacesProvider);
    final permissions = ref.watch(permissionsProvider);
    final (error, retry) = workspaces.hasError
        ? (workspaces.error, () => ref.invalidate(workspacesProvider))
        : permissions.hasError
        ? (permissions.error, () => ref.invalidate(permissionsProvider))
        : (null, null);

    return DeepScreen(
      bottom: error == null
          ? null
          : DeepScreenSheet(
              children: [SrErrorState(error: error, onRetry: retry)],
            ),
    );
  }
}

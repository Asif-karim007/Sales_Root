import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/routes.dart';

/// Sends the user to the no-access screen unless the role, plan and level
/// allow [right] in [module].
GoRouterRedirect requireAccess(
  AppModule module, [
  ModuleRight right = ModuleRight.view,
]) => (context, state) {
  final access = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(moduleAccessProvider(module));
  if (access.allows(right)) return null;
  return Routes.noAccessFor(module.wire, planLocked: access.lockedByPlan);
};

/// The `:id` path parameter.
int idParam(GoRouterState state) =>
    int.tryParse(state.pathParameters['id'] ?? '') ?? 0;

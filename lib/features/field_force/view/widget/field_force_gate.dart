import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Shows [child] when [module] allows [right]; the Field Force upsell when
/// the plan lacks the add-on, and no-access otherwise.
class FieldForceGate extends ConsumerWidget {
  const FieldForceGate({
    super.key,
    required this.module,
    required this.child,
    this.right = ModuleRight.view,
  });

  final AppModule module;
  final ModuleRight right;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(moduleAccessProvider(module));
    if (access.lockedByPlan) {
      return Center(
        child: SingleChildScrollView(
          child: SrPlanLocked(onAction: () => context.push(Routes.addOns)),
        ),
      );
    }
    if (!access.allows(right)) {
      return const Center(child: SingleChildScrollView(child: SrNoAccess()));
    }
    return child;
  }
}

/// The plan-limit sheet for a 402: what ran out, and the way to a bigger
/// plan.
Future<void> showQuotaSheet(BuildContext context, ApiFailure failure) {
  final kind = (failure.quota ?? QuotaKind.storage).name;
  return showSrSheet<void>(
    context: context,
    builder: (sheet) => SrSheet(
      child: SrPlanLocked(
        message: failure.message,
        onAction: () {
          Navigator.of(sheet).pop();
          context.push('${Routes.planChoose}?reason=quota&kind=$kind');
        },
      ),
    ),
  );
}

/// Opens a visit screen, or the Field Force upsell when the plan lacks it.
void openVisitRoute(BuildContext context, WidgetRef ref, String location) {
  final access = ref.read(moduleAccessProvider(AppModule.visit));
  if (!access.lockedByPlan) {
    context.push(location);
    return;
  }
  showSrSheet<void>(
    context: context,
    builder: (sheet) => SrSheet(
      child: SrPlanLocked(
        onAction: () {
          Navigator.of(sheet).pop();
          context.push(Routes.addOns);
        },
      ),
    ),
  );
}

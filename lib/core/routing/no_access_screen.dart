import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Where guards send a route the role or plan doesn't allow.
class NoAccessScreen extends StatelessWidget {
  const NoAccessScreen({super.key, required this.planLocked});

  final bool planLocked;

  @override
  Widget build(BuildContext context) {
    return SrScaffold(
      appBar: const SrAppBar(),
      body: Center(
        child: planLocked
            ? SrPlanLocked(
                onAction: () => context.pushReplacement(Routes.planUsage),
              )
            : const SrNoAccess(),
      ),
    );
  }
}

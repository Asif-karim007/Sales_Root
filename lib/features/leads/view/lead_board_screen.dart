import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/features/leads/providers/lead_providers.dart';
import 'package:salesroot/features/leads/view/widget/lead_board_view.dart';
import 'package:salesroot/features/leads/view/widget/lead_filter_sheet.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #22 on its own route, for links from outside the Leads tab.
class LeadBoardScreen extends ConsumerWidget {
  const LeadBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filtered = ref.watch(leadFilterProvider).activeCount > 0;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.leadsPipeline,
        actions: [
          SrIconButton(
            icon: Icons.tune_rounded,
            tooltip: l10n.commonFilter,
            badge: filtered,
            onTap: () => showSrSheet<void>(
              context: context,
              builder: (_) => const LeadFilterSheet(),
            ),
          ),
        ],
      ),
      body: const LeadBoardView(),
    );
  }
}

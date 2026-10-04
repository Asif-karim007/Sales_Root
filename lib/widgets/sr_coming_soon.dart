import 'package:flutter/material.dart';

import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/sr_scaffold.dart';
import 'package:salesroot/widgets/sr_states.dart';

/// Stands in for a screen that is not built yet.
class SrComingSoonScreen extends StatelessWidget {
  const SrComingSoonScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SrScaffold(
      appBar: SrAppBar(title: title),
      body: Center(
        child: SingleChildScrollView(
          child: SrEmptyState(
            title: context.l10n.commonComingSoon,
            icon: Icons.construction_rounded,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:salesroot/features/growth/models/conversation.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// All, unassigned and mine.
class ConversationBoxChips extends StatelessWidget {
  const ConversationBoxChips({
    super.key,
    required this.box,
    required this.onChanged,
  });

  final ConversationBox box;
  final ValueChanged<ConversationBox> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const boxes = ConversationBox.values;
    return SrChipRow(
      index: boxes.indexOf(box),
      onChanged: (i) => onChanged(boxes[i]),
      chips: [
        for (final b in boxes)
          SrChipItem(switch (b) {
            ConversationBox.all => l10n.commonAll,
            ConversationBox.unassigned => l10n.growthInboxUnassigned,
            ConversationBox.mine => l10n.growthInboxMine,
          }),
      ],
    );
  }
}

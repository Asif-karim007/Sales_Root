import 'package:flutter/material.dart';

import 'package:salesroot/widgets/widgets.dart';

/// Merge fields the server fills per recipient; a tap inserts one at the
/// cursor.
class MergeTags extends StatelessWidget {
  const MergeTags({
    super.key,
    required this.tags,
    required this.controller,
    required this.onInserted,
  });

  final List<String> tags;
  final TextEditingController controller;
  final VoidCallback onInserted;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final tag in tags)
        SrChip(label: tag, tone: SrTone.accent, onTap: () => _insert(tag)),
    ],
  );

  void _insert(String tag) {
    final text = controller.text;
    final selection = controller.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, tag),
      selection: TextSelection.collapsed(offset: start + tag.length),
    );
    onInserted();
  }
}

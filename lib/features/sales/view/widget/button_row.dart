import 'package:flutter/material.dart';

/// Footer buttons side by side, sharing the width equally.
class ButtonRow extends StatelessWidget {
  const ButtonRow({super.key, required this.buttons});

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: buttons[i]),
        ],
      ],
    );
  }
}

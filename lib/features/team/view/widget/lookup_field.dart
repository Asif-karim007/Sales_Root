import 'package:flutter/material.dart';

import 'package:salesroot/widgets/widgets.dart';

/// A picker field over [options] that selects the one whose [idOf] is
/// [selected].
class LookupField<T> extends StatelessWidget {
  const LookupField({
    super.key,
    required this.title,
    required this.options,
    required this.idOf,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
    this.subtitleOf,
    this.label,
    this.placeholder,
    this.error,
    this.icon,
    this.withAvatar = false,
  });

  final String title;
  final List<T> options;
  final String Function(T) idOf;
  final String Function(T) labelOf;
  final String? Function(T)? subtitleOf;
  final String? selected;
  final ValueChanged<T> onChanged;
  final String? label;
  final String? placeholder;
  final String? error;
  final IconData? icon;
  final bool withAvatar;

  @override
  Widget build(BuildContext context) {
    String? value;
    for (final option in options) {
      if (idOf(option) == selected) value = labelOf(option);
    }
    return SrPickerField(
      label: label,
      icon: icon,
      value: value,
      placeholder: placeholder,
      error: error,
      onTap: () async {
        final picked = await showSrSheet<T>(
          context: context,
          builder: (_) => SrOptionSheet<T>(
            title: title,
            options: options,
            labelOf: labelOf,
            subtitleOf: subtitleOf,
            isSelected: (o) => idOf(o) == selected,
            withAvatar: withAvatar,
          ),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

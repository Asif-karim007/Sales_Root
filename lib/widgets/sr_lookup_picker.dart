import 'package:flutter/material.dart';

import 'package:salesroot/widgets/sr_picker.dart';
import 'package:salesroot/widgets/sr_sheet.dart';

/// An `{ Id, Name }` choice for [SrLookupPicker] and [SrLookupMultiPicker].
@immutable
class SrLookupOption {
  const SrLookupOption({
    required this.id,
    required this.name,
    this.subtitle,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String? subtitle;
  final String? imageUrl;
}

/// A picker field over [SrLookupOption]s that selects one id.
class SrLookupPicker extends StatelessWidget {
  const SrLookupPicker({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.label,
    this.placeholder,
    this.icon,
    this.error,
    this.withAvatar = false,
  });

  final String title;
  final List<SrLookupOption> options;
  final String? selected;
  final ValueChanged<String> onChanged;
  final String? label;
  final String? placeholder;
  final IconData? icon;
  final String? error;
  final bool withAvatar;

  @override
  Widget build(BuildContext context) {
    String? value;
    for (final option in options) {
      if (option.id == selected) value = option.name;
    }

    return SrPickerField(
      label: label,
      icon: icon,
      value: value,
      placeholder: placeholder,
      error: error,
      onTap: () async {
        final picked = await showSrSheet<SrLookupOption>(
          context: context,
          builder: (_) => SrOptionSheet<SrLookupOption>(
            title: title,
            options: options,
            labelOf: (o) => o.name,
            subtitleOf: (o) => o.subtitle,
            imageOf: (o) => o.imageUrl,
            isSelected: (o) => o.id == selected,
            withAvatar: withAvatar,
          ),
        );
        if (picked != null) onChanged(picked.id);
      },
    );
  }
}

/// A picker field over [SrLookupOption]s that selects several ids.
class SrLookupMultiPicker extends StatelessWidget {
  const SrLookupMultiPicker({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.label,
    this.placeholder,
    this.icon,
    this.error,
    this.withAvatar = false,
  });

  final String title;
  final List<SrLookupOption> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final String? label;
  final String? placeholder;
  final IconData? icon;
  final String? error;
  final bool withAvatar;

  @override
  Widget build(BuildContext context) {
    final names = [
      for (final option in options)
        if (selected.contains(option.id)) option.name,
    ];

    return SrPickerField(
      label: label,
      icon: icon,
      value: names.join(', '),
      placeholder: placeholder,
      error: error,
      onTap: () async {
        final picked = await showSrSheet<List<SrLookupOption>>(
          context: context,
          builder: (_) => SrMultiOptionSheet<SrLookupOption>(
            title: title,
            options: options,
            labelOf: (o) => o.name,
            subtitleOf: (o) => o.subtitle,
            imageOf: (o) => o.imageUrl,
            isSelected: (o) => selected.contains(o.id),
            withAvatar: withAvatar,
          ),
        );
        if (picked == null) return;
        onChanged([for (final option in picked) option.id]);
      },
    );
  }
}

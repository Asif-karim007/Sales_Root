import 'dart:async';

import 'package:flutter/material.dart';

import 'package:salesroot/widgets/widgets.dart';

/// A search field that reports what was typed after a short pause.
class SearchBox extends StatefulWidget {
  const SearchBox({
    super.key,
    required this.hint,
    required this.onSearch,
    this.initial = '',
    this.controller,
    this.suffix,
  });

  final String hint;
  final ValueChanged<String> onSearch;
  final String initial;

  /// Lets the owner write into the field, as voice search does.
  final TextEditingController? controller;
  final Widget? suffix;

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  static const _pause = Duration(milliseconds: 350);

  late final TextEditingController _own = TextEditingController(
    text: widget.initial,
  );
  Timer? _timer;

  TextEditingController get _controller => widget.controller ?? _own;

  @override
  void dispose() {
    _timer?.cancel();
    _own.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _timer?.cancel();
    _timer = Timer(_pause, () => widget.onSearch(value.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return SrTextField(
      controller: _controller,
      hint: widget.hint,
      prefixIcon: Icons.search_rounded,
      suffix: widget.suffix,
      textInputAction: TextInputAction.search,
      onChanged: _changed,
      onSubmitted: (value) {
        _timer?.cancel();
        widget.onSearch(value.trim());
      },
    );
  }
}

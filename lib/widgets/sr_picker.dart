import 'dart:async';

import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/sr_avatar.dart';
import 'package:salesroot/widgets/sr_button.dart';
import 'package:salesroot/widgets/sr_sheet.dart';
import 'package:salesroot/widgets/sr_states.dart';
import 'package:salesroot/widgets/sr_text_field.dart';

/// A tappable field that shows the picked value and opens a chooser.
class SrPickerField extends StatelessWidget {
  const SrPickerField({
    super.key,
    required this.onTap,
    this.value,
    this.placeholder,
    this.icon,
    this.label,
    this.error,
    this.enabled = true,
  });

  final VoidCallback onTap;
  final String? value;
  final String? placeholder;
  final IconData? icon;
  final String? label;
  final String? error;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SrDropdownField(
    onTap: onTap,
    value: value,
    placeholder: placeholder,
    icon: icon,
    label: label,
    error: error,
    enabled: enabled,
  );
}

List<T> _filter<T>(List<T> options, String query, String Function(T) labelOf) {
  final term = query.trim().toLowerCase();
  if (term.isEmpty) return options;
  return options.where((o) => labelOf(o).toLowerCase().contains(term)).toList();
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.hint});

  final TextEditingController controller;
  final String? hint;

  @override
  Widget build(BuildContext context) => SrTextField(
    controller: controller,
    hint: hint ?? context.l10n.commonSearch,
    prefixIcon: Icons.search_rounded,
    textInputAction: TextInputAction.search,
  );
}

class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) => SrEmptyState(
    title: context.l10n.dsSearchEmptyTitle,
    message: context.l10n.dsSearchEmptyBody,
    icon: Icons.search_off_rounded,
  );
}

/// Searchable single-choice sheet; pops with the chosen option.
class SrOptionSheet<T> extends StatefulWidget {
  const SrOptionSheet({
    super.key,
    required this.title,
    required this.options,
    required this.labelOf,
    required this.isSelected,
    this.searchHint,
    this.subtitleOf,
    this.withAvatar = false,
    this.imageOf,
  });

  final String title;
  final List<T> options;
  final String Function(T) labelOf;
  final bool Function(T) isSelected;
  final String? searchHint;
  final String? Function(T)? subtitleOf;
  final bool withAvatar;
  final String? Function(T)? imageOf;

  @override
  State<SrOptionSheet<T>> createState() => _SrOptionSheetState<T>();
}

class _SrOptionSheetState<T> extends State<SrOptionSheet<T>> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(_onQuery);
  }

  void _onQuery() => setState(() {});

  @override
  void dispose() {
    _search.removeListener(_onQuery);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = _filter(widget.options, _search.text, widget.labelOf);

    return SrSheet(
      title: widget.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SearchBox(controller: _search, hint: widget.searchHint),
          const SizedBox(height: 6),
          Flexible(
            child: options.isEmpty
                ? const SingleChildScrollView(child: _NoMatches())
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(top: 6),
                    itemCount: options.length,
                    itemBuilder: (context, i) {
                      final option = options[i];
                      return _OptionRow(
                        label: widget.labelOf(option),
                        subtitle: widget.subtitleOf?.call(option),
                        selected: widget.isSelected(option),
                        withAvatar: widget.withAvatar,
                        imageUrl: widget.imageOf?.call(option),
                        onTap: () => Navigator.of(context).pop(option),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Single-choice sheet for lists too large to load up front: [search] is
/// asked for one page at a time, and the next page loads near the end.
class SrSearchSheet<T> extends StatefulWidget {
  const SrSearchSheet({
    super.key,
    required this.title,
    required this.search,
    required this.labelOf,
    required this.isSelected,
    this.pageSize = 20,
    this.searchHint,
    this.subtitleOf,
    this.withAvatar = false,
    this.imageOf,
  });

  final String title;
  final Future<List<T>> Function(String term, int page) search;
  final String Function(T) labelOf;
  final bool Function(T) isSelected;
  final int pageSize;
  final String? searchHint;
  final String? Function(T)? subtitleOf;
  final bool withAvatar;
  final String? Function(T)? imageOf;

  @override
  State<SrSearchSheet<T>> createState() => _SrSearchSheetState<T>();
}

class _SrSearchSheetState<T> extends State<SrSearchSheet<T>> {
  static const _debounce = Duration(milliseconds: 350);

  final _search = TextEditingController();
  final _results = <T>[];
  Timer? _timer;
  String _term = '';
  int _request = 0;
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onQuery);
    _load(reset: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.removeListener(_onQuery);
    _search.dispose();
    super.dispose();
  }

  void _onQuery() {
    final term = _search.text.trim();
    if (term == _term) return;
    _term = term;
    _timer?.cancel();
    _timer = Timer(_debounce, () => _load(reset: true));
  }

  Future<void> _load({bool reset = false}) async {
    if (!reset && (_loading || !_hasMore || _error != null)) return;
    final request = ++_request;
    final page = reset ? 1 : _page + 1;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _results.clear();
        _hasMore = true;
      }
    });
    try {
      final hits = await widget.search(_term, page);
      if (!mounted || request != _request) return;
      setState(() {
        _results.addAll(hits);
        _page = page;
        _hasMore = hits.length >= widget.pageSize;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() => _error = error);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  void _retryMore() {
    setState(() => _error = null);
    _load();
  }

  bool _onScroll(ScrollNotification note) {
    if (note.metrics.extentAfter < 240) _load();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return SrSheet(
      title: widget.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SearchBox(controller: _search, hint: widget.searchHint),
          const SizedBox(height: 6),
          Flexible(child: _results.isEmpty ? _state() : _list()),
        ],
      ),
    );
  }

  Widget _state() {
    final error = _error;
    if (_loading) return const _SearchSpinner();
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SrErrorState(
          error: error,
          compact: true,
          onRetry: () => _load(reset: true),
        ),
      );
    }
    return const SingleChildScrollView(child: _NoMatches());
  }

  Widget _list() {
    final error = _error;
    final footer = _loading || error != null;

    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.only(top: 6),
        itemCount: _results.length + (footer ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _results.length) {
            return error == null
                ? const _SearchSpinner()
                : SrErrorState(
                    error: error,
                    compact: true,
                    onRetry: _retryMore,
                  );
          }
          final option = _results[i];
          return _OptionRow(
            label: widget.labelOf(option),
            subtitle: widget.subtitleOf?.call(option),
            selected: widget.isSelected(option),
            withAvatar: widget.withAvatar,
            imageUrl: widget.imageOf?.call(option),
            onTap: () => Navigator.of(context).pop(option),
          );
        },
      ),
    );
  }
}

class _SearchSpinner extends StatelessWidget {
  const _SearchSpinner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        heightFactor: 1,
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation<Color>(
              SrColors.of(context).accent,
            ),
          ),
        ),
      ),
    );
  }
}

/// Searchable multi-choice sheet; pops with every checked option on apply.
class SrMultiOptionSheet<T> extends StatefulWidget {
  const SrMultiOptionSheet({
    super.key,
    required this.title,
    required this.options,
    required this.labelOf,
    required this.isSelected,
    this.searchHint,
    this.subtitleOf,
    this.withAvatar = false,
    this.imageOf,
  });

  final String title;
  final List<T> options;
  final String Function(T) labelOf;
  final bool Function(T) isSelected;
  final String? searchHint;
  final String? Function(T)? subtitleOf;
  final bool withAvatar;
  final String? Function(T)? imageOf;

  @override
  State<SrMultiOptionSheet<T>> createState() => _SrMultiOptionSheetState<T>();
}

class _SrMultiOptionSheetState<T> extends State<SrMultiOptionSheet<T>> {
  final _search = TextEditingController();
  late final Set<T> _picked = widget.options.where(widget.isSelected).toSet();

  @override
  void initState() {
    super.initState();
    _search.addListener(_onQuery);
  }

  void _onQuery() => setState(() {});

  void _toggle(T option) => setState(() {
    if (!_picked.remove(option)) _picked.add(option);
  });

  @override
  void dispose() {
    _search.removeListener(_onQuery);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = _filter(widget.options, _search.text, widget.labelOf);

    return SrSheet(
      title: widget.title,
      subtitle: l10n.dsSelectedCount(context.fmt.number(_picked.length)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SearchBox(controller: _search, hint: widget.searchHint),
          const SizedBox(height: 6),
          Flexible(
            child: options.isEmpty
                ? const SingleChildScrollView(child: _NoMatches())
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(top: 6),
                    itemCount: options.length,
                    itemBuilder: (context, i) {
                      final option = options[i];
                      return _OptionRow(
                        label: widget.labelOf(option),
                        subtitle: widget.subtitleOf?.call(option),
                        selected: _picked.contains(option),
                        multi: true,
                        withAvatar: widget.withAvatar,
                        imageUrl: widget.imageOf?.call(option),
                        onTap: () => _toggle(option),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          SrButton(
            label: l10n.commonApply,
            expand: true,
            onPressed: () => Navigator.of(context).pop(_picked.toList()),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.multi = false,
    this.withAvatar = false,
    this.imageUrl,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool multi;
  final bool withAvatar;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final detail = subtitle;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? c.tint : Colors.transparent,
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  if (withAvatar) ...[
                    SrAvatar(name: label, imageUrl: imageUrl, size: 34),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: AppText.rowTitle(
                            selected ? c.accent : c.ink,
                            size: 14.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (detail != null && detail.isNotEmpty)
                          Text(
                            detail,
                            style: AppText.meta(c.ink2, size: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  multi
                      ? SrCheckbox(value: selected, onChanged: (_) => onTap())
                      : _RadioDisc(selected: selected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioDisc extends StatelessWidget {
  const _RadioDisc({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? c.accent : c.ink3, width: 2),
      ),
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: c.accent,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

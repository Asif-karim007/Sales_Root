import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/sr_border.dart';

const double _kMultilineHeight = 96;
const Duration _kFocusFade = Duration(milliseconds: 150);

BoxDecoration _fieldBox(
  SrColors c, {
  required bool focused,
  required bool error,
  required bool enabled,
}) {
  final rim = error
      ? c.danger
      : focused
      ? c.accent
      : c.line;
  return BoxDecoration(
    color: enabled ? c.surface : c.canvas,
    borderRadius: BorderRadius.circular(SrMetrics.radiusButton),
    border: SrBorder.all(color: rim),
    boxShadow: focused
        ? [BoxShadow(color: error ? c.dangerTint : c.tint, spreadRadius: 3)]
        : null,
  );
}

/// The prototype's `.flbl`, with an "optional" suffix when [optional].
class SrFieldLabel extends StatelessWidget {
  const SrFieldLabel(this.text, {super.key, this.optional = false});

  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Text.rich(
      TextSpan(
        text: text,
        style: AppText.fieldLabel(c.ink2),
        children: [
          if (optional)
            TextSpan(
              text: ' · ${context.l10n.commonOptional}',
              style: AppText.meta(c.ink3, size: 12),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _FieldMessage extends StatelessWidget {
  const _FieldMessage({required this.text, required this.error});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final color = error ? c.danger : c.ink2;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (error) ...[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(Icons.error_outline_rounded, size: 14, color: color),
            ),
            const SizedBox(width: 5),
          ],
          Expanded(child: Text(text, style: AppText.meta(color, size: 12))),
        ],
      ),
    );
  }
}

/// The prototype's `.fin`: a 50px field with a 3px tint ring on focus, or a
/// 96px text area when [multiline].
class SrTextField extends StatefulWidget {
  const SrTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.label,
    this.optional = false,
    this.hint,
    this.helper,
    this.error,
    this.prefixIcon,
    this.prefix,
    this.suffix,
    this.suffixText,
    this.obscure = false,
    this.multiline = false,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? label;
  final bool optional;
  final String? hint;
  final String? helper;

  /// Shown in red under the field, and turns the border red.
  final String? error;
  final IconData? prefixIcon;
  final Widget? prefix;
  final Widget? suffix;

  /// A unit shown in a grey box at the end, like `৳` or `km`.
  final String? suffixText;
  final bool obscure;
  final bool multiline;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final List<String>? autofillHints;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<SrTextField> createState() => _SrTextFieldState();
}

class _SrTextFieldState extends State<SrTextField> {
  FocusNode? _ownFocus;
  bool _focused = false;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(SrTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) return;
    (oldWidget.focusNode ?? _ownFocus)?.removeListener(_onFocus);
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (_focus.hasFocus != _focused) {
      setState(() => _focused = _focus.hasFocus);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final label = widget.label;
    final error = widget.error;
    final helper = widget.helper;
    final hasError = error != null && error.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          SrFieldLabel(label, optional: widget.optional),
          const SizedBox(height: 6),
        ],
        TextFieldTapRegion(
          child: AnimatedContainer(
            duration: _kFocusFade,
            height: widget.multiline ? null : SrMetrics.fieldHeight,
            constraints: widget.multiline
                ? const BoxConstraints(minHeight: _kMultilineHeight)
                : null,
            padding: EdgeInsets.only(
              left: 14,
              right: widget.suffixText == null ? 14 : 6,
              top: widget.multiline ? 12 : 0,
              bottom: widget.multiline ? 12 : 0,
            ),
            decoration: _fieldBox(
              c,
              focused: _focused,
              error: hasError,
              enabled: widget.enabled,
            ),
            child: Row(
              crossAxisAlignment: widget.multiline
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: _rowChildren(c),
            ),
          ),
        ),
        if (error != null && error.isNotEmpty)
          _FieldMessage(text: error, error: true)
        else if (helper != null)
          _FieldMessage(text: helper, error: false),
      ],
    );
  }

  List<Widget> _rowChildren(SrColors c) {
    final prefixIcon = widget.prefixIcon;
    final prefix = widget.prefix;
    final suffix = widget.suffix;
    final suffixText = widget.suffixText;

    return [
      if (prefixIcon != null) ...[
        Icon(prefixIcon, size: 19, color: _focused ? c.accent : c.ink3),
        const SizedBox(width: 8),
      ],
      if (prefix != null) ...[prefix, const SizedBox(width: 8)],
      Expanded(child: _input(c)),
      if (suffix != null) ...[const SizedBox(width: 8), suffix],
      if (suffixText != null) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: c.canvas,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(suffixText, style: AppText.rowTitle(c.ink2, size: 13)),
        ),
      ],
    ];
  }

  Widget _input(SrColors c) {
    return TextField(
      controller: widget.controller,
      focusNode: _focus,
      obscureText: widget.obscure,
      keyboardType: widget.multiline
          ? TextInputType.multiline
          : widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      autofillHints: widget.autofillHints,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      maxLength: widget.maxLength,
      minLines: widget.multiline ? 3 : 1,
      maxLines: widget.multiline ? 8 : 1,
      cursorColor: c.accent,
      style: AppText.input(c.ink),
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        counterText: '',
        hintText: widget.hint,
        hintStyle: AppText.input(c.ink3),
      ),
    );
  }
}

/// A field that shows a picked value (or [placeholder]) with a chevron and
/// opens a chooser on tap.
class SrDropdownField extends StatelessWidget {
  const SrDropdownField({
    super.key,
    required this.onTap,
    this.value,
    this.label,
    this.optional = false,
    this.placeholder,
    this.icon,
    this.error,
    this.enabled = true,
    this.trailingIcon = Icons.keyboard_arrow_down_rounded,
  });

  final VoidCallback? onTap;
  final String? value;
  final String? label;
  final bool optional;
  final String? placeholder;
  final IconData? icon;
  final String? error;
  final bool enabled;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final label = this.label;
    final error = this.error;
    final icon = this.icon;
    final shown = value;
    final filled = shown != null && shown.isNotEmpty;
    final hasError = error != null && error.isNotEmpty;
    final shape = BorderRadius.circular(SrMetrics.radiusButton);

    final box = Material(
      color: Colors.transparent,
      child: Ink(
        height: SrMetrics.fieldHeight,
        decoration: _fieldBox(
          c,
          focused: false,
          error: hasError,
          enabled: enabled,
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: shape,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 19, color: c.ink3),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    filled ? shown : (placeholder ?? ''),
                    style: AppText.input(filled ? c.ink : c.ink3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(trailingIcon, size: 20, color: c.ink3),
              ],
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          SrFieldLabel(label, optional: optional),
          const SizedBox(height: 6),
        ],
        Opacity(opacity: enabled ? 1 : 0.6, child: box),
        if (error != null && error.isNotEmpty)
          _FieldMessage(text: error, error: true),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Asks why something is being cancelled; null when the user backs out.
Future<String?> askCancelReason(
  BuildContext context, {
  required String title,
  required String message,
}) => showSrSheet<String>(
  context: context,
  builder: (_) => _ReasonSheet(title: title, message: message),
);

class _ReasonSheet extends StatefulWidget {
  const _ReasonSheet({required this.title, required this.message});

  final String title;
  final String message;

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrSheet(
      title: widget.title,
      subtitle: widget.message,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrTextField(
            controller: _reason,
            label: l10n.salesReason,
            autofocus: true,
            multiline: true,
            maxLength: 200,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          SrButton(
            label: widget.title,
            variant: SrButtonVariant.danger,
            expand: true,
            onPressed: _reason.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(_reason.text.trim()),
          ),
        ],
      ),
    );
  }
}

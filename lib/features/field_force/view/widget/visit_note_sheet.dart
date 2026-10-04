import 'package:flutter/material.dart';

import 'package:salesroot/features/field_force/view/widget/voice_button.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// A note typed or dictated; pops with the text, or null when cancelled.
Future<String?> showVisitNoteSheet(BuildContext context, {String? initial}) =>
    showSrSheet<String>(
      context: context,
      builder: (_) => _VisitNoteSheet(initial: initial),
    );

class _VisitNoteSheet extends StatefulWidget {
  const _VisitNoteSheet({this.initial});

  final String? initial;

  @override
  State<_VisitNoteSheet> createState() => _VisitNoteSheetState();
}

class _VisitNoteSheetState extends State<_VisitNoteSheet> {
  late final _text = TextEditingController(text: widget.initial);
  bool _tried = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    final text = _text.text.trim();
    if (text.isEmpty) {
      setState(() => _tried = true);
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrSheet(
      title: l10n.ffNoteTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrTextField(
            controller: _text,
            hint: l10n.ffNoteHint,
            helper: l10n.ffNoteVoiceHelper,
            error: _tried ? l10n.ffNoteRequired : null,
            multiline: true,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            suffix: FfVoiceButton(controller: _text),
          ),
          const SizedBox(height: 16),
          SrButton(label: l10n.commonSave, expand: true, onPressed: _save),
        ],
      ),
    );
  }
}

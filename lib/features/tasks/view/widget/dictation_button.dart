import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// A mic in a text field: dictation is appended to [controller] in the app's
/// language. [onListening] reports when the mic opens and closes.
class DictationButton extends StatefulWidget {
  const DictationButton({
    super.key,
    required this.controller,
    this.onChanged,
    this.onListening,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<bool>? onListening;

  @override
  State<DictationButton> createState() => _DictationButtonState();
}

class _DictationButtonState extends State<DictationButton> {
  final _speech = SpeechToText();
  bool _listening = false;
  String _before = '';

  @override
  void dispose() {
    if (_listening) _speech.cancel();
    super.dispose();
  }

  void _setListening(bool listening) {
    if (!mounted || listening == _listening) return;
    setState(() => _listening = listening);
    widget.onListening?.call(listening);
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
      _setListening(false);
      return;
    }
    final bangla = context.fmt.isBangla;
    final unavailable = context.l10n.tasksDictateUnavailable;
    var ready = false;
    try {
      ready = await _speech.initialize(
        onStatus: (status) {
          if (status == SpeechToText.doneStatus ||
              status == SpeechToText.notListeningStatus) {
            _setListening(false);
          }
        },
        onError: (_) => _setListening(false),
      );
    } on PlatformException {
      ready = false;
    }
    if (!mounted) return;
    if (!ready) {
      showSrWarning(context, unavailable);
      return;
    }
    _before = widget.controller.text.trim();
    _setListening(true);
    await _speech.listen(
      onResult: _onResult,
      listenOptions: SpeechListenOptions(
        localeId: bangla ? 'bn_BD' : 'en_US',
        listenMode: ListenMode.dictation,
      ),
    );
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    final text = [
      _before,
      result.recognizedWords.trim(),
    ].where((part) => part.isNotEmpty).join(' ');
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.onChanged?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrIconButton(
      icon: _listening ? Icons.stop_circle_outlined : Icons.mic_none_rounded,
      tooltip: _listening ? l10n.tasksDictateStop : l10n.tasksDictate,
      compact: true,
      onTap: _toggle,
    );
  }
}

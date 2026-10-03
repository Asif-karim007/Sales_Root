import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/utils/debug_log.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Speech to text in Bangla or English, shared by the voice lead and the
/// dictation buttons. One listen runs at a time.
class LeadDictation {
  LeadDictation._();

  static final LeadDictation instance = LeadDictation._();

  final SpeechToText _speech = SpeechToText();
  VoidCallback? _onDone;
  VoidCallback? _onError;

  bool get isListening => _speech.isListening;

  /// Starts listening; false when the phone has no recogniser or the
  /// microphone was refused.
  Future<bool> start({
    required bool bangla,
    required ValueChanged<SpeechRecognitionResult> onResult,
    required VoidCallback onDone,
    required VoidCallback onError,
  }) async {
    _onDone = onDone;
    _onError = onError;
    try {
      final ready = await _speech.initialize(
        onError: (error) {
          logDebug('Dictation error: ${error.errorMsg}');
          _onError?.call();
        },
        onStatus: (status) {
          if (status == SpeechToText.doneStatus ||
              status == SpeechToText.notListeningStatus) {
            _onDone?.call();
          }
        },
      );
      if (!ready) return false;
      await _speech.listen(
        onResult: onResult,
        listenOptions: SpeechListenOptions(
          localeId: bangla ? 'bn_BD' : 'en_US',
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
          autoPunctuation: true,
        ),
      );
      return true;
    } on Exception catch (error) {
      logDebug('Dictation unavailable: $error');
      return false;
    }
  }

  Future<void> stop() => _speech.stop();

  Future<void> cancel() async {
    _onDone = null;
    _onError = null;
    await _speech.cancel();
  }
}

/// A mic button that types what is said into [controller]; with [label]
/// it is a full-width secondary button instead of an icon.
class LeadDictateButton extends StatefulWidget {
  const LeadDictateButton({super.key, required this.controller, this.label});

  final TextEditingController controller;
  final String? label;

  @override
  State<LeadDictateButton> createState() => _LeadDictateButtonState();
}

class _LeadDictateButtonState extends State<LeadDictateButton> {
  bool _listening = false;
  String _before = '';

  @override
  void dispose() {
    if (_listening) LeadDictation.instance.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_listening) {
      await LeadDictation.instance.stop();
      return;
    }
    final bangla = Localizations.localeOf(context).languageCode == 'bn';
    final unavailable = context.l10n.leadsDictationUnavailable;
    _before = widget.controller.text.trim();
    setState(() => _listening = true);
    final started = await LeadDictation.instance.start(
      bangla: bangla,
      onResult: _onWords,
      onDone: _finish,
      onError: _finish,
    );
    if (started || !mounted) return;
    _finish();
    showSrError(context, unavailable);
  }

  void _onWords(SpeechRecognitionResult result) {
    if (!mounted) return;
    final words = result.recognizedWords.trim();
    final text = [_before, words].where((t) => t.isNotEmpty).join(' ');
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    if (result.finalResult) _finish();
  }

  void _finish() {
    if (mounted && _listening) setState(() => _listening = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final icon = _listening
        ? Icons.stop_circle_outlined
        : Icons.mic_none_rounded;
    final label = widget.label;
    if (label != null) {
      return SrButton(
        label: _listening ? context.l10n.leadsVoiceListening : label,
        icon: icon,
        variant: SrButtonVariant.secondary,
        expand: true,
        onPressed: _toggle,
      );
    }
    return SrIconButton(
      icon: icon,
      tooltip: context.l10n.leadsDictate,
      compact: true,
      color: _listening ? c.danger : c.accent,
      onTap: _toggle,
    );
  }
}

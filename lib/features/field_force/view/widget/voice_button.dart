import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// A mic that dictates into [controller], after whatever is typed already.
/// Bangla is recognised when the app is in Bangla.
class FfVoiceButton extends StatefulWidget {
  const FfVoiceButton({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<FfVoiceButton> createState() => _FfVoiceButtonState();
}

class _FfVoiceButtonState extends State<FfVoiceButton> {
  final _speech = SpeechToText();
  bool _listening = false;
  String _base = '';

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final unavailable = context.l10n.ffVoiceUnavailable;
    final bangla = Localizations.localeOf(context).languageCode == 'bn';
    final ready = await _speech.initialize(
      onStatus: (status) {
        if (status == SpeechToText.doneStatus ||
            status == SpeechToText.notListeningStatus) {
          if (mounted) setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!mounted) return;
    if (!ready) {
      showSrError(context, unavailable);
      return;
    }
    _base = widget.controller.text.trim();
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        final text = [
          _base,
          result.recognizedWords,
        ].where((part) => part.isNotEmpty).join(' ');
        widget.controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      },
      listenOptions: SpeechListenOptions(
        localeId: bangla ? 'bn_BD' : 'en_US',
        listenFor: const Duration(minutes: 1),
        pauseFor: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return SrIconButton(
      icon: _listening ? Icons.stop_circle_outlined : Icons.mic_none_rounded,
      color: _listening ? c.danger : c.accent,
      tooltip: _listening
          ? context.l10n.ffVoiceStop
          : context.l10n.ffVoiceStart,
      onTap: _toggle,
    );
  }
}

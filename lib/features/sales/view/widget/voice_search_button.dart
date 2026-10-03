import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// A mic in a search field: speaks a product name into [onText], in Bangla
/// or English as the app is set.
class VoiceSearchButton extends StatefulWidget {
  const VoiceSearchButton({super.key, required this.onText});

  final ValueChanged<String> onText;

  @override
  State<VoiceSearchButton> createState() => _VoiceSearchButtonState();
}

class _VoiceSearchButtonState extends State<VoiceSearchButton> {
  final SpeechToText _speech = SpeechToText();
  bool _listening = false;

  @override
  void dispose() {
    if (_listening) _speech.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final l10n = context.l10n;
    final bangla = context.fmt.isBangla;
    final ready = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == SpeechToText.doneStatus ||
            status == SpeechToText.notListeningStatus) {
          setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!mounted) return;
    if (!ready) {
      showSrWarning(context, l10n.salesVoiceUnavailable);
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        widget.onText(result.recognizedWords);
      },
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 3),
        localeId: bangla ? 'bn_BD' : 'en_US',
        listenMode: ListenMode.search,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return SrIconButton(
      icon: _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
      color: _listening ? c.danger : c.accent,
      compact: true,
      tooltip: context.l10n.salesVoiceSearch,
      onTap: _toggle,
    );
  }
}

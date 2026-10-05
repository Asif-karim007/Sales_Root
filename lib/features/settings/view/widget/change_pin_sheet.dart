import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/session/session_store.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/settings/providers/settings_providers.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

enum _Step { current, fresh, confirm }

/// Verifies the current PIN (when there is one), then takes the new one
/// twice. Pops with true once the new PIN is saved.
class ChangePinSheet extends ConsumerStatefulWidget {
  const ChangePinSheet({super.key});

  @override
  ConsumerState<ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends ConsumerState<ChangePinSheet> {
  static const _length = 4;

  _Step? _step;
  String _entry = '';
  String _fresh = '';
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final hasPin = await ref.read(sessionStoreProvider).hasPin();
    if (!mounted) return;
    setState(() => _step = hasPin ? _Step.current : _Step.fresh);
  }

  String get _userId => ref.read(sessionProvider).value?.userId ?? '';

  void _digit(int digit) {
    if (_busy || _entry.length >= _length) return;
    setState(() {
      _entry = '$_entry$digit';
      _error = null;
    });
    if (_entry.length == _length) _submit();
  }

  void _backspace() {
    if (_busy || _entry.isEmpty) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final store = ref.read(sessionStoreProvider);
    final pin = _entry;
    switch (_step) {
      case _Step.current:
        setState(() => _busy = true);
        final ok = await store.checkPin(pin, _userId);
        if (!mounted) return;
        setState(() {
          _busy = false;
          _entry = '';
          if (ok) {
            _step = _Step.fresh;
          } else {
            _error = l10n.settingsPinWrong;
          }
        });
      case _Step.fresh:
        setState(() {
          _fresh = pin;
          _entry = '';
          _step = _Step.confirm;
        });
      case _Step.confirm:
        if (pin != _fresh) {
          setState(() {
            _entry = '';
            _fresh = '';
            _step = _Step.fresh;
            _error = l10n.settingsPinMismatch;
          });
          return;
        }
        setState(() => _busy = true);
        final prefs = ref.read(devicePrefsProvider.notifier);
        await store.writePin(pin, _userId);
        prefs.pinChanged(DateTime.now());
        if (!mounted) return;
        Navigator.of(context).pop(true);
      case null:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final step = _step;
    final error = _error;
    final prompt = switch (step) {
      _Step.current => l10n.settingsPinCurrent,
      _Step.fresh => l10n.settingsPinNew,
      _Step.confirm => l10n.settingsPinConfirm,
      null => '',
    };
    return SrSheet(
      title: l10n.settingsPinChange,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            prompt,
            style: AppText.lead(c.ink2),
            textAlign: TextAlign.center,
          ),
          SrPinDots(filled: _entry.length, error: error != null),
          SizedBox(
            height: 20,
            child: error == null
                ? null
                : Text(error, style: AppText.meta(c.danger)),
          ),
          const SizedBox(height: 8),
          SrKeypad(
            enabled: step != null && !_busy,
            onDigit: _digit,
            onBackspace: _backspace,
          ),
        ],
      ),
    );
  }
}

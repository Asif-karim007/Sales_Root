import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/growth/models/lead_channel.dart';
import 'package:salesroot/features/growth/providers/sources_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The WhatsApp Cloud API number from Meta Business, entered by hand.
class WhatsAppConnectForm extends ConsumerStatefulWidget {
  const WhatsAppConnectForm({super.key});

  @override
  ConsumerState<WhatsAppConnectForm> createState() =>
      _WhatsAppConnectFormState();
}

class _WhatsAppConnectFormState extends ConsumerState<WhatsAppConnectForm> {
  final _phoneNumberId = TextEditingController();
  final _wabaId = TextEditingController();
  final _token = TextEditingController();
  final _displayPhone = TextEditingController();
  bool _busy = false;
  Map<String, String> _errors = const {};

  @override
  void dispose() {
    _phoneNumberId.dispose();
    _wabaId.dispose();
    _token.dispose();
    _displayPhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrTextField(
          controller: _phoneNumberId,
          label: l10n.growthWhatsappPhoneId,
          keyboardType: TextInputType.number,
          error: _errors['phoneNumberId'],
        ),
        const SizedBox(height: 10),
        SrTextField(
          controller: _wabaId,
          label: l10n.growthWhatsappWabaId,
          keyboardType: TextInputType.number,
          error: _errors['wabaId'],
        ),
        const SizedBox(height: 10),
        SrTextField(
          controller: _token,
          label: l10n.growthWhatsappToken,
          obscure: true,
          error: _errors['accessToken'],
        ),
        const SizedBox(height: 10),
        SrTextField(
          controller: _displayPhone,
          label: l10n.growthWhatsappDisplayPhone,
          optional: true,
          keyboardType: TextInputType.phone,
          error: _errors['displayPhone'],
        ),
        const SizedBox(height: 16),
        SrButton(
          label: l10n.growthChannelConnect,
          expand: true,
          loading: _busy,
          onPressed: _connect,
        ),
      ],
    );
  }

  Future<void> _connect() async {
    final l10n = context.l10n;
    final required = {
      'phoneNumberId': _phoneNumberId.text,
      'wabaId': _wabaId.text,
      'accessToken': _token.text,
    };
    final missing = {
      for (final entry in required.entries)
        if (entry.value.trim().isEmpty) entry.key: l10n.commonRequired,
    };
    setState(() => _errors = missing);
    if (missing.isNotEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(channelActionsProvider.notifier)
          .connectWhatsApp(
            WhatsAppConnectInput(
              phoneNumberId: _phoneNumberId.text,
              wabaId: _wabaId.text,
              accessToken: _token.text,
              displayPhone: _displayPhone.text,
            ),
          );
      if (!mounted) return;
      showSrSuccess(context, l10n.growthChannelConnectedDone);
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      if (error is ApiFailure && error.fieldErrors.isNotEmpty) {
        setState(() => _errors = error.fieldErrors);
      } else {
        showSrError(context, growthFailureText(context, error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

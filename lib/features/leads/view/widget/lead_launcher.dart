import 'package:url_launcher/url_launcher.dart';

import 'package:salesroot/core/utils/debug_log.dart';

/// Opens the phone, WhatsApp, SMS and email apps for a lead's contact.
abstract final class LeadLauncher {
  static Future<bool> call(String phone) =>
      _open(Uri(scheme: 'tel', path: _dialable(phone)));

  static Future<bool> sms(String phone) =>
      _open(Uri(scheme: 'sms', path: _dialable(phone)));

  static Future<bool> email(String address) =>
      _open(Uri(scheme: 'mailto', path: address));

  /// wa.me wants the number in international form without the plus.
  static Future<bool> whatsapp(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = '88$digits';
    return _open(Uri.https('wa.me', '/$digits'));
  }

  static String _dialable(String phone) =>
      phone.replaceAll(RegExp(r'[^\d+]'), '');

  static Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception catch (error) {
      logDebug('Could not open $uri: $error');
      return false;
    }
  }
}

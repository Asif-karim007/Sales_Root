import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:salesroot/features/contacts/models/bd_phone.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Opens the dialer, WhatsApp, SMS, mail, maps or the browser, and says so
/// when the phone has nothing that can.
abstract final class ContactLauncher {
  static Future<void> call(BuildContext context, String phone) =>
      _open(context, Uri(scheme: 'tel', path: BdPhone.any(phone) ?? phone));

  static Future<void> sms(BuildContext context, String phone) =>
      _open(context, Uri(scheme: 'sms', path: BdPhone.any(phone) ?? phone));

  static Future<void> whatsApp(BuildContext context, String phone) {
    final number = BdPhone.whatsApp(phone);
    if (number == null) {
      showSrWarning(context, context.l10n.contactsWhatsAppNeedsMobile);
      return Future.value();
    }
    return _open(context, Uri.https('wa.me', '/$number'));
  }

  static Future<void> email(BuildContext context, String address) =>
      _open(context, Uri(scheme: 'mailto', path: address));

  static Future<void> website(BuildContext context, String address) {
    final url = address.startsWith('http') ? address : 'https://$address';
    final uri = Uri.tryParse(url);
    if (uri == null) return Future.value();
    return _open(context, uri);
  }

  /// Google Maps at the pin when there is one, otherwise a search for the
  /// address.
  static Future<void> map(
    BuildContext context, {
    required String label,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    final query = latitude != null && longitude != null
        ? '$latitude,$longitude'
        : [address, label].whereType<String>().join(', ');
    return _open(
      context,
      Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': query,
      }),
    );
  }

  static Future<void> _open(BuildContext context, Uri uri) async {
    final message = context.l10n.contactsCannotOpen;
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
    if (!opened && context.mounted) showSrWarning(context, message);
  }
}

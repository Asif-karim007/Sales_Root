import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Opens [uri] in the app that handles it, or says it couldn't.
Future<void> openExternal(BuildContext context, Uri uri) async {
  final opened = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  ).catchError((Object _) => false);
  if (opened || !context.mounted) return;
  showSrError(context, context.l10n.teamOpenFailed);
}

Uri callUri(String phone) => Uri(scheme: 'tel', path: phone);

Uri smsUri(String phone, String body) =>
    Uri.parse('sms:$phone?body=${Uri.encodeComponent(body)}');

Uri whatsAppUri(String phone, String text) => Uri.parse(
  'https://wa.me/${phone.replaceAll(RegExp(r'\D'), '')}'
  '?text=${Uri.encodeComponent(text)}',
);

Uri mapUri(double lat, double lng) =>
    Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

Future<void> copyText(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  showSrSuccess(context, context.l10n.teamCopied);
}

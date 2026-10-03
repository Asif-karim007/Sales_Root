import 'package:url_launcher/url_launcher.dart';

/// How users reach Nexzen outside the app.
abstract final class SupportLinks {
  static const phone = '09611000000';
  static const whatsApp = '8809611000000';
  static const privacyPolicy = 'https://salesroot.com.bd/privacy';
  static const saleBee = 'https://salebee.net';

  static const company = 'Nexzen Solution Ltd.';
  static const companyInitials = 'NX';
  static const saleBeeName = 'SaleBee CRM';
  static const saleBeeInitials = 'SB';
  static const erpName = 'Nexzen ERP';
  static const erpInitials = 'ER';
  static const salesRootName = 'SalesRoot';
  static const salesRootInitials = 'SR';

  static Uri get call => Uri(scheme: 'tel', path: phone);
  static Uri get chat => Uri.https('wa.me', '/$whatsApp');
}

/// Opens [uri] outside the app; false when nothing could open it.
Future<bool> openExternal(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Exception {
    return false;
  }
}

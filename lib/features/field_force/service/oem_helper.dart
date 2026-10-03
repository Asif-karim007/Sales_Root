import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Phone makers whose battery managers stop background work in their own
/// way; each gets its own settings path on the help screen.
enum PhoneVendor {
  samsung,
  xiaomi,
  oppo,
  realme,
  vivo,
  transsion,
  huawei,
  oneplus,
  iphone,
  other;

  /// These kill a swiped-away app unless auto-start is allowed by hand.
  bool get killsBackgroundApps =>
      this != samsung && this != iphone && this != other;
}

class PhoneInfo {
  const PhoneInfo({required this.vendor, required this.model});

  final PhoneVendor vendor;

  /// "Galaxy A15", "Redmi Note 13", "iPhone 15".
  final String model;
}

/// Picks the battery guide for this phone. Opening the vendor's own
/// auto-start screen needs android_intent_plus, which the app does not use,
/// so every fix opens the app's settings page instead.
class OemHelper {
  const OemHelper();

  static const _aliases = {
    'samsung': PhoneVendor.samsung,
    'redmi': PhoneVendor.xiaomi,
    'poco': PhoneVendor.xiaomi,
    'xiaomi': PhoneVendor.xiaomi,
    'oneplus': PhoneVendor.oneplus,
    'oppo': PhoneVendor.oppo,
    'realme': PhoneVendor.realme,
    'vivo': PhoneVendor.vivo,
    'iqoo': PhoneVendor.vivo,
    'tecno': PhoneVendor.transsion,
    'infinix': PhoneVendor.transsion,
    'itel': PhoneVendor.transsion,
    'huawei': PhoneVendor.huawei,
    'honor': PhoneVendor.huawei,
  };

  Future<PhoneInfo> phone() async {
    final plugin = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      return PhoneInfo(vendor: PhoneVendor.iphone, model: info.modelName);
    }
    if (!Platform.isAndroid) {
      return const PhoneInfo(vendor: PhoneVendor.other, model: '');
    }
    final info = await plugin.androidInfo;
    final brand = info.brand.toLowerCase();
    final maker = info.manufacturer.toLowerCase();
    var vendor = PhoneVendor.other;
    for (final entry in _aliases.entries) {
      if (brand.contains(entry.key) || maker.contains(entry.key)) {
        vendor = entry.value;
        break;
      }
    }
    final label = info.brand.isEmpty
        ? info.model
        : '${info.brand[0].toUpperCase()}${info.brand.substring(1)} '
              '${info.model}';
    return PhoneInfo(
      vendor: vendor,
      model: info.name.isNotEmpty ? info.name : label,
    );
  }
}

/// Bangladeshi phone numbers as people type them: `01711-234567`,
/// `+880 1711 234567` or a landline like `02-55012345`.
abstract final class BdPhone {
  static final _mobile = RegExp(r'^(?:\+?880|0)?(1[3-9]\d{8})$');
  static final _landline = RegExp(r'^0[2-9]\d{6,9}$');

  static String _compact(String raw) =>
      raw.replaceAll(RegExp(r'[\s\-().]'), '');

  /// `+8801711234567` for a valid mobile number, otherwise null.
  static String? mobile(String raw) {
    final match = _mobile.firstMatch(_compact(raw));
    final local = match?.group(1);
    return local == null ? null : '+880$local';
  }

  /// A mobile in `+880` form, or a landline as its digits; null when neither.
  static String? any(String raw) {
    final mobile = BdPhone.mobile(raw);
    if (mobile != null) return mobile;
    final compact = _compact(raw);
    return _landline.hasMatch(compact) ? compact : null;
  }

  /// The digits two numbers are compared by: the last ten.
  static String key(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length <= 10 ? digits : digits.substring(digits.length - 10);
  }

  /// `01711 234 567` for a mobile; anything else as stored.
  static String display(String raw) {
    final mobile = BdPhone.mobile(raw);
    if (mobile == null) return raw;
    final local = '0${mobile.substring(4)}';
    return '${local.substring(0, 5)} ${local.substring(5, 8)} '
        '${local.substring(8)}';
  }

  /// The number in international digits for `wa.me`, or null when it is
  /// not a mobile.
  static String? whatsApp(String raw) => mobile(raw)?.substring(1);
}

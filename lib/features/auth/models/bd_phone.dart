/// Bangladeshi mobile numbers, typed as the ten digits after +880.
abstract final class BdPhone {
  static const countryCode = '+880';

  static final _valid = RegExp(r'^1[3-9]\d{8}$');

  /// The digits after +880, dropping a typed `880` or leading `0`.
  static String local(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('880')) digits = digits.substring(3);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits;
  }

  /// How many digits the keypad accepts: one more when typed with the 0.
  static int maxDigits(String typed) => typed.startsWith('0') ? 11 : 10;

  static bool isValid(String input) => _valid.hasMatch(local(input));

  static String e164(String input) => '$countryCode${local(input)}';

  /// `1711234567` → `1711 234 567`.
  static String group(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 4 || i == 7) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// `+8801711234567` → `+880 1711 234 567`.
  static String display(String number) =>
      '$countryCode ${group(local(number))}';
}

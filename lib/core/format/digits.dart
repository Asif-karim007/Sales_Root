const _bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

/// Swaps Latin digits for Bangla ones when [bangla] is true.
String localizeDigits(String text, {required bool bangla}) {
  if (!bangla) return text;
  final out = StringBuffer();
  for (final unit in text.codeUnits) {
    final digit = unit - 0x30;
    out.write(
      digit >= 0 && digit <= 9 ? _bangla[digit] : String.fromCharCode(unit),
    );
  }
  return out.toString();
}

/// Groups an integer the South Asian way: 12,34,567.
String groupIndian(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  if (digits.length <= 3) return negative ? '-$digits' : digits;
  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  final grouped = '${groups.join(',')},$last3';
  return negative ? '-$grouped' : grouped;
}

enum SmsEncoding { gsm7, ucs2 }

/// How a message splits into billable SMS segments. GSM-7 fits 160
/// characters in one SMS and 153 per part after that; anything outside GSM-7
/// (Bangla included) is sent as UCS-2: 70 in one SMS, 67 per part.
class SmsCount {
  const SmsCount({
    required this.encoding,
    required this.length,
    required this.segments,
  });

  factory SmsCount.of(String text) {
    var gsmLength = 0;
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      if (_gsmBasic.contains(char)) {
        gsmLength += 1;
      } else if (_gsmExtension.contains(char)) {
        gsmLength += 2;
      } else {
        final units = text.length;
        return SmsCount(
          encoding: SmsEncoding.ucs2,
          length: units,
          segments: _segments(units, single: 70, multi: 67),
        );
      }
    }
    return SmsCount(
      encoding: SmsEncoding.gsm7,
      length: gsmLength,
      segments: _segments(gsmLength, single: 160, multi: 153),
    );
  }

  final SmsEncoding encoding;

  /// Characters as the network counts them: GSM extension characters take
  /// two, UCS-2 counts UTF-16 units.
  final int length;
  final int segments;

  bool get isUnicode => encoding == SmsEncoding.ucs2;

  int get singleLimit => isUnicode ? 70 : 160;

  int get partLimit => isUnicode ? 67 : 153;

  /// Characters that fit in the segments used so far.
  int get capacity => segments <= 1 ? singleLimit : segments * partLimit;

  static int _segments(int length, {required int single, required int multi}) {
    if (length == 0) return 0;
    if (length <= single) return 1;
    return (length + multi - 1) ~/ multi;
  }

  static const _gsmBasic =
      '@£\$¥èéùìòÇ\nØø\rÅåΔ_ΦΓΛΩΠΨΣΘΞÆæßÉ !"#¤%&\'()*+,-./0123456789:;<=>?'
      '¡ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÑÜ§¿abcdefghijklmnopqrstuvwxyzäöñüà';

  static const _gsmExtension = '^{}\\[~]|€\f';
}

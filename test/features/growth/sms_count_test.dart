import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/features/growth/models/sms_count.dart';

void main() {
  test('an empty message costs nothing', () {
    final count = SmsCount.of('');
    expect(count.segments, 0);
    expect(count.encoding, SmsEncoding.gsm7);
  });

  test('English uses GSM-7: 160 in one SMS, then 153 per part', () {
    expect(SmsCount.of('a' * 160).segments, 1);
    expect(SmsCount.of('a' * 161).segments, 2);
    expect(SmsCount.of('a' * 306).segments, 2);
    expect(SmsCount.of('a' * 307).segments, 3);
    expect(SmsCount.of('a' * 161).capacity, 306);
  });

  test('GSM extension characters count twice', () {
    final braces = SmsCount.of('{' * 80);
    expect(braces.length, 160);
    expect(braces.segments, 1);
    expect(SmsCount.of('€' * 81).segments, 2);
  });

  test('Bangla is UCS-2: 70 in one SMS, then 67 per part', () {
    expect(SmsCount.of('ক' * 70).segments, 1);
    expect(SmsCount.of('ক' * 71).segments, 2);
    expect(SmsCount.of('ক' * 134).segments, 2);
    expect(SmsCount.of('ক' * 135).segments, 3);
    final count = SmsCount.of('ধন্যবাদ');
    expect(count.isUnicode, isTrue);
    expect(count.singleLimit, 70);
  });

  test('one Bangla letter turns a long English message into UCS-2', () {
    final english = 'Dear customer, your bill is due. ' * 3;
    expect(SmsCount.of(english).segments, 1);
    final mixed = SmsCount.of('$englishধন্যবাদ');
    expect(mixed.encoding, SmsEncoding.ucs2);
    expect(mixed.segments, 2);
  });
}

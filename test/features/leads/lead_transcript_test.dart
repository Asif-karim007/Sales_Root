import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/features/leads/models/lead_activity.dart';
import 'package:salesroot/features/leads/models/lead_transcript.dart';

void main() {
  final now = DateTime(2026, 10, 4, 15, 30);

  test('reads the English example from the prototype', () {
    final heard = LeadTranscript.parse(
      'New lead Rahim Enterprise, number 01912345678, interested in solar, '
      'follow up tomorrow',
      now: now,
    );
    expect(heard.name, 'Rahim Enterprise');
    expect(heard.company, 'Rahim Enterprise');
    expect(heard.phone, '01912345678');
    expect(heard.interests, ['Solar']);
    expect(heard.followUp?.kind, LeadActivityKind.call);
    expect(heard.followUp?.at, DateTime(2026, 10, 5, 10));
  });

  test('reads Bangla with Bangla digits and no punctuation', () {
    final heard = LeadTranscript.parse(
      'নতুন লিড রাহিম এন্টারপ্রাইজ নম্বর ০১৯১২ ৩৪৫ ৬৭৮ সোলারে আগ্রহী কাল ফলো-আপ',
      now: now,
    );
    expect(heard.name, 'রাহিম এন্টারপ্রাইজ');
    expect(heard.company, 'রাহিম এন্টারপ্রাইজ');
    expect(heard.phone, '01912345678');
    expect(heard.interests, ['Solar']);
    expect(heard.followUp?.at, DateTime(2026, 10, 5, 10));
  });

  test('splits a person from their company and reads a visit time', () {
    final heard = LeadTranscript.parse(
      'new lead karim from delta power phone +880 1711 234567 '
      'wants inverter and battery visit on sunday at 3 pm',
      now: now,
    );
    expect(heard.name, 'Karim');
    expect(heard.company, 'Delta Power');
    expect(heard.phone, '01711234567');
    expect(heard.interests, containsAll(['Inverter', 'Battery']));
    expect(heard.followUp?.kind, LeadActivityKind.visit);
    expect(heard.followUp?.at, DateTime(2026, 10, 11, 15));
  });

  test('leaves the follow-up empty when none is said', () {
    final heard = LeadTranscript.parse('Lead Meghna Group', now: now);
    expect(heard.name, 'Meghna Group');
    expect(heard.phone, isNull);
    expect(heard.followUp, isNull);
  });
}

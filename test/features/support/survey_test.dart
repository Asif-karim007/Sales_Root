import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/features/support/providers/support_form_providers.dart';

import 'support_test_container.dart';

void main() {
  test('the survey is asked at most once every 14 days', () async {
    final container = await supportContainer();
    addTearDown(container.dispose);
    final gate = container.read(surveyGateProvider.notifier);
    final start = DateTime(2026, 10, 4, 10);

    expect(gate.tryAsk(now: start), isTrue);
    expect(gate.tryAsk(now: start.add(const Duration(hours: 1))), isFalse);
    expect(gate.tryAsk(now: start.add(const Duration(days: 13))), isFalse);
    expect(gate.tryAsk(now: start.add(const Duration(days: 14))), isTrue);
  });

  test('the limit survives a restart', () async {
    final first = await supportContainer();
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day - 2, 10);
    first.read(surveyGateProvider.notifier).tryAsk(now: start);
    first.dispose();

    final prefs = await SharedPreferences.getInstance();
    final restarted = await supportContainer(prefs: prefs);
    addTearDown(restarted.dispose);
    expect(restarted.read(surveyGateProvider), start);
    expect(restarted.read(surveyGateProvider.notifier).tryAsk(), isFalse);
  });
}

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/growth/data/distribution_repository.dart';
import 'package:salesroot/features/growth/data/fake_distribution_repository.dart';
import 'package:salesroot/features/growth/models/distribution_rule.dart';

part 'distribution_providers.g.dart';

@Riverpod(keepAlive: true)
DistributionRepository distributionRepository(Ref ref) =>
    FakeDistributionRepository(ref.watch(fakeBackendProvider));

/// The rules screen (#139). Switches flip at once and roll back if the
/// server refuses.
@riverpod
class DistributionNotifier extends _$DistributionNotifier {
  @override
  Future<DistributionSettings> build() =>
      ref.watch(distributionRepositoryProvider).settings();

  Future<void> setEnabled(bool enabled) async {
    final before = state.value;
    if (before == null) return;
    state = AsyncData(
      DistributionSettings(enabled: enabled, rules: before.rules),
    );
    try {
      await ref.read(distributionRepositoryProvider).setEnabled(enabled);
      if (ref.mounted) ref.invalidate(ruleTestProvider);
    } catch (_) {
      if (ref.mounted) state = AsyncData(before);
      rethrow;
    }
  }

  Future<void> setRuleEnabled(String id, bool enabled) async {
    final before = state.value;
    if (before == null) return;
    state = AsyncData(
      DistributionSettings(
        enabled: before.enabled,
        rules: [
          for (final rule in before.rules)
            rule.id == id ? rule.withEnabled(enabled) : rule,
        ],
      ),
    );
    try {
      await ref
          .read(distributionRepositoryProvider)
          .setRuleEnabled(id, enabled);
      if (ref.mounted) {
        ref
          ..invalidate(ruleTestProvider)
          ..invalidate(distributionRuleProvider(id));
      }
    } catch (_) {
      if (ref.mounted) state = AsyncData(before);
      rethrow;
    }
  }

  Future<void> refresh() async {
    ref
      ..invalidateSelf()
      ..invalidate(ruleTestProvider);
    await future;
  }
}

@riverpod
Future<RuleTestResult> ruleTest(Ref ref) =>
    ref.watch(distributionRepositoryProvider).test();

/// A rule to edit; [newRuleId] starts a new one.
@riverpod
Future<DistributionRule?> distributionRule(Ref ref, String id) async {
  if (id == newRuleId) return null;
  return ref.watch(distributionRepositoryProvider).rule(id);
}

@riverpod
Future<List<GrowthMember>> ruleMembers(Ref ref) =>
    ref.watch(distributionRepositoryProvider).members();

@riverpod
Future<List<String>> ruleForms(Ref ref) =>
    ref.watch(distributionRepositoryProvider).forms();

@riverpod
Future<List<LocalizedName>> ruleAreas(Ref ref) =>
    ref.watch(distributionRepositoryProvider).areas();

/// The route id that opens the rule editor on a new rule.
const newRuleId = 'new';

enum RuleOutcome { saved, deleted }

/// Saving or deleting one rule (#140).
@riverpod
class RuleSubmit extends _$RuleSubmit {
  @override
  AsyncValue<RuleOutcome?> build(String id) => const AsyncData(null);

  Future<void> save(RuleInput input) => _run(() async {
    final repository = ref.read(distributionRepositoryProvider);
    id == newRuleId
        ? await repository.create(input)
        : await repository.save(id, input);
    return RuleOutcome.saved;
  });

  Future<void> delete() => _run(() async {
    await ref.read(distributionRepositoryProvider).delete(id);
    return RuleOutcome.deleted;
  });

  Future<void> _run(Future<RuleOutcome> Function() work) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(work);
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) {
      ref
        ..invalidate(distributionProvider)
        ..invalidate(ruleTestProvider);
      if (id != newRuleId) ref.invalidate(distributionRuleProvider(id));
    }
  }
}

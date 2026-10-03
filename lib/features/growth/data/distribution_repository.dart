import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/growth/models/distribution_rule.dart';

/// The rules that share new leads out to the team.
abstract interface class DistributionRepository {
  Future<DistributionSettings> settings();

  Future<void> setEnabled(bool enabled);

  Future<DistributionRule> rule(int id);

  Future<DistributionRule> create(RuleInput input);

  Future<DistributionRule> save(int id, RuleInput input);

  Future<void> setRuleEnabled(int id, bool enabled);

  Future<void> delete(int id);

  /// Replays the last [last] leads through the current rules.
  Future<RuleTestResult> test({int last = 50});

  /// Lead form and campaign names a rule can match.
  Future<List<String>> forms();

  /// Areas a rule can match, by their English name.
  Future<List<LocalizedName>> areas();
}

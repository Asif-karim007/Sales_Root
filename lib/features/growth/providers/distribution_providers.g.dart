// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'distribution_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(distributionRepository)
final distributionRepositoryProvider = DistributionRepositoryProvider._();

final class DistributionRepositoryProvider
    extends
        $FunctionalProvider<
          DistributionRepository,
          DistributionRepository,
          DistributionRepository
        >
    with $Provider<DistributionRepository> {
  DistributionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'distributionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$distributionRepositoryHash();

  @$internal
  @override
  $ProviderElement<DistributionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DistributionRepository create(Ref ref) {
    return distributionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DistributionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DistributionRepository>(value),
    );
  }
}

String _$distributionRepositoryHash() =>
    r'3e2279ec096d64213c1c69404953a2a8a0ae6e6e';

/// The rules screen (#139). Switches flip at once and roll back if the
/// server refuses.

@ProviderFor(DistributionNotifier)
final distributionProvider = DistributionNotifierProvider._();

/// The rules screen (#139). Switches flip at once and roll back if the
/// server refuses.
final class DistributionNotifierProvider
    extends $AsyncNotifierProvider<DistributionNotifier, DistributionSettings> {
  /// The rules screen (#139). Switches flip at once and roll back if the
  /// server refuses.
  DistributionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'distributionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$distributionNotifierHash();

  @$internal
  @override
  DistributionNotifier create() => DistributionNotifier();
}

String _$distributionNotifierHash() =>
    r'ac78997cfd272523bbb3cf0c967be1827ad511d4';

/// The rules screen (#139). Switches flip at once and roll back if the
/// server refuses.

abstract class _$DistributionNotifier
    extends $AsyncNotifier<DistributionSettings> {
  FutureOr<DistributionSettings> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<DistributionSettings>, DistributionSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<DistributionSettings>,
                DistributionSettings
              >,
              AsyncValue<DistributionSettings>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(ruleTest)
final ruleTestProvider = RuleTestProvider._();

final class RuleTestProvider
    extends
        $FunctionalProvider<
          AsyncValue<RuleTestResult>,
          RuleTestResult,
          FutureOr<RuleTestResult>
        >
    with $FutureModifier<RuleTestResult>, $FutureProvider<RuleTestResult> {
  RuleTestProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ruleTestProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ruleTestHash();

  @$internal
  @override
  $FutureProviderElement<RuleTestResult> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RuleTestResult> create(Ref ref) {
    return ruleTest(ref);
  }
}

String _$ruleTestHash() => r'dc45862bbe1a1f240985f4895ad39d71913d53ac';

/// A rule to edit; [newRuleId] starts a new one.

@ProviderFor(distributionRule)
final distributionRuleProvider = DistributionRuleFamily._();

/// A rule to edit; [newRuleId] starts a new one.

final class DistributionRuleProvider
    extends
        $FunctionalProvider<
          AsyncValue<DistributionRule?>,
          DistributionRule?,
          FutureOr<DistributionRule?>
        >
    with
        $FutureModifier<DistributionRule?>,
        $FutureProvider<DistributionRule?> {
  /// A rule to edit; [newRuleId] starts a new one.
  DistributionRuleProvider._({
    required DistributionRuleFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'distributionRuleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$distributionRuleHash();

  @override
  String toString() {
    return r'distributionRuleProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DistributionRule?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DistributionRule?> create(Ref ref) {
    final argument = this.argument as String;
    return distributionRule(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DistributionRuleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$distributionRuleHash() => r'e451f8d9e2082d1a54601567465b467c10a227a4';

/// A rule to edit; [newRuleId] starts a new one.

final class DistributionRuleFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DistributionRule?>, String> {
  DistributionRuleFamily._()
    : super(
        retry: null,
        name: r'distributionRuleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A rule to edit; [newRuleId] starts a new one.

  DistributionRuleProvider call(String id) =>
      DistributionRuleProvider._(argument: id, from: this);

  @override
  String toString() => r'distributionRuleProvider';
}

@ProviderFor(ruleMembers)
final ruleMembersProvider = RuleMembersProvider._();

final class RuleMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GrowthMember>>,
          List<GrowthMember>,
          FutureOr<List<GrowthMember>>
        >
    with
        $FutureModifier<List<GrowthMember>>,
        $FutureProvider<List<GrowthMember>> {
  RuleMembersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ruleMembersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ruleMembersHash();

  @$internal
  @override
  $FutureProviderElement<List<GrowthMember>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GrowthMember>> create(Ref ref) {
    return ruleMembers(ref);
  }
}

String _$ruleMembersHash() => r'ef21d0ed78bce6abf2b8f695a2b14e19e2eee20a';

@ProviderFor(ruleForms)
final ruleFormsProvider = RuleFormsProvider._();

final class RuleFormsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  RuleFormsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ruleFormsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ruleFormsHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return ruleForms(ref);
  }
}

String _$ruleFormsHash() => r'b9eed12ea1dc2b269d1a6e56917ea468e779f342';

@ProviderFor(ruleAreas)
final ruleAreasProvider = RuleAreasProvider._();

final class RuleAreasProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LocalizedName>>,
          List<LocalizedName>,
          FutureOr<List<LocalizedName>>
        >
    with
        $FutureModifier<List<LocalizedName>>,
        $FutureProvider<List<LocalizedName>> {
  RuleAreasProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ruleAreasProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ruleAreasHash();

  @$internal
  @override
  $FutureProviderElement<List<LocalizedName>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LocalizedName>> create(Ref ref) {
    return ruleAreas(ref);
  }
}

String _$ruleAreasHash() => r'fdbf6eeb77bd7c7bf68aeec3dda2d1d965e1b42d';

/// Saving or deleting one rule (#140).

@ProviderFor(RuleSubmit)
final ruleSubmitProvider = RuleSubmitFamily._();

/// Saving or deleting one rule (#140).
final class RuleSubmitProvider
    extends $NotifierProvider<RuleSubmit, AsyncValue<RuleOutcome?>> {
  /// Saving or deleting one rule (#140).
  RuleSubmitProvider._({
    required RuleSubmitFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ruleSubmitProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ruleSubmitHash();

  @override
  String toString() {
    return r'ruleSubmitProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RuleSubmit create() => RuleSubmit();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<RuleOutcome?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<RuleOutcome?>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RuleSubmitProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ruleSubmitHash() => r'e457447b78d9eb9b7974070e347818312658a307';

/// Saving or deleting one rule (#140).

final class RuleSubmitFamily extends $Family
    with
        $ClassFamilyOverride<
          RuleSubmit,
          AsyncValue<RuleOutcome?>,
          AsyncValue<RuleOutcome?>,
          AsyncValue<RuleOutcome?>,
          String
        > {
  RuleSubmitFamily._()
    : super(
        retry: null,
        name: r'ruleSubmitProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Saving or deleting one rule (#140).

  RuleSubmitProvider call(String id) =>
      RuleSubmitProvider._(argument: id, from: this);

  @override
  String toString() => r'ruleSubmitProvider';
}

/// Saving or deleting one rule (#140).

abstract class _$RuleSubmit extends $Notifier<AsyncValue<RuleOutcome?>> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  AsyncValue<RuleOutcome?> build(String id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<RuleOutcome?>, AsyncValue<RuleOutcome?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<RuleOutcome?>, AsyncValue<RuleOutcome?>>,
              AsyncValue<RuleOutcome?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

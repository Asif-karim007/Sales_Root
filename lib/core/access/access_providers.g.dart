// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'access_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(accessRepository)
final accessRepositoryProvider = AccessRepositoryProvider._();

final class AccessRepositoryProvider
    extends
        $FunctionalProvider<
          AccessRepository,
          AccessRepository,
          AccessRepository
        >
    with $Provider<AccessRepository> {
  AccessRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accessRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accessRepositoryHash();

  @$internal
  @override
  $ProviderElement<AccessRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AccessRepository create(Ref ref) {
    return accessRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccessRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccessRepository>(value),
    );
  }
}

String _$accessRepositoryHash() => r'dabdf4719981633a6eee29032a156b59ec98fb39';

/// The role's grants in the current workspace, cached for offline starts.

@ProviderFor(PermissionsNotifier)
final permissionsProvider = PermissionsNotifierProvider._();

/// The role's grants in the current workspace, cached for offline starts.
final class PermissionsNotifierProvider
    extends
        $AsyncNotifierProvider<
          PermissionsNotifier,
          Map<AppModule, ModulePermission>
        > {
  /// The role's grants in the current workspace, cached for offline starts.
  PermissionsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'permissionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$permissionsNotifierHash();

  @$internal
  @override
  PermissionsNotifier create() => PermissionsNotifier();
}

String _$permissionsNotifierHash() =>
    r'719262cf78352b761a827be54a2a22a50fab4437';

/// The role's grants in the current workspace, cached for offline starts.

abstract class _$PermissionsNotifier
    extends $AsyncNotifier<Map<AppModule, ModulePermission>> {
  FutureOr<Map<AppModule, ModulePermission>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<AppModule, ModulePermission>>,
              Map<AppModule, ModulePermission>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<AppModule, ModulePermission>>,
                Map<AppModule, ModulePermission>
              >,
              AsyncValue<Map<AppModule, ModulePermission>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(PlanNotifier)
final planProvider = PlanNotifierProvider._();

final class PlanNotifierProvider
    extends $AsyncNotifierProvider<PlanNotifier, Plan?> {
  PlanNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planNotifierHash();

  @$internal
  @override
  PlanNotifier create() => PlanNotifier();
}

String _$planNotifierHash() => r'ebb5f08f64830395717c3907a31ac6af4fa5523f';

abstract class _$PlanNotifier extends $AsyncNotifier<Plan?> {
  FutureOr<Plan?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Plan?>, Plan?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Plan?>, Plan?>,
              AsyncValue<Plan?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(ExperienceLevelNotifier)
final experienceLevelProvider = ExperienceLevelNotifierProvider._();

final class ExperienceLevelNotifierProvider
    extends $NotifierProvider<ExperienceLevelNotifier, ExperienceLevel> {
  ExperienceLevelNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'experienceLevelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$experienceLevelNotifierHash();

  @$internal
  @override
  ExperienceLevelNotifier create() => ExperienceLevelNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExperienceLevel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExperienceLevel>(value),
    );
  }
}

String _$experienceLevelNotifierHash() =>
    r'dd4665ef43c9dd7dd070effd50ebf04d88529064';

abstract class _$ExperienceLevelNotifier extends $Notifier<ExperienceLevel> {
  ExperienceLevel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ExperienceLevel, ExperienceLevel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExperienceLevel, ExperienceLevel>,
              ExperienceLevel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(experienceLevelLocked)
final experienceLevelLockedProvider = ExperienceLevelLockedProvider._();

final class ExperienceLevelLockedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  ExperienceLevelLockedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'experienceLevelLockedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$experienceLevelLockedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return experienceLevelLocked(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$experienceLevelLockedHash() =>
    r'66fd2aee0a2fabdccb8a7550fb052fc054f46d45';

/// What the user may do in [module]: role grants, narrowed by the plan's
/// add-ons and the experience level.

@ProviderFor(moduleAccess)
final moduleAccessProvider = ModuleAccessFamily._();

/// What the user may do in [module]: role grants, narrowed by the plan's
/// add-ons and the experience level.

final class ModuleAccessProvider
    extends $FunctionalProvider<ModuleAccess, ModuleAccess, ModuleAccess>
    with $Provider<ModuleAccess> {
  /// What the user may do in [module]: role grants, narrowed by the plan's
  /// add-ons and the experience level.
  ModuleAccessProvider._({
    required ModuleAccessFamily super.from,
    required AppModule super.argument,
  }) : super(
         retry: null,
         name: r'moduleAccessProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$moduleAccessHash();

  @override
  String toString() {
    return r'moduleAccessProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ModuleAccess> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ModuleAccess create(Ref ref) {
    final argument = this.argument as AppModule;
    return moduleAccess(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ModuleAccess value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ModuleAccess>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ModuleAccessProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$moduleAccessHash() => r'7a8842ed26cabc02177fc00ec6efc63c79c16ee9';

/// What the user may do in [module]: role grants, narrowed by the plan's
/// add-ons and the experience level.

final class ModuleAccessFamily extends $Family
    with $FunctionalFamilyOverride<ModuleAccess, AppModule> {
  ModuleAccessFamily._()
    : super(
        retry: null,
        name: r'moduleAccessProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// What the user may do in [module]: role grants, narrowed by the plan's
  /// add-ons and the experience level.

  ModuleAccessProvider call(AppModule module) =>
      ModuleAccessProvider._(argument: module, from: this);

  @override
  String toString() => r'moduleAccessProvider';
}

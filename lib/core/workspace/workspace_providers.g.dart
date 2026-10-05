// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceApi)
final workspaceApiProvider = WorkspaceApiProvider._();

final class WorkspaceApiProvider
    extends $FunctionalProvider<WorkspaceApi, WorkspaceApi, WorkspaceApi>
    with $Provider<WorkspaceApi> {
  WorkspaceApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workspaceApiHash();

  @$internal
  @override
  $ProviderElement<WorkspaceApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WorkspaceApi create(Ref ref) {
    return workspaceApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceApi>(value),
    );
  }
}

String _$workspaceApiHash() => r'204266a8cd94f6ac4d2405b598592028dfef9895';

@ProviderFor(workspaceRepository)
final workspaceRepositoryProvider = WorkspaceRepositoryProvider._();

final class WorkspaceRepositoryProvider
    extends
        $FunctionalProvider<
          WorkspaceRepository,
          WorkspaceRepository,
          WorkspaceRepository
        >
    with $Provider<WorkspaceRepository> {
  WorkspaceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workspaceRepositoryHash();

  @$internal
  @override
  $ProviderElement<WorkspaceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkspaceRepository create(Ref ref) {
    return workspaceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceRepository>(value),
    );
  }
}

String _$workspaceRepositoryHash() =>
    r'09d553e0bd1fa4d8017931f502b20150ae98770e';

/// The user's workspaces. Cached so a cold start offline still opens.

@ProviderFor(WorkspacesNotifier)
final workspacesProvider = WorkspacesNotifierProvider._();

/// The user's workspaces. Cached so a cold start offline still opens.
final class WorkspacesNotifierProvider
    extends $AsyncNotifierProvider<WorkspacesNotifier, List<Workspace>> {
  /// The user's workspaces. Cached so a cold start offline still opens.
  WorkspacesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspacesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workspacesNotifierHash();

  @$internal
  @override
  WorkspacesNotifier create() => WorkspacesNotifier();
}

String _$workspacesNotifierHash() =>
    r'326979afbe8e6bbc6600bede9d12c3cd0212d773';

/// The user's workspaces. Cached so a cold start offline still opens.

abstract class _$WorkspacesNotifier extends $AsyncNotifier<List<Workspace>> {
  FutureOr<List<Workspace>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Workspace>>, List<Workspace>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Workspace>>, List<Workspace>>,
              AsyncValue<List<Workspace>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The workspace the session token is scoped to.

@ProviderFor(CurrentWorkspaceNotifier)
final currentWorkspaceProvider = CurrentWorkspaceNotifierProvider._();

/// The workspace the session token is scoped to.
final class CurrentWorkspaceNotifierProvider
    extends $NotifierProvider<CurrentWorkspaceNotifier, Workspace?> {
  /// The workspace the session token is scoped to.
  CurrentWorkspaceNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentWorkspaceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentWorkspaceNotifierHash();

  @$internal
  @override
  CurrentWorkspaceNotifier create() => CurrentWorkspaceNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Workspace? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Workspace?>(value),
    );
  }
}

String _$currentWorkspaceNotifierHash() =>
    r'505bb3c1ea90554ff9984a2d6754260291022931';

/// The workspace the session token is scoped to.

abstract class _$CurrentWorkspaceNotifier extends $Notifier<Workspace?> {
  Workspace? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Workspace?, Workspace?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Workspace?, Workspace?>,
              Workspace?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(currentRole)
final currentRoleProvider = CurrentRoleProvider._();

final class CurrentRoleProvider
    extends $FunctionalProvider<WorkspaceRole, WorkspaceRole, WorkspaceRole>
    with $Provider<WorkspaceRole> {
  CurrentRoleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentRoleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentRoleHash();

  @$internal
  @override
  $ProviderElement<WorkspaceRole> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WorkspaceRole create(Ref ref) {
    return currentRole(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceRole value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceRole>(value),
    );
  }
}

String _$currentRoleHash() => r'05c0ea5217dddfa9e5e2d0cbde63aa5785d66b35';

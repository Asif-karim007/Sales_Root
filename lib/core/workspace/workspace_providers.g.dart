// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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
    r'c5c0f81851b2c17eaf7df9d87678a0ebe6d1d1de';

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
    r'0ee7b6200bfdf1125d1cad3f7d5af4b8d9d037ee';

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

@ProviderFor(CurrentWorkspaceNotifier)
final currentWorkspaceProvider = CurrentWorkspaceNotifierProvider._();

final class CurrentWorkspaceNotifierProvider
    extends $NotifierProvider<CurrentWorkspaceNotifier, Workspace?> {
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
    r'bef2653e3753706b3aa5bf60f805f1998f2fb31b';

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

/// The role in the current workspace, after any dev-menu override.

@ProviderFor(currentRole)
final currentRoleProvider = CurrentRoleProvider._();

/// The role in the current workspace, after any dev-menu override.

final class CurrentRoleProvider
    extends $FunctionalProvider<WorkspaceRole, WorkspaceRole, WorkspaceRole>
    with $Provider<WorkspaceRole> {
  /// The role in the current workspace, after any dev-menu override.
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

String _$currentRoleHash() => r'1550e199156771222a8b03109efb15e4f68c92df';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(teamRepository)
final teamRepositoryProvider = TeamRepositoryProvider._();

final class TeamRepositoryProvider
    extends $FunctionalProvider<TeamRepository, TeamRepository, TeamRepository>
    with $Provider<TeamRepository> {
  TeamRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamRepositoryHash();

  @$internal
  @override
  $ProviderElement<TeamRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TeamRepository create(Ref ref) {
    return teamRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamRepository>(value),
    );
  }
}

String _$teamRepositoryHash() => r'fa0f3a3d3c455c51c126b2ca81c62f662ed749ea';

@ProviderFor(MemberFilterNotifier)
final memberFilterProvider = MemberFilterNotifierProvider._();

final class MemberFilterNotifierProvider
    extends $NotifierProvider<MemberFilterNotifier, MemberFilter> {
  MemberFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memberFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memberFilterNotifierHash();

  @$internal
  @override
  MemberFilterNotifier create() => MemberFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemberFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemberFilter>(value),
    );
  }
}

String _$memberFilterNotifierHash() =>
    r'205fa4b61a378bcf928ea24185c7fc78c9e5395a';

abstract class _$MemberFilterNotifier extends $Notifier<MemberFilter> {
  MemberFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MemberFilter, MemberFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MemberFilter, MemberFilter>,
              MemberFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(MemberListNotifier)
final memberListProvider = MemberListNotifierProvider._();

final class MemberListNotifierProvider
    extends $AsyncNotifierProvider<MemberListNotifier, Paged<Member>> {
  MemberListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memberListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memberListNotifierHash();

  @$internal
  @override
  MemberListNotifier create() => MemberListNotifier();
}

String _$memberListNotifierHash() =>
    r'1f651cd05936d540a8c9d1b11577d38c3bdc2de9';

abstract class _$MemberListNotifier extends $AsyncNotifier<Paged<Member>> {
  FutureOr<Paged<Member>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Paged<Member>>, Paged<Member>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<Member>>, Paged<Member>>,
              AsyncValue<Paged<Member>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(pendingInvites)
final pendingInvitesProvider = PendingInvitesProvider._();

final class PendingInvitesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Invite>>,
          List<Invite>,
          FutureOr<List<Invite>>
        >
    with $FutureModifier<List<Invite>>, $FutureProvider<List<Invite>> {
  PendingInvitesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingInvitesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingInvitesHash();

  @$internal
  @override
  $FutureProviderElement<List<Invite>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Invite>> create(Ref ref) {
    return pendingInvites(ref);
  }
}

String _$pendingInvitesHash() => r'f0aad09578a5e4ff820b1ec9a7a2219472b6aeeb';

@ProviderFor(invite)
final inviteProvider = InviteFamily._();

final class InviteProvider
    extends $FunctionalProvider<AsyncValue<Invite>, Invite, FutureOr<Invite>>
    with $FutureModifier<Invite>, $FutureProvider<Invite> {
  InviteProvider._({
    required InviteFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'inviteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inviteHash();

  @override
  String toString() {
    return r'inviteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Invite> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Invite> create(Ref ref) {
    final argument = this.argument as int;
    return invite(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InviteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inviteHash() => r'69714a94f58b9e5ee93ab77376c1ce8e28a0b3f6';

final class InviteFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Invite>, int> {
  InviteFamily._()
    : super(
        retry: null,
        name: r'inviteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  InviteProvider call(int id) => InviteProvider._(argument: id, from: this);

  @override
  String toString() => r'inviteProvider';
}

@ProviderFor(teamDirectory)
final teamDirectoryProvider = TeamDirectoryProvider._();

final class TeamDirectoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Member>>,
          List<Member>,
          FutureOr<List<Member>>
        >
    with $FutureModifier<List<Member>>, $FutureProvider<List<Member>> {
  TeamDirectoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamDirectoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamDirectoryHash();

  @$internal
  @override
  $FutureProviderElement<List<Member>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Member>> create(Ref ref) {
    return teamDirectory(ref);
  }
}

String _$teamDirectoryHash() => r'b0b1e0c361b686f132511ff50f1d8a174b7522e1';

@ProviderFor(member)
final memberProvider = MemberFamily._();

final class MemberProvider
    extends $FunctionalProvider<AsyncValue<Member>, Member, FutureOr<Member>>
    with $FutureModifier<Member>, $FutureProvider<Member> {
  MemberProvider._({
    required MemberFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'memberProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$memberHash();

  @override
  String toString() {
    return r'memberProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Member> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Member> create(Ref ref) {
    final argument = this.argument as int;
    return member(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MemberProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memberHash() => r'f9cb5a0aef98d9e4eff32939b20ea146eb51b499';

final class MemberFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Member>, int> {
  MemberFamily._()
    : super(
        retry: null,
        name: r'memberProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MemberProvider call(int id) => MemberProvider._(argument: id, from: this);

  @override
  String toString() => r'memberProvider';
}

@ProviderFor(seatPacks)
final seatPacksProvider = SeatPacksProvider._();

final class SeatPacksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SeatPack>>,
          List<SeatPack>,
          FutureOr<List<SeatPack>>
        >
    with $FutureModifier<List<SeatPack>>, $FutureProvider<List<SeatPack>> {
  SeatPacksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seatPacksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seatPacksHash();

  @$internal
  @override
  $FutureProviderElement<List<SeatPack>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SeatPack>> create(Ref ref) {
    return seatPacks(ref);
  }
}

String _$seatPacksHash() => r'3b9a0df87edabd30b932943b1c0316f3a43d23b7';

/// Sends an invitation; the form listens for the sent invite or the failure.

@ProviderFor(InviteSender)
final inviteSenderProvider = InviteSenderProvider._();

/// Sends an invitation; the form listens for the sent invite or the failure.
final class InviteSenderProvider
    extends $AsyncNotifierProvider<InviteSender, Invite?> {
  /// Sends an invitation; the form listens for the sent invite or the failure.
  InviteSenderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inviteSenderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inviteSenderHash();

  @$internal
  @override
  InviteSender create() => InviteSender();
}

String _$inviteSenderHash() => r'4abb24295a7b8f1da4191c6c7a1be27349a9fc4e';

/// Sends an invitation; the form listens for the sent invite or the failure.

abstract class _$InviteSender extends $AsyncNotifier<Invite?> {
  FutureOr<Invite?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Invite?>, Invite?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Invite?>, Invite?>,
              AsyncValue<Invite?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Resend and revoke on one pending invitation.

@ProviderFor(InviteActions)
final inviteActionsProvider = InviteActionsFamily._();

/// Resend and revoke on one pending invitation.
final class InviteActionsProvider
    extends $AsyncNotifierProvider<InviteActions, InviteOutcome?> {
  /// Resend and revoke on one pending invitation.
  InviteActionsProvider._({
    required InviteActionsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'inviteActionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inviteActionsHash();

  @override
  String toString() {
    return r'inviteActionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  InviteActions create() => InviteActions();

  @override
  bool operator ==(Object other) {
    return other is InviteActionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inviteActionsHash() => r'09b88718fd651fabe4df57c4afd5e6ddae24b4e5';

/// Resend and revoke on one pending invitation.

final class InviteActionsFamily extends $Family
    with
        $ClassFamilyOverride<
          InviteActions,
          AsyncValue<InviteOutcome?>,
          InviteOutcome?,
          FutureOr<InviteOutcome?>,
          int
        > {
  InviteActionsFamily._()
    : super(
        retry: null,
        name: r'inviteActionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Resend and revoke on one pending invitation.

  InviteActionsProvider call(int id) =>
      InviteActionsProvider._(argument: id, from: this);

  @override
  String toString() => r'inviteActionsProvider';
}

/// Resend and revoke on one pending invitation.

abstract class _$InviteActions extends $AsyncNotifier<InviteOutcome?> {
  late final _$args = ref.$arg as int;
  int get id => _$args;

  FutureOr<InviteOutcome?> build(int id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<InviteOutcome?>, InviteOutcome?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<InviteOutcome?>, InviteOutcome?>,
              AsyncValue<InviteOutcome?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Role, level, manager and active changes on one member.

@ProviderFor(MemberEditor)
final memberEditorProvider = MemberEditorFamily._();

/// Role, level, manager and active changes on one member.
final class MemberEditorProvider
    extends $AsyncNotifierProvider<MemberEditor, Member?> {
  /// Role, level, manager and active changes on one member.
  MemberEditorProvider._({
    required MemberEditorFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'memberEditorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$memberEditorHash();

  @override
  String toString() {
    return r'memberEditorProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MemberEditor create() => MemberEditor();

  @override
  bool operator ==(Object other) {
    return other is MemberEditorProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memberEditorHash() => r'38ad03f5b660372e40b4d8a3e6a6ed472625d517';

/// Role, level, manager and active changes on one member.

final class MemberEditorFamily extends $Family
    with
        $ClassFamilyOverride<
          MemberEditor,
          AsyncValue<Member?>,
          Member?,
          FutureOr<Member?>,
          int
        > {
  MemberEditorFamily._()
    : super(
        retry: null,
        name: r'memberEditorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Role, level, manager and active changes on one member.

  MemberEditorProvider call(int id) =>
      MemberEditorProvider._(argument: id, from: this);

  @override
  String toString() => r'memberEditorProvider';
}

/// Role, level, manager and active changes on one member.

abstract class _$MemberEditor extends $AsyncNotifier<Member?> {
  late final _$args = ref.$arg as int;
  int get id => _$args;

  FutureOr<Member?> build(int id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Member?>, Member?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Member?>, Member?>,
              AsyncValue<Member?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Hands a member's work over and removes them; true once done.

@ProviderFor(MemberRemoval)
final memberRemovalProvider = MemberRemovalFamily._();

/// Hands a member's work over and removes them; true once done.
final class MemberRemovalProvider
    extends $AsyncNotifierProvider<MemberRemoval, bool> {
  /// Hands a member's work over and removes them; true once done.
  MemberRemovalProvider._({
    required MemberRemovalFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'memberRemovalProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$memberRemovalHash();

  @override
  String toString() {
    return r'memberRemovalProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MemberRemoval create() => MemberRemoval();

  @override
  bool operator ==(Object other) {
    return other is MemberRemovalProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memberRemovalHash() => r'52e2f6dc56c9f06f95d53c655f5112c5bad878f9';

/// Hands a member's work over and removes them; true once done.

final class MemberRemovalFamily extends $Family
    with
        $ClassFamilyOverride<
          MemberRemoval,
          AsyncValue<bool>,
          bool,
          FutureOr<bool>,
          int
        > {
  MemberRemovalFamily._()
    : super(
        retry: null,
        name: r'memberRemovalProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Hands a member's work over and removes them; true once done.

  MemberRemovalProvider call(int id) =>
      MemberRemovalProvider._(argument: id, from: this);

  @override
  String toString() => r'memberRemovalProvider';
}

/// Hands a member's work over and removes them; true once done.

abstract class _$MemberRemoval extends $AsyncNotifier<bool> {
  late final _$args = ref.$arg as int;
  int get id => _$args;

  FutureOr<bool> build(int id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

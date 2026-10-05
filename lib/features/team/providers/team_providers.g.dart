// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(teamApi)
final teamApiProvider = TeamApiProvider._();

final class TeamApiProvider
    extends $FunctionalProvider<TeamApi, TeamApi, TeamApi>
    with $Provider<TeamApi> {
  TeamApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamApiHash();

  @$internal
  @override
  $ProviderElement<TeamApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TeamApi create(Ref ref) {
    return teamApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamApi>(value),
    );
  }
}

String _$teamApiHash() => r'2f6866680440bd44f7f393bcd54304807b175324';

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

String _$teamRepositoryHash() => r'859afc393a6d4d304f24bdb2034fe4715923eb33';

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
    r'0f054ac3d6c0eaa1b51c4d61202c35ab73d13562';

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
    required String super.argument,
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
    final argument = this.argument as String;
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

String _$inviteHash() => r'c435f758572890cc551ce7de02c31d377b530dd2';

final class InviteFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Invite>, String> {
  InviteFamily._()
    : super(
        retry: null,
        name: r'inviteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  InviteProvider call(String id) => InviteProvider._(argument: id, from: this);

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
    required String super.argument,
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
    final argument = this.argument as String;
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

String _$memberHash() => r'8af86a2fbc073d0da775f4ffcbde327e0427fba1';

final class MemberFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Member>, String> {
  MemberFamily._()
    : super(
        retry: null,
        name: r'memberProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MemberProvider call(String id) => MemberProvider._(argument: id, from: this);

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

String _$seatPacksHash() => r'fd5ec749d5ac633afe435d761d1d53efee2b1899';

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

/// Revokes one pending invitation; true once done.

@ProviderFor(InviteRevoker)
final inviteRevokerProvider = InviteRevokerFamily._();

/// Revokes one pending invitation; true once done.
final class InviteRevokerProvider
    extends $AsyncNotifierProvider<InviteRevoker, bool> {
  /// Revokes one pending invitation; true once done.
  InviteRevokerProvider._({
    required InviteRevokerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'inviteRevokerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inviteRevokerHash();

  @override
  String toString() {
    return r'inviteRevokerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  InviteRevoker create() => InviteRevoker();

  @override
  bool operator ==(Object other) {
    return other is InviteRevokerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inviteRevokerHash() => r'13044303230cd9bdf6f9e59b9687bd379bd96e31';

/// Revokes one pending invitation; true once done.

final class InviteRevokerFamily extends $Family
    with
        $ClassFamilyOverride<
          InviteRevoker,
          AsyncValue<bool>,
          bool,
          FutureOr<bool>,
          String
        > {
  InviteRevokerFamily._()
    : super(
        retry: null,
        name: r'inviteRevokerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Revokes one pending invitation; true once done.

  InviteRevokerProvider call(String id) =>
      InviteRevokerProvider._(argument: id, from: this);

  @override
  String toString() => r'inviteRevokerProvider';
}

/// Revokes one pending invitation; true once done.

abstract class _$InviteRevoker extends $AsyncNotifier<bool> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<bool> build(String id);
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

/// Role, level, manager and active changes on one member.

@ProviderFor(MemberEditor)
final memberEditorProvider = MemberEditorFamily._();

/// Role, level, manager and active changes on one member.
final class MemberEditorProvider
    extends $AsyncNotifierProvider<MemberEditor, Member?> {
  /// Role, level, manager and active changes on one member.
  MemberEditorProvider._({
    required MemberEditorFamily super.from,
    required String super.argument,
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

String _$memberEditorHash() => r'0640899ebdd423d563d05130d4c69bd52dc0437d';

/// Role, level, manager and active changes on one member.

final class MemberEditorFamily extends $Family
    with
        $ClassFamilyOverride<
          MemberEditor,
          AsyncValue<Member?>,
          Member?,
          FutureOr<Member?>,
          String
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

  MemberEditorProvider call(String id) =>
      MemberEditorProvider._(argument: id, from: this);

  @override
  String toString() => r'memberEditorProvider';
}

/// Role, level, manager and active changes on one member.

abstract class _$MemberEditor extends $AsyncNotifier<Member?> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<Member?> build(String id);
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
    required String super.argument,
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

String _$memberRemovalHash() => r'4e6104fbd8ceb71f4195120ffd5118ba0d5d3c4f';

/// Hands a member's work over and removes them; true once done.

final class MemberRemovalFamily extends $Family
    with
        $ClassFamilyOverride<
          MemberRemoval,
          AsyncValue<bool>,
          bool,
          FutureOr<bool>,
          String
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

  MemberRemovalProvider call(String id) =>
      MemberRemovalProvider._(argument: id, from: this);

  @override
  String toString() => r'memberRemovalProvider';
}

/// Hands a member's work over and removes them; true once done.

abstract class _$MemberRemoval extends $AsyncNotifier<bool> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<bool> build(String id);
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

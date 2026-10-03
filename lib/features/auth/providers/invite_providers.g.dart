// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(invitation)
final invitationProvider = InvitationFamily._();

final class InvitationProvider
    extends
        $FunctionalProvider<
          AsyncValue<Invitation>,
          Invitation,
          FutureOr<Invitation>
        >
    with $FutureModifier<Invitation>, $FutureProvider<Invitation> {
  InvitationProvider._({
    required InvitationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'invitationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$invitationHash();

  @override
  String toString() {
    return r'invitationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Invitation> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Invitation> create(Ref ref) {
    final argument = this.argument as String;
    return invitation(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InvitationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$invitationHash() => r'8b7e6cf781af0dd553b507b7363325c76b216549';

final class InvitationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Invitation>, String> {
  InvitationFamily._()
    : super(
        retry: null,
        name: r'invitationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  InvitationProvider call(String code) =>
      InvitationProvider._(argument: code, from: this);

  @override
  String toString() => r'invitationProvider';
}

@ProviderFor(referral)
final referralProvider = ReferralFamily._();

final class ReferralProvider
    extends
        $FunctionalProvider<AsyncValue<Referral>, Referral, FutureOr<Referral>>
    with $FutureModifier<Referral>, $FutureProvider<Referral> {
  ReferralProvider._({
    required ReferralFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'referralProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$referralHash();

  @override
  String toString() {
    return r'referralProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Referral> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Referral> create(Ref ref) {
    final argument = this.argument as String;
    return referral(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ReferralProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$referralHash() => r'bf7aa39da47955038f61b96a0b27aa36a3a1746f';

final class ReferralFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Referral>, String> {
  ReferralFamily._()
    : super(
        retry: null,
        name: r'referralProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ReferralProvider call(String code) =>
      ReferralProvider._(argument: code, from: this);

  @override
  String toString() => r'referralProvider';
}

@ProviderFor(InviteActionNotifier)
final inviteActionProvider = InviteActionNotifierFamily._();

final class InviteActionNotifierProvider
    extends $AsyncNotifierProvider<InviteActionNotifier, InviteOutcome?> {
  InviteActionNotifierProvider._({
    required InviteActionNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'inviteActionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inviteActionNotifierHash();

  @override
  String toString() {
    return r'inviteActionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  InviteActionNotifier create() => InviteActionNotifier();

  @override
  bool operator ==(Object other) {
    return other is InviteActionNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inviteActionNotifierHash() =>
    r'6704bff82a9572c71d6e4f80540187a59c64455c';

final class InviteActionNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          InviteActionNotifier,
          AsyncValue<InviteOutcome?>,
          InviteOutcome?,
          FutureOr<InviteOutcome?>,
          String
        > {
  InviteActionNotifierFamily._()
    : super(
        retry: null,
        name: r'inviteActionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  InviteActionNotifierProvider call(String code) =>
      InviteActionNotifierProvider._(argument: code, from: this);

  @override
  String toString() => r'inviteActionProvider';
}

abstract class _$InviteActionNotifier extends $AsyncNotifier<InviteOutcome?> {
  late final _$args = ref.$arg as String;
  String get code => _$args;

  FutureOr<InviteOutcome?> build(String code);
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

/// #9. A failed setup after the team exists retries only the setup.

@ProviderFor(CreateTeamNotifier)
final createTeamProvider = CreateTeamNotifierProvider._();

/// #9. A failed setup after the team exists retries only the setup.
final class CreateTeamNotifierProvider
    extends $AsyncNotifierProvider<CreateTeamNotifier, Workspace?> {
  /// #9. A failed setup after the team exists retries only the setup.
  CreateTeamNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createTeamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createTeamNotifierHash();

  @$internal
  @override
  CreateTeamNotifier create() => CreateTeamNotifier();
}

String _$createTeamNotifierHash() =>
    r'97ecd72e53f3bd954edf4f2d5ce7c0cde957606f';

/// #9. A failed setup after the team exists retries only the setup.

abstract class _$CreateTeamNotifier extends $AsyncNotifier<Workspace?> {
  FutureOr<Workspace?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Workspace?>, Workspace?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Workspace?>, Workspace?>,
              AsyncValue<Workspace?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

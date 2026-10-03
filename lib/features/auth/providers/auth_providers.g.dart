// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'186301665ec3968c76cc37e6e923e8a59449820c';

/// The sign-up in progress, kept across the phone, code, PIN, profile and
/// industry screens.

@ProviderFor(SignUpFlowNotifier)
final signUpFlowProvider = SignUpFlowNotifierProvider._();

/// The sign-up in progress, kept across the phone, code, PIN, profile and
/// industry screens.
final class SignUpFlowNotifierProvider
    extends $NotifierProvider<SignUpFlowNotifier, SignUpFlow> {
  /// The sign-up in progress, kept across the phone, code, PIN, profile and
  /// industry screens.
  SignUpFlowNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signUpFlowProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signUpFlowNotifierHash();

  @$internal
  @override
  SignUpFlowNotifier create() => SignUpFlowNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignUpFlow value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignUpFlow>(value),
    );
  }
}

String _$signUpFlowNotifierHash() =>
    r'fc51a1c5b343b63e3cecb97b24f5d5d27a12292a';

/// The sign-up in progress, kept across the phone, code, PIN, profile and
/// industry screens.

abstract class _$SignUpFlowNotifier extends $Notifier<SignUpFlow> {
  SignUpFlow build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SignUpFlow, SignUpFlow>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SignUpFlow, SignUpFlow>,
              SignUpFlow,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(SendCodeNotifier)
final sendCodeProvider = SendCodeNotifierProvider._();

final class SendCodeNotifierProvider
    extends $AsyncNotifierProvider<SendCodeNotifier, OtpChallenge?> {
  SendCodeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sendCodeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sendCodeNotifierHash();

  @$internal
  @override
  SendCodeNotifier create() => SendCodeNotifier();
}

String _$sendCodeNotifierHash() => r'497429cb542c2e570f886df4b3f523871c92407c';

abstract class _$SendCodeNotifier extends $AsyncNotifier<OtpChallenge?> {
  FutureOr<OtpChallenge?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<OtpChallenge?>, OtpChallenge?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OtpChallenge?>, OtpChallenge?>,
              AsyncValue<OtpChallenge?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(ResendCodeNotifier)
final resendCodeProvider = ResendCodeNotifierProvider._();

final class ResendCodeNotifierProvider
    extends $AsyncNotifierProvider<ResendCodeNotifier, OtpChallenge?> {
  ResendCodeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resendCodeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resendCodeNotifierHash();

  @$internal
  @override
  ResendCodeNotifier create() => ResendCodeNotifier();
}

String _$resendCodeNotifierHash() =>
    r'11d8517d5b95a5a527d6203b9774467d936fe235';

abstract class _$ResendCodeNotifier extends $AsyncNotifier<OtpChallenge?> {
  FutureOr<OtpChallenge?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<OtpChallenge?>, OtpChallenge?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OtpChallenge?>, OtpChallenge?>,
              AsyncValue<OtpChallenge?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Checks the SMS code. An existing account without a pending invitation is
/// signed in here; the screen moves every other case on.

@ProviderFor(VerifyCodeNotifier)
final verifyCodeProvider = VerifyCodeNotifierProvider._();

/// Checks the SMS code. An existing account without a pending invitation is
/// signed in here; the screen moves every other case on.
final class VerifyCodeNotifierProvider
    extends $AsyncNotifierProvider<VerifyCodeNotifier, PhoneVerification?> {
  /// Checks the SMS code. An existing account without a pending invitation is
  /// signed in here; the screen moves every other case on.
  VerifyCodeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verifyCodeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verifyCodeNotifierHash();

  @$internal
  @override
  VerifyCodeNotifier create() => VerifyCodeNotifier();
}

String _$verifyCodeNotifierHash() =>
    r'ce4ea95093493db2d5d5cf77285a372183409bcb';

/// Checks the SMS code. An existing account without a pending invitation is
/// signed in here; the screen moves every other case on.

abstract class _$VerifyCodeNotifier extends $AsyncNotifier<PhoneVerification?> {
  FutureOr<PhoneVerification?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<PhoneVerification?>, PhoneVerification?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PhoneVerification?>, PhoneVerification?>,
              AsyncValue<PhoneVerification?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(ProfileSubmitNotifier)
final profileSubmitProvider = ProfileSubmitNotifierProvider._();

final class ProfileSubmitNotifierProvider
    extends $AsyncNotifierProvider<ProfileSubmitNotifier, AuthSession?> {
  ProfileSubmitNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileSubmitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileSubmitNotifierHash();

  @$internal
  @override
  ProfileSubmitNotifier create() => ProfileSubmitNotifier();
}

String _$profileSubmitNotifierHash() =>
    r'5006c1b50712099c2a58f74f16535831d84e3157';

abstract class _$ProfileSubmitNotifier extends $AsyncNotifier<AuthSession?> {
  FutureOr<AuthSession?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AuthSession?>, AuthSession?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AuthSession?>, AuthSession?>,
              AsyncValue<AuthSession?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(IndustrySubmitNotifier)
final industrySubmitProvider = IndustrySubmitNotifierProvider._();

final class IndustrySubmitNotifierProvider
    extends $AsyncNotifierProvider<IndustrySubmitNotifier, IndustryTemplate?> {
  IndustrySubmitNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'industrySubmitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$industrySubmitNotifierHash();

  @$internal
  @override
  IndustrySubmitNotifier create() => IndustrySubmitNotifier();
}

String _$industrySubmitNotifierHash() =>
    r'b92cb4e3f25a70bb7bdc9e31b727065064db34d2';

abstract class _$IndustrySubmitNotifier
    extends $AsyncNotifier<IndustryTemplate?> {
  FutureOr<IndustryTemplate?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<IndustryTemplate?>, IndustryTemplate?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<IndustryTemplate?>, IndustryTemplate?>,
              AsyncValue<IndustryTemplate?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(EmailSignInNotifier)
final emailSignInProvider = EmailSignInNotifierProvider._();

final class EmailSignInNotifierProvider
    extends $AsyncNotifierProvider<EmailSignInNotifier, AuthSession?> {
  EmailSignInNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'emailSignInProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$emailSignInNotifierHash();

  @$internal
  @override
  EmailSignInNotifier create() => EmailSignInNotifier();
}

String _$emailSignInNotifierHash() =>
    r'0510013d59d93df0557591c201d37bdc2d926522';

abstract class _$EmailSignInNotifier extends $AsyncNotifier<AuthSession?> {
  FutureOr<AuthSession?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AuthSession?>, AuthSession?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AuthSession?>, AuthSession?>,
              AsyncValue<AuthSession?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(PasswordResetNotifier)
final passwordResetProvider = PasswordResetNotifierProvider._();

final class PasswordResetNotifierProvider
    extends $AsyncNotifierProvider<PasswordResetNotifier, bool> {
  PasswordResetNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'passwordResetProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$passwordResetNotifierHash();

  @$internal
  @override
  PasswordResetNotifier create() => PasswordResetNotifier();
}

String _$passwordResetNotifierHash() =>
    r'97191a3f71be4bed50321c94d9440105d79bd707';

abstract class _$PasswordResetNotifier extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
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
    return element.handleCreate(ref, build);
  }
}

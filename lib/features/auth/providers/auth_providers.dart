import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/session/auth_session.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/auth/data/auth_repository.dart';
import 'package:salesroot/features/auth/data/fake_auth_repository.dart';
import 'package:salesroot/features/auth/models/otp_challenge.dart';
import 'package:salesroot/features/auth/models/phone_verification.dart';
import 'package:salesroot/features/auth/models/sign_up_flow.dart';
import 'package:salesroot/features/auth/models/sign_up_profile.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => FakeAuthRepository(
  ref.watch(fakeNetworkProvider),
  ref.watch(fakeStoreProvider),
  ref.watch(workspaceRepositoryProvider),
);

/// The sign-up in progress, kept across the phone, code, PIN, profile and
/// industry screens.
@Riverpod(keepAlive: true)
class SignUpFlowNotifier extends _$SignUpFlowNotifier {
  @override
  SignUpFlow build() => const SignUpFlow();

  void codeSent(
    OtpChallenge challenge, {
    String? referralCode,
    String? inviteCode,
  }) => state = SignUpFlow(
    challenge: challenge,
    referralCode: referralCode,
    inviteCode: inviteCode,
  );

  void codeResent(OtpChallenge challenge) =>
      state = state.copyWith(challenge: challenge);

  void verified(AuthSession session) =>
      state = state.copyWith(session: session);

  void profileSaved(
    AuthSession session,
    WorkStyle workStyle, {
    String? inviteCode,
  }) => state = state.copyWith(
    session: session,
    workStyle: workStyle,
    inviteCode: inviteCode,
  );

  /// Signs the verified account in and gives it the experience level its
  /// way of working suggests. Navigate first: sign-in moves the router.
  Future<void> signIn() async {
    final session = state.session;
    if (session == null) return;
    await ref.read(sessionProvider.notifier).signIn(session);
    final style = state.workStyle;
    if (!ref.mounted || style == null) return;
    try {
      await ref.read(workspacesProvider.future);
    } on ApiFailure {
      return;
    }
    if (!ref.mounted) return;
    ref.read(experienceLevelProvider.notifier).set(style.startingLevel);
  }

  void clear() => state = const SignUpFlow();
}

@riverpod
class SendCodeNotifier extends _$SendCodeNotifier {
  @override
  FutureOr<OtpChallenge?> build() => null;

  Future<void> send(
    String phone, {
    String? referralCode,
    String? inviteCode,
  }) async {
    if (state.isLoading) return;
    final referral = referralCode?.trim();
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .requestCode(
            phone,
            referralCode: referral == null || referral.isEmpty
                ? null
                : referral,
          ),
    );
    if (!ref.mounted) return;
    if (result case AsyncData(:final value)) {
      ref
          .read(signUpFlowProvider.notifier)
          .codeSent(value, referralCode: referral, inviteCode: inviteCode);
    }
    state = result;
  }
}

@riverpod
class ResendCodeNotifier extends _$ResendCodeNotifier {
  @override
  FutureOr<OtpChallenge?> build() => null;

  Future<void> resend(OtpChannel channel) async {
    final flow = ref.read(signUpFlowProvider);
    final phone = flow.challenge?.phone;
    if (phone == null || state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .requestCode(
            phone,
            referralCode: flow.referralCode,
            channel: channel,
          ),
    );
    if (!ref.mounted) return;
    if (result case AsyncData(:final value)) {
      ref.read(signUpFlowProvider.notifier).codeResent(value);
    }
    state = result;
  }
}

/// Checks the SMS code. An existing account without a pending invitation is
/// signed in here; the screen moves every other case on.
@riverpod
class VerifyCodeNotifier extends _$VerifyCodeNotifier {
  @override
  FutureOr<PhoneVerification?> build() => null;

  Future<void> verify(String code) async {
    final flow = ref.read(signUpFlowProvider);
    final phone = flow.challenge?.phone;
    if (phone == null || state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).verifyCode(phone, code),
    );
    if (!ref.mounted) return;
    final verification = result.value;
    if (verification != null) {
      final flowNotifier = ref.read(signUpFlowProvider.notifier);
      if (!verification.isNewUser && flow.inviteCode == null) {
        flowNotifier.clear();
        await ref.read(sessionProvider.notifier).signIn(verification.session);
        if (!ref.mounted) return;
      } else {
        flowNotifier.verified(verification.session);
      }
    }
    state = result;
  }

  void clearError() {
    if (state.hasError) state = const AsyncData(null);
  }
}

@riverpod
class ProfileSubmitNotifier extends _$ProfileSubmitNotifier {
  @override
  FutureOr<AuthSession?> build() => null;

  Future<void> submit(
    String name,
    WorkStyle style, {
    String? inviteCode,
  }) async {
    final pending = ref.read(signUpFlowProvider).session;
    if (pending == null || state.isLoading) return;
    final invite = style == WorkStyle.joining ? inviteCode?.trim() : null;
    final repository = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      if (invite != null) await _checkInvitation(repository, invite);
      return repository.completeProfile(
        pending.token,
        SignUpProfile(name: name, workStyle: style),
      );
    });
    if (!ref.mounted) return;
    if (result case AsyncData(:final value)) {
      ref
          .read(signUpFlowProvider.notifier)
          .profileSaved(value, style, inviteCode: invite);
    }
    state = result;
  }

  static Future<void> _checkInvitation(
    AuthRepository repository,
    String code,
  ) async {
    try {
      await repository.invitation(code);
    } on ApiFailure catch (failure) {
      if (!failure.isNotFound) rethrow;
      throw ApiFailure(
        400,
        failure.message,
        fieldErrors: {'InviteCode': failure.message},
      );
    }
  }
}

@riverpod
class IndustrySubmitNotifier extends _$IndustrySubmitNotifier {
  @override
  FutureOr<IndustryTemplate?> build() => null;

  Future<void> apply(IndustryTemplate template) async {
    final pending = ref.read(signUpFlowProvider).session;
    if (pending == null || state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .applyIndustryTemplate(pending.token, template);
      return template;
    });
    if (!ref.mounted) return;
    state = result;
  }
}

@riverpod
class EmailSignInNotifier extends _$EmailSignInNotifier {
  @override
  FutureOr<AuthSession?> build() => null;

  Future<void> signIn(
    String email,
    String password, {
    required bool remember,
  }) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signInWithEmail(email, password, remember: remember),
    );
    if (!ref.mounted) return;
    state = result;
    final session = result.value;
    if (session != null) {
      await ref.read(sessionProvider.notifier).signIn(session);
    }
  }
}

@riverpod
class PasswordResetNotifier extends _$PasswordResetNotifier {
  @override
  FutureOr<bool> build() => false;

  Future<void> send(String email) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).requestPasswordReset(email);
      return true;
    });
    if (!ref.mounted) return;
    state = result;
  }
}

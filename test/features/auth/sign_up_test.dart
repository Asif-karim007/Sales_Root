import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/session/session_store.dart';
import 'package:salesroot/features/auth/data/auth_fixtures.dart';
import 'package:salesroot/features/auth/models/pin_entry.dart';
import 'package:salesroot/features/auth/models/sign_up_profile.dart';
import 'package:salesroot/features/auth/providers/auth_providers.dart';
import 'package:salesroot/features/auth/providers/pin_providers.dart';

import 'auth_test_setup.dart';

void main() {
  Future<void> sendCode(ProviderContainer container, String phone) async {
    container.listen(sendCodeProvider, (_, _) {});
    await container.read(sendCodeProvider.notifier).send(phone);
  }

  Future<void> verify(ProviderContainer container, String code) async {
    container.listen(verifyCodeProvider, (_, _) {});
    await container.read(verifyCodeProvider.notifier).verify(code);
  }

  group('phone number', () {
    test('an invalid number is a 400 on the phone field', () async {
      final container = await authContainer();
      await sendCode(container, '0123');

      final error = container.read(sendCodeProvider).error;
      expect(error, isA<ApiFailure>());
      expect((error as ApiFailure).fieldError('Phone'), isNotNull);
      expect(container.read(signUpFlowProvider).challenge, isNull);
    });

    test('offline fails with status 0', () async {
      final container = await authContainer();
      container
          .read(devSettingsProvider.notifier)
          .update((s) => s.copyWith(offline: true));
      await sendCode(container, '01812345678');

      final error = container.read(sendCodeProvider).error;
      expect(error, isA<ApiFailure>());
      expect((error as ApiFailure).isOffline, isTrue);
    });

    test('a referral code on a registered number is a 409', () async {
      final container = await authContainer();
      container.listen(sendCodeProvider, (_, _) {});
      await container
          .read(sendCodeProvider.notifier)
          .send(demoPhone, referralCode: 'RH4K9P');

      final error = container.read(sendCodeProvider).error as ApiFailure;
      expect(error.isConflict, isTrue);
      expect(error.fieldError('ReferralCode'), isNotNull);
    });

    test('an unknown referral code is a 400 on its field', () async {
      final container = await authContainer();
      container.listen(sendCodeProvider, (_, _) {});
      await container
          .read(sendCodeProvider.notifier)
          .send('01812345678', referralCode: 'NOPE00');

      final error = container.read(sendCodeProvider).error as ApiFailure;
      expect(error.isValidation, isTrue);
      expect(error.fieldError('ReferralCode'), isNotNull);
    });
  });

  group('code verification', () {
    test(
      'a wrong code is a 400 on the code field and signs no one in',
      () async {
        final container = await authContainer();
        await sendCode(container, demoPhone);
        await verify(container, '000000');

        final error = container.read(verifyCodeProvider).error as ApiFailure;
        expect(error.isValidation, isTrue);
        expect(error.fieldError('Code'), isNotNull);
        expect(await container.read(sessionProvider.future), isNull);
      },
    );

    test('an existing number signs in straight away', () async {
      final container = await authContainer();
      await sendCode(container, '01711000000');
      await verify(container, demoSmsCode);

      final session = await container.read(sessionProvider.future);
      expect(session?.userId, 1);
      expect(session?.name, 'Karim Hossain');
      expect(container.read(signUpFlowProvider).session, isNull);
    });

    test('a new number keeps a pending session and is not signed in', () async {
      final container = await authContainer();
      await sendCode(container, '01812345678');
      await verify(container, demoSmsCode);

      expect(container.read(verifyCodeProvider).value?.isNewUser, isTrue);
      expect(container.read(signUpFlowProvider).session, isNotNull);
      expect(await container.read(sessionProvider.future), isNull);
    });
  });

  test('a new user sets a PIN, a profile, and is then signed in', () async {
    final container = await authContainer();
    await sendCode(container, '01812345678');
    await verify(container, demoSmsCode);
    container.listen(pinSetupProvider, (_, _) {});
    final pin = container.read(pinSetupProvider.notifier);

    Future<void> type(String digits) async {
      for (final d in digits.split('')) {
        pin.digit(int.parse(d));
      }
      await pin.submit();
    }

    await type('1234');
    expect(container.read(pinSetupProvider).error, PinSetupError.weak);
    await type('2580');
    await type('2581');
    expect(container.read(pinSetupProvider).error, PinSetupError.mismatch);
    await type('2580');
    await type('2580');
    expect(container.read(pinSetupProvider).saved, isTrue);

    final pending = container.read(signUpFlowProvider).session;
    expect(pending, isNotNull);
    expect(
      await container
          .read(sessionStoreProvider)
          .checkPin('2580', pending?.userId ?? 0),
      isTrue,
    );

    container.listen(profileSubmitProvider, (_, _) {});
    await container
        .read(profileSubmitProvider.notifier)
        .submit('Nusrat Jahan', WorkStyle.team);
    expect(container.read(signUpFlowProvider).session?.name, 'Nusrat Jahan');

    await container.read(signUpFlowProvider.notifier).signIn();
    final session = await container.read(sessionProvider.future);
    expect(session?.name, 'Nusrat Jahan');
    expect(container.read(experienceLevelProvider), ExperienceLevel.standard);
  });

  test('joining needs an invitation that exists', () async {
    final container = await authContainer();
    await sendCode(container, '01812345678');
    await verify(container, demoSmsCode);
    container.listen(profileSubmitProvider, (_, _) {});
    await container
        .read(profileSubmitProvider.notifier)
        .submit('Nusrat Jahan', WorkStyle.joining, inviteCode: 'ZZZZZZ');

    final error = container.read(profileSubmitProvider).error as ApiFailure;
    expect(error.fieldError('InviteCode'), isNotNull);
  });

  group('email sign-in', () {
    test('a wrong password is a 400 and signs no one in', () async {
      final container = await authContainer();
      container.listen(emailSignInProvider, (_, _) {});
      await container
          .read(emailSignInProvider.notifier)
          .signIn(demoEmail, 'nope', remember: true);

      expect(container.read(emailSignInProvider).error, isA<ApiFailure>());
      expect(await container.read(sessionProvider.future), isNull);
    });

    test('the demo account signs in', () async {
      final container = await authContainer();
      container.listen(emailSignInProvider, (_, _) {});
      await container
          .read(emailSignInProvider.notifier)
          .signIn(demoEmail, demoPassword, remember: false);

      final session = await container.read(sessionProvider.future);
      expect(session?.email, demoEmail);
    });
  });
}

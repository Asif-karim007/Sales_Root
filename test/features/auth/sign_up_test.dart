import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/session/session_store.dart';
import 'package:salesroot/features/auth/models/pin_entry.dart';
import 'package:salesroot/features/auth/models/sign_up_profile.dart';
import 'package:salesroot/features/auth/providers/auth_providers.dart';
import 'package:salesroot/features/auth/providers/invite_providers.dart';
import 'package:salesroot/features/auth/providers/pin_providers.dart';

import '../../helpers/api_stub.dart';
import 'auth_test_setup.dart';

void main() {
  Future<void> sendCode(
    ProviderContainer container,
    String phone, {
    String? referralCode,
  }) async {
    container.listen(sendCodeProvider, (_, _) {});
    await container
        .read(sendCodeProvider.notifier)
        .send(phone, referralCode: referralCode);
  }

  Future<void> verify(ProviderContainer container, String code) async {
    container.listen(verifyCodeProvider, (_, _) {});
    await container.read(verifyCodeProvider.notifier).verify(code);
  }

  group('phone number', () {
    test('asks for a sign-in code and keeps the challenge', () async {
      final stub = authStub();
      final container = await authContainer(stub);
      await sendCode(container, testPhone);

      expect(stub.lastBody('POST', 'auth/otp/request'), {
        'phone': testPhone,
        'purpose': 'login',
      });
      expect(container.read(signUpFlowProvider).challenge?.phone, testPhone);
    });

    test('an invalid number is a 422 on the phone field', () async {
      final stub = authStub()
        ..on(
          'POST',
          'auth/otp/request',
          (_) => StubReply(422, fixture('auth_bad_phone')),
        );
      final container = await authContainer(stub);
      await sendCode(container, '0123');

      final error = container.read(sendCodeProvider).error;
      expect(error, isA<ApiFailure>());
      expect((error as ApiFailure).fieldError('phone'), isNotNull);
      expect(container.read(signUpFlowProvider).challenge, isNull);
    });

    test('offline fails with status 0', () async {
      final stub = authStub()..offline = true;
      final container = await authContainer(stub);
      await sendCode(container, testPhone);

      final error = container.read(sendCodeProvider).error;
      expect((error as ApiFailure).isOffline, isTrue);
    });
  });

  group('code verification', () {
    test(
      'a wrong code is a 422 on the code field and signs no one in',
      () async {
        final stub = authStub()
          ..on(
            'POST',
            'auth/otp/verify',
            (_) => StubReply(422, fixture('auth_wrong_code')),
          );
        final container = await authContainer(stub);
        await sendCode(container, testPhone);
        await verify(container, '000000');

        final error = container.read(verifyCodeProvider).error as ApiFailure;
        expect(error.isValidation, isTrue);
        expect(error.fieldError('code'), 'Wrong code');
        expect(await container.read(sessionProvider.future), isNull);
      },
    );

    test('an existing account signs in straight away', () async {
      final stub = authStub();
      final container = await authContainer(stub);
      await sendCode(container, testPhone);
      await verify(container, '123456');

      final body = stub.lastBody('POST', 'auth/otp/verify');
      expect(body['phone'], testPhone);
      expect(body['code'], '123456');
      expect(body['appVersion'], '1.0.0');
      final session = await container.read(sessionProvider.future);
      expect(session?.userId, testUserId);
      expect(session?.name, 'Rafi Ahmed');
      expect(session?.token, 'test.access');
      expect(container.read(signUpFlowProvider).session, isNull);
    });

    test('an account without a name keeps a pending session', () async {
      final stub = authStub()..on('POST', 'auth/otp/verify', newUserTokens());
      final container = await authContainer(stub);
      await sendCode(container, testPhone);
      await verify(container, '123456');

      expect(container.read(verifyCodeProvider).value?.isNewUser, isTrue);
      expect(container.read(signUpFlowProvider).session, isNotNull);
      expect(await container.read(sessionProvider.future), isNull);
    });

    test('a referral code goes with the verification', () async {
      final stub = authStub()..on('POST', 'auth/otp/verify', newUserTokens());
      final container = await authContainer(stub);
      await sendCode(container, testPhone, referralCode: ' Q95ED5 ');
      await verify(container, '123456');

      expect(
        stub.lastBody('POST', 'auth/otp/verify')['referralCode'],
        'Q95ED5',
      );
    });
  });

  test('a new user sets a PIN, a profile, and is then signed in', () async {
    final stub = authStub()
      ..on('POST', 'auth/otp/verify', newUserTokens())
      ..on('POST', 'auth/pin', null)
      ..on('PATCH', 'auth/me', null);
    final container = await authContainer(stub);
    await sendCode(container, testPhone);
    await verify(container, '123456');
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
    expect(stub.lastBody('POST', 'auth/pin'), {'pin': '2580'});
    expect(
      stub.last('POST', 'auth/pin')?.headers['Authorization'],
      'Bearer test.access',
    );
    expect(
      await container.read(sessionStoreProvider).checkPin('2580', testUserId),
      isTrue,
    );

    container.listen(profileSubmitProvider, (_, _) {});
    await container
        .read(profileSubmitProvider.notifier)
        .submit('Nusrat Jahan', WorkStyle.team);
    expect(stub.lastBody('PATCH', 'auth/me'), {'name': 'Nusrat Jahan'});
    expect(container.read(signUpFlowProvider).session?.name, 'Nusrat Jahan');

    await container.read(signUpFlowProvider.notifier).signIn();
    await settle();
    final session = await container.read(sessionProvider.future);
    expect(session?.name, 'Nusrat Jahan');
    expect(container.read(experienceLevelProvider), ExperienceLevel.standard);
  });

  test('a PIN the server refuses is still kept on the device', () async {
    final stub = authStub()
      ..on('POST', 'auth/otp/verify', newUserTokens())
      ..fail('POST', 'auth/pin', 500);
    final container = await authContainer(stub);
    await sendCode(container, testPhone);
    await verify(container, '123456');
    container.listen(pinSetupProvider, (_, _) {});
    final pin = container.read(pinSetupProvider.notifier);
    for (final entry in ['2580', '2580']) {
      for (final d in entry.split('')) {
        pin.digit(int.parse(d));
      }
      await pin.submit();
    }

    expect(container.read(pinSetupProvider).saved, isTrue);
  });

  test('joining needs an invitation that exists', () async {
    final stub = authStub()..on('POST', 'auth/otp/verify', newUserTokens());
    final container = await authContainer(stub);
    await sendCode(container, testPhone);
    await verify(container, '123456');
    container.listen(profileSubmitProvider, (_, _) {});
    await container
        .read(profileSubmitProvider.notifier)
        .submit('Nusrat Jahan', WorkStyle.joining, inviteCode: 'missing');

    final error = container.read(profileSubmitProvider).error as ApiFailure;
    expect(error.fieldError('inviteCode'), isNotNull);
    expect(stub.last('PATCH', 'auth/me'), isNull);
  });

  group('referral link', () {
    test('shows who invited and the bonus', () async {
      final stub = authStub();
      final container = await authContainer(stub);
      container.listen(referralProvider('q95ed5'), (_, _) {});

      final referral = await container.read(referralProvider('q95ed5').future);
      expect(
        stub.last('GET', 'public/referral/{code}')?.path,
        endsWith('Q95ED5'),
      );
      expect(referral.code, 'Q95ED5');
      expect(referral.inviter.en, 'Rafi');
      expect(referral.trialDays, 15);
      expect(referral.creditAmount, 50);
    });

    test('an unknown code is a 404', () async {
      final stub = authStub()
        ..on('GET', 'public/referral/{code}', (_) => const StubReply(404));
      final container = await authContainer(stub);
      container.listen(referralProvider('NOPE00'), (_, _) {});

      await expectLater(
        container.read(referralProvider('NOPE00').future),
        throwsA(isA<ApiFailure>().having((f) => f.isNotFound, '404', true)),
      );
    });
  });
}

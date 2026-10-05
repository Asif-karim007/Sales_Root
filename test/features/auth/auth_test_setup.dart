import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../helpers/api_stub.dart';

/// The test account, as the server knows it.
const testPhone = '+8801711000002';
const testUserId = '01a10101-8644-75d5-813c-211d42aa3d68';

/// The sign-in calls answered from recorded responses: a code is sent, and
/// verifying signs in Rafi Ahmed, an existing account.
ApiStub authStub() {
  PackageInfo.setMockInitialValues(
    appName: 'SalesRoot',
    packageName: 'com.salesrootcrm.salesroot',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );
  return ApiStub()
    ..on('POST', 'auth/otp/request', fixture('auth_otp_request'))
    ..on('POST', 'auth/otp/verify', fixture('auth_tokens'))
    ..on('GET', 'public/referral/{code}', fixture('auth_referral'));
}

/// The verify body of an account that has not finished sign-up: no name yet.
Map<String, dynamic> newUserTokens() {
  final tokens = fixtureMap('auth_tokens');
  return {
    ...tokens,
    'me': {...tokens['me'] as Map<String, dynamic>, 'name': ''},
  };
}

/// A container over [stub], signed out unless [signedIn].
Future<ProviderContainer> authContainer(
  ApiStub stub, {
  bool signedIn = false,
  Map<String, dynamic>? me,
}) => apiContainer(stub, signedIn: signedIn, me: me);

/// Lets fire-and-forget work, like the PIN check after the fourth digit, end.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

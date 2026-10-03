import 'package:salesroot/core/routing/routes.dart';

/// Locations inside the sign-up and sign-in flow, with their query params.
abstract final class AuthLinks {
  static String phone({bool signIn = false, String? invite}) => _with(
    Routes.authPhone,
    {if (signIn) 'mode': 'signin', 'invite': ?invite},
  );

  static String code({bool signIn = false}) =>
      _with(Routes.authCode, {if (signIn) 'mode': 'signin'});

  static String _with(String path, Map<String, String> query) =>
      Uri(path: path, queryParameters: query.isEmpty ? null : query).toString();
}

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/auth_repository.dart';

bool isWebAuthCallback(Uri uri) {
  final Map<String, String> fragment = Uri.splitQueryString(uri.fragment);
  return <String>[
    'code',
    'error',
    'error_code',
    'error_description',
    'access_token',
  ].any(
    (String key) =>
        uri.queryParameters.containsKey(key) || fragment.containsKey(key),
  );
}

/// Uses the SDK's exchange and storage, but returns initialization failures to
/// the UI instead of letting a pre-widget auth stream notification disappear.
Future<AuthFailure?> completeWebAuthCallback(
  Uri uri,
  Future<void> Function(Uri) exchange, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  if (!isWebAuthCallback(uri)) return null;
  final Map<String, String> params = <String, String>{
    ...Uri.splitQueryString(uri.fragment),
    ...uri.queryParameters,
  };
  if (params.containsKey('error') ||
      params.containsKey('error_code') ||
      params.containsKey('error_description')) {
    return AuthFailure(
      params['error'] == 'access_denied'
          ? 'Prihlásenie Google bolo zrušené. Skús to znova. [AUTH-CANCELLED]'
          : 'Google prihlásenie sa nevrátilo úspešne. Skontroluj Client ID, Client Secret a callback v Supabase. [AUTH-OAUTH]',
    );
  }
  try {
    await exchange(uri).timeout(timeout);
    return null;
  } on AuthException catch (error) {
    if (error is AuthPKCEGrantCodeExchangeError ||
        <String>{
          'bad_code_verifier',
          'flow_state_not_found',
          'flow_state_expired',
        }.contains(error.code)) {
      return const AuthFailure(
        'Návrat z prihlásenia sa nepodarilo overiť. Otvor https://vedomax.web.app a začni prihlásenie znova v tom istom prehliadači. [AUTH-PKCE]',
      );
    }
    return const AuthFailure(
      'Prihlásenie sa nepodarilo dokončiť v Supabase. Skontroluj Auth logy. [AUTH-EXCHANGE]',
    );
  } on TimeoutException {
    return const AuthFailure(
      'Server prihlasovania neodpovedal včas. Skontroluj pripojenie a začni nové prihlásenie. [AUTH-TIMEOUT]',
    );
  } on Object {
    return const AuthFailure(
      'Prihlásenie sa nepodarilo dokončiť. Skontroluj pripojenie a začni znova. [AUTH-CONNECTION]',
    );
  }
}

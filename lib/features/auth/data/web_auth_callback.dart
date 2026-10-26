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
          ? 'Potvrdenie účtu bolo zrušené. Skús to znova. [AUTH-CANCELLED]'
          : 'Odkaz na potvrdenie účtu sa nepodarilo spracovať. Vyžiadaj si nový potvrdzovací e-mail. [AUTH-LINK]',
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
        'Potvrdzovací odkaz otvor v prehliadači, v ktorom si začal registráciu. Ak je odkaz starý, vyžiadaj si nový. [AUTH-PKCE]',
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

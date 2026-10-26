import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/auth_repository.dart';

// A fixed, allowlisted return URL avoids accepting arbitrary redirects from input.
const String authRedirectUrl = String.fromEnvironment(
  'AUTH_REDIRECT_URL',
  defaultValue: 'https://vedomax.web.app/',
);

AuthFailure authFailureForCode(String? code) => AuthFailure(switch (code) {
  'over_email_send_rate_limit' ||
  'over_request_rate_limit' => 'Priveľa pokusov. Počkaj a skús to neskôr.',
  'email_address_not_authorized' =>
    'Odosielanie na túto adresu nie je povolené. Správca musí nastaviť vlastné SMTP.',
  'email_not_confirmed' =>
    'Najprv potvrď registračný e-mail. Môžeš požiadať o jeho opätovné odoslanie.',
  'email_provider_disabled' => 'Prihlasovanie e-mailom je momentálne vypnuté.',
  _ =>
    'Prihlásenie alebo registrácia sa nepodarila. Skontroluj údaje a pripojenie.',
});

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this.client);
  final SupabaseClient client;
  @override
  String? get userId => client.auth.currentUser?.id;
  @override
  bool get supportsGoogle => kIsWeb; // Native redirects require platform setup.
  @override
  Stream<String?> watchUserId() async* {
    yield userId;
    yield* client.auth.onAuthStateChange.map(
      (AuthState state) => state.session?.user.id,
    );
  }

  Future<T> _request<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on AuthException catch (error) {
      // Never display raw auth responses, account data or credentials.
      throw authFailureForCode(error.code);
    }
  }

  @override
  Future<void> signIn(String email, String password) => _request(() async {
    await client.auth.signInWithPassword(email: email, password: password);
  });

  @override
  Future<bool> signUp(String email, String password) => _request(() async {
    final AuthResponse response = await client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: authRedirectUrl,
    );
    return response.session != null;
  });

  @override
  Future<bool> signInWithGoogle() => _request(() async {
    if (!supportsGoogle) {
      throw const AuthFailure(
        'Google prihlásenie je zatiaľ dostupné vo webovej verzii.',
      );
    }
    return client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: authRedirectUrl,
      // No extra scopes, offline access, or forced consent. Supabase's Google
      // provider already requests email/profile. These cannot be removed here.
      queryParams: <String, String>{'prompt': 'select_account'},
    );
  });

  @override
  Future<void> resendConfirmation(String email) => _request(() async {
    await client.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: authRedirectUrl,
    );
  });

  @override
  Future<void> signOut() => client.auth.signOut();
}

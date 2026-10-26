import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vedomax/features/auth/data/web_auth_callback.dart';
import 'package:vedomax/features/auth/domain/auth_repository.dart';
import 'package:vedomax/features/auth/presentation/auth_providers.dart';
import 'package:vedomax/features/auth/presentation/login_screen.dart';
import 'auth_test.dart' show FakeAuthRepository;

void main() {
  test('ordinary visit does not attempt token exchange', () async {
    bool exchanged = false;
    expect(
      await completeWebAuthCallback(Uri.parse('https://vedomax.web.app/'), (
        _,
      ) async {
        exchanged = true;
      }),
      isNull,
    );
    expect(exchanged, isFalse);
  });
  test('authorization code is exchanged exactly once', () async {
    int exchanges = 0;
    final Uri uri = Uri.parse('https://vedomax.web.app/?code=one-use-code');
    expect(
      await completeWebAuthCallback(uri, (Uri value) async {
        exchanges++;
        expect(value, uri);
      }),
      isNull,
    );
    expect(exchanges, 1);
  });
  test('provider error is displayed safely and does not exchange', () async {
    final Uri uri = Uri.parse(
      'https://vedomax.web.app/#error=server_error&error_code=unexpected_failure&error_description=SECRET-DATA',
    );
    final AuthFailure? failure = await completeWebAuthCallback(uri, (_) async {
      fail('must not exchange');
    });
    expect(failure?.message, contains('AUTH-LINK'));
    expect(failure?.message, isNot(contains('SECRET-DATA')));
  });
  test(
    'missing PKCE verifier is actionable without exposing server data',
    () async {
      final AuthFailure? failure = await completeWebAuthCallback(
        Uri.parse('https://vedomax.web.app/?code=private'),
        (_) async {
          throw AuthPKCEGrantCodeExchangeError('raw-private-error');
        },
      );
      expect(failure?.message, contains('AUTH-PKCE'));
      expect(failure?.message, isNot(contains('raw-private-error')));
    },
  );
  test('stalled exchange ends with a visible timeout', () async {
    final Completer<void> pending = Completer<void>();
    final AuthFailure? failure = await completeWebAuthCallback(
      Uri.parse('https://vedomax.web.app/?code=private'),
      (_) => pending.future,
      timeout: Duration.zero,
    );
    expect(failure?.message, contains('AUTH-TIMEOUT'));
    pending.complete();
  });
  testWidgets('callback failure is visible on returned login screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const MaterialApp(
          home: LoginScreen(initialMessage: 'Návrat zlyhal. [AUTH-EXCHANGE]'),
        ),
      ),
    );
    expect(find.text('Návrat zlyhal. [AUTH-EXCHANGE]'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedomax/features/auth/data/supabase_auth_repository.dart';
import 'package:vedomax/features/auth/domain/auth_repository.dart';
import 'package:vedomax/features/auth/presentation/auth_providers.dart';
import 'package:vedomax/features/auth/presentation/login_screen.dart';

class FakeAuthRepository implements AuthRepository {
  bool googleLaunched = true;
  int googleCalls = 0;
  String? resentEmail;
  @override
  String? get userId => null;
  @override
  bool get supportsGoogle => true;
  @override
  Stream<String?> watchUserId() => const Stream<String?>.empty();
  @override
  Future<bool> signInWithGoogle() async {
    googleCalls++;
    return googleLaunched;
  }

  @override
  Future<void> resendConfirmation(String email) async {
    resentEmail = email;
  }

  @override
  Future<void> signIn(String email, String password) async {}
  @override
  Future<bool> signUp(String email, String password) async => false;
  @override
  Future<void> signOut() async {}
}

Widget login(FakeAuthRepository repository) => ProviderScope(
  overrides: [authRepositoryProvider.overrideWithValue(repository)],
  child: const MaterialApp(home: LoginScreen()),
);

void main() {
  test('email delivery failures have actionable, sanitized messages', () {
    expect(
      authFailureForCode('email_address_not_authorized').message,
      contains('SMTP'),
    );
    expect(
      authFailureForCode('over_email_send_rate_limit').message,
      contains('Počkaj'),
    );
    expect(
      authFailureForCode('email_not_confirmed').message,
      contains('potvrď'),
    );
    expect(
      authFailureForCode('unknown-private-server-error').message,
      isNot(contains('unknown-private-server-error')),
    );
  });
  testWidgets('Google login does not require an email or password form', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repository = FakeAuthRepository();
    await tester.pumpWidget(login(repository));
    await tester.tap(find.text('Pokračovať cez Google'));
    await tester.pumpAndSettle();
    expect(repository.googleCalls, 1);
    expect(find.text('Zadaj e-mail a heslo s aspoň 8 znakmi.'), findsNothing);
  });
  testWidgets(
    'failed browser launch is visible instead of reporting login success',
    (WidgetTester tester) async {
      final FakeAuthRepository repository = FakeAuthRepository()
        ..googleLaunched = false;
      await tester.pumpWidget(login(repository));
      await tester.tap(find.text('Pokračovať cez Google'));
      await tester.pumpAndSettle();
      expect(
        find.text('Prihlásenie Google sa neotvorilo. Skús to znova.'),
        findsOneWidget,
      );
    },
  );
  testWidgets('resend uses the entered email without needing a password', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repository = FakeAuthRepository();
    await tester.pumpWidget(login(repository));
    await tester.enterText(find.byType(TextField).first, ' pupil@example.com ');
    await tester.ensureVisible(find.text('Poslať potvrdzovací e-mail znova'));
    await tester.tap(find.text('Poslať potvrdzovací e-mail znova'));
    await tester.pumpAndSettle();
    expect(repository.resentEmail, 'pupil@example.com');
    expect(find.textContaining('Ak účet čaká na potvrdenie'), findsOneWidget);
  });
}

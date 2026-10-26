import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedomax/features/auth/data/supabase_auth_repository.dart';
import 'package:vedomax/features/auth/domain/auth_repository.dart';
import 'package:vedomax/features/auth/presentation/auth_providers.dart';
import 'package:vedomax/features/auth/presentation/login_screen.dart';

class FakeAuthRepository implements AuthRepository {
  String? signedInEmail;
  String? signedUpEmail;
  String? resentEmail;
  @override
  String? get userId => null;
  @override
  Stream<String?> watchUserId() => const Stream<String?>.empty();
  @override
  Future<void> resendConfirmation(String email) async {
    resentEmail = email;
  }

  @override
  Future<void> signIn(String email, String password) async {
    signedInEmail = email;
  }

  @override
  Future<bool> signUp(String email, String password) async {
    signedUpEmail = email;
    return false;
  }

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
      contains('MAIL-SETUP'),
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
  testWidgets(
    'email login remains available and has no Google sign-in option',
    (WidgetTester tester) async {
      final FakeAuthRepository repository = FakeAuthRepository();
      await tester.pumpWidget(login(repository));
      expect(find.textContaining('Google'), findsNothing);
      await tester.enterText(
        find.byType(TextField).first,
        ' pupil@example.com ',
      );
      await tester.enterText(find.byType(TextField).last, 'abc123');
      await tester.ensureVisible(find.text('Prihlásiť sa'));
      await tester.tap(find.text('Prihlásiť sa'));
      await tester.pumpAndSettle();
      expect(repository.signedInEmail, 'pupil@example.com');
    },
  );
  testWidgets(
    'registration requires a strong enough password and keeps confirmation guidance',
    (WidgetTester tester) async {
      final FakeAuthRepository repository = FakeAuthRepository();
      await tester.pumpWidget(login(repository));
      await tester.enterText(find.byType(TextField).first, 'pupil@example.com');
      await tester.enterText(find.byType(TextField).last, 'abc123');
      await tester.ensureVisible(find.text('Vytvoriť účet'));
      await tester.tap(find.text('Vytvoriť účet'));
      await tester.pumpAndSettle();
      expect(repository.signedUpEmail, isNull);
      await tester.enterText(find.byType(TextField).last, 'abc12345');
      await tester.ensureVisible(find.text('Vytvoriť účet'));
      await tester.tap(find.text('Vytvoriť účet'));
      await tester.pumpAndSettle();
      expect(repository.signedUpEmail, 'pupil@example.com');
      expect(
        find.textContaining('Registráciu dokončíš potvrdením e-mailu'),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';
import '../domain/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  String? _message;
  Future<void> _authenticate(bool register) async {
    if (!_email.text.trim().contains('@') ||
        _password.text.isEmpty ||
        (register && _password.text.length < 8)) {
      setState(
        () => _message = register
            ? 'Zadaj e-mail a heslo s aspoň 8 znakmi.'
            : 'Zadaj platný e-mail a heslo.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final AuthRepository repository = ref.read(authRepositoryProvider);
      if (register) {
        final bool signedIn = await repository.signUp(
          _email.text.trim(),
          _password.text,
        );
        if (mounted && !signedIn) {
          setState(() => _message = 'Skontroluj e-mail a potvrď registráciu.');
        }
      } else {
        await repository.signIn(_email.text.trim(), _password.text);
      }
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on Object {
      if (mounted) {
        setState(
          () => _message =
              'Prihlásenie sa nepodarilo. Skontroluj údaje a pripojenie.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final bool launched = await ref
          .read(authRepositoryProvider)
          .signInWithGoogle();
      if (mounted && !launched) {
        setState(
          () => _message = 'Prihlásenie Google sa neotvorilo. Skús to znova.',
        );
      }
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on Object {
      if (mounted) {
        setState(
          () => _message =
              'Google prihlásenie sa nepodarilo spustiť. Skús to znova.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    final String email = _email.text.trim();
    if (!email.contains('@') || email.endsWith('@')) {
      setState(() => _message = 'Najprv zadaj svoj e-mail.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref.read(authRepositoryProvider).resendConfirmation(email);
      if (mounted) {
        setState(
          () => _message =
              'Ak účet čaká na potvrdenie, e-mail bude odoslaný. Skontroluj aj spam.',
        );
      }
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on Object {
      if (mounted) {
        setState(
          () => _message = 'E-mail sa nepodarilo odoslať. Skús to neskôr.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Vedomax • Prihlásenie')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: <Widget>[
              const Text('Uč sa. Hraj sa. Napreduj.'),
              const SizedBox(height: 24),
              if (ref.watch(authRepositoryProvider).supportsGoogle) ...<Widget>[
                OutlinedButton.icon(
                  onPressed: _busy ? null : _google,
                  icon: const Icon(Icons.login),
                  label: const Text('Pokračovať cez Google'),
                ),
                const Text(
                  'Google odovzdá Supabase e-mail a základný profil, napríklad meno a fotografiu. Herný profil používa prezývku.',
                ),
                const SizedBox(height: 20),
              ],
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const <String>[AutofillHints.email],
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
              TextField(
                controller: _password,
                obscureText: true,
                autofillHints: const <String>[AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Heslo'),
              ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_message!),
                ),
              FilledButton(
                onPressed: _busy ? null : () => _authenticate(false),
                child: const Text('Prihlásiť sa'),
              ),
              TextButton(
                onPressed: _busy ? null : () => _authenticate(true),
                child: const Text('Vytvoriť účet'),
              ),
              TextButton(
                onPressed: _busy ? null : _resend,
                child: const Text('Poslať potvrdzovací e-mail znova'),
              ),
              const Text(
                'Používaj prezývku. Registráciu a pravidlá ochrany údajov preber so zákonným zástupcom.',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

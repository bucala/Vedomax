import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';
import '../domain/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.initialMessage});
  final String? initialMessage;
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _message = widget.initialMessage;
  }

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
          setState(
            () => _message =
                'Registráciu dokončíš potvrdením e-mailu. Ak neprišiel, skontroluj spam alebo skús opätovné odoslanie.',
          );
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

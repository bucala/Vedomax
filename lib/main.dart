import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/app_store.dart';
import 'screens/home_screen.dart';
import 'widgets/game_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  SupabaseClient? client;
  String? bootError;
  if (url.isNotEmpty && key.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: url,
        publishableKey: key,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      client = Supabase.instance.client;
    } catch (_) {
      bootError =
          'Pripojenie k účtom sa nepodarilo inicializovať. Zatiaľ môžeš pokračovať bez účtu.';
    }
  }
  try {
    final store = AppStore(
      await SharedPreferences.getInstance(),
      client: client,
    );
    await store.initialize();
    runApp(VedomaxApp(store: store, bootError: bootError));
  } catch (_) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Aplikáciu sa nepodarilo načítať. Obnov stránku a skontroluj dostupnosť úložiska.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VedomaxApp extends StatefulWidget {
  const VedomaxApp({super.key, required this.store, this.bootError});
  final AppStore store;
  final String? bootError;
  @override
  State<VedomaxApp> createState() => _VedomaxAppState();
}

class _VedomaxAppState extends State<VedomaxApp> {
  StreamSubscription<AuthState>? subscription;
  @override
  void initState() {
    super.initState();
    subscription = widget.store.client?.auth.onAuthStateChange.listen(
      (_) => widget.store.refreshProfile(),
      onError: (Object _) {
        widget.store.syncError =
            'Prihlásenie sa nepodarilo obnoviť. Skús sa prihlásiť znova.';
        widget.store.refreshProfile();
      },
    );
    // Subscribe first, then re-read the session in case it changed during asset loading.
    unawaited(widget.store.refreshProfile());
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vedomax – Vedomosti na Maximum',
      locale: const Locale('sk'),
      supportedLocales: const [Locale('sk')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      themeMode: widget.store.theme,
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            disableAnimations:
                widget.store.reducedMotion || media.disableAnimations,
          ),
          child: child!,
        );
      },
      home: HomeScreen(store: widget.store, bootError: widget.bootError),
    ),
  );
}

ThemeData appTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final cs = ColorScheme.fromSeed(
    seedColor: teal,
    brightness: brightness,
    primary: dark ? const Color(0xff62d6c2) : teal,
    secondary: violet,
    surface: dark ? const Color(0xff19282e) : Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: dark
        ? const Color(0xff102027)
        : const Color(0xfff5f7f6),
    fontFamily: 'Roboto',
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xff102027) : const Color(0xfff5f7f6),
      surfaceTintColor: Colors.transparent,
    ),
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
      fontFamily: 'Roboto',
      bodyColor: dark ? const Color(0xffe4efed) : const Color(0xff1b353b),
      displayColor: dark ? const Color(0xffe4efed) : const Color(0xff1b353b),
    ),
    dividerColor: dark ? Colors.white : const Color(0xff577575),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cs.surface,
      indicatorColor: teal.withValues(alpha: .12),
    ),
  );
}

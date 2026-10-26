import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/presentation/auth_providers.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/profile/presentation/profile_providers.dart';
import 'features/learning/domain/lesson.dart';
import 'features/learning/presentation/gameplay_controller.dart';
import 'features/learning/presentation/lesson_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!demoMode) {
    const String url = String.fromEnvironment('SUPABASE_URL');
    const String key = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (url.isEmpty || key.isEmpty) {
      runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('Chýba konfigurácia Supabase. Pozri README.'))))); return;
    }
    await Supabase.initialize(url: url, publishableKey: key);
  }
  runApp(const ProviderScope(child: VedomaxApp()));
}
class VedomaxApp extends StatelessWidget {
  const VedomaxApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(title: 'Vedomax', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff6750a4)), useMaterial3: true),
    darkTheme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffa6e55c), brightness: Brightness.dark), useMaterial3: true),
    home: const AuthGate());
}
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (demoMode) return const Dashboard();
    return ref.watch(authStateProvider).when(data: (String? id) => id == null ? const LoginScreen() : Dashboard(key: ValueKey<String>(id)), loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())), error: (Object error, StackTrace stack) => const LoginScreen());
  }
}
class Dashboard extends ConsumerWidget {
  const Dashboard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Vedomax'), actions: <Widget>[if (!demoMode) IconButton(tooltip: 'Odhlásiť sa', onPressed: () async { await ref.read(authRepositoryProvider).signOut(); ref.invalidate(lessonsProvider); }, icon: const Icon(Icons.logout))]),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 700), child: ListView(padding: const EdgeInsets.all(24), children: <Widget>[
      Text('Tvoja ďalšia misia čaká', style: Theme.of(context).textTheme.headlineMedium),
      if (demoMode) const Text('DEMO • Bez účtu • XP sa neukladá') else ref.watch(profileProvider).when(data: (profile) => Text('${profile?.username ?? ''} • ${profile?.xp ?? 0} XP • séria ${profile?.streak ?? 0} dní'), loading: () => const LinearProgressIndicator(), error: (Object e, StackTrace s) => TextButton(onPressed: () => ref.invalidate(profileProvider), child: const Text('Znovu načítať profil'))),
      const SizedBox(height: 20), const Text('Ukážkové učivo • overenie podľa iŠVP ešte prebieha'),
      ref.watch(lessonsProvider).when(data: (List<Lesson> lessons) => Column(children: lessons.map((Lesson lesson) => Card(child: ListTile(contentPadding: const EdgeInsets.all(16), leading: const CircleAvatar(child: Icon(Icons.bolt)), title: Text(lesson.title), subtitle: Text('${lesson.seconds} sekúnd • herná výzva'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (BuildContext context) => LessonScreen(lesson: lesson)))))).toList()), loading: () => const LinearProgressIndicator(), error: (Object e, StackTrace s) => TextButton(onPressed: () => ref.invalidate(lessonsProvider), child: const Text('Lekcie sa nenačítali. Skúsiť znova.'))),
    ]))));
}

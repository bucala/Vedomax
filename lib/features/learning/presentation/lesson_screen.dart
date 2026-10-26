import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../domain/lesson.dart';
import 'gameplay_controller.dart';
import 'widgets/mechanics.dart';
class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key, required this.lesson});
  final Lesson lesson;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GameState game = ref.watch(gameplayProvider(lesson));
    final GameplayController controller = ref.read(gameplayProvider(lesson).notifier);
    Widget body;
    switch (game.phase) {
      case GamePhase.loading:
      case GamePhase.submitting:
        body = const Center(child: CircularProgressIndicator());
      case GamePhase.error:
        body = Column(children: <Widget>[Text(game.message!), FilledButton(onPressed: () => ref.invalidate(gameplayProvider(lesson)), child: const Text('Skúsiť znova'))]);
      case GamePhase.finished:
        body = Column(children: <Widget>[
          if (game.animationTrigger > 0) Lottie.asset(lesson.animation, repeat: false, height: 180, animate: !MediaQuery.of(context).disableAnimations, errorBuilder: (BuildContext context, Object error, StackTrace? stack) => const Icon(Icons.celebration, size: 90)),
          Text(game.score == 100 ? 'Výborne! Misia splnená.' : 'Ešte kúsok tréningu!', style: Theme.of(context).textTheme.headlineSmall),
          Text('Skóre: ${game.score} % • +${game.xp} XP${demoMode ? ' (demo)' : ''}'),
          const SizedBox(height: 20), FilledButton(onPressed: () => ref.invalidate(gameplayProvider(lesson)), child: const Text('Zopakovať')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Späť na predmety')),
        ]);
      case GamePhase.playing:
        final Question question = lesson.questions[game.index];
        final Widget mechanic = switch (question.mechanic) {
          'puzzle_calc' => PuzzleCalc(key: ValueKey<String>(question.id), question: question, onAnswer: controller.answer),
          'detective' => DetectiveMode(key: ValueKey<String>(question.id), question: question, onAnswer: controller.answer),
          'geo_click' => GeoClick(key: ValueKey<String>(question.id), question: question, onAnswer: controller.answer),
          _ => const Text('Táto mechanika bude dostupná v ďalšej verzii.'),
        };
        body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
          Text('Otázka ${game.index+1}/${lesson.questions.length} • ${game.remaining} s'),
          const SizedBox(height: 8), LinearProgressIndicator(value: game.remaining / lesson.seconds),
          const SizedBox(height: 24), Text(question.text, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24), mechanic,
        ]);
    }
    return Scaffold(appBar: AppBar(title: Text(lesson.title)), body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: KeyedSubtree(key: ValueKey<GamePhase>(game.phase), child: body))))));
  }
}

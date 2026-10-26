import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../profile/presentation/profile_providers.dart';
import '../data/learning_repositories.dart';
import '../domain/lesson.dart';
const bool demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: true);
final learningRepositoryProvider = Provider<LearningRepository>((Ref ref) => demoMode ? DemoLearningRepository() : SupabaseLearningRepository(ref.watch(supabaseProvider)));
final lessonsProvider = FutureProvider<List<Lesson>>((Ref ref) => ref.watch(learningRepositoryProvider).lessons());
enum GamePhase { loading, playing, submitting, finished, error }
class GameState {
  const GameState({this.phase = GamePhase.loading, this.index = 0, this.remaining = 0, this.score = 0, this.xp = 0, this.animationTrigger = 0, this.message});
  final GamePhase phase;
  final int index, remaining, score, xp, animationTrigger;
  final String? message;
}
final gameplayProvider = StateNotifierProvider.autoDispose.family<GameplayController, GameState, Lesson>((Ref ref, Lesson lesson) => GameplayController(lesson, ref.watch(learningRepositoryProvider), () { if (!demoMode) ref.invalidate(profileProvider); }));
class GameplayController extends StateNotifier<GameState> {
  GameplayController(this.lesson, this.repository, this.onSync) : super(const GameState()) { unawaited(_start()); }
  final Lesson lesson;
  final LearningRepository repository;
  final void Function() onSync;
  final Map<String, Object> _answers = <String, Object>{};
  Timer? _timer;
  DateTime? _deadline;
  Future<void> _start() async {
    try {
      if (lesson.questions.isEmpty) throw StateError('Empty lesson');
      _deadline = await repository.begin(lesson.id);
      if (!mounted) return;
      _timer = Timer.periodic(const Duration(milliseconds: 250), (Timer timer) => _tick());
      _tick();
    } on Object {
      if (mounted) state = const GameState(phase: GamePhase.error, message: 'Lekciu sa nepodarilo spustiť. Skontroluj pripojenie a skús znova.');
    }
  }
  void _tick() {
    if (!mounted || state.phase == GamePhase.submitting || state.phase == GamePhase.finished) return;
    final int remaining = ((_deadline!.difference(DateTime.now()).inMilliseconds) / 1000).ceil().clamp(0, lesson.seconds);
    state = GameState(phase: GamePhase.playing, index: state.index, remaining: remaining);
    if (remaining == 0) { _timer?.cancel(); state = const GameState(phase: GamePhase.error, message: 'Čas vypršal. Skús lekciu ešte raz.'); }
  }
  Future<void> answer(Object answer) async {
    if (state.phase != GamePhase.playing || state.remaining == 0) return;
    _answers[lesson.questions[state.index].id] = answer;
    if (state.index + 1 < lesson.questions.length) {
      state = GameState(phase: GamePhase.playing, index: state.index + 1, remaining: state.remaining);
      return;
    }
    _timer?.cancel();
    state = GameState(phase: GamePhase.submitting, index: state.index);
    try {
      final LessonResult result = await repository.submit(lesson.id, _answers);
      if (!mounted) return;
      onSync();
      state = GameState(phase: GamePhase.finished, score: result.score, xp: result.xp, animationTrigger: result.score == 100 ? 1 : 0);
    } on Object {
      if (mounted) state = const GameState(phase: GamePhase.error, message: 'Výsledok sa nepotvrdil. Skontroluj pripojenie a reštartuj lekciu.');
    }
  }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
}

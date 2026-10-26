import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/learning.dart';
import '../services/app_store.dart';
import '../widgets/game_widgets.dart';
import '../widgets/motion.dart';

enum LessonPhase {
  loading,
  question,
  submitting,
  feedback,
  points,
  saving,
  finished,
  error,
}

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lesson, required this.store});
  final DailyLesson lesson;
  final AppStore store;
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  LessonPhase phase = LessonPhase.loading;
  int index = 0, awarded = 0;
  Object? selected;
  String? error;
  final input = TextEditingController();
  final List<AnswerFeedback> results = [];
  late final String? owner = widget.store.userId;
  Question get question => widget.lesson.questions[index];
  bool get canAnswer => question.kind == QuestionKind.number
      ? parseAnswer(input.text) != null
      : selected != null;
  @override
  void initState() {
    super.initState();
    start();
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  bool get sameOwner => owner == widget.store.userId;
  Future<void> start() async {
    setState(() {
      phase = LessonPhase.loading;
      error = null;
      index = 0;
      selected = null;
      results.clear();
      input.clear();
    });
    try {
      await widget.store.begin(widget.lesson);
      if (mounted) setState(() => phase = LessonPhase.question);
    } catch (_) {
      if (mounted) {
        setState(() {
          phase = LessonPhase.error;
          error =
              'Lekciu sa nepodarilo spustiť. Skontroluj pripojenie a pripravenosť denného plánu na serveri.';
        });
      }
    }
  }

  Future<void> check() async {
    if (phase != LessonPhase.question || !canAnswer) return;
    if (!sameOwner) {
      setState(() {
        phase = LessonPhase.error;
        error = 'Účet sa zmenil. Vráť sa do menu a otvor lekciu znova.';
      });
      return;
    }
    final answer = question.kind == QuestionKind.number
        ? parseAnswer(input.text)!
        : selected!;
    setState(() {
      phase = LessonPhase.submitting;
      error = null;
    });
    try {
      final feedback = await widget.store.answer(
        widget.lesson,
        question,
        answer,
      );
      if (!mounted) return;
      if (widget.store.haptics) HapticFeedback.lightImpact();
      setState(() {
        results.add(feedback);
        phase = LessonPhase.feedback;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          phase = LessonPhase.question;
          error =
              'Odpoveď sa nepodarilo overiť. Skontroluj pripojenie a odošli ju znova.';
        });
      }
    }
  }

  Future<void> next() async {
    if (index < widget.lesson.questions.length - 1) {
      setState(() {
        index++;
        selected = null;
        input.clear();
        phase = LessonPhase.question;
      });
      return;
    }
    await save();
  }

  Future<void> save() async {
    if (!sameOwner) {
      setState(() {
        phase = LessonPhase.error;
        error = 'Účet sa zmenil. Výsledok nemožno uložiť.';
      });
      return;
    }
    setState(() {
      phase = LessonPhase.saving;
      error = null;
    });
    try {
      final xp = await widget.store.completeLesson(widget.lesson, results);
      if (mounted) {
        setState(() {
          awarded = xp;
          phase = LessonPhase.finished;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          phase = LessonPhase.saving;
          error =
              'Výsledok sa nepodarilo uložiť. Odpovede ostali pripravené, skús uloženie znova.';
        });
      }
    }
  }

  Future<bool> confirmExit() async {
    if (phase == LessonPhase.finished) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Opustiť rozpracovanú lekciu?'),
            content: const Text(
              'Tento pokus sa neuloží. Dokončené lekcie ostanú zachované.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Pokračovať v učení'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Opustiť'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final feedback = results.isEmpty ? null : results.last;
    return PopScope(
      canPop: phase == LessonPhase.finished,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await confirmExit() && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Späť do menu',
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              if (await confirmExit() && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            widget.lesson.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(
                child: Text(
                  '${index + 1} / 4',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                children: [
                  if (phase != LessonPhase.finished) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value:
                            (index + (phase == LessonPhase.points ? 1 : 0)) / 4,
                        minHeight: 10,
                        color: teal,
                        backgroundColor: cs.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (phase == LessonPhase.loading ||
                      phase == LessonPhase.submitting)
                    const Padding(
                      padding: EdgeInsets.all(80),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (phase == LessonPhase.error)
                    Panel(
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 48),
                          const SizedBox(height: 20),
                          Text(error!),
                          const SizedBox(height: 24),
                          GameButton(label: 'Spustiť znova', onPressed: start),
                        ],
                      ),
                    ),
                  if (phase == LessonPhase.question ||
                      phase == LessonPhase.feedback) ...[
                    Text(
                      '${widget.lesson.subject == 'math'
                          ? 'MATEMATIKA'
                          : widget.lesson.subject == 'slovak'
                          ? 'SLOVENČINA'
                          : 'GEOGRAFIA'}  •  DEŇ ${widget.lesson.day}',
                      style: const TextStyle(
                        color: teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      question.prompt,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (question.kind == QuestionKind.choice)
                      ...question.options.asMap().entries.map((entry) {
                        final revealed = phase == LessonPhase.feedback;
                        final correct =
                            revealed && feedback!.correctIndex == entry.key;
                        final wrong =
                            revealed && selected == entry.key && !correct;
                        final border = correct
                            ? teal
                            : wrong
                            ? Colors.deepOrange
                            : selected == entry.key
                            ? violet
                            : cs.outlineVariant;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Semantics(
                            selected: selected == entry.key,
                            child: AnimatedScale(
                              scale:
                                  selected == entry.key &&
                                      !widget.store.reducedMotion &&
                                      !MediaQuery.disableAnimationsOf(context)
                                  ? 1.012
                                  : 1,
                              duration: motionDuration(context, 160),
                              child: OutlinedButton(
                                onPressed: revealed
                                    ? null
                                    : () =>
                                          setState(() => selected = entry.key),
                                style: OutlinedButton.styleFrom(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.all(18),
                                  foregroundColor: cs.onSurface,
                                  disabledForegroundColor: cs.onSurface,
                                  side: BorderSide(color: border, width: 2),
                                  backgroundColor: correct
                                      ? teal.withValues(alpha: .1)
                                      : selected == entry.key
                                      ? violet.withValues(alpha: .08)
                                      : null,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: border),
                                      ),
                                      child: correct
                                          ? const Icon(Icons.check, size: 18)
                                          : Text('${entry.key + 1}'),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    if (question.kind == QuestionKind.number)
                      TextField(
                        controller: input,
                        enabled: phase == LessonPhase.question,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Tvoja odpoveď',
                          suffixText: question.unit,
                          hintText: 'Číslo, napr. −2 alebo 3,14',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => check(),
                      ),
                    if (question.kind == QuestionKind.map)
                      LearningMap(
                        region: question.region,
                        polygons: widget.store.polygons,
                        highlight: question.region == 'sk'
                            ? widget.store.slovakiaPolygons
                            : const [],
                        point: selected as GeoPoint?,
                        target: phase == LessonPhase.feedback
                            ? feedback!.target
                            : null,
                        targetName: question.solution,
                        onChanged: phase == LessonPhase.question
                            ? (p) => setState(() => selected = p)
                            : null,
                      ),
                    if (phase == LessonPhase.question) ...[
                      const SizedBox(height: 24),
                      GameButton(
                        label: 'Skontrolovať odpoveď',
                        icon: Icons.check_rounded,
                        onPressed: canAnswer ? check : null,
                      ),
                      if (question.kind == QuestionKind.map)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            '100 bodov do ${question.fullCreditKm.round()} km. Potom body plynulo klesajú na 0 pri ${question.zeroCreditKm.round()} km.',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                    if (phase == LessonPhase.feedback) ...[
                      const SizedBox(height: 24),
                      Panel(
                        color: teal.withValues(alpha: .09),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: teal,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Najprv si pozri riešenie',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Správna odpoveď: ${feedback!.solution}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              feedback.explanation,
                              style: const TextStyle(height: 1.5),
                            ),
                            if (feedback.distance != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  'Vzdialenosť od cieľa: ${feedback.distance!.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      GameButton(
                        label: 'Zobraziť body',
                        icon: Icons.auto_awesome_rounded,
                        onPressed: () =>
                            setState(() => phase = LessonPhase.points),
                      ),
                    ],
                  ],
                  if (phase == LessonPhase.points && feedback != null)
                    CelebrationBurst(
                      enabled:
                          feedback.points == 100 && !widget.store.reducedMotion,
                      child: Panel(
                        child: Column(
                          children: [
                            Mascot(
                              size: 160,
                              animated: !widget.store.reducedMotion,
                              motion: feedback.points == 100
                                  ? MascotMotion.celebrate
                                  : MascotMotion.idle,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              feedback.points == 100
                                  ? 'Výborne, máš to!'
                                  : feedback.points > 0
                                  ? 'Dobrý smer!'
                                  : 'Každá otázka ťa posúva.',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            CountUp(
                              value: feedback.points,
                              suffix: ' / 100 bodov',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: teal,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: feedback.points / 100,
                              ),
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 900),
                              builder: (_, v, _) => LinearProgressIndicator(
                                value: v,
                                minHeight: 12,
                                color: teal,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const SizedBox(height: 28),
                            GameButton(
                              label: index == 3
                                  ? 'Dokončiť oblasť'
                                  : 'Ďalšia otázka',
                              icon: Icons.arrow_forward_rounded,
                              onPressed: next,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (phase == LessonPhase.saving)
                    Panel(
                      child: Column(
                        children: [
                          if (error == null) ...[
                            const CircularProgressIndicator(),
                            const SizedBox(height: 20),
                            const Text('Ukladám tvoj pokrok…'),
                          ] else ...[
                            Text(error!),
                            const SizedBox(height: 20),
                            GameButton(label: 'Uložiť znova', onPressed: save),
                          ],
                        ],
                      ),
                    ),
                  if (phase == LessonPhase.finished)
                    CelebrationBurst(
                      enabled: !widget.store.reducedMotion,
                      child: Panel(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.emoji_events_rounded,
                              color: amber,
                              size: 64,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Oblasť dokončená!',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('Štyri otázky. O kúsok viac vedomostí.'),
                            const SizedBox(height: 24),
                            CountUp(
                              value: results.fold<int>(
                                0,
                                (s, r) => s + r.points,
                              ),
                              suffix: ' / 400 bodov',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: teal,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '+$awarded XP',
                              style: const TextStyle(
                                fontSize: 22,
                                color: violet,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (awarded == 0)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'XP získaš pri zlepšení svojho najlepšieho výsledku.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            const SizedBox(height: 24),
                            GameButton(
                              label: 'Späť do hlavného menu',
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: start,
                              child: const Text('Precvičiť ešte raz'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (error != null && phase == LessonPhase.question)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(error!, style: TextStyle(color: cs.error)),
                    ),
                  const SizedBox(height: 24),
                  if (phase == LessonPhase.question ||
                      phase == LessonPhase.feedback)
                    Text(
                      '${question.topic} · ${question.section}',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedomax/main.dart';
import 'package:vedomax/features/learning/data/learning_repositories.dart';
import 'package:vedomax/features/learning/domain/lesson.dart';
import 'package:vedomax/features/learning/presentation/gameplay_controller.dart';

class FailingRepository extends DemoLearningRepository {
  @override
  Future<LessonResult> submit(int lessonId, Map<String, Object> answers) => Future<LessonResult>.error(StateError('offline'));
}
void main() {
  test('math grading rejects wrong answers and accepts decimal tolerance', () async {
    final DemoLearningRepository repository = DemoLearningRepository();
    expect((await repository.submit(1, <String,Object>{'math': 4})).score, 0);
    expect((await repository.submit(1, <String,Object>{'math': 5.005})).score, 100);
  });
  test('detective requires exactly both errors', () async {
    final DemoLearningRepository repository = DemoLearningRepository();
    expect((await repository.submit(2, <String,Object>{'detective': <int>[1,5]})).score, 100);
    expect((await repository.submit(2, <String,Object>{'detective': <int>[1,5,0]})).score, 0);
  });
  test('geography uses normalized coordinates and rejects remote taps', () async {
    final DemoLearningRepository repository = DemoLearningRepository();
    expect((await repository.submit(3, <String,Object>{'geo': <String,double>{'x':.307,'y':.424}})).score, 100);
    expect((await repository.submit(3, <String,Object>{'geo': <String,double>{'x':.9,'y':.9}})).score, 0);
  });
  test('controller finishes, emits animation and blocks duplicate submissions', () async {
    final GameplayController controller = GameplayController(demoLessons.first, DemoLearningRepository(), () {});
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.phase, GamePhase.playing);
    await controller.answer(5.0);
    expect(controller.state.score,100);
    expect(controller.state.animationTrigger,1);
    await controller.answer(2.0);
    expect(controller.state.score,100);
  });
  test('sync failure is visible, never reported as success', () async {
    final GameplayController controller = GameplayController(demoLessons.first, FailingRepository(), () {});
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);
    await controller.answer(5.0);
    expect(controller.state.phase,GamePhase.error);
    expect(controller.state.animationTrigger,0);
  });
  testWidgets('demo navigation and successful rescue', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VedomaxApp()));
    await tester.pumpAndSettle();
    expect(find.text('DEMO • Bez účtu • XP sa neukladá'), findsOneWidget);
    expect(find.text('Prihlásiť sa'), findsNothing);
    expect(find.text('Vytvoriť účet'), findsNothing);
    expect(find.text('Slovenčina • Vetriť chybu'), findsOneWidget);
    expect(find.text('Geografia • Slepá mapa'), findsOneWidget);
    await tester.tap(find.text('Matematika • Zachráň prieskumníka'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '5');
    await tester.ensureVisible(find.text('Zachrániť prieskumníka'));
    await tester.tap(find.text('Zachrániť prieskumníka'));
    await tester.pumpAndSettle();
    expect(find.text('Výborne! Misia splnená.'), findsOneWidget);
  });
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedomax/models/learning.dart';
import 'package:vedomax/services/app_store.dart';
import 'package:vedomax/widgets/game_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('streak uses Bratislava midnight rather than UTC midnight', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var now = DateTime.utc(2026, 10, 26, 22, 30);
    final store = AppStore(prefs, now: () => now);
    await store.initialize();
    final lesson = store.lessons.first;
    final good = lesson.questions.map((q) => q.grade(q.answer!)).toList();
    await store.completeLesson(lesson, good);
    expect(store.profile.streak, 1);
    now = DateTime.utc(2026, 10, 26, 23, 30);
    await store.completeLesson(lesson, good);
    expect(store.profile.streak, 2);
    now = DateTime.utc(2026, 10, 30);
    await store.refreshProfile();
    expect(store.profile.streak, 0);
  });
  test('14 days x 3 areas x 4 questions separately for both grades', () {
    final json = jsonDecode(
      File('assets/content/fortnight.json').readAsStringSync(),
    );
    final lessons = (json['lessons'] as List)
        .map((j) => DailyLesson.fromJson(j))
        .toList();
    expect(lessons.length, 84);
    final ids = <String>{};
    for (final grade in [8, 9]) {
      for (var day = 1; day <= 14; day++) {
        final daily = lessons
            .where((l) => l.grade == grade && l.day == day)
            .toList();
        expect(daily.map((l) => l.subject).toSet(), {'math', 'slovak', 'geo'});
        for (final lesson in daily) {
          expect(lesson.questions.length, 4);
          for (final q in lesson.questions) {
            expect(ids.add(q.id), isTrue);
            expect(q.explanation, isNotEmpty);
            expect(q.source, startsWith('https://www.minedu.sk/'));
            if (q.kind == QuestionKind.map) {
              expect(q.grade(q.target!).points, 100);
              expect(q.zeroCreditKm, greaterThan(q.fullCreditKm));
              final view = MapViewport.region(q.region);
              expect(q.target!.lat, inInclusiveRange(view.south, view.north));
              expect(q.target!.lon, inInclusiveRange(view.west, view.east));
            } else {
              expect(q.grade(q.answer!).points, 100);
              expect(q.grade(q.answer! + 10000).points, 0);
              if (q.kind == QuestionKind.choice) {
                expect(q.options.toSet().length, 3);
                expect(q.options[q.answer!.toInt()], q.solution);
              }
            }
          }
        }
      }
    }
    expect(ids.length, 336);
  });
  test('numeric parsing accepts negative/decimal comma but rejects junk', () {
    expect(parseAnswer('-2,5'), -2.5);
    expect(parseAnswer(' 5.0 '), 5);
    for (final value in [
      '5abc',
      '5,2,3',
      'NaN',
      'Infinity',
      '',
      '1e999',
      '--2',
    ]) {
      expect(parseAnswer(value), isNull);
    }
  });
  test('distance scoring is continuous, bounded and geodesic', () {
    expect(
      distanceKm(const GeoPoint(0, 0), const GeoPoint(0, 1)),
      closeTo(111.195, 0.01),
    );
    expect(mapPoints(0, 10, 250), 100);
    expect(mapPoints(10, 10, 250), 100);
    expect(mapPoints(130, 10, 250), 50);
    expect(mapPoints(250, 10, 250), 0);
    expect(mapPoints(10000, 10, 250), 0);
  });
  test(
    'guest saves best scores, avoids XP farming and restores settings',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AppStore(prefs);
      await store.initialize();
      final lesson = store.lessons.first;
      final good = lesson.questions.map((q) => q.grade(q.answer!)).toList();
      expect(await store.completeLesson(lesson, good), 100);
      expect(await store.completeLesson(lesson, good), 0);
      expect(store.profile.xp, 100);
      expect(store.profile.streak, 1);
      await store.setting('grade', 9);
      await store.setting('theme', 2);
      await store.setting('reduced_motion', true);
      final restored = AppStore(prefs);
      await restored.initialize();
      expect(restored.grade, 9);
      expect(restored.theme.index, 2);
      expect(restored.reducedMotion, isTrue);
      expect(restored.best(lesson.id), 100);
      expect(restored.completed(lesson.id), isTrue);
      expect(restored.profile.visible, isFalse);
      expect(
        restored.lessons.where((l) => l.day == 14 && l.grade == 9).length,
        3,
      );
    },
  );
}

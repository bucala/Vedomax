import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedomax/main.dart';
import 'package:vedomax/services/app_store.dart';
import 'package:vedomax/screens/lesson_screen.dart';
import 'package:vedomax/widgets/animated_mascot.dart';

Future<AppStore> loadStore() async {
  SharedPreferences.setMockInitialValues({'v2_reduced_motion': true});
  final store = AppStore(await SharedPreferences.getInstance());
  await store.initialize();
  return store;
}

void main() {
  testWidgets(
    'day selector changes the lesson and the whole subject card opens it',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = (await tester.runAsync(loadStore))!;
      await tester.pumpWidget(VedomaxApp(store: store));
      await tester.pumpAndSettle();
      final day = find.byKey(const ValueKey('day-2'));
      await tester.ensureVisible(day);
      await tester.pumpAndSettle();
      await tester.tap(day);
      await tester.pumpAndSettle();
      expect(find.text('Racionálne čísla'), findsOneWidget);
      await tester.ensureVisible(find.text('Racionálne čísla'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Racionálne čísla'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          store.lessons
              .firstWhere(
                (l) => l.grade == 8 && l.day == 2 && l.subject == 'math',
              )
              .questions
              .first
              .prompt,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('choice answer reveals correct option before scoring', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = (await tester.runAsync(loadStore))!;
    final lesson = store.lessons.firstWhere((l) => l.subject == 'slovak');
    final q = lesson.questions.first;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: appTheme(Brightness.light),
        home: LessonScreen(lesson: lesson, store: store),
      ),
    );
    await tester.pumpAndSettle();
    final wrong = q.options.firstWhere((s) => s != q.solution);
    await tester.tap(find.text(wrong));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skontrolovať odpoveď'));
    await tester.pumpAndSettle();
    expect(find.text('Správna odpoveď: ${q.solution}'), findsOneWidget);
    expect(find.text('0 / 100 bodov'), findsNothing);
    await tester.tap(find.text('Zobraziť body'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 100 bodov'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('desktop menu renders without overflow', (tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = (await tester.runAsync(loadStore))!;
    await tester.pumpWidget(VedomaxApp(store: store));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/brand/vedomax-v.png'),
        tester.element(find.byType(MaterialApp)),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage(Mascot.still),
        tester.element(find.byType(MaterialApp)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ahoj, Prieskumník!'), findsOneWidget);
    expect(
      find.text('Vedomax - Vedomosti na Maximum pre všetky deti'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_desktop.png'),
    );
  });
  testWidgets('mobile layout and settings are functional', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = (await tester.runAsync(loadStore))!;
    await tester.pumpWidget(VedomaxApp(store: store));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_mobile.png'),
    );
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Nastav si vlastné tempo'), findsOneWidget);
    await tester.tap(find.text('9. ročník'));
    await tester.pumpAndSettle();
    expect(store.grade, 9);
    expect(tester.takeException(), isNull);
    await store.setting('theme', 2);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/settings_dark_mobile.png'),
    );
  });
  testWidgets(
    'solution is shown before points and lesson completion persists',
    (tester) async {
      final store = (await tester.runAsync(loadStore))!;
      final lesson = store.lessons.first;
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appTheme(Brightness.light),
          home: LessonScreen(lesson: lesson, store: store),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        await tester.enterText(
          find.byType(TextField),
          '${lesson.questions[i].answer}',
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Skontrolovať odpoveď'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Skontrolovať odpoveď'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.textContaining('Správna odpoveď:'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.textContaining('Správna odpoveď:'), findsOneWidget);
        expect(find.text('100 / 100 bodov'), findsNothing);
        await tester.ensureVisible(find.text('Zobraziť body'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Zobraziť body'));
        await tester.pumpAndSettle();
        expect(find.text('100 / 100 bodov'), findsOneWidget);
        final next = i == 3 ? 'Dokončiť oblasť' : 'Ďalšia otázka';
        await tester.ensureVisible(find.text(next));
        await tester.pumpAndSettle();
        await tester.tap(find.text(next));
        await tester.pumpAndSettle();
      }
      expect(find.text('Oblasť dokončená!'), findsOneWidget);
      expect(store.profile.xp, 100);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('map reveals target and distance only after confirming', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(860, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = (await tester.runAsync(loadStore))!;
    final lesson = store.lessons.firstWhere((l) => l.subject == 'geo');
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: appTheme(Brightness.light),
        home: LessonScreen(lesson: lesson, store: store),
      ),
    );
    await tester.pumpAndSettle();
    final map = find.byKey(const Key('learning-map'));
    await tester.ensureVisible(map);
    await tester.pumpAndSettle();
    await tester.tap(map);
    await tester.pumpAndSettle();
    expect(find.text('Správna odpoveď: Bratislava'), findsNothing);
    await tester.ensureVisible(find.text('Skontrolovať odpoveď'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skontrolovať odpoveď'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Správna odpoveď: Bratislava'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Správna odpoveď: Bratislava'), findsOneWidget);
    expect(find.textContaining('Vzdialenosť od cieľa:'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Zobraziť body'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Zobraziť body'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/map_feedback.png'),
    );
  });
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedomax/widgets/motion.dart';

void main() {
  testWidgets('interactive card responds to hover, touch and keyboard once', (
    tester,
  ) async {
    var activations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 260,
              height: 120,
              child: InteractiveCard(
                color: Colors.teal,
                onTap: () => activations++,
                child: const Center(child: Text('Otvoriť oblasť')),
              ),
            ),
          ),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('Otvoriť oblasť')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otvoriť oblasť'));
    await tester.pumpAndSettle();
    expect(activations, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(activations, 2);
    await mouse.removePointer();
    expect(tester.takeException(), isNull);
  });
  testWidgets('celebration allows taps and stops its ticker', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CelebrationBurst(
              child: SizedBox(
                width: 400,
                height: 300,
                child: TextButton(
                  onPressed: () => taps++,
                  child: const Text('Pokračovať'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Pokračovať'));
    expect(taps, 1);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: CelebrationBurst(
            child: TextButton(
              onPressed: () => taps++,
              child: const Text('Pokračovať'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}

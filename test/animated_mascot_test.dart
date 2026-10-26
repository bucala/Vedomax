import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedomax/widgets/animated_mascot.dart';

void main() {
  test(
    'OBJ render exports contain distinct animated frames and transparency',
    () async {
      for (final clip in [(Mascot.idle, 60), (Mascot.celebration, 36)]) {
        final bytes = await rootBundle.load(clip.$1);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
        );
        expect(codec.frameCount, clip.$2);
        final first = await codec.getNextFrame();
        final second = await codec.getNextFrame();
        expect(first.image.width, 384);
        expect(first.image.height, 384);
        expect(first.duration, const Duration(milliseconds: 50));
        final a = await first.image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final b = await second.image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        expect(a!.getUint8(3), 0);
        expect(
          a.buffer.asUint8List(),
          isNot(orderedEquals(b!.buffer.asUint8List())),
        );
        first.image.dispose();
        second.image.dispose();
        codec.dispose();
      }
    },
  );
  testWidgets(
    'tap celebrates, then returns to idle; reduced motion uses a still',
    (tester) async {
      Widget app({
        bool reduced = false,
        bool active = true,
        double size = 180,
      }) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: TickerMode(
            enabled: active,
            child: Material(
              child: Center(child: Mascot(size: size)),
            ),
          ),
        ),
      );
      await tester.pumpWidget(app());
      await tester.pump(const Duration(milliseconds: 100));
      String asset() =>
          (tester
                      .widget<Image>(
                        find
                            .descendant(
                              of: find.byType(Mascot),
                              matching: find.byType(Image),
                            )
                            .first,
                      )
                      .image
                  as AssetImage)
              .assetName;
      expect(asset(), Mascot.idle);
      await tester.tap(find.byType(Mascot));
      await tester.pump();
      expect(asset(), Mascot.celebration);
      await tester.pump(const Duration(milliseconds: 1850));
      expect(asset(), Mascot.idle);
      await tester.pumpWidget(app(reduced: true));
      await tester.pump();
      expect(asset(), Mascot.still);
      await tester.pumpWidget(app(active: false));
      await tester.pump();
      expect(asset(), Mascot.still);
      await tester.pumpWidget(app(size: 48));
      await tester.pump();
      expect(asset(), 'assets/brand/vedomax-v.png');
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}

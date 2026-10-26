import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/learning.dart';
import 'animated_mascot.dart';
import 'motion.dart';
export 'animated_mascot.dart';

const teal = Color(0xff087f8c);
const violet = Color(0xff7157d9);
const amber = Color(0xffe8a02b);

class Brand extends StatelessWidget {
  const Brand({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Mascot(size: 48),
      const SizedBox(width: 8),
      Text(
        'vedomax',
        style: TextStyle(
          fontSize: compact ? 23 : 28,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.2,
        ),
      ),
    ],
  );
}

class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color = teal,
    this.expand = true,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final bool expand;
  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool down = false;
  bool hovered = false;
  bool focused = false;
  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: MediaQuery.disableAnimationsOf(context)
        ? 1
        : down
        ? .985
        : (hovered || focused)
        ? 1.012
        : 1,
    duration: motionDuration(context, 120),
    child: AnimatedPadding(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 90),
      padding: EdgeInsets.only(top: down ? 4 : 0, bottom: down ? 0 : 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          boxShadow: widget.onPressed == null
              ? []
              : [
                  BoxShadow(
                    color: Color.lerp(widget.color, Colors.black, .24)!,
                    offset: Offset(0, down ? 0 : 4),
                  ),
                ],
        ),
        child: SizedBox(
          width: widget.expand ? double.infinity : null,
          height: 52,
          child: Listener(
            onPointerDown: widget.onPressed == null
                ? null
                : (_) => setState(() => down = true),
            onPointerUp: (_) => setState(() => down = false),
            onPointerCancel: (_) => setState(() => down = false),
            child: FilledButton(
              onPressed: widget.onPressed,
              onHover: (v) => setState(() => hovered = v),
              onFocusChange: (v) => setState(() => focused = v),
              style: FilledButton.styleFrom(
                backgroundColor: widget.color,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(widget.label, textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.color,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? Theme.of(context).colorScheme.surface,
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: .12),
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, this.suffix = '', this.style});
  final int value;
  final String suffix;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.toDouble()),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 1000),
    curve: Curves.easeOutCubic,
    builder: (_, v, _) => Text('${v.round()}$suffix', style: style),
  );
}

class LearningMap extends StatefulWidget {
  const LearningMap({
    super.key,
    required this.region,
    required this.polygons,
    required this.onChanged,
    this.highlight = const [],
    this.point,
    this.target,
    this.targetName,
  });
  final String region;
  final List<List<GeoPoint>> polygons;
  final List<List<GeoPoint>> highlight;
  final ValueChanged<GeoPoint>? onChanged;
  final GeoPoint? point, target;
  final String? targetName;
  @override
  State<LearningMap> createState() => _LearningMapState();
}

class MapViewport {
  const MapViewport(this.west, this.east, this.south, this.north);
  final double west, east, south, north;
  static MapViewport region(String name) => switch (name) {
    'sk' => const MapViewport(16.6, 22.8, 47.5, 49.9),
    'oceania' => const MapViewport(110, 180, -49, -8),
    _ => const MapViewport(-170, -30, -58, 75),
  };
  GeoPoint fromOffset(Offset p, Size size) => GeoPoint(
    north - (p.dy / size.height).clamp(0, 1) * (north - south),
    west + (p.dx / size.width).clamp(0, 1) * (east - west),
  );
  Offset toOffset(GeoPoint p, Size size) => Offset(
    (p.lon - west) / (east - west) * size.width,
    (north - p.lat) / (north - south) * size.height,
  );
  double get aspect =>
      ((east - west) *
              math.cos((north + south) / 2 * math.pi / 180) /
              (north - south))
          .clamp(1, 2.2);
}

class _LearningMapState extends State<LearningMap> {
  bool focused = false;
  @override
  Widget build(BuildContext context) {
    final viewport = MapViewport.region(widget.region);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.region == 'sk'
              ? 'SLOVENSKO'
              : widget.region == 'oceania'
              ? 'AUSTRÁLIA A OCEÁNIA'
              : 'AMERIKA',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 2,
            color: teal,
          ),
        ),
        const SizedBox(height: 12),
        Focus(
          onFocusChange: (v) => setState(() => focused = v),
          onKeyEvent: (_, event) {
            if (widget.onChanged == null || event is KeyUpEvent) {
              return KeyEventResult.ignored;
            }
            final p =
                widget.point ??
                GeoPoint(
                  (viewport.north + viewport.south) / 2,
                  (viewport.east + viewport.west) / 2,
                );
            final latStep = (viewport.north - viewport.south) / 100;
            final lonStep = (viewport.east - viewport.west) / 100;
            GeoPoint? next;
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              next = GeoPoint(p.lat + latStep, p.lon);
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              next = GeoPoint(p.lat - latStep, p.lon);
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              next = GeoPoint(p.lat, p.lon - lonStep);
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              next = GeoPoint(p.lat, p.lon + lonStep);
            }
            if (next == null) return KeyEventResult.ignored;
            widget.onChanged!(
              GeoPoint(
                next.lat.clamp(viewport.south, viewport.north),
                next.lon.clamp(viewport.west, viewport.east),
              ),
            );
            return KeyEventResult.handled;
          },
          child: Semantics(
            label: 'Slepá mapa. Klikni alebo použi šípky na posun značky.',
            value: widget.point == null
                ? 'Bez značky'
                : '${widget.point!.lat.toStringAsFixed(2)}°, ${widget.point!.lon.toStringAsFixed(2)}°',
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: focused ? teal : const Color(0xffc4dedf),
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: viewport.aspect,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.biggest;
                    return GestureDetector(
                      key: const Key('learning-map'),
                      onTapDown: widget.onChanged == null
                          ? null
                          : (e) => widget.onChanged!(
                              viewport.fromOffset(e.localPosition, size),
                            ),
                      child: CustomPaint(
                        size: size,
                        painter: _MapPainter(
                          viewport,
                          widget.polygons,
                          widget.point,
                          widget.target,
                          Theme.of(context).brightness == Brightness.dark,
                          widget.highlight,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 18,
          runSpacing: 6,
          children: [
            if (widget.point != null)
              const _Legend(color: Color(0xffdc7c26), label: 'Tvoj tip'),
            if (widget.target != null)
              _Legend(
                color: teal,
                label: widget.targetName ?? 'Správna poloha',
              ),
          ],
        ),
        if (widget.onChanged != null)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Značku môžeš presúvať. Klávesnica: Tab na mapu, potom šípky.',
              style: TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.location_on_rounded, color: color, size: 17),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class _MapPainter extends CustomPainter {
  _MapPainter(
    this.view,
    this.polygons,
    this.point,
    this.target,
    this.dark,
    this.highlight,
  );
  final MapViewport view;
  final List<List<GeoPoint>> polygons;
  final List<List<GeoPoint>> highlight;
  final GeoPoint? point, target;
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = dark ? const Color(0xff17323d) : const Color(0xffe3f2f2),
    );
    final grid = Paint()
      ..color = (dark ? Colors.white : teal).withValues(alpha: .08)
      ..strokeWidth = 1;
    for (int i = 1; i < 8; i++) {
      canvas.drawLine(
        Offset(size.width * i / 8, 0),
        Offset(size.width * i / 8, size.height),
        grid,
      );
      canvas.drawLine(
        Offset(0, size.height * i / 8),
        Offset(size.width, size.height * i / 8),
        grid,
      );
    }
    for (final polygon in polygons) {
      if (!polygon.any(
        (p) =>
            p.lon >= view.west - 10 &&
            p.lon <= view.east + 10 &&
            p.lat >= view.south - 5 &&
            p.lat <= view.north + 5,
      )) {
        continue;
      }
      final path = Path();
      for (var i = 0; i < polygon.length; i++) {
        final p = view.toOffset(polygon[i], size);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = dark ? const Color(0xff29484f) : const Color(0xffd2e3da),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = dark ? const Color(0xff65a49c) : const Color(0xff6eaaa0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
    for (final polygon in highlight) {
      final path = Path();
      for (var i = 0; i < polygon.length; i++) {
        final p = view.toOffset(polygon[i], size);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = dark ? const Color(0xff3e8376) : const Color(0xffa4d5bd),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = dark ? const Color(0xff84dac4) : teal
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    if (point != null && target != null) {
      canvas.drawLine(
        view.toOffset(point!, size),
        view.toOffset(target!, size),
        Paint()
          ..color = const Color(0xffdc7c26)
          ..strokeWidth = 2,
      );
    }
    void marker(GeoPoint p, Color color) {
      final pos = view.toOffset(p, size);
      canvas.drawCircle(pos, 14, Paint()..color = color.withValues(alpha: .16));
      canvas.drawCircle(pos, 7, Paint()..color = Colors.white);
      canvas.drawCircle(pos, 5, Paint()..color = color);
    }

    if (point != null) marker(point!, const Color(0xffdc7c26));
    if (target != null) marker(target!, teal);
    final text = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(
          fontFamily: 'Roboto',
          color: dark ? Colors.white : teal,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, const Offset(12, 10));
    final compass = Paint()
      ..color = dark ? Colors.white : teal
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(31, 23), const Offset(31, 11), compass);
    canvas.drawLine(const Offset(31, 11), const Offset(27, 15), compass);
    canvas.drawLine(const Offset(31, 11), const Offset(35, 15), compass);
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.point != point ||
      old.target != target ||
      old.dark != dark ||
      old.view.west != view.west ||
      old.polygons != polygons ||
      old.highlight != highlight;
}

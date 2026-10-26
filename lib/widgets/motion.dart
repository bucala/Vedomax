import 'dart:math' as math;
import 'package:flutter/material.dart';

Duration motionDuration(BuildContext context, int milliseconds) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Duration(milliseconds: milliseconds);

/// A bounded fade/slide transition that removes the outgoing page from hit testing.
class MotionSwitcher extends StatelessWidget {
  const MotionSwitcher({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: motionDuration(context, 240),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeIn,
    layoutBuilder: (current, previous) => Stack(
      alignment: Alignment.topCenter,
      children: [
        for (final old in previous)
          Positioned.fill(
            child: IgnorePointer(child: ExcludeSemantics(child: old)),
          ),
        ?current,
      ],
    ),
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, .025),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    ),
    child: child,
  );
}

class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: motionDuration(context, 380),
    curve: Curves.easeOutCubic,
    child: child,
    builder: (_, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 16 * (1 - value)),
        child: child,
      ),
    ),
  );
}

class InteractiveCard extends StatefulWidget {
  const InteractiveCard({
    super.key,
    required this.child,
    required this.onTap,
    required this.color,
  });
  final Widget child;
  final VoidCallback onTap;
  final Color color;
  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
  bool hovered = false, focused = false, pressed = false;
  @override
  Widget build(BuildContext context) {
    final active = hovered || focused;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: pressed && !reduced ? .985 : 1,
      duration: motionDuration(context, 100),
      child: AnimatedContainer(
        duration: motionDuration(context, 180),
        transform: Matrix4.translationValues(0, active && !reduced ? -4 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: active ? .16 : 0),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: widget.onTap,
            onHover: (v) => setState(() => hovered = v),
            onFocusChange: (v) => setState(() => focused = v),
            onHighlightChanged: (v) => setState(() => pressed = v),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: active
                      ? widget.color.withValues(alpha: .6)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, required this.color});
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Dokončené ${(value * 100).round()} percent',
    child: SizedBox(
      width: 28,
      height: 28,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: motionDuration(context, 650),
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: v,
              strokeWidth: 3,
              backgroundColor: color.withValues(alpha: .15),
              color: color,
            ),
            Icon(
              v >= 1 ? Icons.check_rounded : Icons.bolt_rounded,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Finite, deterministic celebration. Never intercepts gestures or loops a ticker.
class CelebrationBurst extends StatefulWidget {
  const CelebrationBurst({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;
  @override
  State<CelebrationBurst> createState() => _CelebrationBurstState();
}

class _CelebrationBurstState extends State<CelebrationBurst>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
      controller.value = 1;
    } else if (!started) {
      started = true;
      controller.forward();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      if (widget.enabled && !MediaQuery.disableAnimationsOf(context))
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: controller,
              builder: (_, _) =>
                  CustomPaint(painter: _ConfettiPainter(controller.value)),
            ),
          ),
        ),
    ],
  );
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    const colors = [
      Color(0xff4fd1b5),
      Color(0xff7157d9),
      Color(0xffe8a02b),
      Color(0xffec7389),
    ];
    final alpha = (1 - progress).clamp(0.0, 1.0);
    for (var i = 0; i < 30; i++) {
      final angle = math.pi * (1.1 + i / 30 * .8);
      final speed = 80 + (i % 7) * 19;
      final origin = Offset(size.width / 2, math.min(size.height * .3, 130));
      final x = origin.dx + math.cos(angle) * speed * progress * 2;
      final y =
          origin.dy +
          math.sin(angle) * speed * progress +
          190 * progress * progress;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 8 + i.toDouble());
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, -5, 6, 10),
          const Radius.circular(2),
        ),
        Paint()..color = colors[i % colors.length].withValues(alpha: alpha),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}

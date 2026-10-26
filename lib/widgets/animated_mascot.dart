import 'dart:async';
import 'package:flutter/material.dart';

enum MascotMotion { idle, celebrate }

/// Renders the supplied OBJ's real 3D animation as a compact transparent WebP.
/// Logos remain static; large mascots pause when reduced motion or TickerMode applies.
class Mascot extends StatefulWidget {
  const Mascot({
    super.key,
    this.size = 180,
    this.animated = true,
    this.motion = MascotMotion.idle,
  });
  final double size;
  final bool animated;
  final MascotMotion motion;

  static const still = 'assets/mascot/vedomax_still.png';
  static const idle = 'assets/mascot/vedomax_idle_wave.webp';
  static const celebration = 'assets/mascot/vedomax_celebrate.webp';

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> {
  Timer? _celebrationTimer;
  bool _celebrating = false;
  void _celebrate() {
    _celebrationTimer?.cancel();
    setState(() => _celebrating = true);
    _celebrationTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _celebrating = false);
    });
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final large = widget.size > 64;
    final moving =
        large &&
        widget.animated &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    final asset = !large
        ? 'assets/brand/vedomax-v.png'
        : !moving
        ? Mascot.still
        : (_celebrating || widget.motion == MascotMotion.celebrate)
        ? Mascot.celebration
        : Mascot.idle;
    final image = Image.asset(
      asset,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      excludeFromSemantics: true,
      errorBuilder: (_, error, stack) => Image.asset(
        'assets/brand/vedomax-v.png',
        width: widget.size,
        height: widget.size,
        excludeFromSemantics: true,
      ),
    );
    return Semantics(
      label: 'Vedomax, veselý 3D maskot v tvare V',
      image: true,
      hint: moving ? 'Ťuknutím spustíš veselú oslavu.' : null,
      child: moving
          ? InkResponse(
              onTap: _celebrate,
              containedInkWell: true,
              customBorder: const CircleBorder(),
              child: image,
            )
          : image,
    );
  }
}

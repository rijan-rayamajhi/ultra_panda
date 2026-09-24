import 'package:flutter/material.dart';

/// Periodic diagonal light sweep over [child]'s opaque pixels only (srcATop),
/// so a cabinet frame image glints while its transparent reel window stays clear.
class FrameShine extends StatefulWidget {
  final Widget child;
  final Duration period;
  final Duration sweep;

  /// 0..1 phase shift so several shines on screen don't fire together.
  final double phase;
  const FrameShine({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 4200),
    this.sweep = const Duration(milliseconds: 1500),
    this.phase = 0,
  });

  @override
  State<FrameShine> createState() => _FrameShineState();
}

class _FrameShineState extends State<FrameShine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
    value: widget.phase % 1.0,
  )..repeat();

  // Fraction of each period spent sweeping; the rest is a pause.
  double get _sweepFraction =>
      (widget.sweep.inMilliseconds / widget.period.inMilliseconds).clamp(
        0.01,
        1.0,
      );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value / _sweepFraction;
        if (t > 1) return child!;
        // Band centre travels from off-left to off-right.
        final x = -0.4 + t * 1.8;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [
              Color(0x00FFFFFF),
              Color(0x88FFF8E1),
              Color(0x00FFFFFF),
            ],
            stops: [
              (x - 0.12).clamp(0.0, 1.0),
              x.clamp(0.0, 1.0),
              (x + 0.12).clamp(0.0, 1.0),
            ],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}

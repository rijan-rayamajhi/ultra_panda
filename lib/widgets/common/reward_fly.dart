import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/app_assets.dart';

enum RewardKind { coins, gems }

/// Root navigator; its overlay sits above every route and dialog.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Marks the on-screen balance a [RewardKind] flies into. The most recently
/// mounted target wins, so a game header takes over from the lobby HUD.
class RewardFlyTarget extends StatefulWidget {
  final RewardKind kind;
  final Widget child;
  const RewardFlyTarget({super.key, required this.kind, required this.child});

  @override
  State<RewardFlyTarget> createState() => _RewardFlyTargetState();
}

class _RewardFlyTargetState extends State<RewardFlyTarget> {
  static final Map<RewardKind, List<_RewardFlyTargetState>> _targets = {
    RewardKind.coins: [],
    RewardKind.gems: [],
  };

  @override
  void initState() {
    super.initState();
    _targets[widget.kind]!.add(this);
  }

  @override
  void dispose() {
    _targets[widget.kind]!.remove(this);
    super.dispose();
  }

  static Offset? centerOf(RewardKind kind) {
    final list = _targets[kind]!;
    for (final t in list.reversed) {
      final box = t.context.findRenderObject() as RenderBox?;
      if (box != null && box.attached && box.hasSize) {
        return box.localToGlobal(box.size.center(Offset.zero));
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class RewardFly {
  static int _active = 0;
  static const _maxConcurrent = 3;

  /// Bursts reward icons from mid-screen into the matching balance.
  static void play(RewardKind kind, int amount) {
    if (amount <= 0 || _active >= _maxConcurrent) return;
    final overlay = rootNavigatorKey.currentState?.overlay;
    final target = _RewardFlyTargetState.centerOf(kind);
    if (overlay == null || target == null) return;
    final size = MediaQuery.sizeOf(overlay.context);
    final count = (3 + math.log(amount + 1) / math.ln10).clamp(4, 10).round();

    _active++;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: _FlyAnimation(
          icon: kind == RewardKind.coins
              ? AppAssets.iconCoin
              : AppAssets.iconGem,
          from: size.center(Offset.zero),
          to: target,
          count: count,
          onDone: () {
            entry.remove();
            _active--;
          },
        ),
      ),
    );
    overlay.insert(entry);
  }
}

class _FlyAnimation extends StatefulWidget {
  final String icon;
  final Offset from;
  final Offset to;
  final int count;
  final VoidCallback onDone;
  const _FlyAnimation({
    required this.icon,
    required this.from,
    required this.to,
    required this.count,
    required this.onDone,
  });

  @override
  State<_FlyAnimation> createState() => _FlyAnimationState();
}

class _FlyAnimationState extends State<_FlyAnimation>
    with SingleTickerProviderStateMixin {
  static const _stagger = 0.045;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final List<Offset> _spread;

  @override
  void initState() {
    super.initState();
    final r = math.Random();
    _spread = List.generate(
      widget.count,
      (_) => Offset((r.nextDouble() - 0.5) * 140, (r.nextDouble() - 0.5) * 90),
    );
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flight = 1 - _stagger * (widget.count - 1);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Stack(
        children: [for (var i = 0; i < widget.count; i++) _particle(i, flight)],
      ),
    );
  }

  Widget _particle(int i, double flight) {
    final t = ((_c.value - i * _stagger) / flight).clamp(0.0, 1.0);
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    // Burst outward for the first 25%, then arc into the target.
    final start =
        widget.from +
        _spread[i] * Curves.easeOut.transform((t / 0.25).clamp(0.0, 1.0));
    final p = Curves.easeInCubic.transform(((t - 0.25) / 0.75).clamp(0.0, 1.0));
    final control = Offset(
      (start.dx + widget.to.dx) / 2,
      math.min(start.dy, widget.to.dy) - 80,
    );
    final pos = Offset(
      _bezier(start.dx, control.dx, widget.to.dx, p),
      _bezier(start.dy, control.dy, widget.to.dy, p),
    );
    final scale = 1.1 - 0.5 * p;
    const s = 26.0;
    return Positioned(
      left: pos.dx - s / 2,
      top: pos.dy - s / 2,
      child: Opacity(
        opacity: t > 0.92 ? (1 - t) / 0.08 : 1,
        child: Transform.scale(
          scale: scale,
          child: Image.asset(widget.icon, width: s, height: s),
        ),
      ),
    );
  }

  static double _bezier(double a, double b, double c, double t) =>
      (1 - t) * (1 - t) * a + 2 * (1 - t) * t * b + t * t * c;
}

/// Balance text that counts up/down to [value] instead of jumping.
class CountingNumber extends StatelessWidget {
  final int value;
  final String Function(int) format;
  final TextStyle? style;
  const CountingNumber({
    super.key,
    required this.value,
    required this.format,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(format(v), style: style, maxLines: 1),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/haptics.dart';
import '../../core/audio_manager.dart';

// Shared palette: matches the gold/crimson cabinet frames.
const _gold = [
  Color(0xFFFFF3B0),
  Color(0xFFFFD54F),
  Color(0xFFB8860B),
  Color(0xFFFFE082),
];
const _goldText = [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFFFA000)];

class SlotControlsBar extends StatelessWidget {
  final int currentBet;
  final int lastWinAmount;
  final bool isSpinning;
  final bool autoSpinActive;
  final int? autoSpinCount;
  final bool canDecreaseBet;
  final bool canIncreaseBet;
  final bool controlsEnabled;
  final VoidCallback onDecreaseBet;
  final VoidCallback onIncreaseBet;
  final VoidCallback onMaxBet;
  final VoidCallback onToggleAutoSpin;
  final VoidCallback onAction;
  final String? winLabel;
  final Widget? actionWidget;
  final String? betSubtitle;

  const SlotControlsBar({
    super.key,
    required this.currentBet,
    required this.lastWinAmount,
    required this.isSpinning,
    required this.autoSpinActive,
    this.autoSpinCount,
    required this.canDecreaseBet,
    required this.canIncreaseBet,
    this.controlsEnabled = true,
    required this.onDecreaseBet,
    required this.onIncreaseBet,
    required this.onMaxBet,
    required this.onToggleAutoSpin,
    required this.onAction,
    this.winLabel,
    this.actionWidget,
    this.betSubtitle,
  });

  static String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  void _click(VoidCallback cb) {
    Haptics.selection();
    AudioManager.instance.playSelectClick();
    cb();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = controlsEnabled && !isSpinning;
    final hasWin = lastWinAmount > 0;

    return Container(
      height: 56,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A0A14), Color(0xFF1C0409), Color(0xFF0A0204)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gold trim along the top edge.
          Container(
            height: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x00FFD54F),
                  Color(0xFFFFE082),
                  Color(0xFFFFD54F),
                  Color(0xFFFFE082),
                  Color(0x00FFD54F),
                ],
              ),
              boxShadow: [BoxShadow(color: Color(0x88FFB300), blurRadius: 6)],
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    _betCluster(enabled),
                    const SizedBox(width: 8),
                    _Pressable(
                      onTap: enabled ? () => _click(onMaxBet) : null,
                      child: _GoldRim(
                        radius: 8,
                        child: _Panel(
                          width: 70,
                          height: 36,
                          radius: 8,
                          colors: const [
                            Color(0xFFD32F2F),
                            Color(0xFF8B0D23),
                            Color(0xFF4A0612),
                          ],
                          child: const _GoldLabel('MAX BET', size: 12),
                        ),
                      ),
                    ),
                    const Spacer(),
                    _winMeter(hasWin),
                    const Spacer(),
                    _autoButton(),
                    const SizedBox(width: 10),
                    _spinButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _betCluster(bool enabled) {
    return _GoldRim(
      radius: 8,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF12030A), Color(0xFF2A0712)],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _roundButton(
              Icons.remove_rounded,
              canDecreaseBet && enabled,
              onDecreaseBet,
            ),
            SizedBox(
              width: 90,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      betSubtitle ?? 'TOTAL BET',
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFFBCAAA4),
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _GoldLabel(_fmt(currentBet), size: 14),
                  ),
                ],
              ),
            ),
            _roundButton(
              Icons.add_rounded,
              canIncreaseBet && enabled,
              onIncreaseBet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundButton(IconData icon, bool enabled, VoidCallback onTap) {
    return _Pressable(
      onTap: enabled ? () => _click(onTap) : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _gold,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment(-0.3, -0.4),
                colors: [
                  Color(0xFFB71C1C),
                  Color(0xFF6A0A1C),
                  Color(0xFF3A050F),
                ],
              ),
            ),
            child: Icon(icon, size: 17, color: const Color(0xFFFFE082)),
          ),
        ),
      ),
    );
  }

  Widget _winMeter(bool hasWin) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: hasWin
            ? const [
                BoxShadow(
                  color: Color(0x99FFC400),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      child: _GoldRim(
        radius: 8,
        child: Container(
          width: 158,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF050103), Color(0xFF1E0610), Color(0xFF0A0205)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                winLabel ?? (hasWin ? 'WIN' : 'LAST WIN'),
                maxLines: 1,
                textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false,
                ),
                style: TextStyle(
                  color: hasWin
                      ? const Color(0xFFFFE082)
                      : const Color(0xFFBCAAA4),
                  fontSize: 7.5,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: hasWin
                    ? _GoldLabel(_fmt(lastWinAmount), size: 16)
                    : const Text(
                        '0',
                        textHeightBehavior: TextHeightBehavior(
                          applyHeightToFirstAscent: false,
                          applyHeightToLastDescent: false,
                        ),
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 16,
                          height: 1.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _autoButton() {
    final canTap = !isSpinning || autoSpinActive;
    return _Pressable(
      onTap: canTap ? () => _click(onToggleAutoSpin) : null,
      child: _GoldRim(
        radius: 8,
        child: _Panel(
          width: 40,
          height: 40,
          radius: 8,
          colors: autoSpinActive
              ? const [Color(0xFFFFB300), Color(0xFFE65100), Color(0xFF8A2A00)]
              : const [Color(0xFF4A0A1A), Color(0xFF2A0610), Color(0xFF12030A)],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                autoSpinActive ? Icons.stop_rounded : Icons.autorenew_rounded,
                size: 16,
                color: autoSpinActive ? Colors.white : const Color(0xFFFFE082),
              ),
              Text(
                autoSpinActive
                    ? ((autoSpinCount ?? 0) > 0 ? '$autoSpinCount' : 'STOP')
                    : 'AUTO',
                style: TextStyle(
                  color: autoSpinActive
                      ? Colors.white
                      : const Color(0xFFFFE082),
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _spinButton() {
    return _Pressable(
      onTap: isSpinning
          ? null
          : () {
              Haptics.medium();
              onAction();
            },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isSpinning ? 0.55 : 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: isSpinning ? Colors.black54 : const Color(0x66FFD700),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: _GoldRim(
            radius: 8,
            width: 2.5,
            child: SizedBox(
              width: 110,
              height: 42,
              child: actionWidget != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: actionWidget,
                    )
                  : _Panel(
                      width: 110,
                      height: 42,
                      radius: 8,
                      colors: const [
                        Color(0xFFD32F2F),
                        Color(0xFF8B0D23),
                        Color(0xFF4A0612),
                      ],
                      child: const _GoldLabel('SPIN', size: 19),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Beveled gold border around [child].
class _GoldRim extends StatelessWidget {
  final Widget child;
  final double radius;
  final double width;
  const _GoldRim({required this.child, required this.radius, this.width = 1.6});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(width),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gold,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

/// Glossy gradient face with a top highlight.
class _Panel extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final List<Color> colors;
  final Widget child;
  const _Panel({
    required this.width,
    required this.height,
    required this.radius,
    required this.colors,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 1,
            left: 6,
            right: 6,
            height: height * 0.42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.35),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GoldLabel extends StatelessWidget {
  final String text;
  final double size;
  const _GoldLabel(this.text, {required this.size});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _goldText,
      ).createShader(r),
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          color: Colors.white,
          fontSize: size,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          shadows: const [
            Shadow(color: Colors.black, offset: Offset(0, 1.5), blurRadius: 2),
          ],
        ),
      ),
    );
  }
}

/// Scales down slightly while pressed; ignores taps when [onTap] is null.
class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Pressable({required this.child, this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: widget.child,
      ),
    );
  }
}

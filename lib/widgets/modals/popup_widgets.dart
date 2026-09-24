import 'package:flutter/material.dart';
import '../../core/haptics.dart';
import '../../core/audio_manager.dart';

enum PillStyle { gold, green, idle, done }

class PillButton extends StatelessWidget {
  final String label;
  final PillStyle style;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;

  const PillButton({
    super.key,
    required this.label,
    required this.style,
    this.onTap,
    this.height = 22,
    this.fontSize = 8,
  });

  @override
  Widget build(BuildContext context) {
    final active = onTap != null && style != PillStyle.done;
    final colors = switch (style) {
      PillStyle.gold => const [Color(0xFFFFD54F), Color(0xFFFF8F00)],
      PillStyle.green => const [Color(0xFF00E676), Color(0xFF00C853)],
      PillStyle.idle => const [Color(0xFF37474F), Color(0xFF212121)],
      PillStyle.done => const [Color(0xFF424242), Color(0xFF212121)],
    };
    final textColor = switch (style) {
      PillStyle.gold => const Color(0xFF3E2723),
      PillStyle.green => Colors.black,
      PillStyle.idle => Colors.white70,
      PillStyle.done => Colors.white38,
    };

    return GestureDetector(
      onTap: active
          ? () {
              if (style == PillStyle.gold || style == PillStyle.green) {
                Haptics.medium();
                AudioManager.instance.playPayoutDing();
              } else {
                Haptics.selection();
                AudioManager.instance.playSelectClick();
              }
              onTap!();
            }
          : null,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(8),
          border: active ? Border.all(color: Colors.white, width: 0.8) : null,
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin header strip used at the top of each feature popup.
class PopupHeaderBar extends StatelessWidget {
  final Widget left;
  final Widget? right;
  const PopupHeaderBar({super.key, required this.left, this.right});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0x99170828),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x66FFD54F), width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: left,
            ),
          ),
          if (right != null) ...[const SizedBox(width: 8), right!],
        ],
      ),
    );
  }
}

const popupLabelStyle = TextStyle(
  color: Color(0xFFFFE082),
  fontSize: 9.5,
  fontWeight: FontWeight.w900,
  letterSpacing: 0.5,
);

/// 3x3 grid that reveals slices of [image] for owned pieces.
class SlicedImageGrid extends StatelessWidget {
  final String image;
  final bool Function(int index) owned;

  const SlicedImageGrid({super.key, required this.image, required this.owned});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth / 3, h = c.maxHeight / 3;
        return Stack(
          children: [
            for (var i = 0; i < 9; i++)
              Positioned(
                left: (i % 3) * w,
                top: (i ~/ 3) * h,
                width: w,
                height: h,
                child: Padding(
                  padding: const EdgeInsets.all(0.6),
                  child: owned(i) ? _slice(i, w, h) : _locked(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _slice(int i, double w, double h) {
    return ClipRect(
      child: OverflowBox(
        maxWidth: w * 3,
        maxHeight: h * 3,
        alignment: Alignment((i % 3) - 1.0, (i ~/ 3) - 1.0),
        child: Image.asset(
          image,
          width: w * 3,
          height: h * 3,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _locked() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xCC0B0414),
        border: Border.all(color: const Color(0x33FFD54F), width: 0.5),
      ),
      child: const Center(
        child: Icon(Icons.lock_rounded, size: 11, color: Colors.white24),
      ),
    );
  }
}

String formatDuration(Duration d) {
  if (d.inDays >= 1) return '${d.inDays}d ${d.inHours % 24}h';
  final h = d.inHours.toString().padLeft(2, '0');
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

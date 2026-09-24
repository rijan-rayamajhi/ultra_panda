import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// One slot reel column shared by every game.
///
/// While [controller] is driving a spin ([isSpinning] true) it scrolls a
/// seamlessly-looping strip of symbol tiles with vertical motion blur; when the
/// spin ends it snaps to the settled [rows] with a short drop-in bounce.
///
/// The caller owns the symbols: [settledCell] builds the final tile for a row
/// (keeping its own win-highlight state) and [spinCell] builds tile `i` of the
/// moving strip (deterministic in `i`, so the strip doesn't flicker).
class ReelColumn extends StatelessWidget {
  final AnimationController controller;
  final bool isSpinning;
  final int rows;
  final Widget Function(int row) settledCell;
  final Widget Function(int i) spinCell;

  /// Tiles in one loop of the moving strip; more = a longer, faster blur.
  final int stripTiles;

  const ReelColumn({
    super.key,
    required this.controller,
    required this.isSpinning,
    required this.rows,
    required this.settledCell,
    required this.spinCell,
    this.stripTiles = 8,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cellH = c.maxHeight / rows;

        if (!isSpinning) {
          // Settle: quick drop-in bounce onto the final symbols.
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            builder: (context, t, child) => Transform.translate(
              offset: Offset(0, (1 - t) * -cellH * 0.18),
              child: child,
            ),
            child: Column(
              children: [
                for (var r = 0; r < rows; r++)
                  Expanded(child: settledCell(r)),
              ],
            ),
          );
        }

        // Spin: two stacked copies of a random strip scrolled by a full strip
        // height each period, so the loop point is seamless. The strip is
        // taller than the window, so let it size freely and clip to the window.
        final total = stripTiles * cellH;
        return ClipRect(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final dy = -controller.value * total;
              return OverflowBox(
                minHeight: 0,
                maxHeight: double.infinity,
                alignment: Alignment.topCenter,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaY: 3.5, sigmaX: 0.4),
                  child: Transform.translate(
                    offset: Offset(0, dy),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < stripTiles * 2; i++)
                          SizedBox(
                            height: cellH,
                            child: spinCell(i % stripTiles),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

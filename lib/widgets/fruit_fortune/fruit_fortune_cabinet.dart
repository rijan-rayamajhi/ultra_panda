import 'package:flutter/material.dart';
import '../../core/app_assets.dart';
import '../common/frame_shine.dart';
import '../common/reel_column.dart';
import '../../models/fruit_fortune_model.dart';

class FruitFortuneCabinet extends StatelessWidget {
  static final List<FruitSymbolType> _spinSymbols = FruitSymbolType.values
      .where((t) => t != FruitSymbolType.scatter)
      .toList();

  final List<FruitSymbolType> grid; // 21 cells: 7 cols x 3 rows
  final Set<int> poppedIndices;
  final int activeMultiplier; // 1, 2, 3, 5, 10
  final bool isSpinning;
  final bool reelsRolling; // reels physically rolling (initial drop only)
  final List<AnimationController> reelControllers;
  final bool isFreeSpins;
  final Animation<double> pulseAnimation;

  const FruitFortuneCabinet({
    super.key,
    required this.grid,
    required this.poppedIndices,
    required this.activeMultiplier,
    required this.isSpinning,
    required this.reelsRolling,
    required this.reelControllers,
    required this.isFreeSpins,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final maxW = constraints.maxWidth;

        // Native frame ratio for Frame_FruitFortune: 1561 x 1008 (~1.5486 : 1)
        double frameHeight = maxH * 0.98;
        double frameWidth = frameHeight * (1561 / 1008);

        if (frameWidth > maxW * 0.98) {
          frameWidth = maxW * 0.98;
          frameHeight = frameWidth * (1008 / 1561);
        }

        // Calibrated transparent window bounds inside Frame_FruitFortune (1561 x 1008):
        // left: 10.19%, top: 30.75%, width: 79.56%, height: 49.31%
        final reelLeft = frameWidth * 0.1019;
        final reelTop = frameHeight * 0.3075;
        final reelWidth = frameWidth * 0.7956;
        final reelHeight = frameHeight * 0.4931;

        // Multiplier ladder header banner positioned in upper frame tier
        final ladderTop = frameHeight * 0.11;
        final ladderLeft = frameWidth * 0.22;
        final ladderWidth = frameWidth * 0.56;
        final ladderHeight = frameHeight * 0.14;

        return SizedBox(
          width: frameWidth,
          height: frameHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Reel Grid Backdrop & Symbols (Layered behind frame)
              Positioned(
                left: reelLeft,
                top: reelTop,
                width: reelWidth,
                height: reelHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(
                      0xF2071A0C,
                    ), // Deep jade-forest velvet backdrop
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isFreeSpins
                          ? const Color(0xFFFF5252)
                          : const Color(0x66FFD700),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isFreeSpins
                            ? const Color(0x44FF1744)
                            : const Color(0x33FFD700),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                      const BoxShadow(
                        color: Colors.black87,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _build7x3Grid(),
                  ),
                ),
              ),

              // 2. Wide Velvet Fruit Fortune Cabinet Frame Overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: FrameShine(
                    child: Image.asset(
                      AppAssets.frameFruitFortune,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),

              // 3. Cascade Multiplier Ladder Bar (Replaces Jackpot Ticker)
              Positioned(
                left: ladderLeft,
                top: ladderTop,
                width: ladderWidth,
                height: ladderHeight,
                child: _buildCascadeMultiplierLadder(),
              ),
            ],
          ),
        );
      },
    );
  }

  // 7 Columns x 3 Rows dynamic flex grid (Zero overflow)
  Widget _build7x3Grid() {
    return Row(
      children: List.generate(7, (col) {
        return Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: col < 6
                    ? const BorderSide(color: Color(0x1FFFFFFF), width: 0.8)
                    : BorderSide.none,
              ),
            ),
            child: ReelColumn(
              controller: reelControllers[col],
              isSpinning: reelsRolling,
              rows: 3,
              settledCell: (row) {
                // Column-major index: col * 3 + row
                final index = col * 3 + row;
                final symbol = (index < grid.length)
                    ? grid[index]
                    : FruitSymbolType.cherry;
                return _buildSymbolCell(
                  symbol: symbol,
                  isWinning: poppedIndices.contains(index),
                );
              },
              spinCell: (i) => _buildSymbolCell(
                symbol: _spinSymbols[(i * 7 + col) % _spinSymbols.length],
                isWinning: false,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSymbolCell({
    required FruitSymbolType symbol,
    required bool isWinning,
  }) {
    final config = FruitSymbolConfig.configs[symbol]!;

    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, _) {
        final scale = isWinning ? 1.0 + (pulseAnimation.value * 0.12) : 1.0;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: isWinning
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(
                              alpha: 0.6 + 0.4 * pulseAnimation.value,
                            ),
                            blurRadius: 10 + 6 * pulseAnimation.value,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Image.asset(
                  config.assetPath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (c, e, s) => _buildFallback(symbol),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallback(FruitSymbolType symbol) {
    String text;
    Color color;

    switch (symbol) {
      case FruitSymbolType.pineapple:
        text = 'PINE';
        color = const Color(0xFFFFD700);
        break;
      case FruitSymbolType.watermelon:
        text = 'MELON';
        color = const Color(0xFFFF1744);
        break;
      case FruitSymbolType.grape:
        text = 'GRAPE';
        color = const Color(0xFFBA68C8);
        break;
      case FruitSymbolType.plum:
        text = 'PLUM';
        color = const Color(0xFFAB47BC);
        break;
      case FruitSymbolType.orange:
        text = 'ORANGE';
        color = const Color(0xFFFF9800);
        break;
      case FruitSymbolType.lemon:
        text = 'LEMON';
        color = const Color(0xFFFFEB3B);
        break;
      case FruitSymbolType.cherry:
        text = 'CHERRY';
        color = const Color(0xFFE91E63);
        break;
      case FruitSymbolType.pandaWild:
        text = 'WILD';
        color = const Color(0xFF00E676);
        break;
      case FruitSymbolType.scatter:
        text = '★ BONUS';
        color = const Color(0xFFFFD54F);
        break;
    }

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // Cascade Multiplier Ladder Bar: 1x -> 2x -> 3x -> 5x -> 10x
  Widget _buildCascadeMultiplierLadder() {
    const ladder = [1, 2, 3, 5, 10];

    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0D2814).withValues(alpha: 0.92),
                const Color(0xFF1B4D28).withValues(alpha: 0.95),
                const Color(0xFF0D2814).withValues(alpha: 0.92),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x5500E676),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'CASCADE:',
                  style: TextStyle(
                    color: Color(0xFFFFF9C4),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                ...ladder.map((step) {
                  final isActive = activeMultiplier >= step;
                  final isCurrent = activeMultiplier == step;

                  return AnimatedContainer(
                    margin: const EdgeInsets.only(left: 6),
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
                            )
                          : null,
                      color: isActive ? null : const Color(0x33000000),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? Colors.white
                            : const Color(0x44FFD700),
                        width: isCurrent ? 1.4 : 0.8,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withValues(
                                  alpha: 0.6 + 0.3 * pulseAnimation.value,
                                ),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      '${step}X',
                      style: TextStyle(
                        color: isActive
                            ? const Color(0xFF3E2723)
                            : const Color(0xFF90A4AE),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

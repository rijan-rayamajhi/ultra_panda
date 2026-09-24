import 'package:flutter/material.dart';
import '../../core/app_assets.dart';
import '../common/frame_shine.dart';
import '../common/reel_column.dart';
import '../../models/classic777_model.dart';

class Classic777Cabinet extends StatelessWidget {
  // Symbols the reels flash through while spinning (deterministic, no flicker).
  static final List<ClassicSymbolType> _spinSymbols = ClassicSymbolType.values
      .where((t) => t != ClassicSymbolType.scatter)
      .toList();

  final List<ClassicSymbolType> grid; // 9 symbols: 3 cols x 3 rows
  final List<LineWinResult> lineWins;
  final bool isSpinning;
  final bool isFreeSpins;
  final int currentBet;
  final List<AnimationController> reelControllers;
  final Animation<double> pulseAnimation;

  const Classic777Cabinet({
    super.key,
    required this.grid,
    required this.lineWins,
    required this.isSpinning,
    required this.isFreeSpins,
    required this.currentBet,
    required this.reelControllers,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final maxW = constraints.maxWidth;

        // Native frame ratio for Frame_Classic777: 1448 x 1086 (~1.3333 : 1)
        double frameHeight = maxH * 0.98;
        double frameWidth = frameHeight * (1448 / 1086);

        if (frameWidth > maxW * 0.96) {
          frameWidth = maxW * 0.96;
          frameHeight = frameWidth * (1086 / 1448);
        }

        // Calibrated transparent window bounds inside Frame_Classic777 (1448 x 1086):
        // left: 13.05%, top: 29.28%, width: 73.90%, height: 61.51%
        final reelLeft = frameWidth * 0.1305;
        // Height re-measured on-device: 0.6151 ran the 3rd row under the
        // frame's bottom band.
        final reelTop = frameHeight * 0.312;
        final reelWidth = frameWidth * 0.7390;
        final reelHeight = frameHeight * 0.525;

        // Jackpot Ticker Bar row at the top of the cabinet (within top 25% of cabinet)
        final tickerTop = frameHeight * 0.080;
        final tickerLeft = frameWidth * 0.18;
        final tickerWidth = frameWidth * 0.64;
        final tickerHeight = frameHeight * 0.14;

        // Identify which cell indices are part of any winning paylines
        final Set<int> winningCells = {};
        for (final win in lineWins) {
          winningCells.addAll(win.payline.cellIndices);
        }

        return SizedBox(
          width: frameWidth,
          height: frameHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Reel Grid Backdrop & Symbols (Layered behind the Vegas cabinet frame)
              Positioned(
                left: reelLeft,
                top: reelTop,
                width: reelWidth,
                height: reelHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xF207030A),
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
                            : const Color(0x44FFD700),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                      const BoxShadow(
                        color: Colors.black,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        // The 3x3 Dynamic Flex Grid (Zero-overflow guaranteed)
                        _build3x3Grid(winningCells),

                        // Payline Laser Traces for winning lines
                        if (!isSpinning && lineWins.isNotEmpty)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: PaylineOverlayPainter(
                                lineWins: lineWins,
                                pulse: pulseAnimation.value,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Retro Vegas Cabinet Frame Overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: FrameShine(
                    child: Image.asset(
                      AppAssets.frameClassic777,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),

              // 3. Single Jackpot Ticker Row Up Top
              Positioned(
                left: tickerLeft,
                top: tickerTop,
                width: tickerWidth,
                height: tickerHeight,
                child: _buildJackpotTicker(),
              ),
            ],
          ),
        );
      },
    );
  }

  // 3 Columns x 3 Rows dynamic flex grid (Zero overflow)
  Widget _build3x3Grid(Set<int> winningCells) {
    return Row(
      children: List.generate(3, (col) {
        return Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: col < 2
                    ? const BorderSide(color: Color(0x2AFFFFFF), width: 1.0)
                    : BorderSide.none,
              ),
            ),
            child: ReelColumn(
              controller: reelControllers[col],
              isSpinning: isSpinning,
              rows: 3,
              settledCell: (row) {
                // Grid index mapping: row * 3 + col.
                final index = row * 3 + col;
                return _buildSymbolCell(
                  symbol: grid[index],
                  isWinner: !isSpinning && winningCells.contains(index),
                  isSpinning: false,
                  colIndex: col,
                  rowIndex: row,
                );
              },
              spinCell: (i) => _buildSymbolCell(
                symbol: _spinSymbols[(i * 3 + col) % _spinSymbols.length],
                isWinner: false,
                isSpinning: true,
                colIndex: col,
                rowIndex: i,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSymbolCell({
    required ClassicSymbolType symbol,
    required bool isWinner,
    required bool isSpinning,
    required int colIndex,
    required int rowIndex,
  }) {
    final config = ClassicSymbolConfig.configs[symbol]!;

    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, _) {
        final scale = isWinner ? 1.0 + (pulseAnimation.value * 0.10) : 1.0;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: isWinner
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(
                              alpha: 0.5 + 0.4 * pulseAnimation.value,
                            ),
                            blurRadius: 12 + 6 * pulseAnimation.value,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Image.asset(
                  config.assetPath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildFallbackSymbol(symbol);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackSymbol(ClassicSymbolType symbol) {
    String text;
    Color color;

    switch (symbol) {
      case ClassicSymbolType.sevenRed:
        text = '7';
        color = const Color(0xFFFF1744);
        break;
      case ClassicSymbolType.sevenGold:
        text = '7';
        color = const Color(0xFFFFD700);
        break;
      case ClassicSymbolType.wild:
        text = 'WILD';
        color = const Color(0xFFFF6D00);
        break;
      case ClassicSymbolType.bar:
        text = 'BAR';
        color = const Color(0xFF00E5FF);
        break;
      case ClassicSymbolType.ace:
        text = 'A';
        color = const Color(0xFFFF4081);
        break;
      case ClassicSymbolType.king:
        text = 'K';
        color = const Color(0xFF7C4DFF);
        break;
      case ClassicSymbolType.queen:
        text = 'Q';
        color = const Color(0xFF00E676);
        break;
      case ClassicSymbolType.jack:
        text = 'J';
        color = const Color(0xFFFFEA00);
        break;
      case ClassicSymbolType.ten:
        text = '10';
        color = const Color(0xFF40C4FF);
        break;
      case ClassicSymbolType.scatter:
        text = '★';
        color = const Color(0xFFFFAB00);
        break;
    }

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // Retro Vegas Single Jackpot Ticker Row
  Widget _buildJackpotTicker() {
    final topJackpot = currentBet * 500; // Seven Red 500x top jackpot
    final formattedJackpot = topJackpot.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1B0206).withValues(alpha: 0.9),
                const Color(0xFF38050E).withValues(alpha: 0.95),
                const Color(0xFF1B0206).withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Color.lerp(
                const Color(0xFFFFD700),
                const Color(0xFFFFF176),
                pulseAnimation.value,
              )!,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFFFFD700,
                ).withValues(alpha: 0.2 + 0.3 * pulseAnimation.value),
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
                const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFFFFD700),
                  size: 14,
                ),
                const SizedBox(width: 6),
                const Text(
                  'TOP 777 JACKPOT: ',
                  style: TextStyle(
                    color: Color(0xFFFFDF00),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  formattedJackpot,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    shadows: [Shadow(color: Color(0xFFFF1744), blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'COINS',
                  style: TextStyle(
                    color: Color(0xFFFFE082),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFFFFD700),
                  size: 14,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// CustomPainter to draw neon payline laser traces across winning cells
class PaylineOverlayPainter extends CustomPainter {
  final List<LineWinResult> lineWins;
  final double pulse;

  static const List<Color> _lineColors = [
    Color(0xFFFF1744), // Line 1: Red
    Color(0xFFFFEA00), // Line 2: Gold/Yellow
    Color(0xFF00E5FF), // Line 3: Cyan
    Color(0xFF00E676), // Line 4: Neon Green
    Color(0xFFFF4081), // Line 5: Neon Pink
  ];

  PaylineOverlayPainter({required this.lineWins, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    if (lineWins.isEmpty) return;

    final cellW = size.width / 3.0;
    final cellH = size.height / 3.0;

    // Center coordinates of cell index (0..8)
    Offset getCellCenter(int index) {
      final col = index % 3;
      final row = index ~/ 3;
      return Offset(col * cellW + cellW / 2.0, row * cellH + cellH / 2.0);
    }

    for (int i = 0; i < lineWins.length; i++) {
      final win = lineWins[i];
      final color = _lineColors[(win.payline.id - 1) % _lineColors.length];

      final p0 = getCellCenter(win.payline.cellIndices[0]);
      final p1 = getCellCenter(win.payline.cellIndices[1]);
      final p2 = getCellCenter(win.payline.cellIndices[2]);

      final path = Path();
      path.moveTo(p0.dx, p0.dy);
      path.lineTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);

      // Outer glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.45 + 0.35 * pulse)
        ..strokeWidth = 7.0 + 3.0 * pulse
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawPath(path, glowPaint);

      // Core bright laser beam
      final corePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      canvas.drawPath(path, corePaint);

      // Node circles at each winning cell
      final nodePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final nodeWhite = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      for (final p in [p0, p1, p2]) {
        canvas.drawCircle(p, 5.0 + 2.0 * pulse, nodePaint);
        canvas.drawCircle(p, 2.5, nodeWhite);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PaylineOverlayPainter oldDelegate) {
    return oldDelegate.pulse != pulse || oldDelegate.lineWins != lineWins;
  }
}

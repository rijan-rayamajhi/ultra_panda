import 'package:flutter/material.dart';
import '../../core/app_assets.dart';
import '../common/frame_shine.dart';
import '../common/reel_column.dart';
import '../../models/triple_diamond_model.dart';

class TripleDiamondCabinet extends StatelessWidget {
  static final List<DiamondSymbolType> _spinSymbols = DiamondSymbolType.values
      .where((t) => t != DiamondSymbolType.scatter)
      .toList();

  final List<DiamondSymbolType> grid; // 9 symbols: 3 cols x 3 rows
  final List<DiamondLineWinResult> lineWins;
  final bool isSpinning;
  final int currentBet;
  final List<AnimationController> reelControllers;
  final Animation<double> pulseAnimation;

  const TripleDiamondCabinet({
    super.key,
    required this.grid,
    required this.lineWins,
    required this.isSpinning,
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

        // Native frame ratio for Frame_TripleDiamond: 1446 x 1087 (~1.3302 : 1)
        double frameHeight = maxH * 0.98;
        double frameWidth = frameHeight * (1446 / 1087);

        if (frameWidth > maxW * 0.96) {
          frameWidth = maxW * 0.96;
          frameHeight = frameWidth * (1087 / 1446);
        }

        // Calibrated inner transparent window bounds in Frame_TripleDiamond (1446 x 1087):
        // left: 14.59%, top: 33.03%, width: 70.82%, height: 48.85%
        final reelLeft = frameWidth * 0.1459;
        final reelTop = frameHeight * 0.3303;
        final reelWidth = frameWidth * 0.7082;
        final reelHeight = frameHeight * 0.4885;

        // Taller Crown Header Jackpot Ticker up top
        final tickerTop = frameHeight * 0.080;
        final tickerLeft = frameWidth * 0.20;
        final tickerWidth = frameWidth * 0.60;
        final tickerHeight = frameHeight * 0.15;

        // Winning cells indices
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
              // 1. Reel Grid Backdrop & Symbols (Layered behind frame)
              Positioned(
                left: reelLeft,
                top: reelTop,
                width: reelWidth,
                height: reelHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(
                      0xF207132B,
                    ), // Royal velvet navy-blue backdrop
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0x8800E5FF),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x5500B0FF),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
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
                              painter: DiamondPaylinePainter(
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

              // 2. Triple Diamond Cabinet Frame Foreground Overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: FrameShine(
                    child: Image.asset(
                      AppAssets.frameTripleDiamond,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),

              // 3. Taller Crown Header Jackpot Ticker (1000x Diamond Jackpot)
              Positioned(
                left: tickerLeft,
                top: tickerTop,
                width: tickerWidth,
                height: tickerHeight,
                child: _buildCrownJackpotTicker(),
              ),
            ],
          ),
        );
      },
    );
  }

  // 3 Columns x 3 Rows dynamic flex grid
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
                final index = row * 3 + col;
                final symbol = (index < grid.length)
                    ? grid[index]
                    : DiamondSymbolType.bar1;
                return _buildSymbolCell(
                  symbol: symbol,
                  isWinner: !isSpinning && winningCells.contains(index),
                );
              },
              spinCell: (i) => _buildSymbolCell(
                symbol: _spinSymbols[(i * 3 + col) % _spinSymbols.length],
                isWinner: false,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSymbolCell({
    required DiamondSymbolType symbol,
    required bool isWinner,
  }) {
    final config = DiamondSymbolConfig.configs[symbol]!;

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
                            color: const Color(0xFF00E5FF).withValues(
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
                  errorBuilder: (c, e, s) => _buildFallback(symbol),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallback(DiamondSymbolType symbol) {
    String text;
    Color color;

    switch (symbol) {
      case DiamondSymbolType.diamondWild:
        text = 'WILD';
        color = const Color(0xFF00E5FF);
        break;
      case DiamondSymbolType.sevenRed:
        text = '7';
        color = const Color(0xFFFF1744);
        break;
      case DiamondSymbolType.sevenGold:
        text = '7';
        color = const Color(0xFFFFD700);
        break;
      case DiamondSymbolType.panda:
        text = 'PANDA';
        color = const Color(0xFF00E676);
        break;
      case DiamondSymbolType.bar3:
        text = 'BAR 3';
        color = const Color(0xFF7C4DFF);
        break;
      case DiamondSymbolType.bar2:
        text = 'BAR 2';
        color = const Color(0xFF40C4FF);
        break;
      case DiamondSymbolType.bar1:
        text = 'BAR 1';
        color = const Color(0xFFFF9100);
        break;
      case DiamondSymbolType.scatter:
        text = '★';
        color = const Color(0xFFFFD54F);
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
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // Taller Crown Header Jackpot Ticker (1000x Diamond Jackpot)
  Widget _buildCrownJackpotTicker() {
    final topJackpot = currentBet * 1000; // Flat 1000x diamond jackpot
    final formattedJackpot = topJackpot.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF071C3D).withValues(alpha: 0.92),
                const Color(0xFF0D3370).withValues(alpha: 0.95),
                const Color(0xFF071C3D).withValues(alpha: 0.92),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Color.lerp(
                const Color(0xFF00E5FF),
                const Color(0xFFFFD700),
                pulseAnimation.value,
              )!,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF00E5FF,
                ).withValues(alpha: 0.3 + 0.3 * pulseAnimation.value),
                blurRadius: 10,
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
                  Icons.diamond_rounded,
                  color: Color(0xFF00E5FF),
                  size: 14,
                ),
                const SizedBox(width: 5),
                const Text(
                  '1,000X DIAMOND JACKPOT: ',
                  style: TextStyle(
                    color: Color(0xFF80D8FF),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  formattedJackpot,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    shadows: [Shadow(color: Color(0xFF00B0FF), blurRadius: 8)],
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.diamond_rounded,
                  color: Color(0xFF00E5FF),
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

// Electric diamond cyan/gold payline laser painter
class DiamondPaylinePainter extends CustomPainter {
  final List<DiamondLineWinResult> lineWins;
  final double pulse;

  static const List<Color> _lineColors = [
    Color(0xFF00E5FF), // Cyan Diamond
    Color(0xFFFFEA00), // Gold
    Color(0xFFFF1744), // Red
    Color(0xFF00E676), // Neon Green
    Color(0xFFE040FB), // Magenta
  ];

  DiamondPaylinePainter({required this.lineWins, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    if (lineWins.isEmpty) return;

    final cellW = size.width / 3.0;
    final cellH = size.height / 3.0;

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

      // Glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.45 + 0.35 * pulse)
        ..strokeWidth = 7.0 + 3.0 * pulse
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawPath(path, glowPaint);

      // Beam
      final corePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      canvas.drawPath(path, corePaint);

      // Diamond sparkle nodes
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
  bool shouldRepaint(covariant DiamondPaylinePainter oldDelegate) {
    return oldDelegate.pulse != pulse || oldDelegate.lineWins != lineWins;
  }
}

import 'package:flutter/material.dart';
import '../../core/app_assets.dart';
import '../common/frame_shine.dart';
import '../common/reel_column.dart';
import '../../models/dragon_gold_model.dart';

class DragonGoldCabinet extends StatelessWidget {
  // Base symbols the reels flash through while spinning (no coin — it's the
  // Hold & Win trigger and shouldn't appear mid-spin as filler).
  static const List<DragonSymbolType> _spinSymbols = [
    DragonSymbolType.dragon,
    DragonSymbolType.tiger,
    DragonSymbolType.koi,
    DragonSymbolType.lantern,
    DragonSymbolType.ingot,
    DragonSymbolType.wild,
  ];

  final List<DragonSymbolType> grid;
  final Map<int, HoldAndWinCoin> lockedCoins;
  final Set<DragonSymbolType> winningSymbols;
  final bool isSpinning;
  final bool isBonusMode;
  final int currentBet;
  final List<AnimationController> reelControllers;
  final Animation<double> pulseAnimation;

  const DragonGoldCabinet({
    super.key,
    required this.grid,
    required this.lockedCoins,
    required this.winningSymbols,
    required this.isSpinning,
    required this.isBonusMode,
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

        // Native frame ratio: 1536 x 1024
        double frameHeight = maxH * 0.995;
        double frameWidth = frameHeight * (1536 / 1024);

        if (frameWidth > maxW * 0.99) {
          frameWidth = maxW * 0.99;
          frameHeight = frameWidth * (1024 / 1536);
        }

        // Calibrated transparent window bounds inside Frame_DragonGold (1536 x 1024):
        // Measured on-device against the frame's inner gold edge.
        final reelLeft = frameWidth * 0.158;
        final reelTop = frameHeight * 0.295;
        final reelWidth = frameWidth * 0.684;
        final reelHeight = frameHeight * 0.52;

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
                    color: const Color(0xF00A030E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0x88FFD700),
                      width: 1.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _build5x3Grid(),
                  ),
                ),
              ),

              // 2. Twin-Dragon Ornate Cabinet Frame (Foreground overlay)
              Positioned.fill(
                child: IgnorePointer(
                  child: FrameShine(
                    child: Image.asset(
                      AppAssets.frameDragonGold,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 5 Columns x 3 Rows dynamic flex grid (Zero overflow)
  Widget _build5x3Grid() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(5, (colIndex) {
        // Hold & Win respins lock the reels — keep them static there.
        if (isBonusMode) {
          return Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(3, (rowIndex) {
                final cellIndex = rowIndex * 5 + colIndex;
                return Expanded(child: _buildCell(cellIndex, colIndex));
              }),
            ),
          );
        }
        return Expanded(
          child: ReelColumn(
            controller: reelControllers[colIndex],
            isSpinning: isSpinning,
            rows: 3,
            settledCell: (row) => _buildCell(row * 5 + colIndex, colIndex),
            spinCell: (i) =>
                _buildSpinTile(_spinSymbols[(i * 5 + colIndex) % _spinSymbols.length]),
          ),
        );
      }),
    );
  }

  // Lightweight tile for the spinning strip.
  Widget _buildSpinTile(DragonSymbolType sym) {
    return Container(
      margin: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: const Color(0x331C0828),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33FFD54F), width: 0.6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Image.asset(
          DragonSymbolConfig.configs[sym]!.assetPath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildCell(int cellIndex, int colIndex) {
    final isLockedCoin = lockedCoins.containsKey(cellIndex);
    final coin = lockedCoins[cellIndex];
    final sym = grid[cellIndex];
    final isWinning =
        winningSymbols.contains(sym) ||
        (winningSymbols.isNotEmpty && sym == DragonSymbolType.wild);

    // Hold & Win bonus mode
    if (isBonusMode) {
      if (isLockedCoin) {
        return _buildLockedCoinCell(coin!);
      } else {
        return _buildEmptyRespinCell();
      }
    }

    // Base Game Cell (settled). Spin motion is handled by ReelColumn.
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        if (isWinning) {
          return ScaleTransition(scale: pulseAnimation, child: child);
        }
        return child!;
      },
      child: Container(
        margin: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          color: isWinning ? const Color(0x55FFD700) : const Color(0x331C0828),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isWinning
                ? const Color(0xFFFFD700)
                : const Color(0x33FFD54F),
            width: isWinning ? 1.6 : 0.6,
          ),
          boxShadow: isWinning
              ? const [
                  BoxShadow(
                    color: Color(0x88FFD700),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(1.0),
              child: Image.asset(
                DragonSymbolConfig.configs[sym]!.assetPath,
                fit: BoxFit.contain,
              ),
            ),
            if (sym == DragonSymbolType.coin)
              Positioned(
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                      width: 0.7,
                    ),
                  ),
                  child: Text(
                    HoldAndWinCoin.formatCompact(currentBet * 2),
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedCoinCell(HoldAndWinCoin coin) {
    return Container(
      margin: const EdgeInsets.all(2.0),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Color(0xAAFFD700), blurRadius: 8, spreadRadius: 1),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(AppAssets.symDragonCoin, fit: BoxFit.contain),
          Positioned(
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A0000), Color(0xFF8E1438)],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD700), width: 0.8),
              ),
              child: Text(
                coin.displayLabel,
                style: TextStyle(
                  color: coin.jackpotTier != null
                      ? const Color(0xFFFFEB3B)
                      : Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRespinCell() {
    return Container(
      margin: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: const Color(0x221A041A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33FFD54F), width: 0.5),
      ),
      child: Center(
        child: Icon(
          Icons.blur_on_rounded,
          size: 14,
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}

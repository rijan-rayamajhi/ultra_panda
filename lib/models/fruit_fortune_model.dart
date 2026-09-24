import 'dart:math' as math;
import '../core/app_assets.dart';

enum FruitSymbolType {
  pineapple,
  watermelon,
  grape,
  plum,
  orange,
  lemon,
  cherry,
  pandaWild,
  scatter,
}

class FruitSymbolConfig {
  final FruitSymbolType type;
  final String name;
  final String assetPath;
  final int basePay; // Base payout for 6+ tier
  final bool isWild;
  final bool isScatter;

  const FruitSymbolConfig({
    required this.type,
    required this.name,
    required this.assetPath,
    required this.basePay,
    this.isWild = false,
    this.isScatter = false,
  });

  static const Map<FruitSymbolType, FruitSymbolConfig> configs = {
    FruitSymbolType.pineapple: FruitSymbolConfig(
      type: FruitSymbolType.pineapple,
      name: 'Pineapple',
      assetPath: AppAssets.symPineapple,
      basePay: 30,
    ),
    FruitSymbolType.watermelon: FruitSymbolConfig(
      type: FruitSymbolType.watermelon,
      name: 'Watermelon',
      assetPath: AppAssets.symWatermelon,
      basePay: 20,
    ),
    FruitSymbolType.grape: FruitSymbolConfig(
      type: FruitSymbolType.grape,
      name: 'Grape',
      assetPath: AppAssets.symGrapes,
      basePay: 12,
    ),
    FruitSymbolType.plum: FruitSymbolConfig(
      type: FruitSymbolType.plum,
      name: 'Plum',
      assetPath: AppAssets.symPlum,
      basePay: 8,
    ),
    FruitSymbolType.orange: FruitSymbolConfig(
      type: FruitSymbolType.orange,
      name: 'Orange',
      assetPath: AppAssets.symOrange,
      basePay: 6,
    ),
    FruitSymbolType.lemon: FruitSymbolConfig(
      type: FruitSymbolType.lemon,
      name: 'Lemon',
      assetPath: AppAssets.symLemon,
      basePay: 5,
    ),
    FruitSymbolType.cherry: FruitSymbolConfig(
      type: FruitSymbolType.cherry,
      name: 'Cherry',
      assetPath: AppAssets.symCherry,
      basePay: 5,
    ),
    FruitSymbolType.pandaWild: FruitSymbolConfig(
      type: FruitSymbolType.pandaWild,
      name: 'Panda Wild',
      assetPath: AppAssets.symPandaWild,
      basePay: 0,
      isWild: true,
    ),
    FruitSymbolType.scatter: FruitSymbolConfig(
      type: FruitSymbolType.scatter,
      name: 'Scatter',
      assetPath: AppAssets.symScatter,
      basePay: 0,
      isScatter: true,
    ),
  };
}

class FruitWinCluster {
  final FruitSymbolType symbol;
  final int count;
  final double tierMultiplier;
  final int basePay;
  final int winAmount;
  final List<int> winningCellIndices;

  const FruitWinCluster({
    required this.symbol,
    required this.count,
    required this.tierMultiplier,
    required this.basePay,
    required this.winAmount,
    required this.winningCellIndices,
  });
}

class CascadeStepResult {
  final int stepIndex; // 0-indexed (0 = initial cascade step)
  final int cascadeMultiplier; // 1x, 2x, 3x, 5x, 10x
  final List<FruitSymbolType> gridBefore; // 21 cells
  final List<FruitWinCluster> clusters;
  final Set<int> poppedIndices;
  final List<FruitSymbolType> gridAfter; // After drop
  final int stepWin;

  const CascadeStepResult({
    required this.stepIndex,
    required this.cascadeMultiplier,
    required this.gridBefore,
    required this.clusters,
    required this.poppedIndices,
    required this.gridAfter,
    required this.stepWin,
  });
}

class FruitSpinResult {
  final List<FruitSymbolType> initialGrid; // 21 cells
  final List<CascadeStepResult> cascadeSteps;
  final int totalWin;
  final int scatterCount;
  final bool triggersFreeSpins;
  final int freeSpinsAwarded;

  const FruitSpinResult({
    required this.initialGrid,
    required this.cascadeSteps,
    required this.totalWin,
    required this.scatterCount,
    required this.triggersFreeSpins,
    required this.freeSpinsAwarded,
  });
}

class FruitFortuneEngine {
  static final math.Random _random = math.Random();

  // Multiplier ladder: 1x -> 2x -> 3x -> 5x -> 10x
  static const List<int> multiplierLadder = [1, 2, 3, 5, 10];
  static const int maxCascades = 12;
  static const int minCluster = 7;
  static const double _payDivisor = 5.6;

  // 7 Columns x 3 Rows = 21 cells
  static const int numCols = 7;
  static const int numRows = 3;
  static const int totalCells = numCols * numRows;

  // Reel weights, cluster sizes and pay divisor tuned by simulation
  // (test/rtp_test.dart) to ~95% RTP including free spins.
  static final List<FruitSymbolType> _reelPool = [
    ...List.filled(21, FruitSymbolType.cherry),
    ...List.filled(21, FruitSymbolType.lemon),
    ...List.filled(21, FruitSymbolType.orange),
    ...List.filled(21, FruitSymbolType.plum),
    ...List.filled(20, FruitSymbolType.grape),
    ...List.filled(18, FruitSymbolType.watermelon),
    ...List.filled(17, FruitSymbolType.pineapple),
    ...List.filled(3, FruitSymbolType.pandaWild),
    ...List.filled(2, FruitSymbolType.scatter),
  ];

  static FruitSymbolType randomSymbol() {
    return _reelPool[_random.nextInt(_reelPool.length)];
  }

  // Generates initial 21-cell grid (column-major index: cell = col * numRows + row)
  static List<FruitSymbolType> generateInitialGrid({
    bool forceFreeSpins = false,
  }) {
    final grid = List.generate(totalCells, (_) => randomSymbol());
    if (forceFreeSpins) {
      grid[0] = FruitSymbolType.scatter;
      grid[10] = FruitSymbolType.scatter;
      grid[20] = FruitSymbolType.scatter;
    }
    return grid;
  }

  // Full Spin evaluation with up to 12 cascades
  static FruitSpinResult playSpin({
    required int bet,
    bool isFreeSpin = false,
    int spinMultiplier = 1, // e.g. 2 for free spins
    bool forceFreeSpins = false,
  }) {
    List<FruitSymbolType> currentGrid = generateInitialGrid(
      forceFreeSpins: forceFreeSpins,
    );
    final initialGrid = List<FruitSymbolType>.from(currentGrid);
    final List<CascadeStepResult> cascadeSteps = [];
    int totalWin = 0;

    int cascadeStep = 0;
    while (cascadeStep < maxCascades) {
      final multLadderIdx = cascadeStep < multiplierLadder.length
          ? cascadeStep
          : multiplierLadder.length - 1;
      final stepMultiplier = multiplierLadder[multLadderIdx] * spinMultiplier;

      final eval = evaluateGrid(
        grid: currentGrid,
        bet: bet,
        cascadeMultiplier: stepMultiplier,
      );

      if (eval.clusters.isEmpty) {
        // No more winning clusters -> cascades end
        break;
      }

      totalWin += eval.totalWin;

      // Apply cascade gravity & refill
      final gridAfter = applyCascade(
        grid: currentGrid,
        poppedIndices: eval.poppedIndices,
      );

      cascadeSteps.add(
        CascadeStepResult(
          stepIndex: cascadeStep,
          cascadeMultiplier: stepMultiplier,
          gridBefore: List<FruitSymbolType>.from(currentGrid),
          clusters: eval.clusters,
          poppedIndices: eval.poppedIndices,
          gridAfter: List<FruitSymbolType>.from(gridAfter),
          stepWin: eval.totalWin,
        ),
      );

      currentGrid = gridAfter;
      cascadeStep++;
    }

    // Evaluate scatters (count all scatters present in the final state)
    int scatterCount = 0;
    for (final sym in currentGrid) {
      if (sym == FruitSymbolType.scatter) {
        scatterCount++;
      }
    }

    final bool triggersFreeSpins = scatterCount >= 3;
    final int freeSpinsAwarded = triggersFreeSpins ? 10 : 0;
    if (triggersFreeSpins) {
      totalWin += bet * 5; // 5x bet scatter trigger reward
    }

    return FruitSpinResult(
      initialGrid: initialGrid,
      cascadeSteps: cascadeSteps,
      totalWin: totalWin,
      scatterCount: scatterCount,
      triggersFreeSpins: triggersFreeSpins,
      freeSpinsAwarded: freeSpinsAwarded,
    );
  }

  // Evaluates pay-anywhere clusters on the current grid
  static ({
    List<FruitWinCluster> clusters,
    Set<int> poppedIndices,
    int totalWin,
  })
  evaluateGrid({
    required List<FruitSymbolType> grid,
    required int bet,
    required int cascadeMultiplier,
  }) {
    // 1. Collect indices of Wilds and each Fruit
    final List<int> wildIndices = [];
    final Map<FruitSymbolType, List<int>> fruitIndices = {};

    for (int i = 0; i < grid.length; i++) {
      final sym = grid[i];
      if (sym == FruitSymbolType.pandaWild) {
        wildIndices.add(i);
      } else if (sym != FruitSymbolType.scatter) {
        fruitIndices.putIfAbsent(sym, () => []).add(i);
      }
    }

    final List<FruitWinCluster> clusters = [];
    final Set<int> poppedIndices = {};
    int totalWin = 0;

    final double unitBet = bet / _payDivisor;

    for (final entry in fruitIndices.entries) {
      final fruit = entry.key;
      final rawIndices = entry.value;
      // Panda Wild substitutes for any fruit
      final effectiveCount = rawIndices.length + wildIndices.length;

      if (effectiveCount >= minCluster) {
        double tierMultiplier = 0.0;
        if (effectiveCount >= minCluster + 4) {
          tierMultiplier = 3.0;
        } else if (effectiveCount >= minCluster + 2) {
          tierMultiplier = 1.6;
        } else {
          tierMultiplier = 1.0;
        }

        final config = FruitSymbolConfig.configs[fruit]!;
        final winAmount =
            (config.basePay * tierMultiplier * unitBet * cascadeMultiplier)
                .round();

        final clusterCells = <int>{...rawIndices, ...wildIndices}.toList();
        poppedIndices.addAll(clusterCells);

        clusters.add(
          FruitWinCluster(
            symbol: fruit,
            count: effectiveCount,
            tierMultiplier: tierMultiplier,
            basePay: config.basePay,
            winAmount: winAmount,
            winningCellIndices: clusterCells,
          ),
        );

        totalWin += winAmount;
      }
    }

    return (
      clusters: clusters,
      poppedIndices: poppedIndices,
      totalWin: totalWin,
    );
  }

  // Gravity drop: for each column, collapse remaining symbols down and spawn new at top
  static List<FruitSymbolType> applyCascade({
    required List<FruitSymbolType> grid,
    required Set<int> poppedIndices,
  }) {
    final newGrid = List<FruitSymbolType>.from(grid);

    for (int col = 0; col < numCols; col++) {
      // Column cells from top to bottom: col * numRows + 0, col * numRows + 1, col * numRows + 2
      final colIndices = [
        col * numRows + 0,
        col * numRows + 1,
        col * numRows + 2,
      ];

      // Keep symbols that did NOT pop
      final surviving = <FruitSymbolType>[];
      for (final idx in colIndices) {
        if (!poppedIndices.contains(idx)) {
          surviving.add(grid[idx]);
        }
      }

      // Fill remaining empty spots from top with fresh random symbols
      final needed = numRows - surviving.length;
      final newSymbols = List.generate(needed, (_) => randomSymbol());
      final fullCol = [
        ...newSymbols,
        ...surviving,
      ]; // New on top, surviving dropped to bottom

      for (int r = 0; r < numRows; r++) {
        newGrid[colIndices[r]] = fullCol[r];
      }
    }

    return newGrid;
  }
}

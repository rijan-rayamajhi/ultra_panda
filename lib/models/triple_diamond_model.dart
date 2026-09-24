import 'dart:math' as math;
import '../core/app_assets.dart';

enum DiamondSymbolType {
  diamondWild,
  sevenRed,
  sevenGold,
  panda,
  bar3,
  bar2,
  bar1,
  scatter,
}

class DiamondSymbolConfig {
  final DiamondSymbolType type;
  final String name;
  final String assetPath;
  final int payout; // 3-of-a-kind line payout multiplier
  final bool isWild;
  final bool isScatter;

  const DiamondSymbolConfig({
    required this.type,
    required this.name,
    required this.assetPath,
    required this.payout,
    this.isWild = false,
    this.isScatter = false,
  });

  static const Map<DiamondSymbolType, DiamondSymbolConfig> configs = {
    DiamondSymbolType.diamondWild: DiamondSymbolConfig(
      type: DiamondSymbolType.diamondWild,
      name: 'Diamond',
      assetPath: AppAssets.symDiamond,
      payout: 1000,
      isWild: true,
    ),
    DiamondSymbolType.sevenRed: DiamondSymbolConfig(
      type: DiamondSymbolType.sevenRed,
      name: 'Seven Red',
      assetPath: AppAssets.sym7Red,
      payout: 80,
    ),
    DiamondSymbolType.sevenGold: DiamondSymbolConfig(
      type: DiamondSymbolType.sevenGold,
      name: 'Seven Gold',
      assetPath: AppAssets.sym7Gold,
      payout: 40,
    ),
    DiamondSymbolType.panda: DiamondSymbolConfig(
      type: DiamondSymbolType.panda,
      name: 'Panda',
      assetPath: AppAssets.symPanda,
      payout: 20,
    ),
    DiamondSymbolType.bar3: DiamondSymbolConfig(
      type: DiamondSymbolType.bar3,
      name: 'Triple Bar',
      assetPath: AppAssets.symBar3,
      payout: 12,
    ),
    DiamondSymbolType.bar2: DiamondSymbolConfig(
      type: DiamondSymbolType.bar2,
      name: 'Double Bar',
      assetPath: AppAssets.symBar2,
      payout: 6,
    ),
    DiamondSymbolType.bar1: DiamondSymbolConfig(
      type: DiamondSymbolType.bar1,
      name: 'Single Bar',
      assetPath: AppAssets.symBar1,
      payout: 4,
    ),
    DiamondSymbolType.scatter: DiamondSymbolConfig(
      type: DiamondSymbolType.scatter,
      name: 'Scatter',
      assetPath: AppAssets.symScatter,
      payout: 0,
      isScatter: true,
    ),
  };
}

class DiamondPaylineDefinition {
  final int id;
  final String name;
  final List<int> cellIndices; // 3 cells

  const DiamondPaylineDefinition({
    required this.id,
    required this.name,
    required this.cellIndices,
  });
}

class DiamondLineWinResult {
  final DiamondPaylineDefinition payline;
  final String winningName;
  final int basePayout;
  final int wildMultiplier; // 1x, 3x, or 9x
  final int winAmount;
  final bool isMixedBar;
  final bool isPureDiamonds;

  const DiamondLineWinResult({
    required this.payline,
    required this.winningName,
    required this.basePayout,
    required this.wildMultiplier,
    required this.winAmount,
    this.isMixedBar = false,
    this.isPureDiamonds = false,
  });
}

class DiamondSpinResult {
  final List<DiamondSymbolType> grid; // 9 symbols (3 cols x 3 rows)
  final List<DiamondLineWinResult> lineWins;
  final int totalWin;
  final int scatterCount;
  final bool wasNudged;
  final int? nudgedColIndex;

  const DiamondSpinResult({
    required this.grid,
    required this.lineWins,
    required this.totalWin,
    required this.scatterCount,
    this.wasNudged = false,
    this.nudgedColIndex,
  });
}

class TripleDiamondEngine {
  static final math.Random _random = math.Random();

  // 5 Fixed Paylines in 3x3 Grid:
  // Indices:
  // 0  1  2  (Row 0: Top)
  // 3  4  5  (Row 1: Middle)
  // 6  7  8  (Row 2: Bottom)
  static const List<DiamondPaylineDefinition> paylines = [
    DiamondPaylineDefinition(
      id: 1,
      name: 'Top Horizontal',
      cellIndices: [0, 1, 2],
    ),
    DiamondPaylineDefinition(
      id: 2,
      name: 'Middle Horizontal',
      cellIndices: [3, 4, 5],
    ),
    DiamondPaylineDefinition(
      id: 3,
      name: 'Bottom Horizontal',
      cellIndices: [6, 7, 8],
    ),
    DiamondPaylineDefinition(
      id: 4,
      name: 'Diagonal Down',
      cellIndices: [0, 4, 8],
    ),
    DiamondPaylineDefinition(
      id: 5,
      name: 'Diagonal Up',
      cellIndices: [6, 4, 2],
    ),
  ];

  // Reel weights + nudge tuned by simulation (test/rtp_test.dart) to ~95% RTP.
  static final List<DiamondSymbolType> _reelPool = [
    ...List.filled(44, DiamondSymbolType.bar1),
    ...List.filled(30, DiamondSymbolType.bar2),
    ...List.filled(17, DiamondSymbolType.bar3),
    ...List.filled(11, DiamondSymbolType.panda),
    ...List.filled(6, DiamondSymbolType.sevenGold),
    ...List.filled(4, DiamondSymbolType.sevenRed),
    ...List.filled(3, DiamondSymbolType.diamondWild),
    ...List.filled(3, DiamondSymbolType.scatter),
  ];

  // Nudge pool: low bars only (never Diamonds), so nudges add hit rate
  // without inflating RTP.
  static const List<DiamondSymbolType> nudgeSymbols = [
    DiamondSymbolType.bar1,
    DiamondSymbolType.bar2,
  ];
  static const double _nudgeChance = 0.03;

  static DiamondSpinResult generateSpin({
    required int bet,
    bool forceJackpot = false,
  }) {
    List<DiamondSymbolType> grid = List.generate(
      9,
      (_) => _reelPool[_random.nextInt(_reelPool.length)],
    );

    bool wasNudged = false;
    int? nudgedCol;

    if (forceJackpot) {
      grid[3] = DiamondSymbolType.diamondWild;
      grid[4] = DiamondSymbolType.diamondWild;
      grid[5] = DiamondSymbolType.diamondWild;
    } else {
      if (_random.nextDouble() < _nudgeChance) {
        final targetLine = paylines[_random.nextInt(paylines.length)];
        final nudgeSymbol = nudgeSymbols[_random.nextInt(nudgeSymbols.length)];
        for (final idx in targetLine.cellIndices) {
          grid[idx] = nudgeSymbol;
        }
        wasNudged = true;
        nudgedCol = 2;
      }
    }

    // 1. Evaluate Line Wins (5 fixed paylines)
    // Line bet is bet / 5
    final int lineBet = (bet / 5).round();
    final List<DiamondLineWinResult> lineWins = [];
    int totalWin = 0;

    for (final line in paylines) {
      final s0 = grid[line.cellIndices[0]];
      final s1 = grid[line.cellIndices[1]];
      final s2 = grid[line.cellIndices[2]];

      final eval = _evaluateLine(s0, s1, s2, lineBet);
      if (eval != null) {
        lineWins.add(
          DiamondLineWinResult(
            payline: line,
            winningName: eval.name,
            basePayout: eval.basePayout,
            wildMultiplier: eval.wildMultiplier,
            winAmount: eval.winAmount,
            isPureDiamonds: eval.isPureDiamonds,
          ),
        );
        totalWin += eval.winAmount;
      }
    }

    // 2. Evaluate Scatters (3+ anywhere gives 5x total bet)
    int scatterCount = 0;
    for (final sym in grid) {
      if (sym == DiamondSymbolType.scatter) {
        scatterCount++;
      }
    }

    if (scatterCount >= 3) {
      totalWin += bet * 5;
    }

    return DiamondSpinResult(
      grid: grid,
      lineWins: lineWins,
      totalWin: totalWin,
      scatterCount: scatterCount,
      wasNudged: wasNudged,
      nudgedColIndex: nudgedCol,
    );
  }

  static _DiamondEvaluation? _evaluateLine(
    DiamondSymbolType s0,
    DiamondSymbolType s1,
    DiamondSymbolType s2,
    int lineBet,
  ) {
    if (s0 == DiamondSymbolType.scatter ||
        s1 == DiamondSymbolType.scatter ||
        s2 == DiamondSymbolType.scatter) {
      return null;
    }

    final symbols = [s0, s1, s2];
    final diamondCount = symbols
        .where((s) => s == DiamondSymbolType.diamondWild)
        .length;

    // Case 1: Pure 3x Diamonds (Top 1000x jackpot, not multiplied)
    if (diamondCount == 3) {
      return _DiamondEvaluation(
        name: '3x DIAMONDS',
        basePayout: 1000,
        wildMultiplier: 1,
        winAmount: lineBet * 1000,
        isPureDiamonds: true,
      );
    }

    // Wild line multiplier: 3x per diamond substituting (1 diamond = 3x, 2 diamonds = 9x)
    final wildMultiplier = diamondCount == 2 ? 9 : (diamondCount == 1 ? 3 : 1);

    // Case 2: Matching 3-of-a-kind (with Diamond Wild substitution)
    DiamondSymbolType? candidate;
    for (final s in symbols) {
      if (s != DiamondSymbolType.diamondWild) {
        candidate = s;
        break;
      }
    }

    if (candidate != null) {
      final matchesCandidate = symbols.every(
        (s) => s == candidate || s == DiamondSymbolType.diamondWild,
      );

      if (matchesCandidate) {
        final config = DiamondSymbolConfig.configs[candidate]!;
        final nameSuffix = wildMultiplier > 1 ? ' (${wildMultiplier}X)' : '';
        return _DiamondEvaluation(
          name: '3x ${config.name.toUpperCase()}$nameSuffix',
          basePayout: config.payout,
          wildMultiplier: wildMultiplier,
          winAmount: lineBet * config.payout * wildMultiplier,
        );
      }
    }

    // No mixed-bar pay: with no blank stops, bars make up most of the reel,
    // and an any-bar line would pay on nearly every spin.
    return null;
  }
}

class _DiamondEvaluation {
  final String name;
  final int basePayout;
  final int wildMultiplier;
  final int winAmount;
  final bool isPureDiamonds;

  const _DiamondEvaluation({
    required this.name,
    required this.basePayout,
    required this.wildMultiplier,
    required this.winAmount,
    this.isPureDiamonds = false,
  });
}

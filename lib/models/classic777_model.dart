import 'dart:math' as math;
import '../core/app_assets.dart';

enum ClassicSymbolType {
  sevenRed,
  sevenGold,
  wild,
  bar,
  ace,
  king,
  queen,
  jack,
  ten,
  scatter,
}

class ClassicSymbolConfig {
  final ClassicSymbolType type;
  final String name;
  final String assetPath;
  final int payout; // 3-of-a-kind line payout multiplier

  const ClassicSymbolConfig({
    required this.type,
    required this.name,
    required this.assetPath,
    required this.payout,
  });

  static const Map<ClassicSymbolType, ClassicSymbolConfig> configs = {
    ClassicSymbolType.sevenRed: ClassicSymbolConfig(
      type: ClassicSymbolType.sevenRed,
      name: 'Seven Red',
      assetPath: AppAssets.sym7Red,
      payout: 500,
    ),
    ClassicSymbolType.sevenGold: ClassicSymbolConfig(
      type: ClassicSymbolType.sevenGold,
      name: 'Seven Gold',
      assetPath: AppAssets.sym7Gold,
      payout: 250,
    ),
    ClassicSymbolType.wild: ClassicSymbolConfig(
      type: ClassicSymbolType.wild,
      name: 'Wild',
      assetPath: AppAssets.symWild,
      payout: 300,
    ),
    ClassicSymbolType.bar: ClassicSymbolConfig(
      type: ClassicSymbolType.bar,
      name: 'Bar',
      assetPath: AppAssets.symBar,
      payout: 100,
    ),
    ClassicSymbolType.ace: ClassicSymbolConfig(
      type: ClassicSymbolType.ace,
      name: 'Ace',
      assetPath: AppAssets.symA,
      payout: 50,
    ),
    ClassicSymbolType.king: ClassicSymbolConfig(
      type: ClassicSymbolType.king,
      name: 'King',
      assetPath: AppAssets.symK,
      payout: 30,
    ),
    ClassicSymbolType.queen: ClassicSymbolConfig(
      type: ClassicSymbolType.queen,
      name: 'Queen',
      assetPath: AppAssets.symQ,
      payout: 20,
    ),
    ClassicSymbolType.jack: ClassicSymbolConfig(
      type: ClassicSymbolType.jack,
      name: 'Jack',
      assetPath: AppAssets.symJ,
      payout: 15,
    ),
    ClassicSymbolType.ten: ClassicSymbolConfig(
      type: ClassicSymbolType.ten,
      name: 'Ten',
      assetPath: AppAssets.sym10,
      payout: 10,
    ),
    ClassicSymbolType.scatter: ClassicSymbolConfig(
      type: ClassicSymbolType.scatter,
      name: 'Scatter',
      assetPath: AppAssets.symScatter,
      payout: 0,
    ),
  };
}

class PaylineDefinition {
  final int id;
  final String name;
  final List<int> cellIndices; // 3 cells

  const PaylineDefinition({
    required this.id,
    required this.name,
    required this.cellIndices,
  });
}

class LineWinResult {
  final PaylineDefinition payline;
  final String winningName;
  final int payoutMultiplier;
  final int winAmount;
  final bool isMixedSeven;

  const LineWinResult({
    required this.payline,
    required this.winningName,
    required this.payoutMultiplier,
    required this.winAmount,
    this.isMixedSeven = false,
  });
}

class ClassicSpinResult {
  final List<ClassicSymbolType> grid; // 9 symbols (3 cols x 3 rows)
  final List<LineWinResult> lineWins;
  final int totalWin;
  final int scatterCount;
  final bool triggersFreeSpins;
  final int freeSpinsAwarded;
  final bool wasNudged;
  final int? nudgedColIndex;

  const ClassicSpinResult({
    required this.grid,
    required this.lineWins,
    required this.totalWin,
    required this.scatterCount,
    required this.triggersFreeSpins,
    required this.freeSpinsAwarded,
    this.wasNudged = false,
    this.nudgedColIndex,
  });
}

class Classic777Engine {
  static final math.Random _random = math.Random();

  // 5 Fixed Paylines in 3x3 Grid:
  // Indices:
  // 0  1  2  (Row 0: Top)
  // 3  4  5  (Row 1: Middle)
  // 6  7  8  (Row 2: Bottom)
  static const List<PaylineDefinition> paylines = [
    PaylineDefinition(id: 1, name: 'Top Horizontal', cellIndices: [0, 1, 2]),
    PaylineDefinition(id: 2, name: 'Middle Horizontal', cellIndices: [3, 4, 5]),
    PaylineDefinition(id: 3, name: 'Bottom Horizontal', cellIndices: [6, 7, 8]),
    PaylineDefinition(id: 4, name: 'Diagonal Down', cellIndices: [0, 4, 8]),
    PaylineDefinition(id: 5, name: 'Diagonal Up', cellIndices: [6, 4, 2]),
  ];

  // Reel weights + nudge tuned by simulation (test/rtp_test.dart) to ~95% RTP
  // including free spins.
  static final List<ClassicSymbolType> _reelPool = [
    ...List.filled(30, ClassicSymbolType.ten),
    ...List.filled(26, ClassicSymbolType.jack),
    ...List.filled(20, ClassicSymbolType.queen),
    ...List.filled(15, ClassicSymbolType.king),
    ...List.filled(10, ClassicSymbolType.ace),
    ...List.filled(7, ClassicSymbolType.bar),
    ...List.filled(4, ClassicSymbolType.sevenGold),
    ...List.filled(3, ClassicSymbolType.sevenRed),
    ...List.filled(3, ClassicSymbolType.wild),
    ...List.filled(5, ClassicSymbolType.scatter),
  ];

  // Nudge pool: low symbols only, so nudges add hit rate without inflating RTP.
  static const List<ClassicSymbolType> _nudgeSymbols = [
    ClassicSymbolType.ten,
    ClassicSymbolType.jack,
  ];
  static const double _nudgeChance = 0.01;

  static ClassicSpinResult generateSpin({
    required int bet,
    bool isFreeSpin = false,
    int multiplier = 1,
    bool forceFreeSpins = false,
  }) {
    List<ClassicSymbolType> grid = List.generate(
      9,
      (_) => _reelPool[_random.nextInt(_reelPool.length)],
    );

    bool wasNudged = false;
    int? nudgedCol;

    if (forceFreeSpins) {
      grid[0] = ClassicSymbolType.scatter;
      grid[4] = ClassicSymbolType.scatter;
      grid[8] = ClassicSymbolType.scatter;
    } else if (!isFreeSpin) {
      if (_random.nextDouble() < _nudgeChance) {
        final targetLine = paylines[_random.nextInt(paylines.length)];
        final nudgeSymbol =
            _nudgeSymbols[_random.nextInt(_nudgeSymbols.length)];
        for (final idx in targetLine.cellIndices) {
          grid[idx] = nudgeSymbol;
        }
        wasNudged = true;
        nudgedCol = 2; // Nudge effect on last column
      }
    }

    // 1. Evaluate Line Wins (5 fixed paylines)
    // Per-line bet is bet / 5
    final int lineBet = (bet / 5).round();
    final List<LineWinResult> lineWins = [];
    int totalWin = 0;

    for (final line in paylines) {
      final s0 = grid[line.cellIndices[0]];
      final s1 = grid[line.cellIndices[1]];
      final s2 = grid[line.cellIndices[2]];

      final eval = _evaluatePayline(s0, s1, s2, lineBet, multiplier);
      if (eval != null) {
        lineWins.add(
          LineWinResult(
            payline: line,
            winningName: eval.name,
            payoutMultiplier: eval.payout,
            winAmount: eval.winAmount,
            isMixedSeven: eval.isMixedSeven,
          ),
        );
        totalWin += eval.winAmount;
      }
    }

    // 2. Evaluate Scatters (3+ anywhere trigger 10 Free Spins at 2x + 5x bet pay)
    int scatterCount = 0;
    for (final sym in grid) {
      if (sym == ClassicSymbolType.scatter) {
        scatterCount++;
      }
    }

    final bool triggersFreeSpins = scatterCount >= 3;
    final int freeSpinsAwarded = triggersFreeSpins ? 10 : 0;
    if (triggersFreeSpins) {
      // 5x total bet scatter pay
      totalWin += bet * 5;
    }

    return ClassicSpinResult(
      grid: grid,
      lineWins: lineWins,
      totalWin: totalWin,
      scatterCount: scatterCount,
      triggersFreeSpins: triggersFreeSpins,
      freeSpinsAwarded: freeSpinsAwarded,
      wasNudged: wasNudged,
      nudgedColIndex: nudgedCol,
    );
  }

  static _PaylineEvaluation? _evaluatePayline(
    ClassicSymbolType s0,
    ClassicSymbolType s1,
    ClassicSymbolType s2,
    int lineBet,
    int multiplier,
  ) {
    // Cannot make payline wins with scatters
    if (s0 == ClassicSymbolType.scatter ||
        s1 == ClassicSymbolType.scatter ||
        s2 == ClassicSymbolType.scatter) {
      return null;
    }

    final symbols = [s0, s1, s2];

    // Case 1: Pure 3x Wild
    if (symbols.every((s) => s == ClassicSymbolType.wild)) {
      final payout =
          ClassicSymbolConfig.configs[ClassicSymbolType.wild]!.payout;
      return _PaylineEvaluation(
        name: '3x WILD',
        payout: payout,
        winAmount: (lineBet * payout * multiplier),
      );
    }

    // Case 2: Matching 3-of-a-kind (with Wild substitution)
    ClassicSymbolType? candidate;
    for (final s in symbols) {
      if (s != ClassicSymbolType.wild) {
        candidate = s;
        break;
      }
    }

    if (candidate != null) {
      final matchesCandidate = symbols.every(
        (s) => s == candidate || s == ClassicSymbolType.wild,
      );

      if (matchesCandidate) {
        final config = ClassicSymbolConfig.configs[candidate]!;
        return _PaylineEvaluation(
          name: '3x ${config.name.toUpperCase()}',
          payout: config.payout,
          winAmount: (lineBet * config.payout * multiplier),
        );
      }
    }

    // Case 3: Mixed-Seven Combo
    // Any 3 of {SevenRed, SevenGold} (wilds count) pays AnySeven bonus (50x)
    final isMixedSeven = symbols.every(
      (s) =>
          s == ClassicSymbolType.sevenRed ||
          s == ClassicSymbolType.sevenGold ||
          s == ClassicSymbolType.wild,
    );

    if (isMixedSeven) {
      const payout = 50; // 50x AnySeven payout
      return _PaylineEvaluation(
        name: 'MIXED 777',
        payout: payout,
        winAmount: (lineBet * payout * multiplier),
        isMixedSeven: true,
      );
    }

    return null;
  }
}

class _PaylineEvaluation {
  final String name;
  final int payout;
  final int winAmount;
  final bool isMixedSeven;

  const _PaylineEvaluation({
    required this.name,
    required this.payout,
    required this.winAmount,
    this.isMixedSeven = false,
  });
}

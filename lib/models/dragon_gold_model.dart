import 'dart:math' as math;
import '../core/app_assets.dart';

enum DragonSymbolType { dragon, tiger, koi, lantern, ingot, wild, coin }

enum JackpotTier { mini, minor, major, grand }

class DragonSymbolConfig {
  final DragonSymbolType type;
  final String name;
  final String assetPath;
  final int basePay; // Base pay for 6+ anywhere

  const DragonSymbolConfig({
    required this.type,
    required this.name,
    required this.assetPath,
    required this.basePay,
  });

  static const Map<DragonSymbolType, DragonSymbolConfig> configs = {
    DragonSymbolType.dragon: DragonSymbolConfig(
      type: DragonSymbolType.dragon,
      name: 'Dragon',
      assetPath: AppAssets.symDragon,
      basePay: 74,
    ),
    DragonSymbolType.tiger: DragonSymbolConfig(
      type: DragonSymbolType.tiger,
      name: 'Tiger',
      assetPath: AppAssets.symTiger,
      basePay: 49,
    ),
    DragonSymbolType.koi: DragonSymbolConfig(
      type: DragonSymbolType.koi,
      name: 'Koi',
      assetPath: AppAssets.symKoi,
      basePay: 29,
    ),
    DragonSymbolType.lantern: DragonSymbolConfig(
      type: DragonSymbolType.lantern,
      name: 'Lantern',
      assetPath: AppAssets.symLantern,
      basePay: 20,
    ),
    DragonSymbolType.ingot: DragonSymbolConfig(
      type: DragonSymbolType.ingot,
      name: 'Ingot',
      assetPath: AppAssets.symIngot,
      basePay: 15,
    ),
    DragonSymbolType.wild: DragonSymbolConfig(
      type: DragonSymbolType.wild,
      name: 'Wild',
      assetPath: AppAssets.symWild,
      basePay: 0,
    ),
    DragonSymbolType.coin: DragonSymbolConfig(
      type: DragonSymbolType.coin,
      name: 'Dragon Coin',
      assetPath: AppAssets.symDragonCoin,
      basePay: 0,
    ),
  };
}

class HoldAndWinCoin {
  final int cellIndex;
  final int cashMultiplier; // 1x to 40x
  final JackpotTier? jackpotTier;
  final int valueAmount; // Actual coin credit value based on bet

  const HoldAndWinCoin({
    required this.cellIndex,
    required this.cashMultiplier,
    this.jackpotTier,
    required this.valueAmount,
  });

  String get displayLabel {
    if (jackpotTier != null) {
      switch (jackpotTier!) {
        case JackpotTier.mini:
          return 'MINI';
        case JackpotTier.minor:
          return 'MINOR';
        case JackpotTier.major:
          return 'MAJOR';
        case JackpotTier.grand:
          return 'GRAND';
      }
    }
    return formatCompact(valueAmount);
  }

  static String formatCompact(int amount) {
    if (amount >= 1000000) {
      final double val = amount / 1000000.0;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}M';
    } else if (amount >= 1000) {
      final double val = amount / 1000.0;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}K';
    }
    return '$amount';
  }
}

class SpinEvaluationResult {
  final List<DragonSymbolType> grid; // 15 symbols (row major: 3 rows, 5 cols)
  final Map<DragonSymbolType, int> winningSymbolCounts;
  final Map<DragonSymbolType, int> symbolPayouts;
  final int totalBaseWin;
  final List<HoldAndWinCoin> triggeringCoins;
  final bool triggersBonus;

  const SpinEvaluationResult({
    required this.grid,
    required this.winningSymbolCounts,
    required this.symbolPayouts,
    required this.totalBaseWin,
    required this.triggeringCoins,
    required this.triggersBonus,
  });
}

class DragonGoldEngine {
  static final math.Random _random = math.Random();

  // Reel weights, pay divisor and coin values tuned by simulation
  // (test/rtp_test.dart) to ~95% RTP including Hold & Win.
  static const double _payDivisor = 19;
  static final List<DragonSymbolType> _reelPool = [
    ...List.filled(16, DragonSymbolType.ingot),
    ...List.filled(15, DragonSymbolType.lantern),
    ...List.filled(14, DragonSymbolType.koi),
    ...List.filled(13, DragonSymbolType.tiger),
    ...List.filled(12, DragonSymbolType.dragon),
    ...List.filled(3, DragonSymbolType.wild),
    ...List.filled(10, DragonSymbolType.coin),
  ];

  static SpinEvaluationResult generateSpin({
    required int bet,
    bool forceBonus = false,
  }) {
    final List<DragonSymbolType> grid = List.generate(
      15,
      (_) => _reelPool[_random.nextInt(_reelPool.length)],
    );

    if (forceBonus) {
      // Force at least 6 coins
      final coinIndices = <int>{};
      while (coinIndices.length < 6) {
        coinIndices.add(_random.nextInt(15));
      }
      for (final idx in coinIndices) {
        grid[idx] = DragonSymbolType.coin;
      }
    }

    // 1. Evaluate Coins for Hold & Win Trigger (6+ coins anywhere)
    final List<HoldAndWinCoin> coins = [];
    for (int i = 0; i < grid.length; i++) {
      if (grid[i] == DragonSymbolType.coin) {
        coins.add(_generateCoin(cellIndex: i, bet: bet));
      }
    }

    final bool triggersBonus = coins.length >= 6;

    // 2. Base Game Pay-Anywhere Evaluation
    // Land 6, 8, or 10+ anywhere for 1.0x / 1.6x / 3.0x tiers
    // Wild substitutes for whichever symbol maximizes pay
    int wildCount = 0;
    final Map<DragonSymbolType, int> counts = {
      DragonSymbolType.dragon: 0,
      DragonSymbolType.tiger: 0,
      DragonSymbolType.koi: 0,
      DragonSymbolType.lantern: 0,
      DragonSymbolType.ingot: 0,
    };

    for (final sym in grid) {
      if (sym == DragonSymbolType.wild) {
        wildCount++;
      } else if (counts.containsKey(sym)) {
        counts[sym] = (counts[sym] ?? 0) + 1;
      }
    }

    final Map<DragonSymbolType, int> winningCounts = {};
    final Map<DragonSymbolType, int> payouts = {};
    int totalWin = 0;

    // Evaluate each regular symbol with wild substitution
    counts.forEach((sym, rawCount) {
      final totalEligible = rawCount + wildCount;
      if (totalEligible >= 6) {
        double tierMultiplier = 0.0;
        if (totalEligible >= 10) {
          tierMultiplier = 3.0;
        } else if (totalEligible >= 8) {
          tierMultiplier = 1.6;
        } else {
          tierMultiplier = 1.0;
        }

        final basePay = DragonSymbolConfig.configs[sym]!.basePay;
        // Payout scales with bet
        final symbolWin = (basePay * tierMultiplier * (bet / _payDivisor))
            .round();
        if (symbolWin > 0) {
          winningCounts[sym] = totalEligible;
          payouts[sym] = symbolWin;
          totalWin += symbolWin;
        }
      }
    });

    return SpinEvaluationResult(
      grid: grid,
      winningSymbolCounts: winningCounts,
      symbolPayouts: payouts,
      totalBaseWin: totalWin,
      triggeringCoins: coins,
      triggersBonus: triggersBonus,
    );
  }

  static HoldAndWinCoin _generateCoin({
    required int cellIndex,
    required int bet,
  }) {
    final roll = _random.nextDouble();

    // Jackpots
    // Grand (500x) is awarded only when filling all 15 cells!
    // Major (250x): 0.4%
    // Minor (60x): 1.5%
    // Mini (15x): 5%
    if (roll < 0.004) {
      return HoldAndWinCoin(
        cellIndex: cellIndex,
        cashMultiplier: 250,
        jackpotTier: JackpotTier.major,
        valueAmount: bet * 250,
      );
    } else if (roll < 0.019) {
      return HoldAndWinCoin(
        cellIndex: cellIndex,
        cashMultiplier: 60,
        jackpotTier: JackpotTier.minor,
        valueAmount: bet * 60,
      );
    } else if (roll < 0.069) {
      return HoldAndWinCoin(
        cellIndex: cellIndex,
        cashMultiplier: 15,
        jackpotTier: JackpotTier.mini,
        valueAmount: bet * 15,
      );
    }

    // Cash Values: 1x to 40x bet weighted
    final cashRoll = _random.nextDouble();
    int multiplier = 1;
    if (cashRoll < 0.45) {
      multiplier = 1;
    } else if (cashRoll < 0.70) {
      multiplier = 2;
    } else if (cashRoll < 0.83) {
      multiplier = 3;
    } else if (cashRoll < 0.92) {
      multiplier = 5;
    } else if (cashRoll < 0.96) {
      multiplier = 8;
    } else if (cashRoll < 0.985) {
      multiplier = 10;
    } else if (cashRoll < 0.995) {
      multiplier = 20;
    } else {
      multiplier = 40;
    }

    return HoldAndWinCoin(
      cellIndex: cellIndex,
      cashMultiplier: multiplier,
      jackpotTier: null,
      valueAmount: bet * multiplier,
    );
  }

  static const double dropChance = 0.08;

  // Respin simulation for empty cells (8% land chance per cell per respin)
  static HoldAndWinCoin? tryDropCoin({
    required int cellIndex,
    required int bet,
  }) {
    if (_random.nextDouble() < dropChance) {
      return _generateCoin(cellIndex: cellIndex, bet: bet);
    }
    return null;
  }
}

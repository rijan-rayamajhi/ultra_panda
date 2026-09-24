import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_panda/models/fruit_fortune_model.dart';

void main() {
  group('Ultra Panda (Fruit Fortune) Engine Tests', () {
    test('Symbol payouts and base configs match spec', () {
      expect(FruitSymbolConfig.configs[FruitSymbolType.pineapple]!.basePay, 30);
      expect(
        FruitSymbolConfig.configs[FruitSymbolType.watermelon]!.basePay,
        20,
      );
      expect(FruitSymbolConfig.configs[FruitSymbolType.grape]!.basePay, 12);
      expect(FruitSymbolConfig.configs[FruitSymbolType.plum]!.basePay, 8);
      expect(FruitSymbolConfig.configs[FruitSymbolType.orange]!.basePay, 6);
      expect(FruitSymbolConfig.configs[FruitSymbolType.lemon]!.basePay, 5);
      expect(FruitSymbolConfig.configs[FruitSymbolType.cherry]!.basePay, 5);
      expect(
        FruitSymbolConfig.configs[FruitSymbolType.pandaWild]!.isWild,
        true,
      );
      expect(
        FruitSymbolConfig.configs[FruitSymbolType.scatter]!.isScatter,
        true,
      );
    });

    test('Initial grid generates exactly 21 symbols (7x3 format)', () {
      final grid = FruitFortuneEngine.generateInitialGrid();
      expect(grid.length, 21);
    });

    test(
      'Pay-anywhere evaluation triggers with 7+ symbols and applies correct tiers',
      () {
        const bet = 10000;
        // 6 Pineapples is below the minimum cluster
        final grid5 = [
          ...List.filled(6, FruitSymbolType.pineapple),
          ...List.filled(5, FruitSymbolType.lemon),
          ...List.filled(5, FruitSymbolType.plum),
          ...List.filled(5, FruitSymbolType.orange),
        ];
        expect(
          FruitFortuneEngine.evaluateGrid(
            grid: grid5,
            bet: bet,
            cascadeMultiplier: 1,
          ).clusters,
          isEmpty,
        );

        // 7 Pineapples
        final grid6 = [
          ...List.filled(7, FruitSymbolType.pineapple),
          ...List.filled(14, FruitSymbolType.lemon),
        ];
        final eval6 = FruitFortuneEngine.evaluateGrid(
          grid: grid6,
          bet: bet,
          cascadeMultiplier: 1,
        );
        final pineCluster6 = eval6.clusters.firstWhere(
          (c) => c.symbol == FruitSymbolType.pineapple,
        );
        expect(pineCluster6.count, 7);
        expect(pineCluster6.tierMultiplier, 1.0);

        // 9 Pineapples
        final grid8 = [
          ...List.filled(9, FruitSymbolType.pineapple),
          ...List.filled(12, FruitSymbolType.lemon),
        ];
        final eval8 = FruitFortuneEngine.evaluateGrid(
          grid: grid8,
          bet: bet,
          cascadeMultiplier: 1,
        );
        final pineCluster8 = eval8.clusters.firstWhere(
          (c) => c.symbol == FruitSymbolType.pineapple,
        );
        expect(pineCluster8.count, 9);
        expect(pineCluster8.tierMultiplier, 1.6);

        // 10+ Pineapples
        final grid10 = [
          ...List.filled(11, FruitSymbolType.pineapple),
          ...List.filled(10, FruitSymbolType.lemon),
        ];
        final eval10 = FruitFortuneEngine.evaluateGrid(
          grid: grid10,
          bet: bet,
          cascadeMultiplier: 1,
        );
        final pineCluster10 = eval10.clusters.firstWhere(
          (c) => c.symbol == FruitSymbolType.pineapple,
        );
        expect(pineCluster10.count, 11);
        expect(pineCluster10.tierMultiplier, 3.0);
      },
    );

    test('Panda Wild substitutes for fruits to form pay-anywhere clusters', () {
      const bet = 10000;
      // 5 Watermelons + 2 Panda Wilds = 7 effective
      final grid = [
        ...List.filled(5, FruitSymbolType.watermelon),
        ...List.filled(2, FruitSymbolType.pandaWild),
        ...List.filled(14, FruitSymbolType.plum),
      ];
      final eval = FruitFortuneEngine.evaluateGrid(
        grid: grid,
        bet: bet,
        cascadeMultiplier: 1,
      );
      expect(
        eval.clusters.any((c) => c.symbol == FruitSymbolType.watermelon),
        true,
      );
      final melonCluster = eval.clusters.firstWhere(
        (c) => c.symbol == FruitSymbolType.watermelon,
      );
      expect(melonCluster.count, 7);
    });

    test(
      'Cascade ladder steps up multiplier (1x -> 2x -> 3x -> 5x -> 10x)',
      () {
        expect(FruitFortuneEngine.multiplierLadder, [1, 2, 3, 5, 10]);
      },
    );

    test('Force Free Spins generates 10 free spins with scatter payout', () {
      const bet = 5000;
      final result = FruitFortuneEngine.playSpin(
        bet: bet,
        forceFreeSpins: true,
      );
      expect(result.scatterCount >= 3, true);
      expect(result.triggersFreeSpins, true);
      expect(result.freeSpinsAwarded, 10);
      expect(result.totalWin >= bet * 5, true);
    });
  });
}

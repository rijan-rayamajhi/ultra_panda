import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_panda/models/dragon_gold_model.dart';

void main() {
  group('DragonGold Engine Tests', () {
    test('Symbol payouts and base configs match spec', () {
      expect(DragonSymbolConfig.configs[DragonSymbolType.dragon]!.basePay, 74);
      expect(DragonSymbolConfig.configs[DragonSymbolType.tiger]!.basePay, 49);
      expect(DragonSymbolConfig.configs[DragonSymbolType.koi]!.basePay, 29);
      expect(DragonSymbolConfig.configs[DragonSymbolType.lantern]!.basePay, 20);
      expect(DragonSymbolConfig.configs[DragonSymbolType.ingot]!.basePay, 15);
      expect(DragonSymbolConfig.configs[DragonSymbolType.wild]!.basePay, 0);
      expect(DragonSymbolConfig.configs[DragonSymbolType.coin]!.basePay, 0);
    });

    test('Spin generates exactly 15 grid symbols', () {
      final result = DragonGoldEngine.generateSpin(bet: 10000);
      expect(result.grid.length, 15);
    });

    test('Force bonus triggers Hold & Win with at least 6 coins', () {
      final result = DragonGoldEngine.generateSpin(
        bet: 10000,
        forceBonus: true,
      );
      expect(result.triggersBonus, isTrue);
      expect(result.triggeringCoins.length, greaterThanOrEqualTo(6));
    });

    test('Coin drop chance simulation generates valid coin or null', () {
      int droppedCount = 0;
      for (int i = 0; i < 1000; i++) {
        final coin = DragonGoldEngine.tryDropCoin(cellIndex: 0, bet: 10000);
        if (coin != null) {
          droppedCount++;
          expect(coin.valueAmount, greaterThan(0));
        }
      }
      // 11% probability over 1000 rolls should roughly be around 70..160
      expect(droppedCount, greaterThan(40));
      expect(droppedCount, lessThan(200));
    });
  });
}

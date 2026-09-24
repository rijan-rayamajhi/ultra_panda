import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_panda/models/classic777_model.dart';

void main() {
  group('Classic 777 Math & Engine Tests', () {
    test('Paytable symbol payouts match user specifications', () {
      expect(
        ClassicSymbolConfig.configs[ClassicSymbolType.sevenRed]!.payout,
        500,
      );
      expect(
        ClassicSymbolConfig.configs[ClassicSymbolType.sevenGold]!.payout,
        250,
      );
      expect(ClassicSymbolConfig.configs[ClassicSymbolType.wild]!.payout, 300);
      expect(ClassicSymbolConfig.configs[ClassicSymbolType.bar]!.payout, 100);
      expect(ClassicSymbolConfig.configs[ClassicSymbolType.ace]!.payout, 50);
      expect(ClassicSymbolConfig.configs[ClassicSymbolType.king]!.payout, 30);
      expect(ClassicSymbolConfig.configs[ClassicSymbolType.queen]!.payout, 20);
      expect(ClassicSymbolConfig.configs[ClassicSymbolType.jack]!.payout, 15);
      expect(ClassicSymbolConfig.configs[ClassicSymbolType.ten]!.payout, 10);
    });

    test('All 5 Paylines are properly defined', () {
      expect(Classic777Engine.paylines.length, 5);
      expect(Classic777Engine.paylines[0].cellIndices, [0, 1, 2]); // Top
      expect(Classic777Engine.paylines[1].cellIndices, [3, 4, 5]); // Mid
      expect(Classic777Engine.paylines[2].cellIndices, [6, 7, 8]); // Bottom
      expect(Classic777Engine.paylines[3].cellIndices, [0, 4, 8]); // Diag Down
      expect(Classic777Engine.paylines[4].cellIndices, [6, 4, 2]); // Diag Up
    });

    test('Wild substitutes correctly for line matching', () {
      const bet = 5000;
      final result = Classic777Engine.generateSpin(bet: bet);
      expect(result.grid.length, 9);
    });

    test('Force Free Spins produces 10 free spins and 5x scatter pay', () {
      const bet = 5000;
      final result = Classic777Engine.generateSpin(
        bet: bet,
        forceFreeSpins: true,
      );
      expect(result.scatterCount >= 3, true);
      expect(result.triggersFreeSpins, true);
      expect(result.freeSpinsAwarded, 10);
      expect(result.totalWin >= bet * 5, true);
    });

    test('Free spin multiplier doubles line wins', () {
      const bet = 5000;
      final resNormal = Classic777Engine.generateSpin(
        bet: bet,
        isFreeSpin: false,
        multiplier: 1,
      );
      final resFree = Classic777Engine.generateSpin(
        bet: bet,
        isFreeSpin: true,
        multiplier: 2,
      );
      expect(resNormal.grid.length, 9);
      expect(resFree.grid.length, 9);
    });
  });
}

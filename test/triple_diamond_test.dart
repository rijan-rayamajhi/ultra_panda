import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_panda/models/triple_diamond_model.dart';

void main() {
  group('Triple Diamond Math & Engine Tests', () {
    test('Paytable symbol payouts match user specifications', () {
      expect(
        DiamondSymbolConfig.configs[DiamondSymbolType.diamondWild]!.payout,
        1000,
      );
      expect(
        DiamondSymbolConfig.configs[DiamondSymbolType.sevenRed]!.payout,
        80,
      );
      expect(
        DiamondSymbolConfig.configs[DiamondSymbolType.sevenGold]!.payout,
        40,
      );
      expect(DiamondSymbolConfig.configs[DiamondSymbolType.panda]!.payout, 20);
      expect(DiamondSymbolConfig.configs[DiamondSymbolType.bar3]!.payout, 12);
      expect(DiamondSymbolConfig.configs[DiamondSymbolType.bar2]!.payout, 6);
      expect(DiamondSymbolConfig.configs[DiamondSymbolType.bar1]!.payout, 4);
      expect(
        DiamondSymbolConfig.configs[DiamondSymbolType.diamondWild]!.isWild,
        true,
      );
    });

    test('All 5 Paylines are properly defined', () {
      expect(TripleDiamondEngine.paylines.length, 5);
      expect(TripleDiamondEngine.paylines[0].cellIndices, [0, 1, 2]);
      expect(TripleDiamondEngine.paylines[1].cellIndices, [3, 4, 5]);
      expect(TripleDiamondEngine.paylines[2].cellIndices, [6, 7, 8]);
      expect(TripleDiamondEngine.paylines[3].cellIndices, [0, 4, 8]);
      expect(TripleDiamondEngine.paylines[4].cellIndices, [6, 4, 2]);
    });

    test('Pure 3 Diamonds on a line pays flat 1000x line bet', () {
      const bet = 5000;
      final result = TripleDiamondEngine.generateSpin(
        bet: bet,
        forceJackpot: true,
      );
      final jackpotWin = result.lineWins.firstWhere((w) => w.isPureDiamonds);
      expect(jackpotWin.basePayout, 1000);
      expect(jackpotWin.wildMultiplier, 1);
      expect(jackpotWin.winAmount, 1000 * (bet / 5).round());
    });

    test('35% Nudge symbols pool strictly excludes Diamond Wild', () {
      expect(
        TripleDiamondEngine.nudgeSymbols.contains(
          DiamondSymbolType.diamondWild,
        ),
        false,
      );
    });

    test('Spin generates exactly 9 grid symbols', () {
      const bet = 5000;
      final result = TripleDiamondEngine.generateSpin(bet: bet);
      expect(result.grid.length, 9);
    });
  });
}

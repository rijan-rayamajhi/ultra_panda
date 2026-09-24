import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ultra_panda/core/player_wallet.dart';
import 'package:ultra_panda/core/progression.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('offline progression pays real rewards and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final wallet = PlayerWallet.instance;
    final p = Progression.instance;
    await wallet.load();
    await p.load();

    // First launch: welcome gift + daily login bonus, both claimable once.
    expect(p.inboxUnclaimed, 2);
    final coinsBefore = wallet.coins, gemsBefore = wallet.gems;
    final total = p.claimAllMessages();
    expect(wallet.coins, coinsBefore + total.coins);
    expect(wallet.gems, gemsBefore + total.gems);
    expect(p.inboxUnclaimed, 0);
    expect(p.claimAllMessages().coins, 0);

    // Spins feed the "spin 40 times" quest; it can only be claimed when done, once.
    final spinQuest = p.todaysQuests.firstWhere((q) => q.id == 'spin_any');
    expect(p.claimQuest(spinQuest), isFalse);
    for (var i = 0; i < 400; i++) {
      wallet.recordSpin(
        betAmount: 10000,
        winAmount: 0,
        gameTitle: 'Dragon Gold',
      );
    }
    expect(p.questReady(spinQuest), isTrue);
    final c = wallet.coins;
    expect(p.claimQuest(spinQuest), isTrue);
    expect(wallet.coins, c + spinQuest.reward.coins);
    expect(p.claimQuest(spinQuest), isFalse);

    // 400 spins drop a meaningful number of cards/pieces (~40 / ~33 expected).
    expect(p.totalCards, greaterThan(10));
    expect(
      [0, 1, 2].fold<int>(0, (s, i) => s + p.puzzleCount(i)),
      greaterThan(8),
    );

    // League points and vault come from bets: 400 * 10,000 bet.
    expect(p.clubPoints, 400 * 10);
    expect(p.vaultRebate, 400 * 10000 * 2 ~/ 100);
    final beforeVault = wallet.coins;
    final rebate = p.claimVault();
    expect(wallet.coins, beforeVault + rebate);
    expect(p.vaultClaimable, isFalse);

    // Wheel: one free spin per day, then it costs gems.
    expect(p.wheelFreeAvailable, isTrue);
    final g = wallet.gems;
    expect(p.payForWheelSpin(), isTrue);
    expect(wallet.gems, g);
    expect(p.wheelFreeAvailable, isFalse);
    expect(p.payForWheelSpin(), isTrue);
    expect(wallet.gems, g - Progression.wheelSpinGemCost);

    // Everything survives an app restart.
    final cards = p.totalCards, points = p.clubPoints;
    await p.load();
    expect(p.totalCards, cards);
    expect(p.clubPoints, points);
    expect(p.wheelFreeAvailable, isFalse);
    expect(p.questClaimed(spinQuest), isTrue);
  });
}

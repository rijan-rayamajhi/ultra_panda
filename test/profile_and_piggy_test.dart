import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ultra_panda/core/player_wallet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerWallet, Profile & Piggy Bank Tests', () {
    test('New player starts with a real, empty profile', () async {
      SharedPreferences.setMockInitialValues({});
      final wallet = PlayerWallet.instance;
      await wallet.load();

      expect(wallet.playerName, 'Panda Player');
      expect(wallet.userId, matches(RegExp(r'^UID: \d{8}$')));
      expect(wallet.level, 1);
      expect(wallet.totalSpins, 0);
      expect(wallet.biggestWin, 0);
      expect(wallet.jackpotsHit, 0);
      expect(wallet.favoriteSlot, '—');
      expect(wallet.vipLevel, 1);
      expect(wallet.vipTitle, 'BRONZE');
      expect(wallet.coins, 1000000);
      expect(wallet.gems, 100);
      expect(wallet.piggyCoins, 0);
      expect(wallet.piggyMax, 5000000);
      expect(wallet.isPiggyFull, isFalse);
      expect(wallet.nextVipLevelAt, 11);
    });

    test('Piggy bank smash collects stashed coins and upgrades capacity', () {
      final wallet = PlayerWallet.instance;
      wallet.addPiggyCoins(wallet.piggyMax);
      expect(wallet.isPiggyFull, isTrue);
      final startCoins = wallet.coins;
      final stashed = wallet.piggyCoins;

      final collected = wallet.smashPiggy();

      expect(collected, stashed);
      expect(wallet.coins, startCoins + collected);
      expect(wallet.piggyCoins, 0);
      expect(wallet.piggyMax, 7500000);
      expect(wallet.isPiggyFull, isFalse);
    });

    test('recordSpin accrues spins, stashes 5% in piggy, and adds XP', () {
      final wallet = PlayerWallet.instance;
      final initialSpins = wallet.totalSpins;
      final initialPiggy = wallet.piggyCoins;

      wallet.recordSpin(
        betAmount: 100000,
        winAmount: 500000,
        gameTitle: 'Dragon Gold',
      );
      wallet.recordSpin(betAmount: 0, winAmount: 0, gameTitle: 'Classic 777');
      wallet.recordSpin(betAmount: 0, winAmount: 0, gameTitle: 'Dragon Gold');

      expect(wallet.totalSpins, initialSpins + 3);
      // 5% of 100,000 is 5,000 stashed
      expect(wallet.piggyCoins, initialPiggy + 5000);
      expect(wallet.biggestWin, 500000);
      // Favorite is the most-played game, not the last one played.
      expect(wallet.favoriteSlot, 'Dragon Gold');
    });

    test('Settings toggles update state properly', () {
      final wallet = PlayerWallet.instance;

      final startTurbo = wallet.turboSpin;
      wallet.toggleTurboSpin();
      expect(wallet.turboSpin, !startTurbo);

      final startHaptic = wallet.hapticEnabled;
      wallet.toggleHaptic();
      expect(wallet.hapticEnabled, !startHaptic);

      final startStopOnBonus = wallet.autoStopOnBonus;
      wallet.toggleAutoStopOnBonus();
      expect(wallet.autoStopOnBonus, !startStopOnBonus);
    });

    test('Leveling stops at the max level', () async {
      SharedPreferences.setMockInitialValues({
        'level': 100,
        'xp': 0,
        'xpTarget': 5000,
      });
      final wallet = PlayerWallet.instance;
      await wallet.load();
      expect(wallet.isMaxLevel, isTrue);
      final gems = wallet.gems;
      for (var i = 0; i < 200; i++) {
        wallet.recordSpin(
          betAmount: 500000,
          winAmount: 0,
          gameTitle: 'Dragon Gold',
        );
      }
      expect(wallet.level, 100);
      expect(wallet.xp, wallet.xpTarget);
      // Level-ups grant +50 gems; none past the cap.
      expect(wallet.gems, gems);
      expect(wallet.vipLevel, 10);
      expect(wallet.nextVipLevelAt, 0);
    });
  });
}

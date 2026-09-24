import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_panda/models/classic777_model.dart';
import 'package:ultra_panda/models/dragon_gold_model.dart';
import 'package:ultra_panda/models/fruit_fortune_model.dart';
import 'package:ultra_panda/models/triple_diamond_model.dart';

// Long-run return-to-player per game, bonus features included, mirroring how
// each screen plays its bonus. Engines use an unseeded Random, so bounds are
// loose enough to absorb sampling noise at this spin count.
const _bet = 10000;
const _spins = 100000;

class SimStats {
  int paid = 0, won = 0, bonusWon = 0, hits = 0, bonuses = 0, spins = 0;
  double get rtp => won / paid;
  double get hitRate => hits / spins;
  double get bonusEvery => bonuses == 0 ? double.infinity : spins / bonuses;
  @override
  String toString() =>
      'RTP ${(rtp * 100).toStringAsFixed(1)}%  hit ${(hitRate * 100).toStringAsFixed(1)}%  '
      'bonus 1-in-${bonusEvery.toStringAsFixed(0)} '
      '(bonus share ${(bonusWon / paid * 100).toStringAsFixed(1)}%)';
}

SimStats simClassic() {
  final s = SimStats();
  for (var i = 0; i < _spins; i++) {
    s.spins++;
    s.paid += _bet;
    final r = Classic777Engine.generateSpin(bet: _bet);
    var win = r.totalWin;
    if (r.triggersFreeSpins) {
      s.bonuses++;
      for (var f = 0; f < r.freeSpinsAwarded; f++) {
        final w = Classic777Engine.generateSpin(
          bet: _bet,
          isFreeSpin: true,
          multiplier: 2,
        ).totalWin;
        win += w;
        s.bonusWon += w;
      }
    }
    if (win > 0) s.hits++;
    s.won += win;
  }
  return s;
}

SimStats simDiamond() {
  final s = SimStats();
  for (var i = 0; i < _spins; i++) {
    s.spins++;
    s.paid += _bet;
    final r = TripleDiamondEngine.generateSpin(bet: _bet);
    if (r.scatterCount >= 3) s.bonuses++;
    if (r.totalWin > 0) s.hits++;
    s.won += r.totalWin;
  }
  return s;
}

SimStats simFruit() {
  final s = SimStats();
  for (var i = 0; i < _spins; i++) {
    s.spins++;
    s.paid += _bet;
    final r = FruitFortuneEngine.playSpin(bet: _bet);
    var win = r.totalWin;
    if (r.triggersFreeSpins) {
      s.bonuses++;
      for (var f = 0; f < r.freeSpinsAwarded; f++) {
        final w = FruitFortuneEngine.playSpin(
          bet: _bet,
          isFreeSpin: true,
          spinMultiplier: 2,
        ).totalWin;
        win += w;
        s.bonusWon += w;
      }
    }
    if (win > 0) s.hits++;
    s.won += win;
  }
  return s;
}

/// Mirrors DragonGoldScreen: 3 respins, reset on any new coin, grand 500x on 15.
int holdAndWin(List<HoldAndWinCoin> start) {
  final locked = {for (final c in start) c.cellIndex: c};
  var respins = 3;
  while (respins > 0 && locked.length < 15) {
    var landed = false;
    for (var i = 0; i < 15; i++) {
      if (locked.containsKey(i)) continue;
      final c = DragonGoldEngine.tryDropCoin(cellIndex: i, bet: _bet);
      if (c != null) {
        locked[i] = c;
        landed = true;
      }
    }
    respins = landed ? 3 : respins - 1;
  }
  var total = locked.values.fold(0, (a, c) => a + c.valueAmount);
  if (locked.length == 15) total += _bet * 500;
  return total;
}

SimStats simDragon() {
  final s = SimStats();
  for (var i = 0; i < _spins; i++) {
    s.spins++;
    s.paid += _bet;
    final r = DragonGoldEngine.generateSpin(bet: _bet);
    // The screen pays either the base win or the bonus, never both.
    var win = r.totalBaseWin;
    if (r.triggersBonus) {
      s.bonuses++;
      win = holdAndWin(r.triggeringCoins);
      s.bonusWon += win;
    }
    if (win > 0) s.hits++;
    s.won += win;
  }
  return s;
}

void main() {
  void check(String name, SimStats Function() sim, {bool hasBonus = true}) {
    test('$name RTP is in the 85–105% band', () {
      final s = sim();
      // ignore: avoid_print
      print('$name: $s');
      expect(s.rtp, inInclusiveRange(0.85, 1.05));
      expect(s.hitRate, inInclusiveRange(0.18, 0.40));
      if (hasBonus) expect(s.bonusEvery, inInclusiveRange(90, 320));
    });
  }

  check('Classic 777', simClassic);
  check('Triple Diamond', simDiamond, hasBonus: false);
  check('Fruit Fortune', simFruit);
  check('Dragon Gold', simDragon);
}

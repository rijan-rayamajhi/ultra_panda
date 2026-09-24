import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_panda/widgets/play_for_real_button.dart';

void main() {
  test('PlayForReal triggers prompt on every 5 spins for each slot game', () {
    const games = [
      'Classic 777',
      'Dragon Gold',
      'Fruit Fortune',
      'Triple Diamond',
    ];

    for (final game in games) {
      for (int spin = 1; spin <= 20; spin++) {
        final shouldPrompt = PlayForReal.recordSlotSpin(game);
        if (spin % 5 == 0) {
          expect(
            shouldPrompt,
            isTrue,
            reason: '$game spin $spin should trigger Play For Real prompt',
          );
        } else {
          expect(
            shouldPrompt,
            isFalse,
            reason: '$game spin $spin should not trigger Play For Real prompt',
          );
        }
      }
    }
  });
}

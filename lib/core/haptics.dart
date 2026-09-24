import 'package:flutter/services.dart';
import 'player_wallet.dart';

/// HapticFeedback gated on the player's Haptics setting.
class Haptics {
  Haptics._();

  static bool get _on => PlayerWallet.instance.hapticEnabled;

  static void selection() {
    if (_on) HapticFeedback.selectionClick();
  }

  static void light() {
    if (_on) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (_on) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (_on) HapticFeedback.heavyImpact();
  }

  static void vibrate() {
    if (_on) HapticFeedback.vibrate();
  }
}

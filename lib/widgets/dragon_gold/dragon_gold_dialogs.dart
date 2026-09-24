import 'package:flutter/material.dart';
import '../modals/popup_widgets.dart';
import '../../core/app_assets.dart';
import '../../core/audio_manager.dart';

class DragonGoldDialogs {
  DragonGoldDialogs._();

  // 1. Bonus Trigger Celebration Banner
  static Future<void> showBonusTrigger(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            child: Container(
              width: 420,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF5D0B1B),
                    Color(0xFF990D23),
                    Color(0xFF5D0B1B),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD700), width: 2.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xAAFFD700),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFFFFD700),
                    size: 40,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'HOLD & WIN BONUS!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFFF9C4),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '6+ DRAGON COINS LOCKED IN PLACE!\n3 RESPINS GRANTED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {
                      AudioManager.instance.playSelectClick();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                      child: const Text(
                        'START RESPINS',
                        style: TextStyle(
                          color: Color(0xFF3E2723),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 2. Bonus Completion Celebration Dialog
  static Future<void> showBonusCompletion(
    BuildContext context, {
    required int total,
    required bool isGrand,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            child: Container(
              width: 440,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4A000E),
                    Color(0xFF7A0C22),
                    Color(0xFF4A000E),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD700), width: 2.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xAAFFD700),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isGrand ? '👑 GRAND JACKPOT WON! 👑' : 'BONUS COMPLETE!',
                    style: TextStyle(
                      color: isGrand
                          ? const Color(0xFFFFD700)
                          : const Color(0xFFFFE082),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'TOTAL PRIZE COLLECTED',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(AppAssets.iconCoin, width: 24, height: 24),
                      const SizedBox(width: 8),
                      Text(
                        _formatNumber(total),
                        style: const TextStyle(
                          color: Color(0xFFFFD54F),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.none,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                              offset: Offset(1, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                      child: const Text(
                        'COLLECT',
                        style: TextStyle(
                          color: Color(0xFF3E2723),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 3. Insufficient Funds Alert
  static bool _fundsDialogOpen = false;

  /// Shared by all four games. One at a time, and it needs a tap to close.
  static Future<void> showInsufficientFunds(BuildContext context) async {
    if (_fundsDialogOpen) return;
    _fundsDialogOpen = true;
    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.75),
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF3B0),
                  Color(0xFFFFD54F),
                  Color(0xFFB8860B),
                  Color(0xFFFFE082),
                ],
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x88FFB300), blurRadius: 18),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF4A0A14), Color(0xFF1C0409)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(AppAssets.iconCoin, width: 44, height: 44),
                  const SizedBox(height: 8),
                  const Text(
                    'NOT ENOUGH COINS',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Lower your bet, or grab free coins from the Lucky Wheel, Inbox and Daily Missions in the lobby.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 160,
                    child: PillButton(
                      label: 'OK',
                      style: PillStyle.gold,
                      height: 36,
                      fontSize: 13,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      _fundsDialogOpen = false;
    }
  }

  // 4. Paytable & Rules Popup
  static void showPaytable(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            width: 480,
            height: 310,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xF01A040E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD700), width: 1.6),
              boxShadow: const [
                BoxShadow(color: Colors.black87, blurRadius: 16),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DRAGON GOLD RULES & PAYTABLE',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          AudioManager.instance.playSelectClick();
                          Navigator.of(context).pop();
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0x44FFD54F)),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• FORMAT: 5x3 Grid, Pay Anywhere system.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            '• ANYWHERE COUNT: Land 6+, 8+, or 10+ matching symbols for 1.0x / 1.6x / 3.0x base pay tiers.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '• SYMBOL MULTIPLIERS (6+ anywhere):',
                            style: TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildPaytableRow(
                            'Dragon (Highest)',
                            '74x base',
                            AppAssets.symDragon,
                          ),
                          _buildPaytableRow(
                            'Tiger (High)',
                            '49x base',
                            AppAssets.symTiger,
                          ),
                          _buildPaytableRow(
                            'Koi (Mid)',
                            '29x base',
                            AppAssets.symKoi,
                          ),
                          _buildPaytableRow(
                            'Lantern (Low)',
                            '20x base',
                            AppAssets.symLantern,
                          ),
                          _buildPaytableRow(
                            'Ingot (Common)',
                            '15x base',
                            AppAssets.symIngot,
                          ),
                          _buildPaytableRow(
                            'Wild',
                            'Substitutes for any base symbol',
                            AppAssets.symWild,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '• HOLD & WIN BONUS:',
                            style: TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            'Land 6+ Dragon Coins to trigger 3 respins. Each landed coin locks and resets respins to 3. Fills grant cash values (1x-40x) or Mini (15x), Minor (60x), Major (250x), Grand (500x on 15/15 fill).',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildPaytableRow(String name, String pay, String assetPath) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Image.asset(assetPath, width: 18, height: 18),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            pay,
            style: const TextStyle(
              color: Color(0xFFFFD54F),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

import 'package:flutter/material.dart';
import '../modals/popup_widgets.dart';
import '../../core/audio_manager.dart';
import '../../models/fruit_fortune_model.dart';

class FruitFortuneDialogs {
  // 1. Paytable & Cascade Rules Modal
  static void showPaytableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 440),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F361A), Color(0xFF06180B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x6600E676),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '★ ULTRA PANDA (FRUIT FORTUNE) RULES ★',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFFFFD54F),
                      ),
                      onPressed: () {
                        AudioManager.instance.playSelectClick();
                        Navigator.of(context).pop();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(color: Color(0x66FFD700), height: 16),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pay-Anywhere explanation
                        const Text(
                          'PAY-ANYWHERE 7x3 FORMAT (7+ ANYWHERE)',
                          style: TextStyle(
                            color: Color(0xFFFFF9C4),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'No paylines needed! Match 6 or more of the same fruit anywhere across all 21 positions to score a win.',
                          style: TextStyle(
                            color: Color(0xFFCFD8DC),
                            fontSize: 9.5,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Symbol Payouts List
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: FruitSymbolType.values
                              .where(
                                (s) =>
                                    s != FruitSymbolType.scatter &&
                                    s != FruitSymbolType.pandaWild,
                              )
                              .map((sym) {
                                final cfg = FruitSymbolConfig.configs[sym]!;
                                return Container(
                                  width: 125,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0x88000000),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0x55FFD700),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        cfg.assetPath,
                                        width: 32,
                                        height: 32,
                                        fit: BoxFit.contain,
                                        errorBuilder: (c, e, s) => const Icon(
                                          Icons.fastfood,
                                          color: Color(0xFFFFD700),
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              cfg.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              'Base: ${cfg.basePay}',
                                              style: const TextStyle(
                                                color: Color(0xFFFFD700),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const Text(
                                              '7+:1x | 9+:1.6x | 11+:3x',
                                              style: TextStyle(
                                                color: Color(0xFFB0BEC5),
                                                fontSize: 7.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              })
                              .toList(),
                        ),

                        const SizedBox(height: 12),
                        const Divider(color: Color(0x44FFD700), height: 12),

                        // Special Mechanics
                        const Text(
                          'SPECIAL MECHANICS',
                          style: TextStyle(
                            color: Color(0xFFFFF9C4),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildRuleBullet(
                          'Panda (Wild)',
                          'The cheerful panda mascot substitutes for any fruit to create and enlarge winning clusters!',
                        ),
                        _buildRuleBullet(
                          'Cascade (Tumble) Ladder',
                          'Winning fruits pop and clear! New fruits tumble from above. Each consecutive cascade ramps up the multiplier: 1X → 2X → 3X → 5X → 10X (capped at 12 steps).',
                        ),
                        _buildRuleBullet(
                          'Scatter Free Spins (10 Spins @ 2X)',
                          '3+ Scatters award 10 Free Spins with a doubled 2x win multiplier on all cascades plus an instant 5x total bet scatter pay!',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildRuleBullet(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: Color(0xFFFFD700), fontSize: 11),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 10),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      color: Color(0xFFFFDF00),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Free Spins Trigger Celebration Modal
  static void showFreeSpinsTriggerDialog({
    required BuildContext context,
    required VoidCallback onStart,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F361A), Color(0xFF06180B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD700), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xAA00E676),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFFFFD700),
                  size: 54,
                ),
                const SizedBox(height: 8),
                const Text(
                  'FREE SPINS TRIGGERED!',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '10 FREE SPINS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text(
                  'ALL CASCADE MULTIPLIERS DOUBLED (2X)',
                  style: TextStyle(
                    color: Color(0xFF69F0AE),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 220,
                  child: PillButton(
                    label: 'START FREE SPINS',
                    style: PillStyle.gold,
                    height: 42,
                    fontSize: 14,
                    onTap: () {
                      Navigator.of(context).pop();
                      onStart();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 3. Free Spins Completed Summary Modal
  static void showFreeSpinsCompletedDialog({
    required BuildContext context,
    required int totalWin,
    required VoidCallback onDismiss,
  }) {
    final formattedWin = totalWin.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F361A), Color(0xFF06180B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD700), width: 2),
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
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFFD700),
                  size: 54,
                ),
                const SizedBox(height: 8),
                const Text(
                  'FREE SPINS COMPLETED!',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'TOTAL FEATURE WIN',
                  style: TextStyle(
                    color: Color(0xFFB0BEC5),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  formattedWin,
                  style: const TextStyle(
                    color: Color(0xFFFFF9C4),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const Text(
                  'COINS',
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 220,
                  child: PillButton(
                    label: 'COLLECT',
                    style: PillStyle.gold,
                    height: 42,
                    fontSize: 14,
                    onTap: () {
                      Navigator.of(context).pop();
                      onDismiss();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

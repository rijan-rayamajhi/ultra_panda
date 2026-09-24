import 'package:flutter/material.dart';
import '../modals/popup_widgets.dart';
import '../../core/audio_manager.dart';
import '../../models/classic777_model.dart';

class Classic777Dialogs {
  // 1. Paytable and 5 Paylines Rules Modal
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
                colors: [Color(0xFF26050C), Color(0xFF140206)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66FF1744),
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
                      '★ CLASSIC 777 PAYTABLE & RULES ★',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 14,
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

                // Paytable Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Symbols Grid
                        const Text(
                          '3-OF-A-KIND LINE PAYOUTS (PER LINE BET)',
                          style: TextStyle(
                            color: Color(0xFFFFF9C4),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ClassicSymbolType.values
                              .where((s) => s != ClassicSymbolType.scatter)
                              .map((sym) {
                                final cfg = ClassicSymbolConfig.configs[sym]!;
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
                                        width: 30,
                                        height: 30,
                                        fit: BoxFit.contain,
                                        errorBuilder: (c, e, s) => const Icon(
                                          Icons.stars,
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
                                              '${cfg.payout}x',
                                              style: const TextStyle(
                                                color: Color(0xFFFFD700),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
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
                          'Wild Substitution',
                          'Substitutes for any symbol except Scatter to complete line wins.',
                        ),
                        _buildRuleBullet(
                          'Mixed-Seven Combo (50x)',
                          'Any 3 of {Seven Red, Seven Gold} (Wilds count) across a line pays 50x line bet.',
                        ),
                        _buildRuleBullet(
                          'Free Spins (10 Spins @ 2x)',
                          '3+ Scatters anywhere award 10 Free Spins with an active 2x Multiplier on all wins plus an instant 5x total bet scatter payout!',
                        ),
                        _buildRuleBullet(
                          'Guaranteed Win Nudge',
                          '35% of spins are automatically nudged to hit a guaranteed payline win!',
                        ),

                        const SizedBox(height: 12),
                        const Divider(color: Color(0x44FFD700), height: 12),

                        // 5 Fixed Paylines visual scheme
                        const Text(
                          '5 FIXED PAYLINES',
                          style: TextStyle(
                            color: Color(0xFFFFF9C4),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildLineIcon('Line 1', 'Top Row', [0, 1, 2]),
                            _buildLineIcon('Line 2', 'Mid Row', [3, 4, 5]),
                            _buildLineIcon('Line 3', 'Bot Row', [6, 7, 8]),
                            _buildLineIcon('Line 4', 'Diag Down', [0, 4, 8]),
                            _buildLineIcon('Line 5', 'Diag Up', [6, 4, 2]),
                          ],
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
      padding: const EdgeInsets.only(bottom: 5.0),
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

  static Widget _buildLineIcon(String name, String desc, List<int> cells) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0x88000000),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x66FFD700), width: 0.8),
          ),
          child: Column(
            children: List.generate(3, (r) {
              return Expanded(
                child: Row(
                  children: List.generate(3, (c) {
                    final idx = r * 3 + c;
                    final isHighlighted = cells.contains(idx);
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? const Color(0xFFFF1744)
                              : const Color(0x22FFFFFF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          name,
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          desc,
          style: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 7.5),
        ),
      ],
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
                colors: [Color(0xFF5A0010), Color(0xFF1F0006)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD700), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xAAFF1744),
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
                  'ALL WINS MULTIPLIED BY 2X',
                  style: TextStyle(
                    color: Color(0xFFFF8A80),
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

  // 3. Free Spins Completed Celebration Modal
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
                colors: [Color(0xFF5A0010), Color(0xFF1F0006)],
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

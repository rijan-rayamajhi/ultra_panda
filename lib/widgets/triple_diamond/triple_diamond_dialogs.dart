import 'package:flutter/material.dart';
import '../../core/audio_manager.dart';
import '../../models/triple_diamond_model.dart';

class TripleDiamondDialogs {
  // Paytable & Rules Modal
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
                colors: [Color(0xFF071F47), Color(0xFF030D1C)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x6600B0FF),
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
                      '★ TRIPLE DIAMOND PAYTABLE & RULES ★',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF80D8FF),
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
                const Divider(color: Color(0x6600E5FF), height: 16),

                // Paytable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '3-OF-A-KIND LINE PAYOUTS (PER LINE BET)',
                          style: TextStyle(
                            color: Color(0xFFE1F5FE),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: DiamondSymbolType.values
                              .where((s) => s != DiamondSymbolType.scatter)
                              .map((sym) {
                                final cfg = DiamondSymbolConfig.configs[sym]!;
                                return Container(
                                  width: 125,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0x88000000),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0x5500E5FF),
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
                                          Icons.diamond,
                                          color: Color(0xFF00E5FF),
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
                                                color: Color(0xFF00E5FF),
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
                        const Divider(color: Color(0x4400E5FF), height: 12),

                        // Special Mechanics
                        const Text(
                          'SPECIAL MECHANICS',
                          style: TextStyle(
                            color: Color(0xFFE1F5FE),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildRuleBullet(
                          'Diamond Multiplier (3x & 9x)',
                          'Every Diamond substituting in a winning line multiplies the win by 3X! Two Diamonds substituting on a line pay a massive 9X (3x3)!',
                        ),
                        _buildRuleBullet(
                          '1,000x Diamond Jackpot',
                          '3 Diamonds on any payline pay the monumental 1,000X flat jackpot (earned naturally off the reels)!',
                        ),

                        const SizedBox(height: 12),
                        const Divider(color: Color(0x4400E5FF), height: 12),

                        // 5 Fixed Paylines visual scheme
                        const Text(
                          '5 FIXED PAYLINES',
                          style: TextStyle(
                            color: Color(0xFFE1F5FE),
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
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 10),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      color: Color(0xFF80D8FF),
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
            border: Border.all(color: const Color(0x6600E5FF), width: 0.8),
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
                              ? const Color(0xFF00E5FF)
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
            color: Color(0xFF00E5FF),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          desc,
          style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 7.5),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/haptics.dart';
import '../../core/app_assets.dart';
import '../../core/audio_manager.dart';
import '../../core/player_wallet.dart';
import '../modals/settings_dialog.dart';
import '../play_for_real_button.dart';
import '../../core/progression.dart';
import 'reward_fly.dart';

class SlotHeader extends StatelessWidget {
  final String title;
  final VoidCallback onExit;
  final VoidCallback onOpenInfo;
  final bool isInteractionBlocked;
  final Gradient? titleGradient;

  const SlotHeader({
    super.key,
    required this.title,
    required this.onExit,
    required this.onOpenInfo,
    this.isInteractionBlocked = false,
    this.titleGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 2.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 2. Game Title Plaque (centered on the full header width)
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient:
                      titleGradient ??
                      const LinearGradient(
                        colors: [
                          Color(0xFF5D0B1B),
                          Color(0xFF8B0D23),
                          Color(0xFFB71C1C),
                          Color(0xFF8B0D23),
                          Color(0xFF5D0B1B),
                        ],
                      ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFFD700),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66FFD700),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '★',
                      style: TextStyle(color: Color(0xFFFFD700), fontSize: 10),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFFFF9C4),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '★',
                      style: TextStyle(color: Color(0xFFFFD700), fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Lobby Back Button + Play-for-real link
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: isInteractionBlocked
                        ? null
                        : () {
                            Haptics.selection();
                            AudioManager.instance.playSelectClick();
                            onExit();
                          },
                    child: Container(
                      // Gold rim.
                      padding: const EdgeInsets.all(1.4),
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
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFD32F2F),
                              Color(0xFF8B0D23),
                              Color(0xFF4A0612),
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Color(0xFFFFE082),
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            _GoldLabel('LOBBY', size: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const PlayForRealButton(compact: true),
                ],
              ),

              // 3. Balance Display & Rules Info Button ('i')
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: PlayerWallet.instance,
                    builder: (context, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xDD0D0414),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFFD54F),
                            width: 0.9,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              AppAssets.iconCoin,
                              width: 14,
                              height: 14,
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.monetization_on,
                                color: Color(0xFFFFD700),
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 5),
                            RewardFlyTarget(
                              kind: RewardKind.coins,
                              child: CountingNumber(
                                value: PlayerWallet.instance.coins,
                                format: fmt,
                                style: const TextStyle(
                                  color: Color(0xFFFFD54F),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),

                  // Information circular badge ('i')
                  GestureDetector(
                    onTap: () {
                      Haptics.selection();
                      AudioManager.instance.playSelectClick();
                      onOpenInfo();
                    },
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFF8D6E63)],
                        ),
                        border: Border.all(color: Colors.white, width: 1.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'i',
                          style: TextStyle(
                            color: Color(0xFF2E0909),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Settings gear button
                  GestureDetector(
                    onTap: () {
                      Haptics.selection();
                      AudioManager.instance.playSelectClick();
                      SettingsDialog.show(context);
                    },
                    child: Container(
                      width: 26,
                      height: 26,
                      padding: const EdgeInsets.all(4.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFF37474F), Color(0xFF1E102E)],
                        ),
                        border: Border.all(
                          color: const Color(0xFFFFD54F),
                          width: 0.9,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        AppAssets.iconSettings,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Gold-gradient shimmer text, matching the MAX BET / SPIN labels.
class _GoldLabel extends StatelessWidget {
  final String text;
  final double size;
  const _GoldLabel(this.text, {required this.size});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFFFA000)],
      ).createShader(r),
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          color: Colors.white,
          fontSize: size,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          shadows: const [
            Shadow(color: Colors.black, offset: Offset(0, 1.5), blurRadius: 2),
          ],
        ),
      ),
    );
  }
}

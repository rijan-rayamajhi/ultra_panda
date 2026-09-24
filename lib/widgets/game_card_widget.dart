import 'package:flutter/material.dart';
import 'common/frame_shine.dart';
import '../core/progression.dart';
import '../core/player_wallet.dart';
import '../core/app_assets.dart';
import '../core/haptics.dart';
import '../models/game_card_model.dart';

class GameCardWidget extends StatefulWidget {
  final GameCardModel game;
  final VoidCallback? onTap;

  /// 0..1 offset so lobby cards glint one after another.
  final double shinePhase;
  const GameCardWidget({
    super.key,
    required this.game,
    this.onTap,
    this.shinePhase = 0,
  });

  @override
  State<GameCardWidget> createState() => _GameCardWidgetState();
}

class _GameCardWidgetState extends State<GameCardWidget>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTap: () {
        Haptics.medium();
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AspectRatio(
          aspectRatio: game.aspectRatio, // Native artwork aspect ratio
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: [
                // Deep ambient shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.75),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
                // Colored card aura
                BoxShadow(
                  color: game.tagColor.withValues(alpha: 0.28),
                  blurRadius: 16,
                  spreadRadius: -1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. 3D Card Artwork
                  FrameShine(
                    period: const Duration(minutes: 1),
                    phase: widget.shinePhase,
                    child: Image.asset(game.imagePath, fit: BoxFit.cover),
                  ),

                  // 2. Subtle top sheen gradient
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.12),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // 3. Top Status Tag (HOT / POPULAR / NEW / MEGA)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            game.tagColor,
                            game.tagColor.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (game.tag == 'HOT') ...[
                            const Icon(
                              Icons.local_fire_department,
                              size: 10,
                              color: Colors.yellow,
                            ),
                            const SizedBox(width: 2),
                          ] else if (game.tag == 'MEGA') ...[
                            const Icon(
                              Icons.diamond,
                              size: 9,
                              color: Colors.cyanAccent,
                            ),
                            const SizedBox(width: 2),
                          ],
                          Text(
                            game.tag,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. Luxury Floating Jackpot Plaque
                  Positioned(
                    bottom: 6,
                    left: 7,
                    right: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 3.5,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xEE1E0B00),
                            Color(0xF03A1700),
                            Color(0xEE1E0B00),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFFD54F),
                          width: 0.9,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AnimatedBuilder(
                        animation: PlayerWallet.instance,
                        builder: (context, _) {
                          final best = PlayerWallet.instance.bestWinFor(
                            game.title,
                          );
                          // Title lives in the artwork; the plaque only shows
                          // the call-to-action / personal best.
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (best > 0) ...[
                                Image.asset(
                                  AppAssets.iconCoin,
                                  width: 11,
                                  height: 11,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                best > 0
                                    ? 'YOUR BEST ${compact(best)}'
                                    : 'TAP TO PLAY',
                                style: const TextStyle(
                                  color: Color(0xFFFFF176),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

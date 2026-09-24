import 'package:flutter/material.dart';
import '../core/haptics.dart';
import '../core/app_assets.dart';
import '../core/player_wallet.dart';
import 'common/reward_fly.dart';
import 'currency_pill.dart';

class TopHudBar extends StatelessWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onPiggyTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onGetMoreTap;

  const TopHudBar({
    super.key,
    this.onProfileTap,
    this.onPiggyTap,
    this.onSettingsTap,
    this.onGetMoreTap,
  });

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
          child: SizedBox(
            height: 38,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // LEFT: Profile & Currencies
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildProfileBadge(),
                      const SizedBox(width: 8),
                      AnimatedBuilder(
                        animation: PlayerWallet.instance,
                        builder: (context, _) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CurrencyPill(
                                iconPath: AppAssets.iconGem,
                                amount: PlayerWallet.instance.gems,
                                kind: RewardKind.gems,
                                textColor: const Color(0xFF80DEEA),
                                width: 104,
                                onAddTap: onGetMoreTap,
                              ),
                              const SizedBox(width: 6),
                              CurrencyPill(
                                iconPath: AppAssets.iconCoin,
                                amount: PlayerWallet.instance.coins,
                                kind: RewardKind.coins,
                                textColor: const Color(0xFFFFD54F),
                                width: 128,
                                onAddTap: onGetMoreTap,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // CENTER: Perfectly centered Grand Jackpot
                Align(
                  alignment: Alignment.center,
                  child: AnimatedBuilder(
                    animation: PlayerWallet.instance,
                    builder: (context, _) => _buildJackpotBanner(),
                  ),
                ),

                // RIGHT: Piggy & Settings
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildPiggyButton(),
                      const SizedBox(width: 8),
                      _buildSettingsButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJackpotBanner() {
    return SizedBox(
      width: 156,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(AppAssets.barGrand, fit: BoxFit.contain),
          // Optically centered inside the red plaque; shrinks to fit so large
          // totals never overflow the banner art.
          Positioned(
            top: 14,
            child: SizedBox(
              width: 118,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'WON ${_formatNumber(PlayerWallet.instance.totalWon)}',
                  maxLines: 1,
                  style: const TextStyle(
                    color: Color(0xFFFFF9C4),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    shadows: [
                      Shadow(
                        color: Color(0xFF8B0000),
                        offset: Offset(1, 1),
                        blurRadius: 3,
                      ),
                      Shadow(
                        color: Colors.black,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBadge() {
    return GestureDetector(
      onTap: () {
        Haptics.selection();
        onProfileTap?.call();
      },
      child: AnimatedBuilder(
        animation: PlayerWallet.instance,
        builder: (context, _) {
          final wallet = PlayerWallet.instance;
          final avatarAsset = wallet.avatarIndex == 0
              ? AppAssets.hostAvatar
              : wallet.avatarIndex == 1
              ? AppAssets.iconProfile
              : AppAssets.hostHero;

          return SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(1.5),
                  child: ClipOval(
                    child: Image.asset(avatarAsset, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3.5,
                      vertical: 0.8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE082), Color(0xFFFF8F00)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 0.8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      'LV.${wallet.level}',
                      style: const TextStyle(
                        color: Color(0xFF3E2723),
                        fontSize: 6.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPiggyButton() {
    return GestureDetector(
      onTap: () {
        Haptics.selection();
        onPiggyTap?.call();
      },
      child: AnimatedBuilder(
        animation: PlayerWallet.instance,
        builder: (context, _) {
          final wallet = PlayerWallet.instance;
          final isFull = wallet.isPiggyFull;

          return SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Image.asset(AppAssets.iconPiggy, fit: BoxFit.contain),
                Positioned(
                  top: 0,
                  right: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3.5,
                      vertical: 1.2,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isFull
                            ? [const Color(0xFFFF1744), const Color(0xFFC2185B)]
                            : [
                                const Color(0xFFFFB300),
                                const Color(0xFFE65100),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 0.7),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      isFull
                          ? 'FULL!'
                          : '${(wallet.piggyFillRatio * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 6.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsButton() {
    return GestureDetector(
      onTap: () {
        Haptics.selection();
        onSettingsTap?.call();
      },
      child: Container(
        width: 34,
        height: 34,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF1B0F2A).withValues(alpha: 0.65),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.7),
            width: 1.3,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Image.asset(AppAssets.iconSettings, fit: BoxFit.contain),
      ),
    );
  }
}

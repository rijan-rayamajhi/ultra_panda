import 'package:flutter/material.dart';
import '../../core/app_assets.dart';
import '../../core/haptics.dart';
import '../../core/player_wallet.dart';
import 'base_popup_dialog.dart';
import 'popup_widgets.dart';

class PiggyBankDialog extends StatefulWidget {
  const PiggyBankDialog({super.key});

  static Future<void> show(BuildContext context) {
    return BasePopupDialog.show(
      context: context,
      title: 'GOLDEN PIGGY BANK',
      content: const PiggyBankDialog(),
      width: 530,
      height: 330,
    );
  }

  @override
  State<PiggyBankDialog> createState() => _PiggyBankDialogState();
}

class _PiggyBankDialogState extends State<PiggyBankDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  bool _justCracked = false;
  int _crackedAmount = 0;
  String? _message;

  static const _smashGemCost = 100;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _smashPiggy() {
    final wallet = PlayerWallet.instance;
    if (!wallet.isPiggyFull) return;
    if (!wallet.deductGems(_smashGemCost)) {
      Haptics.light();
      setState(() => _message = 'NEED $_smashGemCost GEMS TO SMASH');
      return;
    }

    // PillButton already plays the payout ding.
    Haptics.heavy();
    final collected = wallet.smashPiggy();

    setState(() {
      _message = null;
      _justCracked = true;
      _crackedAmount = collected;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _justCracked = false);
    });
  }

  static BoxDecoration _panel() => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xCC3A0A14), Color(0xCC12030A)],
    ),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0x80FFD54F), width: 0.9),
  );

  static Widget _step(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 14, color: const Color(0xFFFFD54F)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFFFF3E0),
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PlayerWallet.instance,
      builder: (context, _) {
        final wallet = PlayerWallet.instance;
        final isFull = wallet.isPiggyFull;

        if (_justCracked) {
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF5D0B1B),
                    Color(0xFF8E1438),
                    Color(0xFF5D0B1B),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD700), width: 2),
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
                    Icons.stars_rounded,
                    color: Color(0xFFFFD700),
                    size: 40,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'PIGGY SMASHED!',
                    style: TextStyle(
                      color: Color(0xFFFFF9C4),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+${_formatNumber(_crackedAmount)} COINS\nADDED TO YOUR WALLET!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Piggy capacity is now ${_formatNumber(wallet.piggyMax)} coins',
                    style: TextStyle(color: Colors.white70, fontSize: 8.5),
                  ),
                ],
              ),
            ),
          );
        }

        final ratio = wallet.piggyFillRatio;
        final accent = isFull
            ? const Color(0xFFFF5252)
            : const Color(0xFFFFD54F);

        return Row(
          children: [
            // Left: animated piggy + fill meter
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                decoration: _panel(),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isFull
                              ? const [Color(0xFFFF1744), Color(0xFFB71C1C)]
                              : const [Color(0xFFFFB300), Color(0xFFE65100)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white70, width: 0.7),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isFull ? 'READY TO SMASH' : 'SAVING UP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.4),
                                  blurRadius: 22,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              AppAssets.iconPiggy,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${(ratio * 100).toInt()}% FULL',
                          style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${wallet.formattedPiggyCoins} / ${_formatNumber(wallet.piggyMax)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 10,
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFF3B0),
                            Color(0xFFB8860B),
                            Color(0xFFFFE082),
                          ],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: const Color(0xFF1C0409),
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Right: balance, how it works, action
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF3E1204), Color(0xFF1A0600)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFFD700),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Image.asset(AppAssets.iconCoin, width: 30, height: 30),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SAVED IN PIGGY',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${wallet.formattedPiggyCoins} COINS',
                                  style: const TextStyle(
                                    color: Color(0xFFFFD54F),
                                    fontSize: 15,
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
                              ),
                              Text(
                                isFull
                                    ? 'Full! Smash it open to collect.'
                                    : '${_formatNumber(wallet.piggyMax - wallet.piggyCoins)} more to fill',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: _panel(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _step(
                            Icons.savings_rounded,
                            '5% of every spin bet is saved here automatically',
                          ),
                          _step(
                            Icons.diamond_rounded,
                            'When it\'s full, smash it open for $_smashGemCost gems',
                          ),
                          _step(
                            Icons.trending_up_rounded,
                            'Capacity grows 50% after each smash, up to ${_formatNumber(PlayerWallet.piggyMaxCap)}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFF8A80),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  PillButton(
                    label: isFull
                        ? 'SMASH OPEN  •  $_smashGemCost GEMS'
                        : 'FILL TO 100% TO SMASH',
                    style: isFull ? PillStyle.gold : PillStyle.idle,
                    height: 30,
                    fontSize: 9.5,
                    onTap: isFull ? _smashPiggy : null,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

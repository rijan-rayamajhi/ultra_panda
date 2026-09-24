import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_assets.dart';
import '../core/audio_manager.dart';
import '../core/haptics.dart';
import '../core/player_wallet.dart';
import '../core/progression.dart';
import '../models/dragon_gold_model.dart';
import '../widgets/dragon_gold/dragon_gold_jackpots.dart';
import '../widgets/dragon_gold/dragon_gold_cabinet.dart';
import '../widgets/dragon_gold/dragon_gold_dialogs.dart';
import '../widgets/common/slot_header.dart';
import '../widgets/common/slot_controls_bar.dart';
import '../widgets/play_for_real_button.dart';

class DragonGoldScreen extends StatefulWidget {
  const DragonGoldScreen({super.key});

  @override
  State<DragonGoldScreen> createState() => _DragonGoldScreenState();
}

class _DragonGoldScreenState extends State<DragonGoldScreen>
    with TickerProviderStateMixin {
  // Bet configuration
  static const List<int> _betOptions = [
    5000,
    10000,
    25000,
    50000,
    100000,
    250000,
  ];
  int _currentBetIndex = 1; // Default: 10,000
  int get _currentBet => _betOptions[_currentBetIndex];

  // Game state
  bool _isSpinning = false;
  bool _isBonusMode = false;
  int _respinsLeft = 3;
  int _lastWinAmount = 0;
  bool _autoSpinActive = false;
  int _autoSpinCount = 0;
  bool _resumeAutoAfterBonus = false;
  bool _pendingRealPrompt = false;

  // Every pending callback lives here so dispose() can kill it.
  final List<Timer> _timers = [];
  // Base-game win generated but not yet credited (reels still animating).
  int _pendingWin = 0;

  static bool get _turbo => PlayerWallet.instance.turboSpin;
  static Duration _ms(int ms) => Duration(milliseconds: _turbo ? ms ~/ 2 : ms);

  void _after(int ms, VoidCallback fn) {
    _timers.add(
      Timer(_ms(ms), () {
        if (mounted) fn();
      }),
    );
  }

  void _creditPendingWin() {
    if (_pendingWin <= 0) return;
    PlayerWallet.instance.addCoins(_pendingWin);
    _pendingWin = 0;
  }

  // Grid states (15 positions: 5 cols x 3 rows)
  List<DragonSymbolType> _currentGrid = [
    DragonSymbolType.ingot,
    DragonSymbolType.lantern,
    DragonSymbolType.koi,
    DragonSymbolType.tiger,
    DragonSymbolType.dragon,
    DragonSymbolType.lantern,
    DragonSymbolType.ingot,
    DragonSymbolType.wild,
    DragonSymbolType.lantern,
    DragonSymbolType.ingot,
    DragonSymbolType.koi,
    DragonSymbolType.dragon,
    DragonSymbolType.ingot,
    DragonSymbolType.tiger,
    DragonSymbolType.coin,
  ];

  // Hold & Win locked coins (cellIndex -> HoldAndWinCoin)
  final Map<int, HoldAndWinCoin> _lockedCoins = {};

  // Winning symbols in current spin (for base pay highlights)
  Set<DragonSymbolType> _winningSymbols = {};

  // Reel spin controllers (5 columns staggered)
  late List<AnimationController> _reelControllers;

  // Pulse controller for wins and celebration
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _reelControllers = List.generate(5, (col) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 700 + (col * 180)),
      );
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    // Never lose a bet's payout because the player left mid-animation.
    _creditPendingWin();
    for (final c in _reelControllers) {
      c.dispose();
    }
    _pulseController.dispose();
    super.dispose();
  }

  // Handle Base Spin
  void _spin() {
    if (!mounted || _isSpinning || _isBonusMode) return;

    final wallet = PlayerWallet.instance;
    if (!wallet.deductCoins(_currentBet)) {
      _stopAutoSpin();
      DragonGoldDialogs.showInsufficientFunds(context);
      return;
    }

    Haptics.heavy();
    AudioManager.instance.playSpinWhoosh();
    setState(() {
      _isSpinning = true;
      _winningSymbols.clear();
      _lastWinAmount = 0;
    });

    for (int i = 0; i < 5; i++) {
      _reelControllers[i]
        ..duration = _ms(700 + i * 180)
        ..forward(from: 0.0);
    }

    final result = DragonGoldEngine.generateSpin(bet: _currentBet);
    // Recorded now so leaving mid-animation can't drop the spin.
    wallet.recordSpin(
      betAmount: _currentBet,
      winAmount: result.totalBaseWin,
      gameTitle: 'Dragon Gold',
    );
    if (!result.triggersBonus) _pendingWin = result.totalBaseWin;

    final shouldShowRealPrompt =
        PlayForReal.recordSlotSpin('Dragon Gold');

    _after(1450, () {
      setState(() {
        _currentGrid = List.from(result.grid);
      });

      Future.wait(_reelControllers.map((c) => c.animateTo(1.0))).then((_) {
        if (!mounted) return;

        setState(() {
          _isSpinning = false;
        });

        if (result.triggersBonus) {
          _pendingRealPrompt = shouldShowRealPrompt;
          AudioManager.instance.playPayoutDing();
          _triggerHoldAndWin(result.triggeringCoins);
        } else {
          if (result.totalBaseWin > 0) {
            Haptics.vibrate();
            AudioManager.instance.playPayoutDing();
            _creditPendingWin();
            setState(() {
              _lastWinAmount = result.totalBaseWin;
              _winningSymbols = result.winningSymbolCounts.keys.toSet();
            });
          }

          if (shouldShowRealPrompt) {
            _stopAutoSpin();
            _after(400, () {
              if (mounted) PlayForReal.showPrompt(context);
            });
          } else if (_autoSpinActive) {
            if (_autoSpinCount > 0) {
              _autoSpinCount--;
              if (_autoSpinCount == 0) {
                _stopAutoSpin();
              } else {
                _after(1200, _spin);
              }
            } else {
              _after(1200, _spin);
            }
          }
        }
      });
    });
  }

  // Trigger Hold & Win Mode
  void _triggerHoldAndWin(List<HoldAndWinCoin> initialCoins) {
    _resumeAutoAfterBonus =
        _autoSpinActive && !PlayerWallet.instance.autoStopOnBonus;
    final resumeCount = _autoSpinCount;
    _stopAutoSpin();
    if (_resumeAutoAfterBonus) _autoSpinCount = resumeCount;
    Progression.instance.onBonusTriggered();
    Haptics.heavy();

    _lockedCoins.clear();
    for (final coin in initialCoins) {
      _lockedCoins[coin.cellIndex] = coin;
    }

    DragonGoldDialogs.showBonusTrigger(context).then((_) {
      if (!mounted) return;
      setState(() {
        _isBonusMode = true;
        _respinsLeft = 3;
      });
    });
  }

  // Execute one Respin step in Hold & Win
  void _respinHoldAndWin() {
    if (_isSpinning || !_isBonusMode || _respinsLeft <= 0) return;

    Haptics.medium();
    AudioManager.instance.playSpinWhoosh();
    setState(() {
      _isSpinning = true;
    });

    for (final c in _reelControllers) {
      c.forward(from: 0.0);
    }

    _after(1000, () {
      bool landedNewCoin = false;
      final newlyLanded = <HoldAndWinCoin>[];

      for (int i = 0; i < 15; i++) {
        if (!_lockedCoins.containsKey(i)) {
          final droppedCoin = DragonGoldEngine.tryDropCoin(
            cellIndex: i,
            bet: _currentBet,
          );
          if (droppedCoin != null) {
            landedNewCoin = true;
            newlyLanded.add(droppedCoin);
          }
        }
      }

      setState(() {
        for (final coin in newlyLanded) {
          _lockedCoins[coin.cellIndex] = coin;
        }

        if (landedNewCoin) {
          Haptics.heavy();
          AudioManager.instance.playPayoutDing();
          _respinsLeft = 3;
        } else {
          _respinsLeft = math.max(0, _respinsLeft - 1);
        }
        _isSpinning = false;
      });

      if (_lockedCoins.length == 15 || _respinsLeft == 0) {
        _after(800, _concludeHoldAndWin);
      }
    });
  }

  // Conclude Hold & Win with grand check and payout
  void _concludeHoldAndWin() {
    int total = 0;
    bool hasGrand = _lockedCoins.length == 15;

    for (final coin in _lockedCoins.values) {
      total += coin.valueAmount;
    }

    if (hasGrand) {
      total += _currentBet * 500;
      PlayerWallet.instance.recordJackpotHit();
    }

    PlayerWallet.instance.addCoins(total);
    PlayerWallet.instance.recordBonusWin(total, 'Dragon Gold');
    AudioManager.instance.playPayoutDing();
    if (!mounted) return;

    DragonGoldDialogs.showBonusCompletion(
      context,
      total: total,
      isGrand: hasGrand,
    ).then((_) {
      if (!mounted) return;
      setState(() {
        _isBonusMode = false;
        _lockedCoins.clear();
        _lastWinAmount = total;
      });
      if (_pendingRealPrompt) {
        _pendingRealPrompt = false;
        _after(400, () {
          if (mounted) PlayForReal.showPrompt(context);
        });
      } else if (_resumeAutoAfterBonus) {
        _resumeAutoAfterBonus = false;
        setState(() => _autoSpinActive = true);
        _after(800, _spin);
      }
    });
  }

  void _stopAutoSpin() {
    if (!mounted) return;
    setState(() {
      _autoSpinActive = false;
      _autoSpinCount = 0;
    });
  }

  void _toggleAutoSpin() {
    if (_isBonusMode) return;
    if (_autoSpinActive) {
      _stopAutoSpin();
    } else {
      setState(() {
        _autoSpinActive = true;
        _autoSpinCount = 25;
      });
      _spin();
    }
  }

  void _adjustBet(int delta) {
    if (_isSpinning || _isBonusMode) return;
    Haptics.selection();
    setState(() {
      _currentBetIndex = (_currentBetIndex + delta).clamp(
        0,
        _betOptions.length - 1,
      );
    });
  }

  void _maxBet() {
    if (_isSpinning || _isBonusMode) return;
    Haptics.heavy();
    setState(() {
      _currentBetIndex = _betOptions.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return PopScope(
      canPop: !_isSpinning && !_isBonusMode,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Dragon Temple Background & Atmospheric Scrim
            Image.asset(
              AppAssets.bgDragonGold,
              fit: BoxFit.cover,
              width: screenSize.width,
              height: screenSize.height,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.68),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Center Twin-Dragon Cabinet Frame & 5x3 Reels
            // Scaled up so the frame's transparent ornament edges tuck under
            // the header/jackpot row (painted after this).
            Positioned(
              top: 66,
              bottom: 62,
              left: 0,
              right: 0,
              child: Center(
                child: Transform.scale(
                  scale: 1.15,
                  child: DragonGoldCabinet(
                    grid: _currentGrid,
                    lockedCoins: _lockedCoins,
                    winningSymbols: _winningSymbols,
                    isSpinning: _isSpinning,
                    isBonusMode: _isBonusMode,
                    currentBet: _currentBet,
                    reelControllers: _reelControllers,
                    pulseAnimation: PlayerWallet.instance.winEffectsEnabled
                        ? _pulseAnimation
                        : const AlwaysStoppedAnimation(1.0),
                  ),
                ),
              ),
            ),

            // 3. Top Header & Jackpot Row (Unified SlotHeader)
            SafeArea(
              child: Column(
                children: [
                  SlotHeader(
                    title: 'DRAGON GOLD',
                    onExit: () => Navigator.of(context).pop(),
                    onOpenInfo: () => DragonGoldDialogs.showPaytable(context),
                    isInteractionBlocked: _isSpinning || _isBonusMode,
                  ),
                  const SizedBox(height: 2),
                  DragonGoldJackpots(currentBet: _currentBet),
                ],
              ),
            ),

            // 4. Floating Respins Banner in Hold & Win Mode
            if (_isBonusMode)
              Positioned(
                top: 76,
                left: 0,
                right: 0,
                child: Center(child: _buildRespinCounterBanner()),
              ),

            // 5. Bottom Control Bar (Unified SlotControlsBar)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlotControlsBar(
                currentBet: _currentBet,
                lastWinAmount: _lastWinAmount,
                isSpinning: _isSpinning,
                controlsEnabled: !_isSpinning && !_isBonusMode,
                autoSpinActive: _autoSpinActive,
                autoSpinCount: _autoSpinCount,
                canDecreaseBet: _currentBetIndex > 0,
                canIncreaseBet: _currentBetIndex < _betOptions.length - 1,
                onDecreaseBet: () => _adjustBet(-1),
                onIncreaseBet: () => _adjustBet(1),
                onMaxBet: _maxBet,
                onToggleAutoSpin: _toggleAutoSpin,
                onAction: _isBonusMode ? _respinHoldAndWin : _spin,
                actionWidget: _isBonusMode
                    ? Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1.4),
                          boxShadow: const [
                            BoxShadow(color: Color(0xAAFFD700), blurRadius: 10),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'RESPIN',
                            style: TextStyle(
                              color: Color(0xFF3E2723),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Respins Counter floating badge in Hold & Win
  Widget _buildRespinCounterBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5D0B1B), Color(0xFF990D23), Color(0xFF5D0B1B)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.6),
        boxShadow: const [
          BoxShadow(color: Color(0xAAFFD700), blurRadius: 12, spreadRadius: 2),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.fireplace_rounded,
            color: Color(0xFFFFD700),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'RESPINS REMAINING: $_respinsLeft',
            style: const TextStyle(
              color: Color(0xFFFFF9C4),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.fireplace_rounded,
            color: Color(0xFFFFD700),
            size: 16,
          ),
        ],
      ),
    );
  }
}

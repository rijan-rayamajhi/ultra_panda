import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_assets.dart';
import '../core/audio_manager.dart';
import '../core/haptics.dart';
import '../core/player_wallet.dart';
import '../core/progression.dart';
import '../models/fruit_fortune_model.dart';
import '../widgets/common/slot_header.dart';
import '../widgets/dragon_gold/dragon_gold_dialogs.dart';
import '../widgets/common/slot_controls_bar.dart';
import '../widgets/fruit_fortune/fruit_fortune_cabinet.dart';
import '../widgets/fruit_fortune/fruit_fortune_dialogs.dart';
import '../widgets/play_for_real_button.dart';

class FruitFortuneScreen extends StatefulWidget {
  const FruitFortuneScreen({super.key});

  @override
  State<FruitFortuneScreen> createState() => _FruitFortuneScreenState();
}

class _FruitFortuneScreenState extends State<FruitFortuneScreen>
    with TickerProviderStateMixin {
  // Bet configuration
  static const List<int> _betOptions = [
    500,
    1000,
    2500,
    5000,
    10000,
    25000,
    50000,
    100000,
  ];
  int _currentBetIndex = 2; // Default: 2,500
  int get _currentBet => _betOptions[_currentBetIndex];

  // Game state
  int _lastWin = 0;
  bool _isSpinning = false;
  bool _isAutoSpin = false;
  bool _isFreeSpins = false;
  int _freeSpinsRemaining = 0;
  int _totalFreeSpinsWin = 0;

  // Active cascade state
  int _activeMultiplier = 1;
  Set<int> _poppedIndices = {};

  // 21 cells grid: 7 cols x 3 rows
  List<FruitSymbolType> _grid = FruitFortuneEngine.generateInitialGrid();

  late final AnimationController _pulseController;
  late final List<AnimationController> _reelControllers;

  // True only while the reels roll on the initial drop (not during cascades).
  bool _reelsRolling = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _reelControllers = List.generate(
      7,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  // Base-game win generated but not yet shown/credited (reels animating).
  int _pendingWin = 0;
  static Duration _ms(int ms) =>
      Duration(milliseconds: PlayerWallet.instance.turboSpin ? ms ~/ 2 : ms);

  void _creditPendingWin() {
    if (_pendingWin <= 0) return;
    PlayerWallet.instance.addCoins(_pendingWin);
    _pendingWin = 0;
  }

  @override
  void dispose() {
    // Never lose a paid spin's win because the player left mid-animation.
    _creditPendingWin();
    _pulseController.dispose();
    for (final c in _reelControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSpin({bool forceFreeSpins = false}) async {
    if (!mounted || _isSpinning) return;

    if (!_isFreeSpins) {
      if (!PlayerWallet.instance.deductCoins(_currentBet)) {
        setState(() => _isAutoSpin = false);
        DragonGoldDialogs.showInsufficientFunds(context);
        return;
      }
    }

    setState(() {
      _isSpinning = true;
      _poppedIndices = {};
      _activeMultiplier = _isFreeSpins ? 2 : 1;
    });

    Haptics.medium();
    AudioManager.instance.playSpinWhoosh();

    // 1. Initial Spin Drop (result + record up front so an exit mid-cascade
    // still pays via dispose()).
    final spinMultiplier = _isFreeSpins ? 2 : 1;
    final spinResult = FruitFortuneEngine.playSpin(
      bet: _currentBet,
      isFreeSpin: _isFreeSpins,
      spinMultiplier: spinMultiplier,
      forceFreeSpins: forceFreeSpins,
    );
    PlayerWallet.instance.recordSpin(
      betAmount: _isFreeSpins ? 0 : _currentBet,
      winAmount: spinResult.totalWin,
      gameTitle: 'Fruit Fortune',
    );
    _pendingWin = spinResult.totalWin;

    final shouldShowRealPrompt =
        !_isFreeSpins && PlayForReal.recordSlotSpin('Fruit Fortune');

    // Roll the reels, then stop them left-to-right onto the dropped grid.
    for (final c in _reelControllers) {
      c.repeat();
    }
    setState(() => _reelsRolling = true);
    for (var col = 0; col < _reelControllers.length; col++) {
      await Future.delayed(_ms(40));
      _reelControllers[col].stop();
      Haptics.light();
    }

    if (!mounted) return;

    // Show initial dropped grid
    setState(() {
      _grid = List.from(spinResult.initialGrid);
      _reelsRolling = false;
    });

    await Future.delayed(_ms(350));

    // 2. Cascade Tumble Sequence
    int runningWin = 0;
    if (spinResult.cascadeSteps.isNotEmpty) {
      for (final step in spinResult.cascadeSteps) {
        if (!mounted) return;

        // A. Highlight winning clusters and update multiplier ladder
        setState(() {
          _grid = List.from(step.gridBefore);
          _poppedIndices = Set.from(step.poppedIndices);
          _activeMultiplier = step.cascadeMultiplier;
          runningWin += step.stepWin;
          _lastWin = runningWin;
        });

        Haptics.light();
        AudioManager.instance.playPayoutDing();
        await Future.delayed(_ms(550));

        if (!mounted) return;

        // B. Clear popped symbols and drop new ones
        setState(() {
          _grid = List.from(step.gridAfter);
          _poppedIndices = {};
        });

        Haptics.selection();
        await Future.delayed(_ms(400));
      }
    }

    if (!mounted) return;

    // 3. Finalize spin payout
    setState(() {
      _isSpinning = false;
      _poppedIndices = {};
    });

    if (spinResult.totalWin > 0) {
      Haptics.vibrate();
      AudioManager.instance.playPayoutDing();
      _creditPendingWin();
      setState(() {
        _lastWin = spinResult.totalWin;
        if (_isFreeSpins) {
          _totalFreeSpinsWin += spinResult.totalWin;
        }
      });
    } else {
      if (!_isFreeSpins) {
        setState(() => _lastWin = 0);
      }
    }

    // 4. Free Spins Trigger (3+ Scatters)
    if (spinResult.triggersFreeSpins && !_isFreeSpins) {
      Progression.instance.onBonusTriggered();
      if (PlayerWallet.instance.autoStopOnBonus) {
        setState(() => _isAutoSpin = false);
      }
      AudioManager.instance.playPayoutDing();
      await Future.delayed(_ms(400));
      if (!mounted) return;

      FruitFortuneDialogs.showFreeSpinsTriggerDialog(
        context: context,
        onStart: () {
          setState(() {
            _isFreeSpins = true;
            _freeSpinsRemaining = 10;
            _totalFreeSpinsWin = 0;
            _lastWin = 0;
          });
          _runFreeSpinsLoop(pendingRealPrompt: shouldShowRealPrompt);
        },
      );
      return;
    }

    // Play for real popup check (every 5 spins)
    if (shouldShowRealPrompt) {
      if (_isAutoSpin) {
        setState(() => _isAutoSpin = false);
      }
      await Future.delayed(_ms(400));
      if (!mounted) return;
      await PlayForReal.showPrompt(context);
    }

    // 5. Auto-spin handling
    if (_isAutoSpin && !_isFreeSpins) {
      await Future.delayed(_ms(700));
      if (mounted && _isAutoSpin) {
        _handleSpin();
      }
    }
  }

  Future<void> _runFreeSpinsLoop({bool pendingRealPrompt = false}) async {
    while (_isFreeSpins && _freeSpinsRemaining > 0 && mounted) {
      await Future.delayed(_ms(400));
      if (!mounted) return;

      setState(() {
        _freeSpinsRemaining--;
      });

      await _handleSpin();

      await Future.delayed(_ms(600));
    }

    if (!mounted) return;

    FruitFortuneDialogs.showFreeSpinsCompletedDialog(
      context: context,
      totalWin: _totalFreeSpinsWin,
      onDismiss: () async {
        if (mounted) {
          setState(() {
            _isFreeSpins = false;
            _freeSpinsRemaining = 0;
          });
          if (pendingRealPrompt) {
            await Future.delayed(_ms(300));
            if (mounted) await PlayForReal.showPrompt(context);
          }
          // Auto-stop-on-bonus off: carry on autospinning after the bonus.
          if (_isAutoSpin) _handleSpin();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSpinning && !_isFreeSpins,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. Tropical Asian Jade Ambient Background
            Positioned.fill(
              child: Image.asset(
                AppAssets.bgFruitFortune,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF0F361A),
                        Color(0xFF041208),
                        Colors.black,
                      ],
                      radius: 1.2,
                    ),
                  ),
                ),
              ),
            ),

            // 2. Ambient Gradient Vignette
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0x99000000),
                      Colors.transparent,
                      Color(0xBB000000),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 3. Screen Layout (Unified Header, Cabinet, Unified Controls)
            SafeArea(
              left: false,
              right: false,
              bottom: false,
              child: Column(
                children: [
                  // Top Header Bar
                  SafeArea(
                    top: false,
                    bottom: false,
                    child: SlotHeader(
                      title: 'FRUIT FORTUNE',
                      titleGradient: const LinearGradient(
                        colors: [
                          Color(0xFF0A3D1E),
                          Color(0xFF1B6B38),
                          Color(0xFF2E7D32),
                          Color(0xFF1B6B38),
                          Color(0xFF0A3D1E),
                        ],
                      ),
                      onExit: () => Navigator.of(context).pop(),
                      onOpenInfo: () =>
                          FruitFortuneDialogs.showPaytableDialog(context),
                      isInteractionBlocked: _isSpinning || _isFreeSpins,
                    ),
                  ),

                  // Main 7x3 Cabinet Frame with Cascade Multiplier Ladder
                  Expanded(
                    child: Transform.scale(
                      scale: 1.12,
                      alignment: Alignment.topCenter,
                      child: Center(
                        child: FruitFortuneCabinet(
                          grid: _grid,
                          poppedIndices: _poppedIndices,
                          activeMultiplier: _activeMultiplier,
                          isSpinning: _isSpinning,
                          reelsRolling: _reelsRolling,
                          reelControllers: _reelControllers,
                          isFreeSpins: _isFreeSpins,
                          pulseAnimation:
                              PlayerWallet.instance.winEffectsEnabled
                              ? _pulseController
                              : const AlwaysStoppedAnimation(0.0),
                        ),
                      ),
                    ),
                  ),

                  // Bottom Controls Dock
                  SlotControlsBar(
                    currentBet: _currentBet,
                    lastWinAmount: _lastWin,
                    isSpinning: _isSpinning,
                    controlsEnabled: !_isSpinning && !_isFreeSpins,
                    autoSpinActive: _isAutoSpin,
                    canDecreaseBet: _currentBetIndex > 0,
                    canIncreaseBet: _currentBetIndex < _betOptions.length - 1,
                    betSubtitle: 'TOTAL BET (7x3)',
                    winLabel: _isFreeSpins ? 'FREE SPINS WIN (2X)' : null,
                    onDecreaseBet: () {
                      if (_currentBetIndex > 0) {
                        setState(() => _currentBetIndex--);
                      }
                    },
                    onIncreaseBet: () {
                      if (_currentBetIndex < _betOptions.length - 1) {
                        setState(() => _currentBetIndex++);
                      }
                    },
                    onMaxBet: () {
                      setState(() => _currentBetIndex = _betOptions.length - 1);
                    },
                    onToggleAutoSpin: () {
                      setState(() => _isAutoSpin = !_isAutoSpin);
                      if (_isAutoSpin && !_isSpinning) {
                        _handleSpin();
                      }
                    },
                    onAction: () => _handleSpin(),
                    actionWidget: _isFreeSpins
                        ? Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.4,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x8800E676),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'FREE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    '$_freeSpinsRemaining',
                                    style: const TextStyle(
                                      color: Color(0xFFFFF9C4),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

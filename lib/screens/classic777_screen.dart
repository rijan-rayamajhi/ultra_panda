import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_assets.dart';
import '../core/audio_manager.dart';
import '../core/haptics.dart';
import '../core/player_wallet.dart';
import '../core/progression.dart';
import '../models/classic777_model.dart';
import '../widgets/classic777/classic777_cabinet.dart';
import '../widgets/classic777/classic777_dialogs.dart';
import '../widgets/common/slot_header.dart';
import '../widgets/dragon_gold/dragon_gold_dialogs.dart';
import '../widgets/common/slot_controls_bar.dart';
import '../widgets/play_for_real_button.dart';

class Classic777Screen extends StatefulWidget {
  const Classic777Screen({super.key});

  @override
  State<Classic777Screen> createState() => _Classic777ScreenState();
}

class _Classic777ScreenState extends State<Classic777Screen>
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

  int _lastWin = 0;
  bool _isSpinning = false;
  bool _isAutoSpin = false;
  bool _isFreeSpins = false;
  int _freeSpinsRemaining = 0;
  int _totalFreeSpinsWin = 0;

  // 3x3 Grid State (initial clean starter symbols)
  List<ClassicSymbolType> _grid = [
    ClassicSymbolType.sevenRed,
    ClassicSymbolType.wild,
    ClassicSymbolType.sevenGold,
    ClassicSymbolType.bar,
    ClassicSymbolType.sevenRed,
    ClassicSymbolType.bar,
    ClassicSymbolType.ace,
    ClassicSymbolType.king,
    ClassicSymbolType.queen,
  ];

  List<LineWinResult> _currentLineWins = [];

  // Reel animations: 3 columns
  late final List<AnimationController> _reelControllers;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _reelControllers = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
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
    for (final c in _reelControllers) {
      c.dispose();
    }
    _pulseController.dispose();
    super.dispose();
  }

  // Spin Trigger logic
  Future<void> _handleSpin({bool forceFreeSpins = false}) async {
    if (!mounted || _isSpinning) return;

    // Check balance if regular spin
    if (!_isFreeSpins) {
      if (!PlayerWallet.instance.deductCoins(_currentBet)) {
        setState(() => _isAutoSpin = false);
        DragonGoldDialogs.showInsufficientFunds(context);
        return;
      }
    }

    setState(() {
      _isSpinning = true;
      _currentLineWins = [];
    });

    Haptics.medium();
    AudioManager.instance.playSpinWhoosh();

    // Start reel rolling animations
    for (final c in _reelControllers) {
      c.repeat();
    }

    // Generate spin evaluation from math engine
    final multiplier = _isFreeSpins ? 2 : 1;
    final spinResult = Classic777Engine.generateSpin(
      bet: _currentBet,
      isFreeSpin: _isFreeSpins,
      multiplier: multiplier,
      forceFreeSpins: forceFreeSpins,
    );
    // Recorded up front so leaving mid-animation can't drop the spin.
    PlayerWallet.instance.recordSpin(
      betAmount: _isFreeSpins ? 0 : _currentBet,
      winAmount: spinResult.totalWin,
      gameTitle: 'Classic 777',
    );
    _pendingWin = spinResult.totalWin;

    final shouldShowRealPrompt =
        !_isFreeSpins && PlayForReal.recordSlotSpin('Classic 777');

    // Staggered reel stop (Col 0 -> Col 1 -> Col 2)
    await Future.delayed(_ms(400));
    _reelControllers[0].stop();
    Haptics.light();

    await Future.delayed(_ms(250));
    _reelControllers[1].stop();
    Haptics.light();

    await Future.delayed(_ms(250));
    _reelControllers[2].stop();
    Haptics.heavy();

    if (!mounted) return;

    // Update with final grid & evaluate payout
    setState(() {
      _grid = spinResult.grid;
      _currentLineWins = spinResult.lineWins;
      _isSpinning = false;
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

    // Check Free Spins trigger (3+ Scatters)
    if (spinResult.triggersFreeSpins && !_isFreeSpins) {
      Progression.instance.onBonusTriggered();
      if (PlayerWallet.instance.autoStopOnBonus) {
        setState(() => _isAutoSpin = false);
      }
      AudioManager.instance.playPayoutDing();
      await Future.delayed(_ms(400));
      if (!mounted) return;

      Classic777Dialogs.showFreeSpinsTriggerDialog(
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

    // Auto-spin next spin handling
    if (_isAutoSpin && !_isFreeSpins) {
      await Future.delayed(_ms(700));
      if (mounted && _isAutoSpin) {
        _handleSpin();
      }
    }
  }

  // Free spins execution loop
  Future<void> _runFreeSpinsLoop({bool pendingRealPrompt = false}) async {
    while (_isFreeSpins && _freeSpinsRemaining > 0 && mounted) {
      await Future.delayed(_ms(500));
      if (!mounted) return;

      setState(() {
        _freeSpinsRemaining--;
      });

      await _handleSpin();

      await Future.delayed(_ms(800));
    }

    if (!mounted) return;

    // Conclude Free Spins
    Classic777Dialogs.showFreeSpinsCompletedDialog(
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
            // 1. Retro Vegas Casino Ambient Background
            Positioned.fill(
              child: Image.asset(
                AppAssets.bgSlot777,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF4A000D),
                        Color(0xFF140003),
                        Colors.black,
                      ],
                      radius: 1.2,
                    ),
                  ),
                ),
              ),
            ),

            // 2. Ambient Dark Gradient Overlay for Readability
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

            // 3. Screen Layout (Header, Cabinet, Controls)
            SafeArea(
              left: false,
              right: false,
              bottom: false,
              child: Column(
                children: [
                  // Top Header Bar (Unified SlotHeader)
                  SafeArea(
                    top: false,
                    bottom: false,
                    child: SlotHeader(
                      title: 'CLASSIC 777',
                      onExit: () => Navigator.of(context).pop(),
                      onOpenInfo: () =>
                          Classic777Dialogs.showPaytableDialog(context),
                      isInteractionBlocked: _isSpinning || _isFreeSpins,
                    ),
                  ),

                  // Main 3x3 Retro Cabinet with Golden Frame & Ticker
                  Expanded(
                    child: Transform.scale(
                      scale: 1.12,
                      alignment: Alignment.topCenter,
                      child: Center(
                        child: Classic777Cabinet(
                          grid: _grid,
                          lineWins: _currentLineWins,
                          isSpinning: _isSpinning,
                          isFreeSpins: _isFreeSpins,
                          currentBet: _currentBet,
                          reelControllers: _reelControllers,
                          pulseAnimation:
                              PlayerWallet.instance.winEffectsEnabled
                              ? _pulseController
                              : const AlwaysStoppedAnimation(0.0),
                        ),
                      ),
                    ),
                  ),

                  // Bottom Controls Dock (Unified SlotControlsBar)
                  SlotControlsBar(
                    currentBet: _currentBet,
                    lastWinAmount: _lastWin,
                    isSpinning: _isSpinning,
                    controlsEnabled: !_isSpinning && !_isFreeSpins,
                    autoSpinActive: _isAutoSpin,
                    canDecreaseBet: _currentBetIndex > 0,
                    canIncreaseBet: _currentBetIndex < _betOptions.length - 1,
                    betSubtitle: 'TOTAL BET (5 LINES)',
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
                                colors: [Color(0xFFFF3D00), Color(0xFFDD2C00)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.4,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x88FF3D00),
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

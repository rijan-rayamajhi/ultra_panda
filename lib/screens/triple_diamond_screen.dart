import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_assets.dart';
import '../core/audio_manager.dart';
import '../core/haptics.dart';
import '../core/player_wallet.dart';
import '../models/triple_diamond_model.dart';
import '../widgets/common/slot_header.dart';
import '../widgets/dragon_gold/dragon_gold_dialogs.dart';
import '../widgets/common/slot_controls_bar.dart';
import '../widgets/triple_diamond/triple_diamond_cabinet.dart';
import '../widgets/triple_diamond/triple_diamond_dialogs.dart';
import '../widgets/play_for_real_button.dart';

class TripleDiamondScreen extends StatefulWidget {
  const TripleDiamondScreen({super.key});

  @override
  State<TripleDiamondScreen> createState() => _TripleDiamondScreenState();
}

class _TripleDiamondScreenState extends State<TripleDiamondScreen>
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

  // 3x3 Grid State
  List<DiamondSymbolType> _grid = [
    DiamondSymbolType.diamondWild,
    DiamondSymbolType.sevenRed,
    DiamondSymbolType.bar3,
    DiamondSymbolType.sevenGold,
    DiamondSymbolType.diamondWild,
    DiamondSymbolType.panda,
    DiamondSymbolType.bar2,
    DiamondSymbolType.bar1,
    DiamondSymbolType.bar3,
  ];

  List<DiamondLineWinResult> _currentLineWins = [];

  // Reel animations (3 columns)
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

  Future<void> _handleSpin({bool forceJackpot = false}) async {
    if (!mounted || _isSpinning) return;

    if (!PlayerWallet.instance.deductCoins(_currentBet)) {
      setState(() => _isAutoSpin = false);
      DragonGoldDialogs.showInsufficientFunds(context);
      return;
    }

    setState(() {
      _isSpinning = true;
      _currentLineWins = [];
    });

    Haptics.medium();
    AudioManager.instance.playSpinWhoosh();

    // Start reel rolling
    for (final c in _reelControllers) {
      c.repeat();
    }

    // Evaluate spin
    final spinResult = TripleDiamondEngine.generateSpin(
      bet: _currentBet,
      forceJackpot: forceJackpot,
    );
    // Recorded up front so leaving mid-animation can't drop the spin.
    PlayerWallet.instance.recordSpin(
      betAmount: _currentBet,
      winAmount: spinResult.totalWin,
      gameTitle: 'Triple Diamond',
    );
    _pendingWin = spinResult.totalWin;

    final shouldShowRealPrompt =
        PlayForReal.recordSlotSpin('Triple Diamond');

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

    setState(() {
      _grid = spinResult.grid;
      _currentLineWins = spinResult.lineWins;
      _isSpinning = false;
    });

    if (spinResult.totalWin > 0) {
      Haptics.vibrate();
      AudioManager.instance.playPayoutDing();
      _creditPendingWin();
      setState(() => _lastWin = spinResult.totalWin);
    } else {
      setState(() => _lastWin = 0);
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
    if (_isAutoSpin) {
      await Future.delayed(_ms(700));
      if (mounted && _isAutoSpin) {
        _handleSpin();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSpinning,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. Royal Velvet Blue Crystal Ambient Background
            Positioned.fill(
              child: Image.asset(
                AppAssets.bgTripleDiamond,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF072147),
                        Color(0xFF030D1C),
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
                      title: 'TRIPLE DIAMOND',
                      titleGradient: const LinearGradient(
                        colors: [
                          Color(0xFF062354),
                          Color(0xFF0B4699),
                          Color(0xFF0288D1),
                          Color(0xFF0B4699),
                          Color(0xFF062354),
                        ],
                      ),
                      onExit: () => Navigator.of(context).pop(),
                      onOpenInfo: () =>
                          TripleDiamondDialogs.showPaytableDialog(context),
                      isInteractionBlocked: _isSpinning,
                    ),
                  ),

                  // Main 3x3 Sleek Chrome Cabinet Frame with Crown Ticker
                  Expanded(
                    child: Transform.scale(
                      scale: 1.12,
                      alignment: Alignment.topCenter,
                      child: Center(
                        child: TripleDiamondCabinet(
                          grid: _grid,
                          lineWins: _currentLineWins,
                          isSpinning: _isSpinning,
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

                  // Bottom Controls Dock
                  SlotControlsBar(
                    currentBet: _currentBet,
                    lastWinAmount: _lastWin,
                    isSpinning: _isSpinning,
                    controlsEnabled: !_isSpinning,
                    autoSpinActive: _isAutoSpin,
                    canDecreaseBet: _currentBetIndex > 0,
                    canIncreaseBet: _currentBetIndex < _betOptions.length - 1,
                    betSubtitle: 'TOTAL BET (5 LINES)',
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

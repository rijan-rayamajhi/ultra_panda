import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_assets.dart';
import '../core/audio_manager.dart';
import '../core/player_wallet.dart';
import '../core/progression.dart';
import 'lobby_screen.dart';

/// Boot screen: runs the real startup work (save data, audio, lobby image
/// precache) and shows its actual progress on a bar aligned to the plaque
/// baked into the splash art.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  static const _artAspect = 1672 / 941;
  static const _minShowTime = Duration(milliseconds: 1200);
  static const _lobbyImages = [
    AppAssets.bgLobby,
    AppAssets.cardDragonGold,
    AppAssets.cardSlot777,
    AppAssets.cardFruitFortune,
    AppAssets.cardTripleDiamond,
    AppAssets.iconCoin,
    AppAssets.iconGem,
    AppAssets.barGrand,
  ];

  double _progress = 0;
  String _status = 'LOADING';

  @override
  void initState() {
    super.initState();
    // precacheImage needs an inherited MediaQuery, so start after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  void _step(double progress, String status) {
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _status = status;
    });
  }

  Future<void> _boot() async {
    final minTime = Future.delayed(_minShowTime);
    try {
      _step(0.1, 'LOADING YOUR PROGRESS');
      await PlayerWallet.instance.load();
      await Progression.instance.load();

      _step(0.35, 'TUNING THE REELS');
      AudioManager.instance.init();

      // Capped so a slow disk never holds the player on the splash.
      await () async {
        for (var i = 0; i < _lobbyImages.length; i++) {
          if (!mounted) return;
          await precacheImage(AssetImage(_lobbyImages[i]), context);
          _step(
            0.4 + 0.55 * (i + 1) / _lobbyImages.length,
            'PREPARING THE LOBBY',
          );
        }
      }().timeout(const Duration(seconds: 3));
    } catch (e, st) {
      // Never strand the player on the splash; the lobby works with defaults.
      debugPrint('Startup step failed: $e\n$st');
    }
    await minTime;
    _step(1, 'READY!');
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => const LobbyScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0405),
      body: LayoutBuilder(
        builder: (context, c) {
          final size = c.biggest;
          // Where the art lands under BoxFit.cover.
          final artW = math.max(size.width, size.height * _artAspect);
          final artH = artW / _artAspect;
          final artTop = (size.height - artH) / 2;
          final barW = math.min(artW * 0.29, size.width * 0.6);
          // Plaque centre is ~91.5% down the art; on wide screens that falls
          // off the bottom, so keep the bar on screen.
          final barCenterY = math.min(artTop + artH * 0.915, size.height - 30);

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(AppAssets.splashLoading, fit: BoxFit.cover),
              // Legibility scrim behind the bar and status text.
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 90,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xAA000000)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: (size.width - barW) / 2,
                width: barW,
                top: barCenterY - 26,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _status,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFFFFF3B0),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: _progress),
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                      builder: (context, v, _) => _GoldProgressBar(value: v),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GoldProgressBar extends StatelessWidget {
  final double value;
  const _GoldProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.all(2),
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
          BoxShadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2)),
          BoxShadow(color: Color(0x66FFD54F), blurRadius: 10),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0B1F10), Color(0xFF14361C)],
                  ),
                ),
              ),
            ),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFF59D),
                      Color(0xFFFFC107),
                      Color(0xFFFF8F00),
                    ],
                  ),
                ),
                child: SizedBox.expand(),
              ),
            ),
            // Top gloss
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

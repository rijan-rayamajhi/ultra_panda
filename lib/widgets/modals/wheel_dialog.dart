import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/haptics.dart';
import '../../core/app_assets.dart';
import '../../core/audio_manager.dart';
import '../../core/progression.dart';
import 'base_popup_dialog.dart';
import 'popup_widgets.dart';

class WheelPrizeItem {
  final String label;
  final String sublabel;
  final String fullTitle;
  final String iconPath;
  final Color primaryColor;
  final Reward reward;
  final int weight;

  const WheelPrizeItem({
    required this.label,
    required this.sublabel,
    required this.fullTitle,
    required this.iconPath,
    required this.reward,
    required this.weight,
    this.primaryColor = const Color(0xFFFFD54F),
  });
}

class WheelDialog extends StatefulWidget {
  const WheelDialog({super.key});

  static Future<void> show(BuildContext context) {
    return BasePopupDialog.show(
      context: context,
      title: 'LUCKY WHEEL',
      content: const WheelDialog(),
    );
  }

  @override
  State<WheelDialog> createState() => _WheelDialogState();
}

class _WheelDialogState extends State<WheelDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  double _currentRotation = 0.0;
  bool _isSpinning = false;
  WheelPrizeItem? _wonPrize;

  // Weights sum to 100, so each weight is the percent chance of that sector.
  static const List<WheelPrizeItem> _prizes = [
    WheelPrizeItem(
      label: '500K',
      sublabel: 'COINS',
      fullTitle: '500,000 COINS',
      iconPath: AppAssets.iconCoin,
      reward: Reward(coins: 500000),
      weight: 28,
    ),
    WheelPrizeItem(
      label: '50',
      sublabel: 'GEMS',
      fullTitle: '50 GEMS',
      iconPath: AppAssets.iconGem,
      reward: Reward(gems: 50),
      weight: 14,
    ),
    WheelPrizeItem(
      label: '1M',
      sublabel: 'COINS',
      fullTitle: '1,000,000 COINS',
      iconPath: AppAssets.iconCoin,
      reward: Reward(coins: 1000000),
      weight: 22,
    ),
    WheelPrizeItem(
      label: '100',
      sublabel: 'GEMS',
      fullTitle: '100 GEMS',
      iconPath: AppAssets.iconGem,
      reward: Reward(gems: 100),
      weight: 6,
    ),
    WheelPrizeItem(
      label: '2.5M',
      sublabel: 'COINS',
      fullTitle: '2,500,000 COINS',
      iconPath: AppAssets.iconCoin,
      reward: Reward(coins: 2500000),
      weight: 14,
    ),
    WheelPrizeItem(
      label: '3M',
      sublabel: 'COINS',
      fullTitle: '3,000,000 COINS',
      iconPath: AppAssets.iconCoin,
      reward: Reward(coins: 3000000),
      weight: 9,
    ),
    WheelPrizeItem(
      label: '5M',
      sublabel: 'COINS',
      fullTitle: '5,000,000 COINS',
      iconPath: AppAssets.iconCoin,
      reward: Reward(coins: 5000000),
      weight: 5,
    ),
    WheelPrizeItem(
      label: 'BIG',
      sublabel: 'JACKPOT',
      fullTitle: '10M COINS + 100 GEMS',
      iconPath: AppAssets.iconGift,
      reward: Reward(coins: 10000000, gems: 100),
      weight: 2,
    ),
  ];

  final math.Random _random = math.Random();
  Timer? _ticker;
  String? _error;

  int _pickWeighted() {
    var roll = _random.nextInt(_prizes.fold(0, (s, p) => s + p.weight));
    for (var i = 0; i < _prizes.length; i++) {
      roll -= _prizes[i].weight;
      if (roll < 0) return i;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    Progression.instance.refresh();
    // Drives the free-spin countdown.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !Progression.instance.wheelFreeAvailable) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _spinController.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (_isSpinning) return;
    if (!Progression.instance.payForWheelSpin()) {
      Haptics.light();
      setState(
        () => _error = 'NEED ${Progression.wheelSpinGemCost} GEMS TO SPIN',
      );
      return;
    }

    Haptics.heavy();
    AudioManager.instance.playSpinWhoosh();
    setState(() {
      _isSpinning = true;
      _wonPrize = null;
      _error = null;
    });

    final targetSector = _pickWeighted();
    final fullSpins = 5 + _random.nextInt(3); // 5 to 7 full revolutions

    // Calculate exact target rotation so sector targetSector lands at 12 o'clock (top pointer)
    const sectorAngle = 2 * math.pi / 8;
    final currentMod = _currentRotation % (2 * math.pi);
    final targetMod = ((8 - targetSector) % 8) * sectorAngle;

    double forwardDelta = (fullSpins * 2 * math.pi) + (targetMod - currentMod);
    if (forwardDelta < fullSpins * 2 * math.pi) {
      forwardDelta += 2 * math.pi;
    }

    final startRotation = _currentRotation;
    final endRotation = _currentRotation + forwardDelta;

    _spinAnimation = Tween<double>(begin: startRotation, end: endRotation)
        .animate(
          CurvedAnimation(parent: _spinController, curve: Curves.easeOutCirc),
        );

    _spinController.forward(from: 0.0).then((_) {
      // Credit even if the dialog was closed mid-spin: the spin was paid for.
      Progression.instance.creditWheelPrize(_prizes[targetSector].reward);
      if (mounted) {
        Haptics.heavy();
        AudioManager.instance.playPayoutDing();
        setState(() {
          _isSpinning = false;
          _currentRotation = endRotation;
          _wonPrize = _prizes[targetSector];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const double wheelSize = 212.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // LEFT: Casino Wheel with Realistic Flapper & Center Hub
        Expanded(
          flex: 5,
          child: Center(
            child: SizedBox(
              width: wheelSize,
              height: wheelSize,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // 1. Spinning Disc (Background Artwork + Sector Badges)
                  AnimatedBuilder(
                    animation: _spinController,
                    builder: (context, child) {
                      final angle = _isSpinning
                          ? _spinAnimation.value
                          : _currentRotation;
                      return Transform.rotate(angle: angle, child: child);
                    },
                    child: Container(
                      width: wheelSize,
                      height: wheelSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black87,
                            blurRadius: 12,
                            offset: Offset(0, 5),
                          ),
                          BoxShadow(
                            color: Color(0x66FFD700),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // High-res Wheel graphic
                          Image.asset(
                            AppAssets.wheelFace,
                            width: wheelSize,
                            height: wheelSize,
                            fit: BoxFit.contain,
                          ),

                          // 8 Sector Badges positioned radially
                          ...List.generate(_prizes.length, (index) {
                            return _buildSectorBadge(
                              item: _prizes[index],
                              sectorIndex: index,
                              wheelSize: wheelSize,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  // 2. Center 3D Casino Hub (Covers hole seamlessly, non-rotating)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFFFFDE7),
                          Color(0xFFFFD54F),
                          Color(0xFFFF8F00),
                          Color(0xFF5D4037),
                        ],
                        stops: [0.0, 0.45, 0.82, 1.0],
                      ),
                      border: Border.all(
                        color: const Color(0xFFFFF9C4),
                        width: 2.0,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                        BoxShadow(
                          color: Color(0x55FFD700),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [
                              Color(0xFF8E1438),
                              Color(0xFF54071B),
                              Color(0xFF2A000A),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFFFFD700),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          size: 24,
                          color: Color(0xFFFFD700),
                          shadows: [
                            Shadow(color: Color(0xFFFFE082), blurRadius: 6),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Ornate Golden Top Flapper Needle (NO rectangular box shadow!)
                  Positioned(
                    top: -8,
                    child: AnimatedBuilder(
                      animation: _spinController,
                      builder: (context, child) {
                        double deflection = 0.0;
                        if (_isSpinning) {
                          final currentAngle = _spinAnimation.value;
                          final progress = _spinController.value;
                          // Ticks as each of the 8 sector boundaries passes
                          deflection =
                              math.sin(currentAngle * 8) *
                              (1.0 - progress) *
                              0.12;
                        }
                        return Transform.rotate(
                          angle: deflection,
                          alignment: const Alignment(0, -0.6),
                          child: child,
                        );
                      },
                      child: const _CasinoWheelFlapper(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 14),

        // RIGHT: Controls, Status & Win Presentation
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1 Free Spin Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF250D3A), Color(0xFF140522)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFFD54F),
                    width: 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      size: 13,
                      color: Color(0xFFFFD700),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      Progression.instance.wheelFreeAvailable
                          ? 'FREE SPIN READY!'
                          : 'FREE SPIN IN ${formatDuration(Progression.instance.timeUntilDailyReset)}',
                      style: const TextStyle(
                        color: Color(0xFFFFE082),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Status / Reward Display
              SizedBox(
                height: 58,
                child: Center(
                  child: _wonPrize != null
                      ? _buildWinBanner(_wonPrize!)
                      : _buildIdlePrompt(),
                ),
              ),

              const SizedBox(height: 12),

              // Spin / Action Button
              GestureDetector(
                onTap: _isSpinning ? null : _spinWheel,
                child: AnimatedScale(
                  scale: _isSpinning ? 0.94 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Opacity(
                    opacity: _isSpinning ? 0.65 : 1.0,
                    child: Container(
                      height: 44,
                      width: 134,
                      alignment: Alignment.center,
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
                        border: Border.all(
                          color: const Color(0xFFFFD54F),
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66FFD700),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: Colors.black87,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ShaderMask(
                        shaderCallback: (r) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFFDE7),
                            Color(0xFFFFD54F),
                            Color(0xFFFFA000),
                          ],
                        ).createShader(r),
                        child: const Text(
                          'SPIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(0, 1.5),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!Progression.instance.wheelFreeAvailable) ...[
                    Image.asset(AppAssets.iconGem, width: 12, height: 12),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    Progression.instance.wheelFreeAvailable
                        ? 'FREE'
                        : '${Progression.wheelSpinGemCost} GEMS PER SPIN',
                    style: const TextStyle(
                      color: Color(0xFFFFE082),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectorBadge({
    required WheelPrizeItem item,
    required int sectorIndex,
    required double wheelSize,
  }) {
    // 8 sectors centered at 0, 45, 90, 135, 180, 225, 270, 315 degrees
    final angle = sectorIndex * (math.pi / 4);
    // Radial offset from wheel center into colored sector
    final radius = wheelSize * 0.285;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationZ(angle)
        ..translateByDouble(0.0, -radius, 0.0, 1.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            item.iconPath,
            width: 15,
            height: 15,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 1),
          Text(
            item.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
              shadows: [
                Shadow(
                  color: Colors.black,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
                Shadow(
                  color: Colors.black,
                  offset: Offset(-1, -1),
                  blurRadius: 2,
                ),
                Shadow(
                  color: Colors.black,
                  offset: Offset(0, 1.5),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
          Text(
            item.sublabel,
            style: const TextStyle(
              color: Color(0xFFFFD54F),
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
              shadows: [
                Shadow(
                  color: Colors.black,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
                Shadow(
                  color: Colors.black,
                  offset: Offset(-1, -1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinBanner(WheelPrizeItem prize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 1.4),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
          BoxShadow(color: Color(0x66FFD700), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.celebration_rounded,
                size: 12,
                color: Color(0xFF3E2723),
              ),
              SizedBox(width: 4),
              Text(
                'YOU WON!',
                style: TextStyle(
                  color: Color(0xFF3E2723),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.celebration_rounded,
                size: 12,
                color: Color(0xFF3E2723),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                prize.iconPath,
                width: 16,
                height: 16,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  prize.fullTitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                      Shadow(
                        color: Color(0xFF5D4037),
                        offset: Offset(-1, -1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdlePrompt() {
    return Text(
      _error ??
          (_isSpinning ? 'SPINNING FOR FORTUNE...' : 'TAP SPIN TO WIN BIG!'),
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        shadows: [
          Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2),
        ],
      ),
    );
  }
}

/// Ornate Casino Wheel Flapper Pointer
/// Custom painted golden arrow needle with ruby jewel and clean vector path drop shadow.
/// Eliminates the ugly rectangular container shadow artifact entirely.
class _CasinoWheelFlapper extends StatelessWidget {
  const _CasinoWheelFlapper();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(26, 36),
      painter: _CasinoWheelFlapperPainter(),
    );
  }
}

class _CasinoWheelFlapperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const pivotY = 9.0;
    const pivotR = 8.5;

    // 1. Build the exact pointer contour path
    final path = Path();
    // Start at top pivot circle left tangent
    path.moveTo(cx - pivotR, pivotY);
    // Arc over top pin
    path.arcToPoint(
      Offset(cx + pivotR, pivotY),
      radius: const Radius.circular(pivotR),
      clockwise: true,
    );
    // Right shoulder slanting sharply down to needle tip
    path.lineTo(cx + 2.0, size.height);
    // Needle tip
    path.arcToPoint(
      Offset(cx - 2.0, size.height),
      radius: const Radius.circular(8),
      clockwise: true,
    );
    // Slant back up to left pivot tangent
    path.lineTo(cx - pivotR, pivotY);
    path.close();

    // 2. Pure Vector Path Drop Shadow (strictly conforms to arrow contour)
    canvas.drawShadow(path, Colors.black, 4.0, true);

    // 3. Gold Metallic Gradient Fill
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFDE7),
          Color(0xFFFFD54F),
          Color(0xFFFFA000),
          Color(0xFF8D6E63),
        ],
        stops: [0.0, 0.35, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, bodyPaint);

    // 4. Gold Bevel Highlight Stroke
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFFFE082), Color(0xFFFF8F00)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, strokePaint);

    // 5. Center Pivot Ruby Jewel
    final jewelCenter = Offset(cx, pivotY);
    final jewelPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFF5252), Color(0xFFD50000), Color(0xFF6B0000)],
        stops: [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: jewelCenter, radius: 5.0));

    canvas.drawCircle(jewelCenter, 5.0, jewelPaint);

    // Specular highlight sparkle on ruby
    final sparklePaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(cx - 1.5, pivotY - 1.5), 1.2, sparklePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

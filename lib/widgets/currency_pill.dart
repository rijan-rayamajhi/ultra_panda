import 'package:flutter/material.dart';
import '../core/haptics.dart';
import '../core/progression.dart';
import 'common/reward_fly.dart';

class CurrencyPill extends StatelessWidget {
  final String iconPath;
  final int amount;
  final RewardKind kind;
  final Color textColor;
  final double width;
  final VoidCallback? onAddTap;

  const CurrencyPill({
    super.key,
    required this.iconPath,
    required this.amount,
    required this.kind,
    required this.textColor,
    required this.width,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Drawn capsule frame — scales to any width without distortion.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2A0712), Color(0xFF12030A)],
                ),
                border: Border.all(
                  color: const Color(0xFFFFD54F),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),

          // Numeric Value — shrinks to fit so large balances never overflow.
          Positioned(
            left: 26,
            right: 22,
            child: RewardFlyTarget(
              kind: kind,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: CountingNumber(
                  value: amount,
                  format: fmt,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    shadows: const [
                      Shadow(
                        color: Colors.black,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Plus / Add Button
          Positioned(
            right: 2,
            child: GestureDetector(
              onTap: () {
                Haptics.light();
                onAddTap?.call();
              },
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border.fromBorderSide(
                    BorderSide(color: Color(0xFFFFE082), width: 1),
                  ),
                ),
                child: const Icon(Icons.add, size: 12, color: Colors.white),
              ),
            ),
          ),

          // Overlapping Left Icon
          Positioned(
            left: -5,
            child: SizedBox(
              width: 28,
              height: 28,
              child: Image.asset(iconPath, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}

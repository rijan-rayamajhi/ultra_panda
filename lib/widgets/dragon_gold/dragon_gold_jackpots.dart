import 'package:flutter/material.dart';

class DragonGoldJackpots extends StatelessWidget {
  final int currentBet;

  const DragonGoldJackpots({super.key, required this.currentBet});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildJackpotCard(
            name: 'MINI',
            amount: currentBet * 15,
            accentColor: const Color(0xFF69F0AE),
          ),
          const SizedBox(width: 8),
          _buildJackpotCard(
            name: 'MINOR',
            amount: currentBet * 60,
            accentColor: const Color(0xFF80D8FF),
          ),
          const SizedBox(width: 8),
          _buildJackpotCard(
            name: 'MAJOR',
            amount: currentBet * 250,
            accentColor: const Color(0xFFEA80FC),
          ),
          const SizedBox(width: 8),
          _buildJackpotCard(
            name: 'GRAND',
            amount: currentBet * 500,
            accentColor: const Color(0xFFFF5252),
          ),
        ],
      ),
    );
  }

  Widget _buildJackpotCard({
    required String name,
    required int amount,
    required Color accentColor,
  }) {
    return Container(
      width: 104,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xE61A0510),
            accentColor.withValues(alpha: 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.85),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.35),
            blurRadius: 6,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$name: ',
            style: TextStyle(
              color: accentColor,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          Text(
            _formatNumber(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

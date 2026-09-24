import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_assets.dart';
import '../core/haptics.dart';
import '../widgets/modals/popup_widgets.dart';
import 'lobby_screen.dart';

/// First-launch 18+ confirmation and no-real-money disclaimer.
class AgeGateScreen extends StatefulWidget {
  const AgeGateScreen({super.key});

  static const prefsKey = 'ageConfirmed';

  static Future<bool> isConfirmed() async =>
      (await SharedPreferences.getInstance()).getBool(prefsKey) ?? false;

  @override
  State<AgeGateScreen> createState() => _AgeGateScreenState();
}

class _AgeGateScreenState extends State<AgeGateScreen> {
  bool _underage = false;

  static const disclaimer =
      'Ultra Panda is for entertainment only — no real money gambling. '
      'Coins and gems have no cash value and cannot be redeemed. '
      'Practice or success at social gaming does not imply future success '
      'at real-money gambling.';

  Future<void> _confirm() async {
    Haptics.medium();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AgeGateScreen.prefsKey, true);
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppAssets.splashLoading, fit: BoxFit.cover),
          const ColoredBox(color: Color(0xC7000000)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
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
                      BoxShadow(color: Color(0x66FFD54F), blurRadius: 18),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF4A0A18), Color(0xFF1C0409)],
                      ),
                    ),
                    child: _underage ? _blocked() : _prompt(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: Color(0xFFFFE082),
      fontSize: 18,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.5,
    ),
  );

  Widget _body(String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: Color(0xFFF5E6C8),
      fontSize: 11.5,
      height: 1.4,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _prompt() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _title('18+ ONLY'),
        const SizedBox(height: 10),
        _body('You must be 18 or older to play.\n\n$disclaimer'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              // Idle PillButton ignores taps, so handle it here.
              child: GestureDetector(
                onTap: () => setState(() => _underage = true),
                child: const PillButton(
                  label: 'I AM UNDER 18',
                  style: PillStyle.idle,
                  height: 34,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PillButton(
                label: 'I AM 18 OR OLDER',
                style: PillStyle.gold,
                height: 34,
                fontSize: 10,
                onTap: _confirm,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _blocked() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _title('SORRY'),
        const SizedBox(height: 10),
        _body('Ultra Panda is only available to players aged 18 and over.'),
      ],
    );
  }
}

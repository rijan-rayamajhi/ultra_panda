import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/audio_manager.dart';
import '../core/haptics.dart';
import 'modals/base_popup_dialog.dart';
import 'modals/popup_widgets.dart';

/// Opt-in link-out to the partner real-money site. Never tied to game
/// outcomes: a persistent lobby button plus at most one prompt per day.
class PlayForReal {
  static final Uri destination = Uri.parse(
    'https://www.spinnerlog.com/register'
    '?src=0db3c978-4547-4fee-8d28-7abbc787ebd8'
    '&utm_source=ultrapanda_app'
    '&utm_medium=banner'
    '&utm_campaign=return_traffic',
  );

  static const _lastPromptKey = 'playForRealPromptDay';
  static final Map<String, int> _slotSpinCounts = {};

  /// Records a spin for the given slot game. Returns true if the popup should show (every 5 spins).
  static bool recordSlotSpin(String gameTitle) {
    final count = (_slotSpinCounts[gameTitle] ?? 0) + 1;
    _slotSpinCounts[gameTitle] = count;
    return count % 5 == 0;
  }

  /// Current spin count for a given game.
  static int getSpinCount(String gameTitle) => _slotSpinCounts[gameTitle] ?? 0;

  static Future<void> open() async {
    Haptics.selection();
    AudioManager.instance.playSelectClick();
    try {
      await launchUrl(destination, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  /// Explicitly shows the "Play for Real" popup dialog. Resolves when dismissed.
  static Future<void> showPrompt(BuildContext context) async {
    if (!context.mounted) return;
    await BasePopupDialog.show(
      context: context,
      title: 'PLAY FOR REAL',
      width: 470,
      height: 290,
      content: const _PromptBody(),
    );
  }

  /// Shows the prompt if it hasn't been shown today. Resolves when dismissed.
  static Future<void> maybeShowDailyPrompt(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    if (prefs.getString(_lastPromptKey) == today || !context.mounted) return;
    await prefs.setString(_lastPromptKey, today);
    if (!context.mounted) return;
    await showPrompt(context);
  }
}

class _PromptBody extends StatelessWidget {
  const _PromptBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 4),
        // Golden Badge
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF3B0), Color(0xFFFFD54F), Color(0xFFFF8F00)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66FFD700),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.casino_rounded,
            size: 22,
            color: Color(0xFF3E2723),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'READY TO PLAY FOR REAL REWARDS?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFFFE082),
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            shadows: [
              Shadow(
                color: Colors.black,
                offset: Offset(0, 1.5),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Take your slot gameplay to the next level on our official partner site.\n'
          'Instant deposits, fast cashouts, and huge real jackpots!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 9.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '18+ only. Real-money gambling involves risk — only play with funds you can afford to lose. '
          'Results in Ultra Panda do not predict real-money results.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white60,
            fontSize: 7.5,
            height: 1.3,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: PillButton(
                label: 'NO THANKS',
                style: PillStyle.idle,
                height: 30,
                fontSize: 9.5,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PillButton(
                label: 'PLAY FOR REAL',
                style: PillStyle.gold,
                height: 30,
                fontSize: 9.5,
                onTap: () {
                  Navigator.of(context).pop();
                  PlayForReal.open();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
      ],
    );
  }
}

/// Persistent, clearly labelled lobby entry point.
class PlayForRealButton extends StatelessWidget {
  /// Compact variant for the in-game header.
  final bool compact;
  const PlayForRealButton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    const radius = 8.0;
    return GestureDetector(
      onTap: PlayForReal.open,
      child: Container(
        // Gold rim.
        padding: EdgeInsets.all(compact ? 1.4 : 1.8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
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
            BoxShadow(color: Color(0x66FFD700), blurRadius: 8, spreadRadius: 1),
          ],
        ),
        child: Container(
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 9, vertical: 4)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFD32F2F),
                Color(0xFF8B0D23),
                Color(0xFF4A0612),
              ],
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.open_in_new_rounded,
                size: compact ? 11 : 14,
                color: const Color(0xFFFFE082),
              ),
              SizedBox(width: compact ? 4 : 6),
              _GoldLabel('PLAY FOR REAL', size: compact ? 9 : 11),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gold-gradient shimmer text, matching the MAX BET / SPIN labels.
class _GoldLabel extends StatelessWidget {
  final String text;
  final double size;
  const _GoldLabel(this.text, {required this.size});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFFFA000)],
      ).createShader(r),
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          color: Colors.white,
          fontSize: size,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          shadows: const [
            Shadow(color: Colors.black, offset: Offset(0, 1.5), blurRadius: 2),
          ],
        ),
      ),
    );
  }
}

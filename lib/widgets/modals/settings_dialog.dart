import 'package:flutter/material.dart';
import '../../core/audio_manager.dart';
import '../../core/haptics.dart';
import '../../core/player_wallet.dart';
import 'base_popup_dialog.dart';

const _gold = [
  Color(0xFFFFF3B0),
  Color(0xFFFFD54F),
  Color(0xFFB8860B),
  Color(0xFFFFE082),
];

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  static const appVersion = 'v1.0.0';

  static Future<void> show(BuildContext context) {
    return BasePopupDialog.show(
      context: context,
      title: 'AUDIO & SETTINGS',
      content: const SettingsDialog(),
      width: 530,
      height: 330,
    );
  }

  void _toggle(VoidCallback action) {
    Haptics.selection();
    AudioManager.instance.playSelectClick();
    action();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        AudioManager.instance,
        PlayerWallet.instance,
      ]),
      builder: (context, _) {
        final audio = AudioManager.instance;
        final wallet = PlayerWallet.instance;

        return Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Panel(
                      title: 'AUDIO & FEEDBACK',
                      rows: [
                        _ToggleRow(
                          icon: audio.isMuted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          title: 'MASTER AUDIO',
                          value: !audio.isMuted,
                          onTap: () => _toggle(audio.toggleMute),
                        ),
                        _SliderRow(
                          icon: Icons.music_note_rounded,
                          title: 'MUSIC',
                          value: audio.musicVolume,
                          enabled: !audio.isMuted,
                          onChanged: audio.setMusicVolume,
                        ),
                        _SliderRow(
                          icon: Icons.graphic_eq_rounded,
                          title: 'EFFECTS',
                          value: audio.sfxVolume,
                          enabled: !audio.isMuted,
                          onChanged: audio.setSfxVolume,
                        ),
                        _ToggleRow(
                          icon: Icons.vibration_rounded,
                          title: 'HAPTIC VIBRATION',
                          value: wallet.hapticEnabled,
                          onTap: () => _toggle(wallet.toggleHaptic),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Panel(
                      title: 'GAMEPLAY',
                      rows: [
                        _ToggleRow(
                          icon: Icons.bolt_rounded,
                          title: 'TURBO SPINS',
                          value: wallet.turboSpin,
                          onTap: () => _toggle(wallet.toggleTurboSpin),
                        ),
                        _ToggleRow(
                          icon: Icons.pause_circle_filled_rounded,
                          title: 'STOP AUTO ON BONUS',
                          value: wallet.autoStopOnBonus,
                          onTap: () => _toggle(wallet.toggleAutoStopOnBonus),
                        ),
                        _ToggleRow(
                          icon: Icons.auto_awesome_rounded,
                          title: 'WIN EFFECTS',
                          value: wallet.winEffectsEnabled,
                          onTap: () => _toggle(wallet.toggleWinEffects),
                        ),
                        _RowShell(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.badge_rounded,
                                color: Color(0xFFFFD54F),
                                size: 15,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  wallet.userId,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Text(
                                appVersion,
                                style: TextStyle(
                                  color: Color(0xFFBCAAA4),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'For entertainment only. No real money gambling. Coins have no cash value.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  const _Panel({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xCC3A0A14), Color(0xCC1C0409), Color(0xCC0A0204)],
        ),
        border: Border.all(color: const Color(0x99FFD54F), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFFE082),
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            Expanded(child: rows[i]),
          ],
        ],
      ),
    );
  }
}

class _RowShell extends StatelessWidget {
  final Widget child;
  const _RowShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33FFD54F), width: 0.6),
      ),
      child: child,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final VoidCallback onTap;
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Whole row is the tap target.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _RowShell(
        child: Row(
          children: [
            Icon(
              icon,
              color: value ? const Color(0xFFFFD54F) : Colors.white38,
              size: 15,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value ? Colors.white : Colors.white60,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _GoldSwitch(value: value),
          ],
        ),
      ),
    );
  }
}

class _GoldSwitch extends StatelessWidget {
  final bool value;
  const _GoldSwitch({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 24,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gold,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: value
                ? const [Color(0xFF69F0AE), Color(0xFF00A844)]
                : const [Color(0xFF12030A), Color(0xFF2A0712)],
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 19,
            height: 19,
            margin: const EdgeInsets.all(1),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment(-0.3, -0.4),
                colors: [
                  Color(0xFFFFFDE7),
                  Color(0xFFFFD54F),
                  Color(0xFFB8860B),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;
  const _SliderRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      child: Row(
        children: [
          Icon(
            icon,
            color: enabled ? const Color(0xFFFFD54F) : Colors.white38,
            size: 15,
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 50,
            child: Text(
              title,
              style: TextStyle(
                color: enabled ? Colors.white : Colors.white60,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 6,
                activeTrackColor: const Color(0xFFFFC107),
                inactiveTrackColor: const Color(0xFF12030A),
                disabledActiveTrackColor: Colors.white24,
                disabledInactiveTrackColor: Colors.black45,
                thumbColor: const Color(0xFFFFE082),
                disabledThumbColor: Colors.white38,
                overlayColor: const Color(0x33FFD54F),
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8,
                  elevation: 3,
                ),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                trackShape: const RoundedRectSliderTrackShape(),
              ),
              child: Slider(
                value: enabled ? value : 0,
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              enabled ? '${(value * 100).round()}%' : 'OFF',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: enabled
                    ? const Color(0xFFFFD54F)
                    : const Color(0xFFFF8A80),
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

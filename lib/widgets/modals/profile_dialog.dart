import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_assets.dart';
import '../../core/audio_manager.dart';
import '../../core/player_wallet.dart';
import '../../core/progression.dart';
import 'base_popup_dialog.dart';
import 'club_dialog.dart';
import 'popup_widgets.dart';

class ProfileDialog extends StatefulWidget {
  const ProfileDialog({super.key});

  static Future<void> show(BuildContext context) {
    return BasePopupDialog.show(
      context: context,
      title: 'VIP PLAYER PROFILE',
      content: const ProfileDialog(),
      width: 530,
      height: 330,
    );
  }

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  static const _avatars = [AppAssets.hostAvatar, AppAssets.iconProfile];

  bool _uidCopied = false;
  bool _statsCopied = false;

  void _flash(void Function(bool) set) {
    set(true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => set(false));
    });
  }

  void _copyUid(PlayerWallet w) {
    Clipboard.setData(ClipboardData(text: w.userId));
    HapticFeedback.lightImpact();
    AudioManager.instance.playSelectClick();
    setState(() => _flash((v) => _uidCopied = v));
  }

  void _copyStats(PlayerWallet w, Progression p) {
    Clipboard.setData(
      ClipboardData(
        text: [
          'Ultra Panda — ${w.playerName} (${w.userId})',
          'Level ${w.level} • VIP ${w.vipLevel} ${w.vipTitle}',
          'Total spins: ${fmt(w.totalSpins)}',
          'Biggest win: ${fmt(w.biggestWin)} coins',
          'Grand jackpots: ${w.jackpotsHit}',
          'Favorite slot: ${w.favoriteSlot}',
          'Cards: ${p.totalCards}/${Progression.piecesPerSet * 3} (Season ${p.season})',
        ].join('\n'),
      ),
    );
    HapticFeedback.mediumImpact();
    AudioManager.instance.playPayoutDing();
    setState(() => _flash((v) => _statsCopied = v));
  }

  Future<void> _editName(PlayerWallet w) async {
    AudioManager.instance.playSelectClick();
    final name = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      // Pinned to the top so it stays visible above the landscape keyboard.
      pageBuilder: (ctx, _, _) => SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Material(
              color: Colors.transparent,
              child: _NameEditor(initialName: w.playerName),
            ),
          ),
        ),
      ),
    );
    if (name != null && name.trim().length >= 2) {
      w.setPlayerName(name);
      AudioManager.instance.playPayoutDing();
    }
  }

  void _nextAvatar(PlayerWallet w) {
    HapticFeedback.lightImpact();
    AudioManager.instance.playSelectClick();
    w.setAvatarIndex(w.avatarIndex + 1);
  }

  @override
  Widget build(BuildContext context) {
    final w = PlayerWallet.instance;
    final p = Progression.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([w, p]),
      builder: (context, _) => Row(
        children: [
          Expanded(flex: 4, child: _identityPanel(w)),
          const SizedBox(width: 10),
          Expanded(flex: 6, child: _statsPanel(w, p)),
        ],
      ),
    );
  }

  Widget _identityPanel(PlayerWallet w) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x9926093F), Color(0x99100420)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x66FFD54F), width: 0.9),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _nextAvatar(w),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFF3B0),
                        Color(0xFFFFD54F),
                        Color(0xFFB8860B),
                        Color(0xFFFFE082),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x88FFD700),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      _avatars[w.avatarIndex],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF8F00),
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                    child: const Icon(
                      Icons.sync_rounded,
                      color: Colors.white,
                      size: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8E24AA), Color(0xFF4A148C)],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD700), width: 0.8),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFFD700),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'VIP ${w.vipLevel} • ${w.vipTitle}',
                    style: const TextStyle(
                      color: Color(0xFFFFE082),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                'LV. ${w.level}',
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                w.isMaxLevel
                    ? 'MAX LEVEL'
                    : '${fmt(w.xp)} / ${fmt(w.xpTarget)} XP',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: w.xpRatio,
              minHeight: 6,
              backgroundColor: Colors.black54,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF00E676)),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            w.nextVipLevelAt == 0
                ? 'MAX VIP RANK REACHED'
                : 'NEXT VIP RANK AT LV. ${w.nextVipLevelAt}',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 6.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: PillButton(
              label: 'CHANGE AVATAR',
              style: PillStyle.gold,
              height: 22,
              onTap: () => _nextAvatar(w),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsPanel(PlayerWallet w, Progression p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(
              child: GestureDetector(
                onTap: () => _editName(w),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        w.playerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFE082),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white12,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Color(0xFFFFD54F),
                        size: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _copyUid(w),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0x80FFD54F),
                    width: 0.7,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _uidCopied ? 'COPIED' : w.userId,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _uidCopied
                          ? Icons.check_circle_rounded
                          : Icons.copy_rounded,
                      color: _uidCopied
                          ? const Color(0xFF00E676)
                          : const Color(0xFFFFD54F),
                      size: 10,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Column(
            children: [
              _statRow(
                _stat(
                  'TOTAL SPINS',
                  fmt(w.totalSpins),
                  Icons.refresh_rounded,
                  const Color(0xFF29B6F6),
                ),
                _stat(
                  'BIGGEST WIN',
                  '${fmt(w.biggestWin)} COINS',
                  Icons.emoji_events_rounded,
                  const Color(0xFFFFD700),
                ),
              ),
              _statRow(
                _stat(
                  'GRAND JACKPOTS',
                  fmt(w.jackpotsHit),
                  Icons.military_tech_rounded,
                  const Color(0xFFFF4081),
                ),
                _stat(
                  'FAVORITE SLOT',
                  w.favoriteSlot,
                  Icons.casino_rounded,
                  const Color(0xFF00E676),
                ),
              ),
              _statRow(
                _stat(
                  'LOGIN STREAK',
                  '${p.loginStreak} DAY${p.loginStreak == 1 ? '' : 'S'}',
                  Icons.local_fire_department_rounded,
                  const Color(0xFFFF9100),
                ),
                _stat(
                  'CARDS • SEASON ${p.season}',
                  '${p.totalCards} / ${Progression.piecesPerSet * 3}',
                  Icons.style_rounded,
                  const Color(0xFFEA80FC),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: PillButton(
                label: 'PANDA VIP CLUB',
                style: PillStyle.gold,
                height: 26,
                fontSize: 9,
                onTap: () {
                  Navigator.of(context).pop();
                  ClubDialog.show(context);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PillButton(
                label: _statsCopied ? 'COPIED TO CLIPBOARD' : 'COPY MY STATS',
                style: PillStyle.green,
                height: 26,
                fontSize: 9,
                onTap: () => _copyStats(w, p),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statRow(Widget a, Widget b) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(children: [a, const SizedBox(width: 6), b]),
      ),
    );
  }

  Widget _stat(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x99200A33), Color(0x99100418)],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 0.7),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 6.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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

class _NameEditor extends StatefulWidget {
  final String initialName;
  const _NameEditor({required this.initialName});

  @override
  State<_NameEditor> createState() => _NameEditorState();
}

class _NameEditorState extends State<_NameEditor> {
  late final TextEditingController controller = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void save() => Navigator.of(context).pop(controller.text);
    return Container(
      width: 520,
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A0A14), Color(0xFF12030A)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.4),
        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 16)],
      ),
      child: Row(
        children: [
          const Text(
            'NAME',
            style: TextStyle(
              color: Color(0xFFFFD54F),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              maxLength: 16,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 _.\-]')),
              ],
              onSubmitted: (_) => save(),
              cursorColor: const Color(0xFFFFD54F),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                hintText: '2–16 letters or numbers',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                filled: true,
                fillColor: Colors.black54,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0x80FFD54F)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFFFD54F),
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 76,
            child: PillButton(
              label: 'CANCEL',
              style: PillStyle.idle,
              height: 36,
              fontSize: 10,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 76,
            child: PillButton(
              label: 'SAVE',
              style: PillStyle.gold,
              height: 36,
              fontSize: 10,
              onTap: save,
            ),
          ),
        ],
      ),
    );
  }
}

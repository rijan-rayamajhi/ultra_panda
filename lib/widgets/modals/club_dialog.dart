import 'package:flutter/material.dart';
import '../../core/app_assets.dart';
import '../../core/progression.dart';
import 'base_popup_dialog.dart';
import 'popup_widgets.dart';

class ClubDialog extends StatelessWidget {
  const ClubDialog({super.key});

  static Future<void> show(BuildContext context) {
    Progression.instance.refresh();
    return BasePopupDialog.show(
      context: context,
      title: 'PANDA VIP CLUB',
      content: const ClubDialog(),
    );
  }

  static const _tierColors = {
    'BRONZE': Color(0xFFFF8A65),
    'SILVER': Color(0xFFCFD8DC),
    'GOLD': Color(0xFFFFD700),
    'DIAMOND': Color(0xFF80DEEA),
  };

  @override
  Widget build(BuildContext context) {
    final p = Progression.instance;
    return AnimatedBuilder(
      animation: p,
      builder: (context, _) {
        final tier = Progression.tierFor(p.clubPoints);
        final board = p.leaderboard;
        return Row(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0x77150A26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0x59FFD54F),
                    width: 0.9,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Image.asset(AppAssets.navClub, width: 40, height: 40),
                        const SizedBox(height: 2),
                        Text(
                          '$tier TIER',
                          style: TextStyle(
                            color: _tierColors[tier],
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          '${fmt(p.clubPoints)} LEAGUE PTS THIS WEEK',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF64FFDA),
                          width: 0.6,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'VAULT: ${fmt(p.vaultRebate)} COINS',
                            style: const TextStyle(
                              color: Color(0xFF64FFDA),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${Progression.vaultRatePercent}% OF EVERY BET IS SAVED FOR YOU',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 6.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: PillButton(
                        label: p.vaultClaimable
                            ? 'CLAIM VAULT REBATE'
                            : 'MIN ${fmt(Progression.vaultMinimum)} TO CLAIM',
                        style: p.vaultClaimable
                            ? PillStyle.gold
                            : PillStyle.idle,
                        height: 26,
                        fontSize: 8.5,
                        onTap: p.vaultClaimable ? p.claimVault : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        const Text('WEEKLY LEAGUE', style: popupLabelStyle),
                        const Spacer(),
                        Text(
                          'ENDS IN ${formatDuration(p.timeUntilWeeklyReset)}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Expanded(
                    child: ListView.separated(
                      itemCount: board.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, i) => _row(board[i], i),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 3, left: 4),
                    child: Text(
                      '1 PT PER 1,000 COINS BET  •  PRIZES ARRIVE IN YOUR INBOX ON MONDAY',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 6.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _row(LeaderRow r, int i) {
    const medal = [Color(0xFFFFD700), Color(0xFFCFD8DC), Color(0xFFFF8A65)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: r.isYou ? const Color(0x44FFD700) : const Color(0x55110620),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: r.isYou ? const Color(0xFFFFD700) : Colors.white10,
          width: r.isYou ? 1.0 : 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: i < 3 ? medal[i] : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${i + 1}',
              style: TextStyle(
                color: i < 3 ? Colors.black : Colors.white60,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              r.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: r.isYou ? const Color(0xFFFFE082) : Colors.white,
                fontSize: 9,
                fontWeight: r.isYou ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${fmt(r.points)} PTS',
            style: const TextStyle(
              color: Color(0xFF80DEEA),
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 52,
            child: Text(
              '+${Progression.weeklyPrizes[i].shortLabel}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

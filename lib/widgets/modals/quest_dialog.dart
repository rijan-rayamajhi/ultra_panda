import 'package:flutter/material.dart';
import '../../core/app_assets.dart';
import '../../core/progression.dart';
import 'base_popup_dialog.dart';
import 'popup_widgets.dart';

class QuestDialog extends StatelessWidget {
  const QuestDialog({super.key});

  static Future<void> show(BuildContext context) {
    Progression.instance.refresh();
    return BasePopupDialog.show(
      context: context,
      title: 'DAILY MISSIONS',
      content: const QuestDialog(),
    );
  }

  String _progressLabel(int v, int target) =>
      target >= 10000 ? '${compact(v)}/${compact(target)}' : '$v/$target';

  @override
  Widget build(BuildContext context) {
    final p = Progression.instance;
    return AnimatedBuilder(
      animation: p,
      builder: (context, _) {
        final quests = p.todaysQuests;
        return Column(
          children: [
            // Daily chest
            Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0x99170828),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x66FFD54F), width: 0.8),
              ),
              child: Row(
                children: [
                  const Text('DAILY CHEST', style: popupLabelStyle),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: p.chestPoints / Progression.chestTarget,
                        minHeight: 10,
                        backgroundColor: Colors.black54,
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF00E676),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 108,
                    child: PillButton(
                      label: p.chestClaimed
                          ? 'OPENED'
                          : p.chestReady
                          ? 'OPEN ${Progression.chestReward.shortLabel}'
                          : '${p.chestPoints}/${Progression.chestTarget} PTS',
                      style: p.chestClaimed
                          ? PillStyle.done
                          : p.chestReady
                          ? PillStyle.green
                          : PillStyle.idle,
                      height: 20,
                      onTap: p.chestReady ? p.claimChest : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: ListView.separated(
                itemCount: quests.length,
                separatorBuilder: (_, _) => const SizedBox(height: 5),
                itemBuilder: (context, i) {
                  final q = quests[i];
                  final progress = p.questProgress(q);
                  final ready = p.questReady(q);
                  final claimed = p.questClaimed(q);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x66110620),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ready && !claimed
                            ? const Color(0xFFFFD700)
                            : Colors.white10,
                        width: ready && !claimed ? 1.0 : 0.6,
                      ),
                    ),
                    child: Row(
                      children: [
                        Image.asset(AppAssets.navQuest, width: 26, height: 26),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      q.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${q.reward.label}  •  +${Progression.chestPointsPerQuest} PTS',
                                    style: const TextStyle(
                                      color: Color(0xFFFFD54F),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress / q.target,
                                  minHeight: 6,
                                  backgroundColor: Colors.black54,
                                  valueColor: AlwaysStoppedAnimation(
                                    ready
                                        ? const Color(0xFFFFD700)
                                        : const Color(0xFF29B6F6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 62,
                          child: PillButton(
                            label: claimed
                                ? 'DONE'
                                : ready
                                ? 'CLAIM'
                                : _progressLabel(progress, q.target),
                            style: claimed
                                ? PillStyle.done
                                : ready
                                ? PillStyle.green
                                : PillStyle.idle,
                            onTap: ready && !claimed
                                ? () => p.claimQuest(q)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Text(
              'NEW MISSIONS IN ${formatDuration(p.timeUntilDailyReset)}',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 7.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        );
      },
    );
  }
}

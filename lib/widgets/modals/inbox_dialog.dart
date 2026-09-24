import 'package:flutter/material.dart';
import '../../core/app_assets.dart';
import '../../core/progression.dart';
import 'base_popup_dialog.dart';
import 'popup_widgets.dart';

class InboxDialog extends StatelessWidget {
  const InboxDialog({super.key});

  static Future<void> show(BuildContext context) {
    Progression.instance.refresh();
    return BasePopupDialog.show(
      context: context,
      title: 'PANDA INBOX',
      content: const InboxDialog(),
    );
  }

  static String _ago(int ms) {
    final d = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(ms),
    );
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final p = Progression.instance;
    return AnimatedBuilder(
      animation: p,
      builder: (context, _) {
        final messages = p.inbox;
        return Column(
          children: [
            PopupHeaderBar(
              left: Text(
                p.inboxUnclaimed > 0
                    ? '${p.inboxUnclaimed} GIFT${p.inboxUnclaimed == 1 ? '' : 'S'} WAITING'
                    : 'ALL GIFTS COLLECTED',
                style: popupLabelStyle,
              ),
              right: PillButton(
                label: 'COLLECT ALL',
                style: p.inboxUnclaimed > 0 ? PillStyle.green : PillStyle.done,
                height: 20,
                onTap: p.inboxUnclaimed > 0 ? p.claimAllMessages : null,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No messages yet.\nCome back tomorrow for your daily bonus!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: messages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 5),
                      itemBuilder: (context, i) {
                        final m = messages[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x66130623),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: m.claimed
                                  ? Colors.white10
                                  : const Color(0x66FFD54F),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Opacity(
                                opacity: m.claimed ? 0.4 : 1,
                                child: Image.asset(
                                  AppAssets.iconGift,
                                  width: 28,
                                  height: 28,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            m.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _ago(m.createdAt),
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 7.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      m.body,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 7.5,
                                      ),
                                    ),
                                    Text(
                                      m.reward.label,
                                      style: const TextStyle(
                                        color: Color(0xFFFFD54F),
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 62,
                                child: PillButton(
                                  label: m.claimed ? 'CLAIMED' : 'CLAIM',
                                  style: m.claimed
                                      ? PillStyle.done
                                      : PillStyle.gold,
                                  onTap: m.claimed
                                      ? null
                                      : () => p.claimMessage(m.id),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

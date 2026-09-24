import 'package:flutter/material.dart';
import '../../core/progression.dart';
import 'base_popup_dialog.dart';
import 'popup_widgets.dart';

class CardsDialog extends StatelessWidget {
  const CardsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return BasePopupDialog.show(
      context: context,
      title: 'CARD ALBUMS',
      content: const CardsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Progression.instance;
    return AnimatedBuilder(
      animation: p,
      builder: (context, _) {
        const total = Progression.piecesPerSet * 3;
        return Column(
          children: [
            PopupHeaderBar(
              left: Text(
                'SEASON ${p.season}  •  ${p.totalCards}/$total CARDS  •  CARDS DROP FROM ANY SPIN',
                style: popupLabelStyle,
              ),
              right: p.seasonComplete
                  ? PillButton(
                      label: 'START SEASON ${p.season + 1}',
                      style: PillStyle.green,
                      height: 20,
                      onTap: p.startNewSeason,
                    )
                  : Text(
                      'SEASON BONUS: ${Progression.seasonBonus.shortLabel}',
                      style: const TextStyle(
                        color: Color(0xFF64FFDA),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Row(
                children: [
                  for (var a = 0; a < Progression.albums.length; a++)
                    Expanded(child: _album(p, a)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _album(Progression p, int a) {
    final set = Progression.albums[a];
    final complete = p.albumComplete(a);
    final claimed = p.albumClaimed(a);
    return Container(
      margin: EdgeInsets.only(left: a == 0 ? 0 : 4, right: a == 2 ? 0 : 4),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0x660D031A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: complete ? const Color(0xFFFFD700) : const Color(0x4DFFD54F),
          width: complete ? 1.4 : 0.8,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SlicedImageGrid(
                image: set.image,
                owned: (i) => p.cardOwned(a, i),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            set.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '${p.albumCount(a)} / ${Progression.piecesPerSet} CARDS',
            style: const TextStyle(
              color: Color(0xFFFFD54F),
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            width: double.infinity,
            child: PillButton(
              label: claimed
                  ? 'CLAIMED'
                  : complete
                  ? 'CLAIM ${set.reward.shortLabel}'
                  : 'REWARD ${set.reward.shortLabel}',
              style: claimed
                  ? PillStyle.done
                  : complete
                  ? PillStyle.green
                  : PillStyle.idle,
              height: 20,
              onTap: complete && !claimed ? () => p.claimAlbum(a) : null,
            ),
          ),
        ],
      ),
    );
  }
}

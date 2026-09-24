import 'package:flutter/material.dart';
import '../../core/progression.dart';
import 'base_popup_dialog.dart';
import 'popup_widgets.dart';

class PuzzleDialog extends StatelessWidget {
  const PuzzleDialog({super.key});

  static Future<void> show(BuildContext context) {
    return BasePopupDialog.show(
      context: context,
      title: 'PANDA JIGSAW PUZZLE',
      content: const PuzzleDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Progression.instance;
    return AnimatedBuilder(
      animation: p,
      builder: (context, _) {
        return Column(
          children: [
            PopupHeaderBar(
              left: Text(
                'ROUND ${p.puzzleRound}  •  PIECES DROP FROM ANY SPIN  •  FINISH ALL 3 FOR THE GRAND PRIZE',
                style: popupLabelStyle,
              ),
              right: PillButton(
                label: p.puzzleGrandReady
                    ? 'CLAIM GRAND ${Progression.puzzleGrandPrize.shortLabel}'
                    : 'GRAND ${Progression.puzzleGrandPrize.shortLabel}',
                style: p.puzzleGrandReady ? PillStyle.green : PillStyle.idle,
                height: 20,
                onTap: p.puzzleGrandReady ? p.claimPuzzleGrand : null,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Row(
                children: [
                  for (var i = 0; i < Progression.puzzles.length; i++)
                    Expanded(child: _puzzle(p, i)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _puzzle(Progression p, int i) {
    final set = Progression.puzzles[i];
    final complete = p.puzzleComplete(i);
    final claimed = p.puzzleClaimed(i);
    return Container(
      margin: EdgeInsets.only(left: i == 0 ? 0 : 4, right: i == 2 ? 0 : 4),
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
                owned: (k) => p.pieceOwned(i, k),
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
            'PIECES ${p.puzzleCount(i)} / ${Progression.piecesPerSet}',
            style: const TextStyle(
              color: Color(0xFF64FFDA),
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
              onTap: complete && !claimed ? () => p.claimPuzzle(i) : null,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_assets.dart';
import '../core/audio_manager.dart';
import '../core/progression.dart';
import '../models/game_card_model.dart';
import '../widgets/play_for_real_button.dart';
import '../widgets/top_hud_bar.dart';
import '../widgets/bottom_dock_bar.dart';
import '../widgets/game_card_widget.dart';
import '../widgets/modals/wheel_dialog.dart';
import '../widgets/modals/cards_dialog.dart';
import '../widgets/modals/club_dialog.dart';
import '../widgets/modals/inbox_dialog.dart';
import '../widgets/modals/puzzle_dialog.dart';
import '../widgets/modals/quest_dialog.dart';
import '../widgets/modals/settings_dialog.dart';
import '../widgets/modals/profile_dialog.dart';
import '../widgets/modals/piggy_bank_dialog.dart';
import 'dragon_gold_screen.dart';
import 'classic777_screen.dart';
import 'fruit_fortune_screen.dart';
import 'triple_diamond_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  int _selectedNavIndex = -1;

  List<NavItemModel> get _navItems {
    final p = Progression.instance;
    return [
      NavItemModel(
        iconPath: AppAssets.navCards,
        label: 'CARDS',
        badge: p.cardsBadge,
      ),
      NavItemModel(
        iconPath: AppAssets.navClub,
        label: 'CLUB',
        badge: p.clubBadge,
      ),
      NavItemModel(
        iconPath: AppAssets.navInbox,
        label: 'INBOX',
        badge: p.inboxBadge,
      ),
      NavItemModel(
        iconPath: AppAssets.navPuzzle,
        label: 'PUZZLE',
        badge: p.puzzleBadge,
      ),
      NavItemModel(
        iconPath: AppAssets.navQuest,
        label: 'QUEST',
        badge: p.questBadge,
      ),
      NavItemModel(
        iconPath: AppAssets.navWheel,
        label: 'WHEEL',
        badge: p.wheelBadge,
      ),
    ];
  }

  final List<GameCardModel> _gameCards = const [
    GameCardModel(
      title: 'Dragon Gold',
      imagePath: AppAssets.cardDragonGold,
      tag: 'HOT',
      tagColor: Color(0xFFFF3D00),
    ),
    GameCardModel(
      title: 'Classic 777',
      imagePath: AppAssets.cardSlot777,
      tag: 'POPULAR',
      tagColor: Color(0xFFFF9100),
      aspectRatio: 1066 / 1408,
    ),
    GameCardModel(
      title: 'Fruit Fortune',
      imagePath: AppAssets.cardFruitFortune,
      tag: 'NEW',
      tagColor: Color(0xFF00E676),
      aspectRatio: 1091 / 1442,
    ),
    GameCardModel(
      title: 'Triple Diamond',
      imagePath: AppAssets.cardTripleDiamond,
      tag: 'MEGA',
      tagColor: Color(0xFFE040FB),
      aspectRatio: 1091 / 1442,
    ),
  ];

  @override
  void initState() {
    super.initState();
    AudioManager.instance.playLobbyMusic();
  }

  Future<void> _handleNavigation(int index) async {
    AudioManager.instance.playSelectClick();
    setState(() => _selectedNavIndex = index);

    await switch (index) {
      0 => CardsDialog.show(context),
      1 => ClubDialog.show(context),
      2 => InboxDialog.show(context),
      3 => PuzzleDialog.show(context),
      4 => QuestDialog.show(context),
      _ => WheelDialog.show(context),
    };
    if (mounted) setState(() => _selectedNavIndex = -1);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Artwork
          Image.asset(
            AppAssets.bgLobby,
            fit: BoxFit.cover,
            width: screenSize.width,
            height: screenSize.height,
          ),

          // 2. Subtle Lighting Scrims
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 85,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. Center Game Cards
          Positioned(
            top: 50,
            bottom: 84, // Clear gap above bottom dock
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              bottom: false,
              child: Builder(
                builder: (context) {
                  const hPad = 20.0, gap = 14.0;
                  final size = MediaQuery.of(context).size;
                  // Cap card height so all cards fit the width uncropped,
                  // with tops/bottoms aligned across differing art ratios.
                  final sumAspect = _gameCards.fold<double>(
                    0,
                    (s, g) => s + g.aspectRatio,
                  );
                  final availW =
                      size.width - hPad * 2 - gap * (_gameCards.length - 1);
                  final availH = size.height - 50 - 84;
                  final cardH = math.min(availW / sumAspect, availH);
                  return Center(
                    child: SizedBox(
                      height: cardH,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: hPad),
                        itemCount: _gameCards.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: gap),
                        itemBuilder: (context, index) {
                          final game = _gameCards[index];
                          return GameCardWidget(
                            game: game,
                            // Stagger the glints so cards shine in turn.
                            shinePhase: 1 - index / _gameCards.length,
                            onTap: () async {
                              AudioManager.instance.playSelectClick();
                              await PlayForReal.maybeShowDailyPrompt(context);
                              if (!context.mounted) return;
                              final Widget screen = switch (game.title) {
                                'Dragon Gold' => const DragonGoldScreen(),
                                'Classic 777' => const Classic777Screen(),
                                'Fruit Fortune' => const FruitFortuneScreen(),
                                _ => const TripleDiamondScreen(),
                              };
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => screen),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 4. Top HUD Bar
          TopHudBar(
            onGetMoreTap: () => WheelDialog.show(context),
            onProfileTap: () {
              AudioManager.instance.playSelectClick();
              ProfileDialog.show(context);
            },
            onPiggyTap: () {
              AudioManager.instance.playSelectClick();
              PiggyBankDialog.show(context);
            },
            onSettingsTap: () {
              AudioManager.instance.playSelectClick();
              SettingsDialog.show(context);
            },
          ),

          // 5. Play-for-real opt-in link (not tied to game outcomes).
          // Bottom aligned with the dock so both read as one bottom row.
          const Positioned(
            bottom: 7,
            right: 18,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 58,
                child: Center(child: PlayForRealButton()),
              ),
            ),
          ),

          // 6. Bottom Navigation Dock
          AnimatedBuilder(
            animation: Progression.instance,
            builder: (context, _) => BottomDockBar(
              items: _navItems,
              selectedIndex: _selectedNavIndex,
              onItemSelected: _handleNavigation,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_assets.dart';
import 'player_wallet.dart';

/// Root messenger so progression events (card drops etc.) can toast on any screen.
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

class Reward {
  final int coins;
  final int gems;
  const Reward({this.coins = 0, this.gems = 0});

  String get label {
    final parts = <String>[
      if (coins > 0) '${fmt(coins)} COINS',
      if (gems > 0) '$gems GEMS',
    ];
    return parts.join(' + ');
  }

  String get shortLabel {
    final parts = <String>[
      if (coins > 0) compact(coins),
      if (gems > 0) '${gems}G',
    ];
    return parts.join(' + ');
  }
}

String fmt(int n) => n.toString().replaceAllMapped(
  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
  (m) => '${m[1]},',
);

String compact(int n) {
  if (n >= 1000000) {
    final v = n / 1000000;
    return '${v == v.roundToDouble() ? v.toInt() : v.toStringAsFixed(1)}M';
  }
  if (n >= 1000) return '${n ~/ 1000}K';
  return '$n';
}

class Quest {
  final String id;
  final String title;
  final int target;
  final Reward reward;
  final int Function(Progression p) progressOf;
  const Quest(this.id, this.title, this.target, this.reward, this.progressOf);
}

class InboxMessage {
  final int id;
  final String title;
  final String body;
  final int coins;
  final int gems;
  final int createdAt;
  bool claimed;

  InboxMessage({
    required this.id,
    required this.title,
    required this.body,
    this.coins = 0,
    this.gems = 0,
    required this.createdAt,
    this.claimed = false,
  });

  Reward get reward => Reward(coins: coins, gems: gems);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'coins': coins,
    'gems': gems,
    'createdAt': createdAt,
    'claimed': claimed,
  };

  factory InboxMessage.fromJson(Map<String, dynamic> j) => InboxMessage(
    id: j['id'] as int,
    title: j['title'] as String,
    body: j['body'] as String,
    coins: j['coins'] as int,
    gems: j['gems'] as int,
    createdAt: j['createdAt'] as int,
    claimed: j['claimed'] as bool,
  );
}

class CollectionSet {
  final String name;
  final String image;
  final Reward reward;
  const CollectionSet(this.name, this.image, this.reward);
}

class LeaderRow {
  final String name;
  final int points;
  final bool isYou;
  const LeaderRow(this.name, this.points, this.isYou);
}

/// Offline meta-progression: daily quests, card albums, puzzles, club league,
/// inbox and the daily wheel. Everything is fed by real spins and persisted.
class Progression extends ChangeNotifier {
  Progression._();
  static final Progression instance = Progression._();

  static const _prefsKey = 'progression_v1';
  static const piecesPerSet = 9;
  static const cardDuplicateCoins = 25000;
  static const pieceDuplicateCoins = 20000;
  static const chestTarget = 100;
  static const chestPointsPerQuest = 35;
  static const chestReward = Reward(coins: 1000000, gems: 25);
  static const wheelSpinGemCost = 30;
  static const vaultRatePercent = 2;
  static const vaultMinimum = 1000;
  static const seasonBonus = Reward(coins: 25000000, gems: 200);
  static const puzzleGrandPrize = Reward(coins: 50000000, gems: 100);
  static const games = [
    'Dragon Gold',
    'Classic 777',
    'Fruit Fortune',
    'Triple Diamond',
  ];

  static const albums = [
    CollectionSet(
      'DRAGON DYNASTY',
      AppAssets.cardDragonGold,
      Reward(coins: 5000000, gems: 30),
    ),
    CollectionSet(
      'FORTUNE PANDA',
      AppAssets.cardFruitFortune,
      Reward(coins: 7500000, gems: 40),
    ),
    CollectionSet(
      'DIAMOND HEIST',
      AppAssets.cardTripleDiamond,
      Reward(coins: 10000000, gems: 50),
    ),
  ];

  static const puzzles = [
    CollectionSet('ROYAL PANDA', AppAssets.puzzle01, Reward(coins: 3000000)),
    CollectionSet('DRAGON SHINE', AppAssets.puzzle02, Reward(coins: 3000000)),
    CollectionSet('FRUIT PARADISE', AppAssets.puzzle03, Reward(coins: 3000000)),
  ];

  static const _rivalNames = [
    'JadeTiger',
    'LuckyLotus',
    'GoldenKoi',
    'RedLantern',
  ];
  static const _rivalBase = [6000, 3500, 1800, 700];
  static const weeklyPrizes = [
    Reward(coins: 10000000, gems: 100),
    Reward(coins: 5000000, gems: 50),
    Reward(coins: 2500000, gems: 25),
    Reward(coins: 1000000),
    Reward(coins: 500000),
  ];

  final math.Random _rng = math.Random();
  SharedPreferences? _prefs;

  // Daily
  String _day = '';
  int _daySpins = 0;
  int _dayWin = 0;
  int _dayBet = 0;
  int _dayBonuses = 0;
  Map<String, int> _dayGameSpins = {};
  Set<String> _questsClaimed = {};
  bool _chestClaimed = false;
  bool _wheelFreeUsed = false;
  int _loginStreak = 0;

  // Weekly club league
  String _week = '';
  int _weekPoints = 0;
  int _vaultAccum = 0;

  // Collections (bitmask of owned pieces per set)
  List<int> _cardMasks = [0, 0, 0];
  int _albumsClaimed = 0;
  int _season = 1;
  List<int> _puzzleMasks = [0, 0, 0];
  int _puzzlesClaimed = 0;
  int _puzzleRound = 1;

  // Inbox
  List<InboxMessage> _inbox = [];
  bool _welcomeSent = false;
  int _nextMsgId = 1;

  // ---------------------------------------------------------------- persistence

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        _fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Corrupt save: keep defaults rather than crash on boot.
      }
    }
    _rollover();
    _save();
    notifyListeners();
  }

  void _fromJson(Map<String, dynamic> j) {
    _day = j['day'] as String? ?? '';
    _daySpins = j['daySpins'] as int? ?? 0;
    _dayWin = j['dayWin'] as int? ?? 0;
    _dayBet = j['dayBet'] as int? ?? 0;
    _dayBonuses = j['dayBonuses'] as int? ?? 0;
    _dayGameSpins = Map<String, int>.from(j['dayGameSpins'] as Map? ?? {});
    _questsClaimed = Set<String>.from(j['questsClaimed'] as List? ?? []);
    _chestClaimed = j['chestClaimed'] as bool? ?? false;
    _wheelFreeUsed = j['wheelFreeUsed'] as bool? ?? false;
    _loginStreak = j['loginStreak'] as int? ?? 0;
    _week = j['week'] as String? ?? '';
    _weekPoints = j['weekPoints'] as int? ?? 0;
    _vaultAccum = j['vaultAccum'] as int? ?? 0;
    _cardMasks = List<int>.from(j['cardMasks'] as List? ?? [0, 0, 0]);
    _albumsClaimed = j['albumsClaimed'] as int? ?? 0;
    _season = j['season'] as int? ?? 1;
    _puzzleMasks = List<int>.from(j['puzzleMasks'] as List? ?? [0, 0, 0]);
    _puzzlesClaimed = j['puzzlesClaimed'] as int? ?? 0;
    _puzzleRound = j['puzzleRound'] as int? ?? 1;
    _inbox = (j['inbox'] as List? ?? [])
        .map((e) => InboxMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    _welcomeSent = j['welcomeSent'] as bool? ?? false;
    _nextMsgId = j['nextMsgId'] as int? ?? 1;
  }

  void _save() {
    _prefs?.setString(
      _prefsKey,
      jsonEncode({
        'day': _day,
        'daySpins': _daySpins,
        'dayWin': _dayWin,
        'dayBet': _dayBet,
        'dayBonuses': _dayBonuses,
        'dayGameSpins': _dayGameSpins,
        'questsClaimed': _questsClaimed.toList(),
        'chestClaimed': _chestClaimed,
        'wheelFreeUsed': _wheelFreeUsed,
        'loginStreak': _loginStreak,
        'week': _week,
        'weekPoints': _weekPoints,
        'vaultAccum': _vaultAccum,
        'cardMasks': _cardMasks,
        'albumsClaimed': _albumsClaimed,
        'season': _season,
        'puzzleMasks': _puzzleMasks,
        'puzzlesClaimed': _puzzlesClaimed,
        'puzzleRound': _puzzleRound,
        'inbox': _inbox.map((m) => m.toJson()).toList(),
        'welcomeSent': _welcomeSent,
        'nextMsgId': _nextMsgId,
      }),
    );
  }

  void _commit() {
    _save();
    notifyListeners();
  }

  // ------------------------------------------------------------- day / week

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _weekKey(DateTime d) => _dayKey(
    DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1)),
  );

  /// Call when a feature screen opens so a new day/week is picked up mid-session.
  void refresh() {
    if (_rollover()) _commit();
  }

  /// Returns true when anything changed. Only moves forward in time, so
  /// winding the device clock back can't re-arm dailies.
  bool _rollover() {
    final now = DateTime.now();
    var changed = false;

    if (!_welcomeSent) {
      _welcomeSent = true;
      _addMessage(
        'WELCOME TO ULTRA PANDA',
        'A starter gift to begin your fortune. Good luck!',
        const Reward(coins: 2000000, gems: 50),
      );
      changed = true;
    }

    final today = _dayKey(now);
    if (today.compareTo(_day) > 0) {
      final yesterday = _dayKey(now.subtract(const Duration(days: 1)));
      _loginStreak = _day == yesterday ? _loginStreak + 1 : 1;
      _day = today;
      _daySpins = 0;
      _dayWin = 0;
      _dayBet = 0;
      _dayBonuses = 0;
      _dayGameSpins = {};
      _questsClaimed = {};
      _chestClaimed = false;
      _wheelFreeUsed = false;

      final streakDay = math.min(_loginStreak, 7);
      final base = 250000 + PlayerWallet.instance.level * 10000;
      final coins = (base * (1 + (streakDay - 1) * 0.15)).round();
      _addMessage(
        'DAILY LOGIN BONUS',
        _loginStreak > 1
            ? 'Day $_loginStreak login streak! Keep it going for bigger bonuses.'
            : 'Your daily bonus is here. Log in tomorrow to start a streak!',
        Reward(coins: coins, gems: streakDay >= 7 ? 20 : 5),
      );
      changed = true;
    }

    final week = _weekKey(now);
    if (week.compareTo(_week) > 0) {
      if (_week.isNotEmpty && _weekPoints > 0) {
        final rank = _rankFor(_weekPoints, _week, 1.0);
        final prize = weeklyPrizes[rank - 1];
        _addMessage(
          'WEEKLY LEAGUE RESULT',
          'You finished #$rank with ${fmt(_weekPoints)} points. Here is your prize!',
          prize,
        );
      }
      _week = week;
      _weekPoints = 0;
      changed = true;
    }

    final cutoff = now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    final before = _inbox.length;
    _inbox.removeWhere((m) => m.claimed && m.createdAt < cutoff);
    if (_inbox.length > 30) _inbox = _inbox.sublist(0, 30);
    if (_inbox.length != before) changed = true;

    return changed;
  }

  void _addMessage(String title, String body, Reward reward) {
    _inbox.insert(
      0,
      InboxMessage(
        id: _nextMsgId++,
        title: title,
        body: body,
        coins: reward.coins,
        gems: reward.gems,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Duration get timeUntilDailyReset {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1).difference(now);
  }

  Duration get timeUntilWeeklyReset {
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day + 7).difference(now);
  }

  // ---------------------------------------------------------------- game hooks

  void onSpin({required int bet, required int win, required String game}) {
    _rollover();
    _daySpins++;
    _dayWin += win;
    _dayBet += bet;
    _dayGameSpins[game] = (_dayGameSpins[game] ?? 0) + 1;
    if (bet > 0) {
      _weekPoints += math.max(1, bet ~/ 1000);
      _vaultAccum += bet;
    }
    if (_rng.nextInt(10) == 0) _dropCard();
    if (_rng.nextInt(12) == 0) _dropPiece();
    _commit();
  }

  void onBonusTriggered() {
    _rollover();
    _dayBonuses++;
    _commit();
  }

  /// Bonus-round payouts that don't go through a spin's win amount.
  void onBonusWin(int amount) {
    if (amount <= 0) return;
    _dayWin += amount;
    _commit();
  }

  // ---------------------------------------------------------------- credit

  void _credit(Reward r) {
    PlayerWallet.instance.addCoins(r.coins);
    PlayerWallet.instance.addGems(r.gems);
  }

  void _toast(String msg) {
    rootMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFFFE082),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          width: 380,
          duration: const Duration(milliseconds: 1800),
          backgroundColor: const Color(0xF21A0510),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFFFD54F)),
          ),
        ),
      );
  }

  // ---------------------------------------------------------------- cards

  int get season => _season;
  bool cardOwned(int album, int i) => _cardMasks[album] & (1 << i) != 0;
  int albumCount(int album) => _bitCount(_cardMasks[album]);
  bool albumComplete(int album) => albumCount(album) == piecesPerSet;
  bool albumClaimed(int album) => _albumsClaimed & (1 << album) != 0;
  int get totalCards => [0, 1, 2].fold(0, (s, a) => s + albumCount(a));
  bool get seasonComplete => _albumsClaimed == 0x7;

  void _dropCard() {
    final pick = _pickPiece(_cardMasks);
    final album = pick ~/ piecesPerSet, i = pick % piecesPerSet;
    final name = albums[album].name;
    if (cardOwned(album, i)) {
      _credit(const Reward(coins: cardDuplicateCoins));
      _toast('Duplicate $name card  •  +${fmt(cardDuplicateCoins)} coins');
    } else {
      _cardMasks[album] |= 1 << i;
      _toast(
        albumComplete(album)
            ? '$name album complete! Claim it in CARDS'
            : 'New card!  $name  ${albumCount(album)}/$piecesPerSet',
      );
    }
  }

  bool claimAlbum(int album) {
    if (!albumComplete(album) || albumClaimed(album)) return false;
    _albumsClaimed |= 1 << album;
    _credit(albums[album].reward);
    if (seasonComplete) {
      _credit(seasonBonus);
      _toast('Season $_season complete!  +${seasonBonus.label}');
    }
    _commit();
    return true;
  }

  void startNewSeason() {
    if (!seasonComplete) return;
    _season++;
    _cardMasks = [0, 0, 0];
    _albumsClaimed = 0;
    _commit();
  }

  // ---------------------------------------------------------------- puzzles

  int get puzzleRound => _puzzleRound;
  bool pieceOwned(int p, int i) => _puzzleMasks[p] & (1 << i) != 0;
  int puzzleCount(int p) => _bitCount(_puzzleMasks[p]);
  bool puzzleComplete(int p) => puzzleCount(p) == piecesPerSet;
  bool puzzleClaimed(int p) => _puzzlesClaimed & (1 << p) != 0;
  bool get puzzleGrandReady => _puzzlesClaimed == 0x7;

  void _dropPiece() {
    final pick = _pickPiece(_puzzleMasks);
    final p = pick ~/ piecesPerSet, i = pick % piecesPerSet;
    final name = puzzles[p].name;
    if (pieceOwned(p, i)) {
      _credit(const Reward(coins: pieceDuplicateCoins));
      _toast('Duplicate puzzle piece  •  +${fmt(pieceDuplicateCoins)} coins');
    } else {
      _puzzleMasks[p] |= 1 << i;
      _toast(
        puzzleComplete(p)
            ? '$name puzzle complete! Claim it in PUZZLE'
            : 'Puzzle piece!  $name  ${puzzleCount(p)}/$piecesPerSet',
      );
    }
  }

  bool claimPuzzle(int p) {
    if (!puzzleComplete(p) || puzzleClaimed(p)) return false;
    _puzzlesClaimed |= 1 << p;
    _credit(puzzles[p].reward);
    _commit();
    return true;
  }

  /// Grand prize for finishing all three; starts a fresh round of puzzles.
  bool claimPuzzleGrand() {
    if (!puzzleGrandReady) return false;
    _credit(puzzleGrandPrize);
    _puzzleRound++;
    _puzzleMasks = [0, 0, 0];
    _puzzlesClaimed = 0;
    _commit();
    return true;
  }

  /// Biased toward missing pieces so collections finish in a sane number of spins.
  int _pickPiece(List<int> masks) {
    final missing = <int>[
      for (var s = 0; s < masks.length; s++)
        for (var i = 0; i < piecesPerSet; i++)
          if (masks[s] & (1 << i) == 0) s * piecesPerSet + i,
    ];
    if (missing.isNotEmpty && _rng.nextDouble() < 0.7) {
      return missing[_rng.nextInt(missing.length)];
    }
    return _rng.nextInt(masks.length * piecesPerSet);
  }

  static int _bitCount(int v) {
    var c = 0;
    while (v != 0) {
      c += v & 1;
      v >>= 1;
    }
    return c;
  }

  // ---------------------------------------------------------------- quests

  List<Quest> get todaysQuests {
    final seed = _day.codeUnits.fold<int>(
      7,
      (h, c) => (h * 31 + c) & 0x7fffffff,
    );
    final r = math.Random(seed);
    final game = games[seed % games.length];
    final pool = [
      Quest(
        'spin_game',
        'SPIN 20 TIMES IN ${game.toUpperCase()}',
        20,
        const Reward(coins: 400000),
        (p) => p._dayGameSpins[game] ?? 0,
      ),
      Quest(
        'win_total',
        'WIN 1,000,000 COINS IN TOTAL',
        1000000,
        const Reward(gems: 15),
        (p) => p._dayWin,
      ),
      Quest(
        'bonus',
        'TRIGGER ANY BONUS GAME',
        1,
        const Reward(coins: 750000),
        (p) => p._dayBonuses,
      ),
      Quest(
        'bet_total',
        'BET 2,500,000 COINS IN TOTAL',
        2500000,
        const Reward(coins: 500000),
        (p) => p._dayBet,
      ),
    ]..shuffle(r);
    return [
      Quest(
        'spin_any',
        'SPIN 40 TIMES IN ANY SLOT',
        40,
        const Reward(coins: 300000),
        (p) => p._daySpins,
      ),
      pool[0],
      pool[1],
    ];
  }

  int questProgress(Quest q) => q.progressOf(this).clamp(0, q.target);
  bool questReady(Quest q) => questProgress(q) >= q.target;
  bool questClaimed(Quest q) => _questsClaimed.contains(q.id);

  bool claimQuest(Quest q) {
    if (!questReady(q) || questClaimed(q)) return false;
    _questsClaimed.add(q.id);
    _credit(q.reward);
    _commit();
    return true;
  }

  int get chestPoints =>
      math.min(_questsClaimed.length * chestPointsPerQuest, chestTarget);
  bool get chestReady => chestPoints >= chestTarget && !_chestClaimed;
  bool get chestClaimed => _chestClaimed;

  bool claimChest() {
    if (!chestReady) return false;
    _chestClaimed = true;
    _credit(chestReward);
    _commit();
    return true;
  }

  // ---------------------------------------------------------------- inbox

  List<InboxMessage> get inbox => List.unmodifiable(_inbox);
  int get inboxUnclaimed => _inbox.where((m) => !m.claimed).length;

  bool claimMessage(int id) {
    final m = _inbox.where((m) => m.id == id && !m.claimed).firstOrNull;
    if (m == null) return false;
    m.claimed = true;
    _credit(m.reward);
    _commit();
    return true;
  }

  Reward claimAllMessages() {
    var coins = 0, gems = 0;
    for (final m in _inbox.where((m) => !m.claimed)) {
      m.claimed = true;
      coins += m.coins;
      gems += m.gems;
    }
    final total = Reward(coins: coins, gems: gems);
    _credit(total);
    _commit();
    return total;
  }

  // ---------------------------------------------------------------- wheel

  bool get wheelFreeAvailable => !_wheelFreeUsed;
  int get loginStreak => _loginStreak;

  /// Pays for a spin (free daily, else gems). False if the player can't afford it.
  bool payForWheelSpin() {
    _rollover();
    if (!_wheelFreeUsed) {
      _wheelFreeUsed = true;
    } else if (!PlayerWallet.instance.deductGems(wheelSpinGemCost)) {
      return false;
    }
    _commit();
    return true;
  }

  void creditWheelPrize(Reward r) => _credit(r);

  // ---------------------------------------------------------------- club

  int get clubPoints => _weekPoints;
  int get vaultRebate => _vaultAccum * vaultRatePercent ~/ 100;
  bool get vaultClaimable => vaultRebate >= vaultMinimum;

  int claimVault() {
    if (!vaultClaimable) return 0;
    final amount = vaultRebate;
    _vaultAccum = 0;
    _credit(Reward(coins: amount));
    _commit();
    return amount;
  }

  static String tierFor(int points) => points >= 5000
      ? 'DIAMOND'
      : points >= 2000
      ? 'GOLD'
      : points >= 500
      ? 'SILVER'
      : 'BRONZE';

  double get _weekFraction {
    final elapsed = const Duration(days: 7) - timeUntilWeeklyReset;
    return (elapsed.inMinutes / const Duration(days: 7).inMinutes).clamp(
      0.05,
      1.0,
    );
  }

  List<int> _rivalPoints(String week, double fraction) {
    final r = math.Random(
      week.codeUnits.fold<int>(3, (h, c) => (h * 31 + c) & 0x7fffffff),
    );
    return [
      for (final base in _rivalBase)
        (base * (0.7 + r.nextDouble() * 0.6) * fraction).round(),
    ];
  }

  int _rankFor(int points, String week, double fraction) =>
      1 + _rivalPoints(week, fraction).where((p) => p > points).length;

  List<LeaderRow> get leaderboard {
    final pts = _rivalPoints(_week, _weekFraction);
    return [
      for (var i = 0; i < _rivalNames.length; i++)
        LeaderRow(_rivalNames[i], pts[i], false),
      LeaderRow('${PlayerWallet.instance.playerName} (You)', _weekPoints, true),
    ]..sort((a, b) => b.points.compareTo(a.points));
  }

  // ---------------------------------------------------------------- lobby badges

  String get cardsBadge {
    final n = [
      0,
      1,
      2,
    ].where((a) => albumComplete(a) && !albumClaimed(a)).length;
    return n > 0 ? '$n' : '';
  }

  String get puzzleBadge {
    final n =
        [0, 1, 2].where((p) => puzzleComplete(p) && !puzzleClaimed(p)).length +
        (puzzleGrandReady ? 1 : 0);
    return n > 0 ? '$n' : '';
  }

  String get questBadge {
    final n =
        todaysQuests.where((q) => questReady(q) && !questClaimed(q)).length +
        (chestReady ? 1 : 0);
    return n > 0 ? '$n' : '';
  }

  String get inboxBadge => inboxUnclaimed > 0 ? '$inboxUnclaimed' : '';
  String get clubBadge => vaultClaimable ? '!' : '';
  String get wheelBadge => wheelFreeAvailable ? 'FREE' : '';
}

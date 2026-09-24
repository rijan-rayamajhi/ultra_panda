import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'progression.dart';

class PlayerWallet extends ChangeNotifier {
  PlayerWallet._();
  static final PlayerWallet instance = PlayerWallet._();

  SharedPreferences? _prefs;

  /// Fired after coins/gems are credited; the UI animates it.
  void Function(int coins, int gems)? onCredit;

  // Currencies
  int _coins = 1000000;
  int _gems = 100;

  // Piggy Bank
  int _piggyCoins = 0;
  int _piggyMax = 5000000;
  static const piggyMaxCap = 50000000;

  // Player Profile
  String _playerName = 'Panda Player';
  String _userId = '';
  int _level = 1;
  int _xp = 0;
  int _xpTarget = 5000;
  int _avatarIndex = 0; // 0: hostAvatar, 1: iconProfile

  static const avatarCount = 2;
  static const maxLevel = 100;
  static const _vipTitles = [
    'BRONZE',
    'SILVER',
    'GOLD',
    'PLATINUM',
    'RUBY',
    'SAPPHIRE',
    'EMERALD',
    'DIAMOND',
    'ROYAL',
    'DIAMOND ELITE',
  ];

  // Career Statistics
  int _totalSpins = 0;
  int _biggestWin = 0;
  int _jackpotsHit = 0;
  Map<String, int> _gameSpins = {};
  Map<String, int> _gameBestWin = {};
  int _totalWon = 0;

  // Settings State
  bool _turboSpin = false;
  bool _hapticEnabled = true;
  bool _autoStopOnBonus = true;
  bool _winEffectsEnabled = true;

  /// Loads any previously saved progress. Call once before the app is shown;
  /// falls back to the hardcoded defaults above on first launch.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;

    _coins = prefs.getInt('coins') ?? _coins;
    _gems = prefs.getInt('gems') ?? _gems;
    _piggyCoins = prefs.getInt('piggyCoins') ?? _piggyCoins;
    _piggyMax = prefs.getInt('piggyMax') ?? _piggyMax;
    _playerName = prefs.getString('playerName') ?? _playerName;
    _level = math.min(prefs.getInt('level') ?? _level, maxLevel);
    _xp = prefs.getInt('xp') ?? _xp;
    _xpTarget = prefs.getInt('xpTarget') ?? _xpTarget;
    _avatarIndex = prefs.getInt('avatarIndex') ?? _avatarIndex;
    _totalSpins = prefs.getInt('totalSpins') ?? _totalSpins;
    _biggestWin = prefs.getInt('biggestWin') ?? _biggestWin;
    _jackpotsHit = prefs.getInt('jackpotsHit') ?? _jackpotsHit;
    _userId = prefs.getString('userId') ?? '';
    if (_userId.isEmpty) {
      // Stable per-install player ID, generated once.
      _userId = List.generate(
        8,
        (_) => math.Random.secure().nextInt(10),
      ).join();
      prefs.setString('userId', _userId);
    }
    _gameSpins = _decodeCounts(prefs.getString('gameSpins'));
    _gameBestWin = _decodeCounts(prefs.getString('gameBestWin'));
    _totalWon = prefs.getInt('totalWon') ?? 0;
    _avatarIndex %= avatarCount;
    _turboSpin = prefs.getBool('turboSpin') ?? _turboSpin;
    _hapticEnabled = prefs.getBool('hapticEnabled') ?? _hapticEnabled;
    _autoStopOnBonus = prefs.getBool('autoStopOnBonus') ?? _autoStopOnBonus;
    _winEffectsEnabled =
        prefs.getBool('winEffectsEnabled') ?? _winEffectsEnabled;

    notifyListeners();
  }

  /// Corrupt saved JSON must not abort load(); fall back to empty.
  static Map<String, int> _decodeCounts(String? raw) {
    if (raw == null) return {};
    try {
      return Map<String, int>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  void _save() {
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setInt('coins', _coins);
    prefs.setInt('gems', _gems);
    prefs.setInt('piggyCoins', _piggyCoins);
    prefs.setInt('piggyMax', _piggyMax);
    prefs.setString('playerName', _playerName);
    prefs.setInt('level', _level);
    prefs.setInt('xp', _xp);
    prefs.setInt('xpTarget', _xpTarget);
    prefs.setInt('avatarIndex', _avatarIndex);
    prefs.setInt('totalSpins', _totalSpins);
    prefs.setInt('biggestWin', _biggestWin);
    prefs.setInt('jackpotsHit', _jackpotsHit);
    prefs.setString('gameSpins', jsonEncode(_gameSpins));
    prefs.setString('gameBestWin', jsonEncode(_gameBestWin));
    prefs.setInt('totalWon', _totalWon);
    prefs.setBool('turboSpin', _turboSpin);
    prefs.setBool('hapticEnabled', _hapticEnabled);
    prefs.setBool('autoStopOnBonus', _autoStopOnBonus);
    prefs.setBool('winEffectsEnabled', _winEffectsEnabled);
  }

  // Getters - Currencies
  int get coins => _coins;
  int get gems => _gems;

  // Getters - Piggy Bank
  int get piggyCoins => _piggyCoins;
  int get piggyMax => _piggyMax;
  bool get isPiggyFull => _piggyCoins >= _piggyMax;
  double get piggyFillRatio => (_piggyCoins / _piggyMax).clamp(0.0, 1.0);

  // Getters - Player Profile
  String get playerName => _playerName;
  String get userId => 'UID: $_userId';
  int get level => _level;
  int get xp => _xp;
  int get xpTarget => _xpTarget;
  double get xpRatio => (_xp / _xpTarget).clamp(0.0, 1.0);

  /// VIP rank earned by level: one rank every 10 levels, capped at 10.
  int get vipLevel => math.min(1 + (_level - 1) ~/ 10, _vipTitles.length);
  String get vipTitle => _vipTitles[vipLevel - 1];
  int get nextVipLevelAt =>
      vipLevel >= _vipTitles.length ? 0 : vipLevel * 10 + 1;
  int get avatarIndex => _avatarIndex;
  bool get isMaxLevel => _level >= maxLevel;

  // Getters - Career Statistics
  int get totalSpins => _totalSpins;
  int get biggestWin => _biggestWin;
  int get jackpotsHit => _jackpotsHit;
  int get totalWon => _totalWon;
  int bestWinFor(String game) => _gameBestWin[game] ?? 0;

  /// Most-played game, or '—' before the first spin.
  String get favoriteSlot => _gameSpins.isEmpty
      ? '—'
      : _gameSpins.entries.reduce((a, b) => b.value > a.value ? b : a).key;

  // Getters - Settings
  bool get turboSpin => _turboSpin;
  bool get hapticEnabled => _hapticEnabled;
  bool get autoStopOnBonus => _autoStopOnBonus;
  bool get winEffectsEnabled => _winEffectsEnabled;

  String get formattedCoins => _formatNumber(_coins);
  String get formattedGems => _formatNumber(_gems);
  String get formattedPiggyCoins => _formatNumber(_piggyCoins);
  String get formattedBiggestWin => _formatNumber(_biggestWin);

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // Currency Mutators
  void addCoins(int amount) {
    if (amount <= 0) return;
    _coins += amount;
    notifyListeners();
    _save();
    onCredit?.call(amount, 0);
  }

  bool deductCoins(int amount) {
    if (amount <= 0) return true;
    if (_coins < amount) return false;
    _coins -= amount;
    notifyListeners();
    _save();
    return true;
  }

  void addGems(int amount) {
    if (amount <= 0) return;
    _gems += amount;
    notifyListeners();
    _save();
    onCredit?.call(0, amount);
  }

  bool deductGems(int amount) {
    if (amount <= 0) return true;
    if (_gems < amount) return false;
    _gems -= amount;
    notifyListeners();
    _save();
    return true;
  }

  // Piggy Bank Operations
  void addPiggyCoins(int amount) {
    if (amount <= 0) return;
    _piggyCoins = (_piggyCoins + amount).clamp(0, _piggyMax);
    notifyListeners();
    _save();
  }

  int smashPiggy() {
    final collected = _piggyCoins;
    _coins += collected;
    // Empty it and grow capacity 50% per smash, capped.
    _piggyCoins = 0;
    _piggyMax = math.min(_piggyMax * 3 ~/ 2, piggyMaxCap);
    notifyListeners();
    _save();
    onCredit?.call(collected, 0);
    return collected;
  }

  // Profile Operations
  void setPlayerName(String name) {
    if (name.trim().isNotEmpty) {
      _playerName = name.trim();
      notifyListeners();
      _save();
    }
  }

  void setAvatarIndex(int index) {
    _avatarIndex = index % avatarCount;
    notifyListeners();
    _save();
  }

  void _trackWin(int amount, String game) {
    if (amount <= 0) return;
    _totalWon += amount;
    if (amount > _biggestWin) _biggestWin = amount;
    if (amount > bestWinFor(game)) _gameBestWin[game] = amount;
  }

  /// Bonus-round payouts that aren't part of a single spin's win.
  void recordBonusWin(int amount, String game) {
    if (amount <= 0) return;
    _trackWin(amount, game);
    notifyListeners();
    _save();
    Progression.instance.onBonusWin(amount);
  }

  void recordJackpotHit() {
    _jackpotsHit += 1;
    notifyListeners();
    _save();
  }

  void recordSpin({
    required int betAmount,
    required int winAmount,
    required String gameTitle,
  }) {
    _totalSpins += 1;
    // Add 5% of bet into piggy bank if not full
    final piggyContribution = (betAmount * 0.05).round();
    if (piggyContribution > 0 && !isPiggyFull) {
      _piggyCoins = (_piggyCoins + piggyContribution).clamp(0, _piggyMax);
    }

    _gameSpins[gameTitle] = (_gameSpins[gameTitle] ?? 0) + 1;
    _trackWin(winAmount, gameTitle);

    // Gain XP
    final earnedXp = (betAmount / 1000).clamp(50, 500).toInt();
    _xp += earnedXp;
    if (isMaxLevel) {
      _xp = math.min(_xp, _xpTarget);
    } else if (_xp >= _xpTarget) {
      _level += 1;
      _xp = _xp - _xpTarget;
      _xpTarget = (_xpTarget * 1.25).round();
      // Level up rewards
      _coins += 500000;
      _gems += 50;
      onCredit?.call(500000, 50);
    }
    notifyListeners();
    _save();
    Progression.instance.onSpin(
      bet: betAmount,
      win: winAmount,
      game: gameTitle,
    );
  }

  // Settings Toggles
  void toggleTurboSpin() {
    _turboSpin = !_turboSpin;
    notifyListeners();
    _save();
  }

  void toggleHaptic() {
    _hapticEnabled = !_hapticEnabled;
    notifyListeners();
    _save();
  }

  void toggleAutoStopOnBonus() {
    _autoStopOnBonus = !_autoStopOnBonus;
    notifyListeners();
    _save();
  }

  void toggleWinEffects() {
    _winEffectsEnabled = !_winEffectsEnabled;
    notifyListeners();
    _save();
  }
}

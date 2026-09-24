import 'dart:developer' as developer;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_assets.dart';

class AudioManager extends ChangeNotifier with WidgetsBindingObserver {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  final AudioPlayer _musicPlayer = AudioPlayer();
  // Small round-robin pool so a click doesn't cut off a payout ding.
  final List<AudioPlayer> _sfxPool = List.generate(3, (_) => AudioPlayer());
  int _sfxNext = 0;

  SharedPreferences? _prefs;
  bool _isMuted = false;
  bool _isMusicPlaying = false;
  bool _pausedByLifecycle = false;
  double _musicVolume = 0.5;
  double _sfxVolume = 0.8;

  bool get isMuted => _isMuted;
  bool get isMusicPlaying => _isMusicPlaying;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  Future<void> init() async {
    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addObserver(this);
    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      _isMuted = prefs.getBool('audioMuted') ?? _isMuted;
      _musicVolume = prefs.getDouble('musicVolume') ?? _musicVolume;
      _sfxVolume = prefs.getDouble('sfxVolume') ?? _sfxVolume;
      notifyListeners();
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(_isMuted ? 0 : _musicVolume);
    } catch (e) {
      developer.log('AudioManager init error: $e');
    }
  }

  void _save() {
    _prefs?.setBool('audioMuted', _isMuted);
    _prefs?.setDouble('musicVolume', _musicVolume);
    _prefs?.setDouble('sfxVolume', _sfxVolume);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_pausedByLifecycle) {
        _pausedByLifecycle = false;
        resumeMusic();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (_isMusicPlaying) {
        _pausedByLifecycle = true;
        pauseMusic();
      }
    }
  }

  // Background Music
  Future<void> playLobbyMusic() async {
    if (_isMuted) return;
    try {
      await _musicPlayer.stop();
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(_musicVolume);
      // AssetSource expects path relative to assets/
      await _musicPlayer.play(AssetSource(AppAssets.musicLobby));
      _isMusicPlaying = true;
      notifyListeners();
    } catch (e) {
      developer.log('Error playing music: $e');
    }
  }

  Future<void> stopMusic() async {
    try {
      await _musicPlayer.stop();
      _isMusicPlaying = false;
      notifyListeners();
    } catch (e) {
      developer.log('Error stopping music: $e');
    }
  }

  Future<void> pauseMusic() async {
    try {
      await _musicPlayer.pause();
      _isMusicPlaying = false;
      notifyListeners();
    } catch (e) {
      developer.log('Error pausing music: $e');
    }
  }

  Future<void> resumeMusic() async {
    if (_isMuted) return;
    try {
      await _musicPlayer.resume();
      _isMusicPlaying = true;
      notifyListeners();
    } catch (e) {
      developer.log('Error resuming music: $e');
    }
  }

  Future<void> _playSfx(String asset) async {
    if (_isMuted || _sfxVolume <= 0) return;
    final player = _sfxPool[_sfxNext];
    _sfxNext = (_sfxNext + 1) % _sfxPool.length;
    try {
      await player.stop();
      await player.play(AssetSource(asset), volume: _sfxVolume);
    } catch (e) {
      developer.log('Error playing SFX $asset: $e');
    }
  }

  Future<void> playSelectClick() => _playSfx(AppAssets.sfxSelectClick);
  Future<void> playSpinWhoosh() => _playSfx(AppAssets.sfxSpinWhoosh);
  Future<void> playPayoutDing() => _playSfx(AppAssets.sfxPayoutDing);

  // Mute / Unmute toggle
  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _musicPlayer.setVolume(0);
      for (final p in _sfxPool) {
        p.stop();
      }
    } else {
      _musicPlayer.setVolume(_musicVolume);
      if (!_isMusicPlaying) {
        playLobbyMusic();
      }
    }
    _save();
    notifyListeners();
  }

  void setMusicVolume(double vol) {
    _musicVolume = vol.clamp(0.0, 1.0);
    if (!_isMuted) {
      _musicPlayer.setVolume(_musicVolume);
    }
    _save();
    notifyListeners();
  }

  void setSfxVolume(double vol) {
    _sfxVolume = vol.clamp(0.0, 1.0);
    _save();
    notifyListeners();
  }
}

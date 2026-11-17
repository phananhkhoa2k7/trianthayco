import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService extends ChangeNotifier with WidgetsBindingObserver {
  static const _asset = 'audio/bgm.mp3';
  static const _prefKey = 'bgm_muted';

  final AudioPlayer _player = AudioPlayer();
  bool _sourceLoaded = false;
  bool _available = true;
  bool _muted = false;
  bool _soft = false;
  bool _hidden = false;

  AudioService() {
    WidgetsBinding.instance.addObserver(this);
    _loadPrefs();
  }

  bool get muted => _muted;
  bool get available => _available;

  /// Gọi mỗi khi người dùng chạm vào màn hình (đảm bảo vượt qua chính sách Autoplay của Mobile Browser)
  void markUserInteraction() {
    if (!_muted && !_hidden && _player.state != PlayerState.playing) {
      start();
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _muted = prefs.getBool(_prefKey) ?? false;
    notifyListeners();
  }

  Future<void> start() async {
    if (!_available || _muted || _hidden) return;
    try {
      if (!_sourceLoaded) {
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.setSource(AssetSource(_asset));
        _sourceLoaded = true;
      }
      await _player.setVolume(_soft ? 0.12 : 0.4);
      if (_player.state != PlayerState.playing) {
        await _player.resume();
      }
    } catch (e) {
      // Nếu lỗi do trình duyệt chưa nhận cử chỉ người dùng, KHÔNG khóa _available
      // để lần chạm tiếp theo có thể thử phát lại.
      debugPrint('BGM đang chờ tương tác hoặc lỗi: $e');
    }
  }

  void setSoft(bool value) {
    if (_soft == value) return;
    _soft = value;
    _sync();
  }

  Future<void> toggleMute() async {
    _muted = !_muted;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, _muted);
    if (!_muted) {
      await start();
    } else {
      await _sync();
    }
  }

  Future<void> _sync() async {
    if (!_sourceLoaded || !_available) return;
    try {
      await _player.setVolume(_soft ? 0.12 : 0.4);
      if (_muted || _hidden) {
        await _player.pause();
      } else if (_player.state != PlayerState.playing) {
        await _player.resume();
      }
    } catch (e) {
      debugPrint('BGM sync lỗi: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _hidden = state != AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    super.dispose();
  }
}
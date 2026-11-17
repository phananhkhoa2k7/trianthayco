import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý nhạc nền (thay cho biến global trong main.dart).
/// - Trình duyệt chặn autoplay => start() được gọi ở lần chạm đầu tiên.
/// - Tự tạm dừng khi tab/ứng dụng bị ẩn (tiết kiệm pin & CPU).
/// - Nhớ trạng thái tắt/mở tiếng; thiếu file bgm.mp3 vẫn không làm game lỗi.
class AudioService extends ChangeNotifier with WidgetsBindingObserver {
  static const _asset = 'audio/bgm.mp3';
  static const _prefKey = 'bgm_muted';

  final AudioPlayer _player = AudioPlayer();
  bool _started = false;
  bool _available = true;
  bool _muted = false;
  bool _soft = false; // true: hạ âm lượng (màn hình tri ân)
  bool _hidden = false;

  AudioService() {
    WidgetsBinding.instance.addObserver(this);
    _loadPrefs();
  }

  bool get muted => _muted;
  bool get available => _available;

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _muted = prefs.getBool(_prefKey) ?? false;
    notifyListeners();
  }

  /// Gọi sau tương tác đầu tiên của người dùng. Gọi nhiều lần cũng an toàn.
  Future<void> start() async {
    if (_started || !_available) return;
    _started = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setSource(AssetSource(_asset));
      await _sync();
    } catch (e) {
      _available = false; // thiếu file / không phát được => bỏ qua im lặng
      debugPrint('BGM không khả dụng: $e');
      notifyListeners();
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
    if (!_muted) await start();
    await _sync();
  }

  Future<void> _sync() async {
    if (!_started || !_available) return;
    try {
      await _player.setVolume(_soft ? 0.12 : 0.4);
      if (_muted || _hidden) {
        await _player.pause();
      } else {
        await _player.resume();
      }
    } catch (e) {
      debugPrint('BGM lỗi: $e');
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

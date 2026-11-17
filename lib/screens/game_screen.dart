import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/wishes.dart';
import '../models/teacher.dart';
import '../services/audio_service.dart';
import '../services/maze_generator.dart';
import '../theme/app_theme.dart';
import '../widgets/maze_view.dart';
import '../widgets/mute_button.dart';
import '../widgets/petal_background.dart';
import '../widgets/sprites.dart';
import 'tribute_screen.dart';

class LevelConfig {
  final int rows, cols, maxFlowers, maxLetters;
  final LevelTheme theme;
  const LevelConfig(this.rows, this.cols, this.maxFlowers, this.maxLetters, this.theme);
}

const List<LevelConfig> kLevels = [
  LevelConfig(
    7, 7, 3, 2,
    LevelTheme(
      name: 'Sân trường',
      subtitle: 'Nơi mọi câu chuyện bắt đầu',
      floorA: Color(0xFFE9F7EC),
      floorB: Color(0xFFD9F0DE),
      hedge: Color(0xFF4FAE7C),
      hedgeDark: Color(0xFF2F7F57),
    ),
  ),
  LevelConfig(
    9, 9, 3, 2,
    LevelTheme(
      name: 'Vườn hoa tri ân',
      subtitle: 'Mỗi bông hoa một lời cảm ơn',
      floorA: Color(0xFFFFF3E3),
      floorB: Color(0xFFFFE8D0),
      hedge: Color(0xFFF08BA3),
      hedgeDark: Color(0xFFC2506B),
    ),
  ),
  LevelConfig(
    11, 11, 3, 2,
    LevelTheme(
      name: 'Hành lang kỷ niệm',
      subtitle: 'Những ngày tháng không quên',
      floorA: Color(0xFFFFF8E1),
      floorB: Color(0xFFFFEFC2),
      hedge: Color(0xFFB08968),
      hedgeDark: Color(0xFF7A5A40),
    ),
  ),
];

const LevelTheme _classroomTheme = LevelTheme(
  name: 'Lớp học',
  subtitle: '',
  floorA: Colors.white,
  floorB: Colors.white,
  hedge: Colors.brown,
  hedgeDark: Colors.brown,
);

class GameScreen extends StatefulWidget {
  final Teacher teacher;
  const GameScreen({super.key, required this.teacher});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _focus = FocusNode();
  final _rng = Random();
  late final List<String> _wishPool = List.of(kWishes)..shuffle(_rng);
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  final ValueNotifier<Point<int>> _player = ValueNotifier(const Point(0, 0));

  int _level = 0;
  late Maze _maze;
  int _levelFlowers = 0, _levelLetters = 0, _totalFlowers = 0;
  final List<String> _collectedWishes = [];

  bool _classroom = false;
  bool _dialogOpen = false;
  Offset _dragAcc = Offset.zero;

  Timer? _moveTimer;
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  String? _flashMsg;
  IconData _flashIcon = Icons.mail;
  int _flashId = 0; // Key duy nhất đảm bảo thông báo luôn hiện mỗi lần nhặt
  Timer? _flashTimer;

  LevelConfig get _cfg => kLevels[_level];
  bool get _exitOpen =>
      _levelFlowers >= _cfg.maxFlowers && _levelLetters >= _cfg.maxLetters;

  @override
  void initState() {
    super.initState();
    _loadLevel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final audio = context.read<AudioService>();
      audio.setSoft(false);
      audio.start();
    });
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    _flashTimer?.cancel();
    _confetti.dispose();
    _player.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _loadLevel() {
    _maze = MazeGenerator.generate(
      rows: _cfg.rows,
      cols: _cfg.cols,
      flowerCount: _cfg.maxFlowers,
      letterCount: _cfg.maxLetters,
      random: _rng,
    );
    _player.value = _maze.start;
    _levelFlowers = 0;
    _levelLetters = 0;
  }

  /// Cá nhân hóa lời chúc theo đúng xưng hô Thầy/Cô
  String _personalizeWish(String raw) {
    final h = widget.teacher.honorific.toLowerCase();
    return raw.replaceAll('thầy cô', h).replaceAll('Thầy cô', widget.teacher.honorific);
  }

  String _nextWish() {
    final raw = _wishPool.isNotEmpty
        ? _wishPool.removeLast()
        : kWishes[_rng.nextInt(kWishes.length)];
    return _personalizeWish(raw);
  }

  void _flash(String msg, IconData icon) {
    _flashTimer?.cancel();
    setState(() {
      _flashId++;
      _flashMsg = msg;
      _flashIcon = icon;
    });
    _flashTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) setState(() => _flashMsg = null);
    });
  }

  void _stopMoving() {
    _pressedKeys.clear();
    _moveTimer?.cancel();
  }

  void _move(Dir d) {
    // Đảm bảo kích hoạt nhạc nền ngay khi người dùng thao tác di chuyển trên điện thoại
    context.read<AudioService>().markUserInteraction();

    if (_dialogOpen || _classroom || !_maze.canMove(_player.value, d)) return;
    final next = _maze.step(_player.value, d);
    _player.value = next;

    String? msg;
    IconData icon = Icons.mail_rounded;
    var collected = false;
    final h = widget.teacher.honorific.toLowerCase();

    if (_levelFlowers < _cfg.maxFlowers && _maze.flowers.remove(next)) {
      _levelFlowers++;
      _totalFlowers++;
      collected = true;
      msg = 'Đã nhặt một bông hoa tươi thắm tặng $h! ($_levelFlowers/${_cfg.maxFlowers})';
      icon = Icons.local_florist_rounded;
    }

    if (_levelLetters < _cfg.maxLetters && _maze.letters.remove(next)) {
      _levelLetters++;
      final wish = _nextWish();
      _collectedWishes.add(wish);
      collected = true;
      msg = wish;
      icon = Icons.mail_rounded;
    }

    if (collected) setState(() {});
    if (msg != null) _flash(msg, icon);
    if (next == _maze.exit) _onReachExit();
  }

  Future<void> _onReachExit() async {
    _stopMoving();
    if (!_exitOpen) {
      _flash('Cổng trường chưa mở! Hãy nhặt đủ hoa và thư trong ải này nhé.',
          Icons.lock_outline_rounded);
      return;
    }
    _dialogOpen = true;
    _confetti.play();
    // Chờ thêm một chút nếu vừa nhặt thư cuối cùng ngay sát cổng để người chơi kịp đọc lời chúc
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    final last = _level == kLevels.length - 1;
    final h = widget.teacher.honorific.toLowerCase();
    await _showCard(
      title: 'Qua ải ${_level + 1}!',
      body: last
          ? 'Bạn đã đi hết ba ải. Giờ là lúc gặp $h và trao những điều đã gom góp.'
          : 'Bạn đã gom đủ hoa và thư. Phía trước là "${kLevels[_level + 1].theme.name}".',
      button: last ? 'Đi gặp $h' : 'Ải tiếp theo',
    );
    _dialogOpen = false;
    if (!mounted) return;
    _focus.requestFocus();

    if (last) {
      setState(() => _classroom = true);
      _player.value = const Point(3, 6);
      _walkToTeacher();
    } else {
      setState(() {
        _level++;
        _loadLevel();
      });
    }
  }

  Future<void> _walkToTeacher() async {
    while (mounted && _player.value.y > 3) {
      await Future.delayed(const Duration(milliseconds: 320));
      if (!mounted) return;
      _player.value = Point(3, _player.value.y - 1);
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _confetti.play();
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final t = widget.teacher;
    await _showCard(
      title: 'Chúc mừng ngày 20/11!',
      body: 'Bạn đã trao bó hoa tươi thắm nhất đến ${t.honorific.toLowerCase()} ${t.name}. '
          'Chắc ${t.honorific.toLowerCase()} sẽ rất vui đấy!',
      button: 'Viết lời tri ân',
    );
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TributeScreen(
        teacher: t,
        flowers: _totalFlowers,
        wishes: List.of(_collectedWishes),
      ),
    ));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _showCard(
      {required String title, required String body, required String button}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FlowerIcon(size: 34),
                  SizedBox(width: 8),
                  LetterIcon(size: 34),
                ],
              ),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: scriptStyle(32)),
              const SizedBox(height: 8),
              Text(body, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(button)),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMovement() {
    bool k(LogicalKeyboardKey a, LogicalKeyboardKey b) =>
        _pressedKeys.contains(a) || _pressedKeys.contains(b);
    if (k(LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyW)) {
      _move(Dir.up);
    } else if (k(LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS)) {
      _move(Dir.down);
    } else if (k(LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA)) {
      _move(Dir.left);
    } else if (k(LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD)) {
      _move(Dir.right);
    }
  }

  void _onKeyEvent(KeyEvent e) {
    if (e is KeyDownEvent) {
      _pressedKeys.add(e.logicalKey);
      if (_moveTimer == null || !_moveTimer!.isActive) {
        _handleMovement();
        _moveTimer = Timer.periodic(
            const Duration(milliseconds: 130), (_) => _handleMovement());
      }
    } else if (e is KeyUpEvent) {
      _pressedKeys.remove(e.logicalKey);
      if (_pressedKeys.isEmpty) _moveTimer?.cancel();
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    _dragAcc += d.delta;
    if (_dragAcc.distance < 24) return;
    if (_dragAcc.dx.abs() > _dragAcc.dy.abs()) {
      _move(_dragAcc.dx > 0 ? Dir.right : Dir.left);
    } else {
      _move(_dragAcc.dy > 0 ? Dir.down : Dir.up);
    }
    _dragAcc = Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 700;
    final cfg = _classroom ? null : _cfg;
    return Listener(
      onPointerDown: (_) => context.read<AudioService>().markUserInteraction(),
      child: PetalBackground(
        petals: 6,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
                'Tặng hoa ${widget.teacher.honorific.toLowerCase()} ${widget.teacher.name.split(' ').last}'),
            actions: const [MuteButton()],
          ),
          body: KeyboardListener(
            focusNode: _focus,
            autofocus: true,
            onKeyEvent: _onKeyEvent,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _focus.requestFocus,
              onPanUpdate: _onPanUpdate,
              onPanEnd: (_) => _dragAcc = Offset.zero,
              child: SafeArea(
                child: Stack(
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Column(
                          children: [
                            if (cfg != null) _hud(cfg),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final side = min(
                                      min(constraints.maxWidth, constraints.maxHeight),
                                      500.0,
                                    );
                                    return Center(
                                      child: SizedBox(
                                        width: side,
                                        height: side,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(24),
                                            boxShadow: kSoftShadow,
                                          ),
                                          child: MazeView(
                                            rows: _classroom ? 7 : cfg!.rows,
                                            cols: _classroom ? 7 : cfg!.cols,
                                            maze: _classroom ? null : _maze,
                                            player: _player,
                                            exitOpen: _exitOpen,
                                            classroom: _classroom,
                                            theme: _classroom ? _classroomTheme : cfg!.theme,
                                            teacher: widget.teacher,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            if (narrow && !_classroom) _DPad(onMove: _move),
                            if (!_classroom)
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  narrow
                                      ? 'Vuốt hoặc dùng nút mũi tên để di chuyển'
                                      : 'Dùng phím mũi tên (hoặc W/A/S/D) để di chuyển',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 16,
                      right: 16,
                      child: IgnorePointer(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _flashMsg == null
                              ? const SizedBox.shrink(key: ValueKey('none'))
                              : _FlashCard(
                                  key: ValueKey('flash_$_flashId'),
                                  text: _flashMsg!,
                                  icon: _flashIcon),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConfettiWidget(
                        confettiController: _confetti,
                        blastDirectionality: BlastDirectionality.explosive,
                        emissionFrequency: 0.06,
                        numberOfParticles: 14,
                        gravity: 0.25,
                        createParticlePath: heartPath,
                        colors: const [
                          AppColors.rose,
                          AppColors.gold,
                          Color(0xFFFFA8BE),
                          AppColors.leaf,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hud(LevelConfig cfg) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ải ${_level + 1} · ${cfg.theme.name}',
                style: scriptStyle(26, color: AppColors.roseDark)),
            Text(cfg.theme.subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            // Dùng FittedBox giữ tất cả các thẻ trên đúng 1 hàng ngang duy nhất -> Không bao giờ rớt dòng làm thay đổi chiều cao mê cung
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Pill(
                      icon: const FlowerIcon(),
                      text: '$_levelFlowers/${cfg.maxFlowers}'),
                  const SizedBox(width: 8),
                  _Pill(
                      icon: const LetterIcon(),
                      text: '$_levelLetters/${cfg.maxLetters}'),
                  const SizedBox(width: 8),
                  _Pill(
                    icon: Icon(
                        _exitOpen ? Icons.lock_open_rounded : Icons.lock_rounded,
                        size: 20,
                        color: _exitOpen ? AppColors.leaf : Colors.grey),
                    text: _exitOpen ? 'Cổng đã mở' : 'Cổng đang khoá',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Pill extends StatelessWidget {
  final Widget icon;
  final String text;
  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: kSoftShadow,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          icon,
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      );
}

class _FlashCard extends StatelessWidget {
  final String text;
  final IconData icon;
  const _FlashCard({super.key, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.gold, width: 1.5),
              boxShadow: kSoftShadow,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: AppColors.rose),
              const SizedBox(width: 10),
              Flexible(child: Text(text)),
            ]),
          ),
        ),
      );
}

class _DPad extends StatelessWidget {
  final void Function(Dir) onMove;
  const _DPad({required this.onMove});

  Widget _btn(IconData icon, Dir d) => IconButton.filled(
        onPressed: () => onMove(d),
        style: IconButton.styleFrom(
            backgroundColor: AppColors.blush, foregroundColor: AppColors.roseDark),
        icon: Icon(icon),
      );

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.keyboard_arrow_up_rounded, Dir.up),
          Row(mainAxisSize: MainAxisSize.min, children: [
            _btn(Icons.keyboard_arrow_left_rounded, Dir.left),
            const SizedBox(width: 48),
            _btn(Icons.keyboard_arrow_right_rounded, Dir.right),
          ]),
          _btn(Icons.keyboard_arrow_down_rounded, Dir.down),
        ],
      );
}
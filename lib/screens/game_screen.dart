import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/wishes.dart';
import '../models/teacher.dart';
import '../services/maze_generator.dart';
import '../widgets/maze_view.dart';
import 'tribute_screen.dart';
import '../main.dart';

class LevelConfig {
  final int rows, cols, maxFlowers, maxLetters;
  const LevelConfig(this.rows, this.cols, this.maxFlowers, this.maxLetters);
}

const List<LevelConfig> kLevels = [
  LevelConfig(7, 7, 3, 2),
  LevelConfig(9, 9, 3, 2),
  LevelConfig(11, 11, 3, 2),
];

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

  int _level = 0;
  late Maze _maze;
  late Point<int> _player;

  int _levelFlowers = 0, _levelLetters = 0;
  int _totalFlowers = 0;
  final List<String> _collectedWishes = [];


  bool _dialogOpen = false;
  bool _isFinalRoom = false;
  Offset _dragAcc = Offset.zero;

  Timer? _moveTimer;
  final Set<LogicalKeyboardKey> _pressedKeys = {};


  LevelConfig get _cfg => _isFinalRoom ? const LevelConfig(7, 7, 0, 0) : kLevels[_level];
  bool get _exitOpen =>
      _levelFlowers >= kLevels[_level].maxFlowers && _levelLetters >= kLevels[_level].maxLetters;

  @override
  void initState() {
    super.initState();
    playBgmNormal();
    _loadLevel();
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
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
    _player = _maze.start;
    _levelFlowers = 0;
    _levelLetters = 0;
  }

  void _generateEmptyRoom() {
    _maze = MazeGenerator.generate(
      rows: 7,
      cols: 7,
      flowerCount: 0,
      letterCount: 0,
      random: _rng,
    );
    // remove all walls
    for (var r = 0; r < 7; r++) {
      for (var c = 0; c < 7; c++) {
        _maze.cells[r][c].top = false;
        _maze.cells[r][c].right = false;
        _maze.cells[r][c].bottom = false;
        _maze.cells[r][c].left = false;
      }
    }
    _player = const Point(3, 6); // start at bottom middle
  }

  void _playGiftAnimation() async {
    while (_player.y > 3) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        _player = Point(_player.x, _player.y - 1);
      });
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Chúc mừng!'),
        content: Text('Bạn đã gửi tặng bó hoa tươi thắm nhất đến ${widget.teacher.honorific.toLowerCase()} ${widget.teacher.name}!'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tiếp tục'),
          )
        ],
      ),
    );
    
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TributeScreen(
        teacher: widget.teacher,
        flowers: _totalFlowers,
        wishes: List.of(_collectedWishes),
      ),
    ));
    if (mounted) Navigator.of(context).pop();
  }

  String _nextWish() =>
      _wishPool.isNotEmpty ? _wishPool.removeLast() : kWishes[_rng.nextInt(kWishes.length)];

  void _toast(String msg) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final screenHeight = MediaQuery.of(context).size.height;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg), 
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        dismissDirection: isMobile ? DismissDirection.up : DismissDirection.down,
        margin: EdgeInsets.only(
          bottom: isMobile ? (screenHeight - 140) : 20, 
          left: 20, 
          right: 20
        ),
      ));
  }

  void _move(Dir d) {
    if (_dialogOpen || _isFinalRoom || !_maze.canMove(_player, d)) return;
    final next = _maze.step(_player, d);
    String? toast;
    setState(() {
      _player = next;
      if (_levelFlowers < _cfg.maxFlowers && _maze.flowers.remove(next)) {
        _levelFlowers++;
        _totalFlowers++;
      }
      if (_levelLetters < _cfg.maxLetters && _maze.letters.remove(next)) {
        _levelLetters++;
        final wish = _nextWish();
        _collectedWishes.add(wish);
        toast = 'Nhặt được lời chúc: "$wish"';
      }
    });
    if (toast != null) _toast(toast!);
    if (next == _maze.exit) _onReachExit();
  }

  Future<void> _onReachExit() async {
    _pressedKeys.clear();
    _moveTimer?.cancel();
    if (!_exitOpen) {
      _toast('Cửa ra chưa mở! Hãy nhặt đủ hoa và thư trong ải này.');
      return;
    }
    _dialogOpen = true;
    final lastMaze = _level == kLevels.length - 1;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Qua ải ${_level + 1}!'),
        content: Text(lastMaze
            ? 'Bạn đã vượt qua cả 3 ải. Hãy đi gặp ${widget.teacher.honorific.toLowerCase()} nào!'
            : 'Bạn đã thu thập đủ hoa và thư. Sẵn sàng cho ải tiếp theo?'),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lastMaze ? 'Gặp ${widget.teacher.honorific.toLowerCase()}' : 'Ải tiếp theo')),
        ],
      ),
    );
    _dialogOpen = false;
    if (!mounted) return;
    _focus.requestFocus();

    if (lastMaze) {
      setState(() {
        _isFinalRoom = true;
        _generateEmptyRoom();
      });
      _playGiftAnimation();
    } else {
      setState(() {
        _level++;
        _loadLevel();
      });
    }
  }

  void _handleMovement() {
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp) || _pressedKeys.contains(LogicalKeyboardKey.keyW)) {
      _move(Dir.up);
    } else if (_pressedKeys.contains(LogicalKeyboardKey.arrowDown) || _pressedKeys.contains(LogicalKeyboardKey.keyS)) {
      _move(Dir.down);
    } else if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft) || _pressedKeys.contains(LogicalKeyboardKey.keyA)) {
      _move(Dir.left);
    } else if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight) || _pressedKeys.contains(LogicalKeyboardKey.keyD)) {
      _move(Dir.right);
    }
  }

  void _onKeyEvent(KeyEvent e) {
    if (e is KeyDownEvent) {
      _pressedKeys.add(e.logicalKey);
      if (_moveTimer == null || !_moveTimer!.isActive) {
        _handleMovement();
        _moveTimer = Timer.periodic(const Duration(milliseconds: 130), (_) => _handleMovement());
      }
    } else if (e is KeyUpEvent) {
      _pressedKeys.remove(e.logicalKey);
      if (_pressedKeys.isEmpty) {
        _moveTimer?.cancel();
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    _dragAcc += d.delta;
    const threshold = 24.0;
    if (_dragAcc.distance < threshold) return;
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
    return Scaffold(
      appBar: AppBar(title: Text('Tặng hoa cho ${widget.teacher.displayName}')),
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  children: [
                    if (!_isFinalRoom) _hud(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: _cfg.cols / _cfg.rows,
                            child: MazeView(
                              maze: _maze,
                              player: _player,
                              exitOpen: _exitOpen,
                              isFinalRoom: _isFinalRoom,
                              teacher: widget.teacher,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (narrow && !_isFinalRoom) _DPad(onMove: _move),
                    if (!_isFinalRoom) Padding(
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
          ),
        ),
      ),
    );
  }

  Widget _hud() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            Chip(label: Text('Ải ${_level + 1}/${kLevels.length}')),
            Chip(
                avatar: const Icon(Icons.local_florist, color: Colors.pink, size: 18),
                label: Text('Hoa $_levelFlowers/${_cfg.maxFlowers}')),
            Chip(
                avatar: const Icon(Icons.mail, color: Colors.orange, size: 18),
                label: Text('Thư $_levelLetters/${_cfg.maxLetters}')),
            Chip(
                avatar: Icon(_exitOpen ? Icons.lock_open : Icons.lock,
                    color: _exitOpen ? Colors.green : Colors.grey, size: 18),
                label: Text(_exitOpen ? 'Cửa ra đã mở' : 'Cửa ra đang khoá')),
          ],
        ),
      );
}

class _DPad extends StatelessWidget {
  final void Function(Dir) onMove;
  const _DPad({required this.onMove});

  Widget _btn(IconData icon, Dir d) =>
      IconButton.filledTonal(onPressed: () => onMove(d), icon: Icon(icon));

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(Icons.keyboard_arrow_up, Dir.up),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _btn(Icons.keyboard_arrow_left, Dir.left),
            const SizedBox(width: 48),
            _btn(Icons.keyboard_arrow_right, Dir.right),
          ],
        ),
        _btn(Icons.keyboard_arrow_down, Dir.down),
      ],
    );
  }
}

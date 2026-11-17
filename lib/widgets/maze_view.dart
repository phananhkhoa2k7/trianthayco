import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/teacher.dart';
import '../services/maze_generator.dart';
import '../theme/app_theme.dart';
import 'sprites.dart';

/// Chủ đề màu cho từng ải.
class LevelTheme {
  final String name, subtitle;
  final Color floorA, floorB, hedge, hedgeDark;
  const LevelTheme({
    required this.name,
    required this.subtitle,
    required this.floorA,
    required this.floorB,
    required this.hedge,
    required this.hedgeDark,
  });
}

/// Hiển thị mê cung (hoặc lớp học ở màn cuối) theo 3 lớp để vẽ nhẹ:
///  1. Lớp tĩnh (sàn, tường, cổng)  - chỉ vẽ lại khi đổi ải / mở cổng / đổi kích thước.
///  2. Lớp vật phẩm (hoa, thư, lấp lánh) - repaint theo AnimationController, chỉ vài chục nét vẽ.
///  3. Nhân vật - Transform tween, KHÔNG làm rebuild/vẽ lại 2 lớp trên khi di chuyển.
class MazeView extends StatefulWidget {
  final int rows, cols;
  final Maze? maze; // null => cảnh lớp học
  final ValueListenable<Point<int>> player;
  final bool exitOpen;
  final LevelTheme theme;
  final bool classroom;
  final Teacher? teacher;

  const MazeView({
    super.key,
    required this.rows,
    required this.cols,
    required this.player,
    required this.theme,
    this.maze,
    this.exitOpen = false,
    this.classroom = false,
    this.teacher,
  });

  @override
  State<MazeView> createState() => _MazeViewState();
}

class _MazeViewState extends State<MazeView> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      const pad = 8.0;
      final cs = min((box.maxWidth - 2 * pad) / widget.cols,
          (box.maxHeight - 2 * pad) / widget.rows);
      final ox = (box.maxWidth - cs * widget.cols) / 2;
      final oy = (box.maxHeight - cs * widget.rows) / 2;
      final teacher = widget.teacher;

      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: widget.classroom
                      ? _ClassroomPainter(widget.rows, widget.cols, cs, ox, oy)
                      : _MazeStaticPainter(
                          widget.maze!, widget.theme, widget.exitOpen, cs, ox, oy),
                ),
              ),
            ),
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _ItemsPainter(
                    maze: widget.maze,
                    exitOpen: widget.exitOpen,
                    classroom: widget.classroom,
                    cs: cs,
                    ox: ox,
                    oy: oy,
                    anim: _ctrl,
                  ),
                ),
              ),
            ),
            if (widget.classroom && teacher != null)
              Positioned(
                left: ox + 3 * cs,
                top: oy + 2 * cs,
                width: cs,
                height: cs,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: CharacterPainter(teacher.isMale
                        ? CharacterKind.teacherMale
                        : CharacterKind.teacherFemale),
                  ),
                ),
              ),
            // Người chơi: chỉ phần này rebuild khi di chuyển.
            ValueListenableBuilder<Point<int>>(
              valueListenable: widget.player,
              builder: (context, p, child) => TweenAnimationBuilder<Offset>(
                tween: Tween(end: Offset(ox + p.x * cs, oy + p.y * cs)),
                duration: const Duration(milliseconds: 120),
                builder: (_, off, c) => Transform.translate(offset: off, child: c),
                child: child,
              ),
              child: SizedBox(
                width: cs,
                height: cs,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: CharacterPainter(CharacterKind.student,
                        hasFlower: widget.classroom),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _MazeStaticPainter extends CustomPainter {
  final Maze maze;
  final LevelTheme theme;
  final bool exitOpen;
  final double cs, ox, oy;
  _MazeStaticPainter(this.maze, this.theme, this.exitOpen, this.cs, this.ox, this.oy);

  @override
  void paint(Canvas canvas, Size size) {
    final pa = Paint()..color = theme.floorA;
    final pb = Paint()..color = theme.floorB;
    for (var y = 0; y < maze.rows; y++) {
      for (var x = 0; x < maze.cols; x++) {
        canvas.drawRect(Rect.fromLTWH(ox + x * cs, oy + y * cs, cs, cs),
            (x + y).isEven ? pa : pb);
      }
    }

    // Điểm xuất phát
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(ox + cs * .1, oy + cs * .1, cs * .8, cs * .8),
            Radius.circular(cs * .2)),
        Paint()..color = const Color(0x55FFFFFF));

    _gate(canvas);

    // Tường = hàng rào: gom thành 1 Path, vẽ 2 nét (đậm + sáng) cho có chiều sâu.
    // Mỗi cạnh chung chỉ vẽ 1 lần (top/left của mọi ô + bottom hàng cuối + right cột cuối).
    final path = Path();
    for (var y = 0; y < maze.rows; y++) {
      for (var x = 0; x < maze.cols; x++) {
        final cell = maze.cells[y][x];
        final x0 = ox + x * cs, y0 = oy + y * cs;
        if (cell.top) {
          path.moveTo(x0, y0);
          path.lineTo(x0 + cs, y0);
        }
        if (cell.left) {
          path.moveTo(x0, y0);
          path.lineTo(x0, y0 + cs);
        }
        if (y == maze.rows - 1 && cell.bottom) {
          path.moveTo(x0, y0 + cs);
          path.lineTo(x0 + cs, y0 + cs);
        }
        if (x == maze.cols - 1 && cell.right) {
          path.moveTo(x0 + cs, y0);
          path.lineTo(x0 + cs, y0 + cs);
        }
      }
    }
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, stroke..color = theme.hedgeDark..strokeWidth = cs * .17);
    canvas.drawPath(path, stroke..color = theme.hedge..strokeWidth = cs * .11);
  }

  /// Cổng trường: xám khi khoá, vàng + phát sáng khi mở.
  void _gate(Canvas canvas) {
    final x0 = ox + maze.exit.x * cs, y0 = oy + maze.exit.y * cs;
    final col = exitOpen ? AppColors.gold : const Color(0xFF9E9E9E);
    final p = Paint()..color = col;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x0 + cs * .28, y0 + cs * .35, cs * .44, cs * .55),
            Radius.circular(cs * .05)),
        Paint()..color = exitOpen ? const Color(0x663FBF7F) : const Color(0x33000000));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x0 + cs * .14, y0 + cs * .3, cs * .14, cs * .62),
            Radius.circular(cs * .03)),
        p);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x0 + cs * .72, y0 + cs * .3, cs * .14, cs * .62),
            Radius.circular(cs * .03)),
        p);
    canvas.drawArc(
        Rect.fromLTWH(x0 + cs * .14, y0 + cs * .08, cs * .72, cs * .5),
        pi,
        pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cs * .1
          ..color = col);
    paintHeart(canvas, Offset(x0 + cs * .5, y0 + cs * .22), cs * .16,
        Paint()..color = exitOpen ? AppColors.rose : const Color(0xFFBDBDBD));
  }

  @override
  bool shouldRepaint(covariant _MazeStaticPainter old) =>
      old.maze != maze ||
      old.theme != theme ||
      old.exitOpen != exitOpen ||
      old.cs != cs ||
      old.ox != ox ||
      old.oy != oy;
}

class _ItemsPainter extends CustomPainter {
  final Maze? maze;
  final bool exitOpen, classroom;
  final double cs, ox, oy;
  final Animation<double> anim;

  _ItemsPainter({
    required this.maze,
    required this.exitOpen,
    required this.classroom,
    required this.cs,
    required this.ox,
    required this.oy,
    required this.anim,
  }) : super(repaint: anim);

  Offset _center(Point<int> p) => Offset(ox + (p.x + .5) * cs, oy + (p.y + .5) * cs);

  @override
  void paint(Canvas canvas, Size size) {
    final v = anim.value;
    if (classroom) {
      _hearts(canvas, v);
      return;
    }
    final m = maze!;
    final float = sin(v * 2 * pi) * cs * .07;
    final halo = Paint()..color = const Color(0x44FFFFFF);
    for (final p in m.flowers) {
      final c = _center(p).translate(0, float);
      canvas.drawCircle(c, cs * .34, halo);
      paintFlower(canvas, c, cs * .3);
    }
    for (final p in m.letters) {
      final c = _center(p).translate(0, -float);
      canvas.drawCircle(c, cs * .34, halo);
      paintLetter(canvas, c, cs * .3);
    }
    if (exitOpen) {
      final c = _center(m.exit);
      for (var i = 0; i < 3; i++) {
        final a = (sin((v + i / 3) * 2 * pi) + 1) / 2;
        _sparkle(canvas, c + Offset((i - 1) * cs * .38, -cs * (.3 + .12 * i)),
            cs * (.07 + .05 * a), (160 + 95 * a).round());
      }
    }
  }

  void _sparkle(Canvas canvas, Offset c, double r, int alpha) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r * 2)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r * 2, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r * 2)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r * 2, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r * 2);
    canvas.drawPath(path, Paint()..color = AppColors.gold.withAlpha(alpha));
  }

  /// Những trái tim bay lên từ chỗ thầy/cô đứng (ô 3,2).
  void _hearts(Canvas canvas, double v) {
    for (var i = 0; i < 5; i++) {
      final t = (v + i / 5) % 1.0;
      final x = ox + (3.5 + sin((t + i) * 2 * pi) * .5) * cs;
      final y = oy + (2.1 - t * 1.7) * cs;
      paintHeart(canvas, Offset(x, y), cs * .2,
          Paint()..color = AppColors.rose.withAlpha((230 * (1 - t)).round()));
    }
  }

  @override
  bool shouldRepaint(covariant _ItemsPainter old) =>
      old.maze != maze ||
      old.exitOpen != exitOpen ||
      old.classroom != classroom ||
      old.cs != cs ||
      old.ox != ox ||
      old.oy != oy;
}

/// Lớp học màn cuối: tường kem, sàn gỗ, bảng xanh "20/11", cờ hoa, thảm hồng.
class _ClassroomPainter extends CustomPainter {
  final int rows, cols;
  final double cs, ox, oy;
  _ClassroomPainter(this.rows, this.cols, this.cs, this.ox, this.oy);

  @override
  void paint(Canvas canvas, Size size) {
    final w = cs * cols, h = cs * rows;
    final wallH = cs * 2.6;
    canvas.drawRect(Rect.fromLTWH(ox, oy, w, wallH), Paint()..color = const Color(0xFFFFF0DC));
    // Sàn gỗ
    final plankA = Paint()..color = const Color(0xFFF1D6A8);
    final plankB = Paint()..color = const Color(0xFFE8C78F);
    var i = 0;
    for (var y = wallH; y < h; y += cs * .6) {
      canvas.drawRect(Rect.fromLTWH(ox, oy + y, w, min(cs * .6, h - y)),
          i.isEven ? plankA : plankB);
      i++;
    }
    // Thảm hồng dẫn tới cô/thầy
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(ox + 2.6 * cs, oy + 2.7 * cs, 1.8 * cs, 4.3 * cs),
            Radius.circular(cs * .2)),
        Paint()..color = const Color(0xFFFFB3C6));
    // Bảng xanh
    final board = RRect.fromRectAndRadius(
        Rect.fromLTWH(ox + 1.1 * cs, oy + .45 * cs, 4.8 * cs, 1.6 * cs),
        Radius.circular(cs * .1));
    canvas.drawRRect(board, Paint()..color = const Color(0xFF2F6B58));
    canvas.drawRRect(
        board,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cs * .12
          ..color = const Color(0xFF8D6E63));
    final tp = TextPainter(
      text: TextSpan(
        text: 'Tri ân thầy cô\n20/11',
        style: TextStyle(
            color: Colors.white,
            fontSize: cs * .42,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            height: 1.2),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 4.4 * cs);
    tp.paint(canvas,
        Offset(ox + 1.1 * cs + (4.8 * cs - tp.width) / 2, oy + .45 * cs + (1.6 * cs - tp.height) / 2));
    paintHeart(canvas, Offset(ox + 1.7 * cs, oy + 1.65 * cs), cs * .16,
        Paint()..color = const Color(0xFFFFB3C6));
    paintFlower(canvas, Offset(ox + 5.3 * cs, oy + 1.55 * cs), cs * .16);

    // Dây cờ hoa
    const flagColors = [AppColors.rose, AppColors.gold, Color(0xFF7BC8A4), Color(0xFFFFA8BE)];
    final flagW = cs * .42;
    var k = 0;
    for (var x = 0.0; x < w - flagW; x += flagW + cs * .08) {
      final sag = sin((x / w) * pi) * cs * .18;
      final top = oy + cs * .08 + sag;
      canvas.drawPath(
          Path()
            ..moveTo(ox + x, top)
            ..lineTo(ox + x + flagW, top)
            ..lineTo(ox + x + flagW / 2, top + cs * .32)
            ..close(),
          Paint()..color = flagColors[k++ % flagColors.length]);
    }
  }

  @override
  bool shouldRepaint(covariant _ClassroomPainter old) =>
      old.cs != cs || old.ox != ox || old.oy != oy;
}

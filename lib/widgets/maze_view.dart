import 'dart:math';
import 'package:flutter/material.dart';
import '../services/maze_generator.dart';
import '../models/teacher.dart';

class MazeView extends StatefulWidget {
  final Maze maze;
  final Point<int> player;
  final bool exitOpen;
  final bool isFinalRoom;
  final Teacher teacher;

  const MazeView({
    super.key,
    required this.maze,
    required this.player,
    required this.exitOpen,
    this.isFinalRoom = false,
    required this.teacher,
  });

  @override
  State<MazeView> createState() => _MazeViewState();
}

class _MazeViewState extends State<MazeView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      final cs = min(size.width / widget.maze.cols, size.height / widget.maze.rows);
      final ox = (size.width - cs * widget.maze.cols) / 2;
      final oy = (size.height - cs * widget.maze.rows) / 2;

      return Container(
        color: const Color(0xFFFFF8E1),
        child: Stack(
          children: [
            // Static background (walls, items) with floating animation
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _StaticMazePainter(
                      widget.maze, widget.exitOpen, widget.isFinalRoom, cs, ox, oy, _controller.value
                    ),
                  );
                }
              ),
            ),
            // Teacher (in final room)
            if (widget.isFinalRoom)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                left: ox + 3 * cs,
                top: oy + 2 * cs,
                width: cs,
                height: cs,
                child: CustomPaint(
                  painter: _HumanPainter(
                    color: Colors.purple,
                    isFemale: !widget.teacher.isMale,
                    hasFlower: false,
                    isTeacher: true,
                  ),
                ),
              ),
            // Player
            AnimatedPositioned(
              duration: const Duration(milliseconds: 120),
              curve: Curves.linear,
              left: ox + widget.player.x * cs,
              top: oy + widget.player.y * cs,
              width: cs,
              height: cs,
              child: CustomPaint(
                painter: _HumanPainter(
                  color: Colors.blue,
                  isFemale: false,
                  hasFlower: widget.isFinalRoom,
                  isTeacher: false,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _HumanPainter extends CustomPainter {
  final Color color;
  final bool isFemale;
  final bool hasFlower;
  final bool isTeacher;

  _HumanPainter({required this.color, this.isFemale = false, this.hasFlower = false, this.isTeacher = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final skinColor = const Color(0xFFFFCC99);
    final hairColor = Colors.black87;
    final shirtColor = isTeacher ? (isFemale ? Colors.pinkAccent : Colors.teal) : Colors.blueAccent;
    final pantsColor = Colors.indigo.shade900;

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round;

    // Hair Back (for female)
    if (isFemale) {
      fillPaint.color = hairColor;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(cx - w*0.22, h*0.25, cx + w*0.22, h*0.55), Radius.circular(w*0.05)), fillPaint);
    }

    // Head
    fillPaint.color = skinColor;
    canvas.drawCircle(Offset(cx, h * 0.25), w * 0.18, fillPaint);

    // Hair Top
    fillPaint.color = hairColor;
    if (isFemale) {
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, h * 0.25), radius: w * 0.2), pi, pi, true, fillPaint);
    } else {
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, h * 0.22), radius: w * 0.19), pi, pi, true, fillPaint);
    }

    // Eyes
    fillPaint.color = Colors.black87;
    canvas.drawCircle(Offset(cx - w * 0.06, h * 0.23), w * 0.025, fillPaint);
    canvas.drawCircle(Offset(cx + w * 0.06, h * 0.23), w * 0.025, fillPaint);

    // Smile
    strokePaint.color = Colors.black87;
    strokePaint.strokeWidth = w * 0.02;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, h * 0.26), radius: w * 0.06), 0, pi, false, strokePaint);
    strokePaint.strokeWidth = w * 0.06; // reset

    // Body & Legs
    if (isFemale) {
      // Ao Dai / Dress
      fillPaint.color = shirtColor;
      final path = Path()
        ..moveTo(cx - w * 0.15, h * 0.4)
        ..lineTo(cx + w * 0.15, h * 0.4)
        ..lineTo(cx + w * 0.25, h * 0.85)
        ..lineTo(cx - w * 0.25, h * 0.85)
        ..close();
      canvas.drawPath(path, fillPaint);
      // Legs
      strokePaint.color = skinColor;
      canvas.drawLine(Offset(cx - w * 0.1, h * 0.85), Offset(cx - w * 0.1, h * 0.95), strokePaint);
      canvas.drawLine(Offset(cx + w * 0.1, h * 0.85), Offset(cx + w * 0.1, h * 0.95), strokePaint);
    } else {
      // Shirt
      fillPaint.color = shirtColor;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(cx - w*0.18, h*0.4, cx + w*0.18, h*0.65), Radius.circular(w*0.05)), fillPaint);
      // Pants
      fillPaint.color = pantsColor;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(cx - w*0.18, h*0.65, cx + w*0.18, h*0.75), Radius.circular(w*0.02)), fillPaint);
      // Legs
      strokePaint.color = pantsColor;
      canvas.drawLine(Offset(cx - w * 0.08, h * 0.75), Offset(cx - w * 0.08, h * 0.95), strokePaint);
      canvas.drawLine(Offset(cx + w * 0.08, h * 0.75), Offset(cx + w * 0.08, h * 0.95), strokePaint);
    }

    // Arms
    strokePaint.color = skinColor;
    if (hasFlower) {
      // Right arm holding flower
      canvas.drawLine(Offset(cx + w * 0.15, h * 0.45), Offset(cx + w * 0.35, h * 0.4), strokePaint);
      // Left arm down
      canvas.drawLine(Offset(cx - w * 0.15, h * 0.45), Offset(cx - w * 0.25, h * 0.6), strokePaint);
      // Draw flower
      _drawFlower(canvas, Offset(cx + w * 0.4, h * 0.35), w * 0.15);
    } else {
      canvas.drawLine(Offset(cx - w * 0.15, h * 0.45), Offset(cx - w * 0.25, h * 0.6), strokePaint);
      canvas.drawLine(Offset(cx + w * 0.15, h * 0.45), Offset(cx + w * 0.25, h * 0.6), strokePaint);
    }
  }

  void _drawFlower(Canvas canvas, Offset o, double r) {
    final petal = Paint()..color = Colors.pinkAccent;
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * pi / 5;
      canvas.drawCircle(o + Offset(cos(a), sin(a)) * r * 0.55, r * 0.4, petal);
    }
    canvas.drawCircle(o, r * 0.3, Paint()..color = Colors.amber);
  }

  @override
  bool shouldRepaint(covariant _HumanPainter old) =>
      old.color != color || old.isFemale != isFemale || old.hasFlower != hasFlower || old.isTeacher != isTeacher;
}

class _StaticMazePainter extends CustomPainter {
  final Maze maze;
  final bool exitOpen;
  final bool isFinalRoom;
  final double cs, ox, oy;
  final double animationValue;

  _StaticMazePainter(this.maze, this.exitOpen, this.isFinalRoom, this.cs, this.ox, this.oy, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    Offset center(Point<int> p) => Offset(ox + (p.x + 0.5) * cs, oy + (p.y + 0.5) * cs);
    final floatOffset = sin(animationValue * 2 * pi) * (cs * 0.15);

    if (!isFinalRoom) {
      // Exit
      final er = Rect.fromCenter(center: center(maze.exit), width: cs * 0.75, height: cs * 0.75);
      canvas.drawRRect(RRect.fromRectAndRadius(er, Radius.circular(cs * 0.15)),
          Paint()..color = exitOpen ? Colors.green : Colors.grey);
      final c = center(maze.exit);
      canvas.drawLine(Offset(c.dx - cs * 0.12, c.dy - cs * 0.25),
          Offset(c.dx - cs * 0.12, c.dy + cs * 0.25),
          Paint()..color = Colors.white..strokeWidth = max(2, cs * 0.06));
      canvas.drawPath(
          Path()
            ..moveTo(c.dx - cs * 0.12, c.dy - cs * 0.25)
            ..lineTo(c.dx + cs * 0.22, c.dy - cs * 0.1)
            ..lineTo(c.dx - cs * 0.12, c.dy + 0.0),
          Paint()..color = Colors.white);

      // Walls
      final wall = Paint()
        ..color = const Color(0xFF6D4C41)
        ..strokeWidth = max(2, cs * 0.08)
        ..strokeCap = StrokeCap.round;
      for (var y = 0; y < maze.rows; y++) {
        for (var x = 0; x < maze.cols; x++) {
          final cell = maze.cells[y][x];
          final x0 = ox + x * cs, y0 = oy + y * cs;
          if (cell.top) canvas.drawLine(Offset(x0, y0), Offset(x0 + cs, y0), wall);
          if (cell.right) canvas.drawLine(Offset(x0 + cs, y0), Offset(x0 + cs, y0 + cs), wall);
          if (cell.bottom) canvas.drawLine(Offset(x0, y0 + cs), Offset(x0 + cs, y0 + cs), wall);
          if (cell.left) canvas.drawLine(Offset(x0, y0), Offset(x0, y0 + cs), wall);
        }
      }

      // Flowers and letters with floating effect
      for (final p in maze.flowers) {
        _drawFlower(canvas, center(p).translate(0, floatOffset), cs * 0.32);
      }
      for (final p in maze.letters) {
        _letter(canvas, center(p).translate(0, -floatOffset), cs * 0.32);
      }
    }
  }

  void _drawFlower(Canvas canvas, Offset o, double r) {
    final petal = Paint()..color = Colors.pinkAccent;
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * pi / 5;
      canvas.drawCircle(o + Offset(cos(a), sin(a)) * r * 0.55, r * 0.4, petal);
    }
    canvas.drawCircle(o, r * 0.3, Paint()..color = Colors.amber);
  }

  void _letter(Canvas canvas, Offset o, double r) {
    final rect = Rect.fromCenter(center: o, width: r * 1.8, height: r * 1.3);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(2));
    canvas.drawRRect(rr, Paint()..color = Colors.white);
    final line = Paint()
      ..color = Colors.deepOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, r * 0.12);
    canvas.drawRRect(rr, line);
    canvas.drawPath(
        Path()
          ..moveTo(rect.left, rect.top)
          ..lineTo(o.dx, o.dy + r * 0.1)
          ..lineTo(rect.right, rect.top),
        line);
  }

  @override
  bool shouldRepaint(covariant _StaticMazePainter old) => old.animationValue != animationValue;
}

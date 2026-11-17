import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Các hình vẽ dùng chung (nhân vật, hoa, thư, tim). Vẽ bằng Canvas nên không cần asset.

Path heartPath(Size size) {
  final w = size.width, h = size.height;
  return Path()
    ..moveTo(w / 2, h * 0.9)
    ..cubicTo(-w * 0.2, h * 0.4, w * 0.15, -h * 0.2, w / 2, h * 0.3)
    ..cubicTo(w * 0.85, -h * 0.2, w * 1.2, h * 0.4, w / 2, h * 0.9)
    ..close();
}

void paintHeart(Canvas c, Offset o, double s, Paint p) {
  final path = Path()
    ..moveTo(o.dx, o.dy + s * 0.35)
    ..cubicTo(o.dx - s * 0.9, o.dy - s * 0.1, o.dx - s * 0.45, o.dy - s * 0.7,
        o.dx, o.dy - s * 0.25)
    ..cubicTo(o.dx + s * 0.45, o.dy - s * 0.7, o.dx + s * 0.9, o.dy - s * 0.1,
        o.dx, o.dy + s * 0.35);
  c.drawPath(path, p);
}

void paintFlower(Canvas c, Offset o, double r,
    {Color petal = const Color(0xFFFF6F91), Color core = AppColors.gold}) {
  final p = Paint()..color = petal;
  for (var i = 0; i < 6; i++) {
    final a = i * pi / 3;
    c.drawCircle(o + Offset(cos(a), sin(a)) * r * 0.55, r * 0.42, p);
  }
  c.drawCircle(o, r * 0.36, Paint()..color = core);
  c.drawCircle(o.translate(-r * 0.09, -r * 0.09), r * 0.1,
      Paint()..color = const Color(0x88FFFFFF));
}

void paintLetter(Canvas c, Offset o, double r) {
  final rect = Rect.fromCenter(center: o, width: r * 1.9, height: r * 1.35);
  final rr = RRect.fromRectAndRadius(rect, Radius.circular(r * 0.14));
  c.drawRRect(rr, Paint()..color = const Color(0xFFFFFDF5));
  final edge = Paint()
    ..color = AppColors.gold
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(1.5, r * 0.1);
  c.drawRRect(rr, edge);
  c.drawPath(
      Path()
        ..moveTo(rect.left, rect.top)
        ..lineTo(o.dx, o.dy + r * 0.1)
        ..lineTo(rect.right, rect.top),
      edge);
  paintHeart(c, Offset(o.dx, o.dy + r * 0.12), r * 0.42,
      Paint()..color = AppColors.rose);
}

enum CharacterKind { student, teacherFemale, teacherMale }

/// Nhân vật chibi: học sinh (khăn quàng đỏ), cô giáo (áo dài), thầy giáo (cà vạt, kính).
class CharacterPainter extends CustomPainter {
  final CharacterKind kind;
  final bool hasFlower; // cầm bó hoa
  final bool bust; // true: zoom vào mặt + vai (dùng làm avatar tròn)
  const CharacterPainter(this.kind, {this.hasFlower = false, this.bust = false});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    Offset pt(double x, double y) => Offset(x * s, y * s);
    Paint f(Color c) => Paint()..color = c;
    final skin = f(const Color(0xFFFFD7B5));
    final hair = f(const Color(0xFF3B2A2A));
    final armPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.06
      ..color = const Color(0xFFFFD7B5);

    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    if (bust) {
      canvas.translate(s / 2, s / 2);
      canvas.scale(1.9);
      canvas.translate(-s / 2, -s * 0.42);
    }

    // Bóng dưới chân
    canvas.drawOval(
        Rect.fromCenter(center: pt(.5, .95), width: s * .45, height: s * .08),
        f(const Color(0x22000000)));

    // Chân + giày
    final pants = switch (kind) {
      CharacterKind.student => const Color(0xFF30487F),
      CharacterKind.teacherFemale => const Color(0xFFF7F3EE),
      CharacterKind.teacherMale => const Color(0xFF4E5A6B),
    };
    for (final lx in [.34, .51]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTRB(s * lx, s * .64, s * (lx + .15), s * .92),
              Radius.circular(s * .04)),
          f(pants));
    }
    for (final cx in [.41, .59]) {
      canvas.drawOval(
          Rect.fromCenter(center: pt(cx, .93), width: s * .17, height: s * .06),
          f(const Color(0xFF3A2E2E)));
    }

    // Thân áo
    if (kind == CharacterKind.teacherFemale) {
      final dress = Path()
        ..moveTo(s * .36, s * .48)
        ..lineTo(s * .64, s * .48)
        ..lineTo(s * .62, s * .62)
        ..lineTo(s * .70, s * .87)
        ..lineTo(s * .30, s * .87)
        ..lineTo(s * .38, s * .62)
        ..close();
      canvas.drawPath(dress, f(AppColors.rose));
      canvas.drawLine(
          pt(.5, .6),
          pt(.5, .87),
          Paint()
            ..color = const Color(0x55FFFFFF)
            ..strokeWidth = s * .012);
      canvas.drawPath(
          Path()
            ..moveTo(s * .44, s * .48)
            ..lineTo(s * .5, s * .55)
            ..lineTo(s * .56, s * .48),
          Paint()
            ..color = AppColors.gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * .018);
    } else {
      final shirt = RRect.fromRectAndRadius(
          Rect.fromLTRB(s * .31, s * .48, s * .69, s * .7), Radius.circular(s * .07));
      canvas.drawRRect(shirt, f(Colors.white));
      canvas.drawRRect(
          shirt,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = const Color(0xFFE6DADA)
            ..strokeWidth = s * .012);
      if (kind == CharacterKind.student) {
        // Khăn quàng đỏ
        canvas.drawPath(
            Path()
              ..moveTo(s * .4, s * .49)
              ..lineTo(s * .6, s * .49)
              ..lineTo(s * .5, s * .66)
              ..close(),
            f(const Color(0xFFD32F2F)));
      } else {
        // Cà vạt
        canvas.drawPath(
            Path()
              ..moveTo(s * .47, s * .49)
              ..lineTo(s * .53, s * .49)
              ..lineTo(s * .55, s * .64)
              ..lineTo(s * .5, s * .68)
              ..lineTo(s * .45, s * .64)
              ..close(),
            f(AppColors.roseDark));
      }
    }

    // Tay
    canvas.drawLine(pt(.32, .53), pt(.25, .67), armPaint);
    if (hasFlower) {
      canvas.drawLine(pt(.68, .53), pt(.78, .47), armPaint);
      final stem = Paint()
        ..color = AppColors.leaf
        ..strokeWidth = s * .03
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(pt(.78, .49), pt(.83, .36), stem);
      canvas.drawLine(pt(.78, .49), pt(.75, .38), stem);
      paintFlower(canvas, pt(.75, .33), s * .09, petal: const Color(0xFFFFA8BE));
      paintFlower(canvas, pt(.85, .31), s * .1);
    } else {
      canvas.drawLine(pt(.68, .53), pt(.75, .67), armPaint);
    }

    // Tóc sau (nữ)
    if (kind == CharacterKind.teacherFemale) {
      canvas.drawCircle(pt(.5, .09), s * .075, hair); // búi tóc
      canvas.drawOval(
          Rect.fromCenter(center: pt(.3, .36), width: s * .08, height: s * .2), hair);
      canvas.drawOval(
          Rect.fromCenter(center: pt(.7, .36), width: s * .08, height: s * .2), hair);
    }

    // Đầu
    final head = pt(.5, .3);
    canvas.drawCircle(head, s * .2, skin);
    canvas.drawArc(Rect.fromCircle(center: pt(.5, .28), radius: s * .21), pi, pi,
        true, hair);

    // Mặt
    for (final ex in [.43, .57]) {
      canvas.drawOval(
          Rect.fromCenter(center: pt(ex, .33), width: s * .04, height: s * .05),
          f(const Color(0xFF2B1D1D)));
    }
    for (final cx in [.36, .64]) {
      canvas.drawCircle(pt(cx, .385), s * .035, f(const Color(0x66FF6F91)));
    }
    canvas.drawArc(
        Rect.fromCenter(center: pt(.5, .375), width: s * .1, height: s * .07),
        0,
        pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = s * .014
          ..color = const Color(0xFF2B1D1D));

    // Kính (thầy)
    if (kind == CharacterKind.teacherMale) {
      final g = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .014
        ..color = const Color(0xFF3A2E2E);
      canvas.drawCircle(pt(.43, .33), s * .05, g);
      canvas.drawCircle(pt(.57, .33), s * .05, g);
      canvas.drawLine(pt(.48, .33), pt(.52, .33), g);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CharacterPainter old) =>
      old.kind != kind || old.hasFlower != hasFlower || old.bust != bust;
}

/// Icon hoa / thư nhỏ dùng trong HUD và màn hình tri ân.
class FlowerIcon extends StatelessWidget {
  final double size;
  const FlowerIcon({super.key, this.size = 22});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: size, height: size, child: CustomPaint(painter: _IconPainter(false)));
}

class LetterIcon extends StatelessWidget {
  final double size;
  const LetterIcon({super.key, this.size = 22});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: size, height: size, child: CustomPaint(painter: _IconPainter(true)));
}

class _IconPainter extends CustomPainter {
  final bool letter;
  const _IconPainter(this.letter);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    if (letter) {
      paintLetter(canvas, c, size.width * 0.42);
    } else {
      paintFlower(canvas, c, size.width * 0.4);
    }
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) => false;
}

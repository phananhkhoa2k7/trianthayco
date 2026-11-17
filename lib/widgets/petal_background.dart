import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class _Petal {
  final double x, phase, size, rot;
  final int speed, sway; // số nguyên => vòng lặp liền mạch
  final Paint paint;
  _Petal(this.x, this.phase, this.size, this.rot, this.speed, this.sway, Color c)
      : paint = Paint()..color = c;
}

/// Nền gradient kem-hồng với cánh hoa rơi chậm.
/// Chỉ 1 AnimationController + 1 CustomPaint (repaint theo controller),
/// tách RepaintBoundary nên không kéo theo vẽ lại phần còn lại của màn hình.
class PetalBackground extends StatefulWidget {
  final Widget child;
  final int petals;
  const PetalBackground({super.key, required this.child, this.petals = 12});

  @override
  State<PetalBackground> createState() => _PetalBackgroundState();
}

class _PetalBackgroundState extends State<PetalBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 60))
        ..repeat();
  late final List<_Petal> _petals = _make();

  List<_Petal> _make() {
    final r = Random(11);
    const colors = [Color(0x66FF8FA3), Color(0x66FFB3C1), Color(0x55F4B942), Color(0x66FFC4D0)];
    return List.generate(
      widget.petals,
      (i) => _Petal(r.nextDouble(), r.nextDouble(), 6 + r.nextDouble() * 8,
          r.nextDouble() * pi, 1 + r.nextInt(2), 3 + r.nextInt(4),
          colors[r.nextInt(colors.length)]),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.cream, Color(0xFFFFE9EC)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.petals > 0)
            RepaintBoundary(
              child: IgnorePointer(
                child: CustomPaint(painter: _PetalPainter(_petals, _ctrl)),
              ),
            ),
          widget.child,
        ],
      ),
    );
  }
}

class _PetalPainter extends CustomPainter {
  final List<_Petal> petals;
  final Animation<double> anim;
  _PetalPainter(this.petals, this.anim) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in petals) {
      final t = (anim.value * p.speed + p.phase) % 1.0;
      final y = t * (size.height + 40) - 20;
      final x = p.x * size.width +
          sin((anim.value * p.sway + p.phase) * 2 * pi) * 28;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rot + t * 2 * pi);
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.6),
          p.paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PetalPainter old) => false;
}

import 'dart:math';

import 'package:flutter/material.dart';

import '../models/teacher.dart';
import '../theme/app_theme.dart';
import 'sprites.dart';

/// Ảnh đại diện: dùng avatarUrl nếu có, ngược lại vẽ nhân vật hoạt hình (thầy/cô).
class TeacherAvatar extends StatelessWidget {
  final Teacher teacher;
  final double radius;
  const TeacherAvatar({super.key, required this.teacher, this.radius = 28});

  @override
  Widget build(BuildContext context) {
    final kind =
        teacher.isMale ? CharacterKind.teacherMale : CharacterKind.teacherFemale;
    final character = RepaintBoundary(
      child: CustomPaint(painter: CharacterPainter(kind, bust: true)),
    );
    final url = teacher.avatarUrl;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blush, Color(0xFFFFE9B8)],
        ),
        border: Border.all(color: AppColors.gold, width: max(2, radius * 0.07)),
        boxShadow: kSoftShadow,
      ),
      child: ClipOval(
        child: url == null
            ? character
            : Image.network(url, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => character),
      ),
    );
  }
}

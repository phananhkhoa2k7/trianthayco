import 'package:flutter/material.dart';

import '../models/teacher.dart';

/// Ảnh đại diện: dùng avatarUrl nếu có, ngược lại hiển thị chữ cái đầu (placeholder).
class TeacherAvatar extends StatelessWidget {
  final Teacher teacher;
  final double radius;
  const TeacherAvatar({super.key, required this.teacher, this.radius = 28});

  @override
  Widget build(BuildContext context) {
    final url = teacher.avatarUrl;
    if (url != null) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(url));
    }
    // Màu nền ổn định theo id để mỗi thầy/cô một màu.
    final color = Colors.primaries[teacher.id.hashCode.abs() % Colors.primaries.length];
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.shade300,
      child: Text(
        teacher.initial,
        style: TextStyle(
            fontSize: radius * 0.9,
            color: Colors.white,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

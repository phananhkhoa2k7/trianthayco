import 'package:flutter/material.dart';

import '../models/teacher.dart';
import '../widgets/mute_button.dart';
import '../widgets/petal_background.dart';
import '../widgets/teacher_detail_panel.dart';

/// Màn hình chi tiết giáo viên dùng trên mobile.
class TeacherDetailScreen extends StatelessWidget {
  final Teacher teacher;
  const TeacherDetailScreen({super.key, required this.teacher});

  @override
  Widget build(BuildContext context) {
    return PetalBackground(
      petals: 8,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(teacher.displayName),
          actions: const [MuteButton()],
        ),
        body: TeacherDetailPanel(teacher: teacher),
      ),
    );
  }
}

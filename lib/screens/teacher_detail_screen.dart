import 'package:flutter/material.dart';

import '../models/teacher.dart';
import '../widgets/teacher_detail_panel.dart';

/// Màn hình chi tiết giáo viên dùng trên mobile.
class TeacherDetailScreen extends StatelessWidget {
  final Teacher teacher;
  const TeacherDetailScreen({super.key, required this.teacher});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(teacher.displayName)),
      body: TeacherDetailPanel(teacher: teacher),
    );
  }
}

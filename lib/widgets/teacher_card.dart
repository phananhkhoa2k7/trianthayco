import 'package:flutter/material.dart';

import '../models/teacher.dart';
import 'teacher_avatar.dart';

/// Thẻ giáo viên trong danh sách.
class TeacherCard extends StatelessWidget {
  final Teacher teacher;
  final bool selected;
  final VoidCallback onTap;
  const TeacherCard({
    super.key,
    required this.teacher,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: selected ? cs.primaryContainer : null,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: TeacherAvatar(teacher: teacher),
        title: Text(teacher.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${teacher.degree} • ${teacher.department}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

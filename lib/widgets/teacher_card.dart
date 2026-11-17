import 'package:flutter/material.dart';

import '../models/teacher.dart';
import '../theme/app_theme.dart';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Material(
        color: selected ? AppColors.blush : Colors.white,
        elevation: 0,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: selected ? AppColors.rose : AppColors.rose.withAlpha(30),
                  width: selected ? 2 : 1),
              boxShadow: selected ? null : kSoftShadow,
            ),
            child: Row(
              children: [
                TeacherAvatar(teacher: teacher, radius: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(teacher.displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('${teacher.degree} · ${teacher.major}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.favorite_border_rounded, color: AppColors.rose),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

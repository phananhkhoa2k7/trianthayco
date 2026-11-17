import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gift.dart';
import '../models/teacher.dart';
import '../screens/game_screen.dart';
import '../services/teacher_gift_repository.dart';
import '../theme/app_theme.dart';
import 'gift_summary_view.dart';
import 'sprites.dart';
import 'teacher_avatar.dart';

/// Chi tiết một giáo viên + nút chơi game + quà đã nhận.
/// Dùng chung cho cột phải (desktop) và màn hình riêng (mobile).
class TeacherDetailPanel extends StatefulWidget {
  final Teacher teacher;
  const TeacherDetailPanel({super.key, required this.teacher});

  @override
  State<TeacherDetailPanel> createState() => _TeacherDetailPanelState();
}

class _TeacherDetailPanelState extends State<TeacherDetailPanel> {
  late Future<GiftSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<GiftSummary> _load() =>
      context.read<TeacherGiftRepository>().getSummary(widget.teacher.id);

  Future<void> _play() async {
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => GameScreen(teacher: widget.teacher)));
    if (mounted) setState(() => _future = _load()); // tải lại số liệu mới
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.teacher;
    final h = t.honorific.toLowerCase();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thiệp giới thiệu
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.rose.withAlpha(50), width: 2),
                  boxShadow: kSoftShadow,
                ),
                child: Column(
                  children: [
                    TeacherAvatar(teacher: t, radius: 56),
                    const SizedBox(height: 12),
                    Text(t.displayName,
                        textAlign: TextAlign.center, style: scriptStyle(36)),
                    Text('${t.degree} · ${t.department}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const Divider(height: 28),
                    _row(Icons.cake_rounded, 'Năm sinh', '${t.birthYear}'),
                    _row(Icons.school_rounded, 'Học vị', t.degree),
                    _row(Icons.menu_book_rounded, 'Chuyên ngành', t.major),
                    _row(Icons.apartment_rounded, 'Khoa/Bộ môn', t.department),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Học phần giảng dạy',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final c in t.courses)
                            Chip(
                                label: Text(c, style: const TextStyle(fontSize: 12)),
                                visualDensity: VisualDensity.compact),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: FilledButton.icon(
                  onPressed: _play,
                  icon: const FlowerIcon(size: 24),
                  label: Text('Tặng hoa cho $h'),
                ),
              ),
              const SizedBox(height: 28),
              Text('Món quà $h đã nhận', style: scriptStyle(30)),
              const SizedBox(height: 12),
              FutureBuilder<GiftSummary>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    return Text('Không tải được dữ liệu: ${snap.error}');
                  }
                  return GiftSummaryView(summary: snap.data!);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.rose),
            const SizedBox(width: 8),
            SizedBox(
                width: 110,
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: Text(value)),
          ],
        ),
      );
}

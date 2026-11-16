import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gift.dart';
import '../models/teacher.dart';
import '../screens/game_screen.dart';
import '../services/teacher_gift_repository.dart';
import 'gift_summary_view.dart';
import 'teacher_avatar.dart';

/// Nội dung chi tiết một giáo viên + nút chơi game + quà đã nhận.
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
    // Quay lại sau khi chơi => tải lại số liệu mới.
    if (mounted) setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.teacher;
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: TeacherAvatar(teacher: t, radius: 56)),
              const SizedBox(height: 12),
              Center(child: Text(t.displayName, style: text.headlineSmall)),
              const SizedBox(height: 16),
              _row(Icons.cake, 'Năm sinh', '${t.birthYear}'),
              _row(Icons.school, 'Học vị', t.degree),
              _row(Icons.menu_book, 'Chuyên ngành', t.major),
              _row(Icons.apartment, 'Khoa/Bộ môn', t.department),
              const SizedBox(height: 8),
              Text('Học phần giảng dạy', style: text.titleSmall),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [for (final c in t.courses) Chip(label: Text(c))],
              ),
              const SizedBox(height: 20),
              Center(
                child: FilledButton.icon(
                  onPressed: _play,
                  icon: const Icon(Icons.local_florist),
                  label: Text('Tặng hoa cho ${t.honorific.toLowerCase()}'),
                ),
              ),
              const Divider(height: 40),
              Text('Quà ${t.honorific.toLowerCase()} đã nhận',
                  style: text.titleLarge),
              const SizedBox(height: 12),
              FutureBuilder<GiftSummary>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
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
            Icon(icon, size: 20),
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

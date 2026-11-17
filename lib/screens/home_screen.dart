import 'dart:math';

import 'package:flutter/material.dart';

import '../data/teachers.dart';
import '../data/wishes.dart';
import '../models/teacher.dart';
import '../theme/app_theme.dart';
import '../utils/text_utils.dart';
import '../widgets/mute_button.dart';
import '../widgets/petal_background.dart';
import '../widgets/sprites.dart';
import '../widgets/teacher_card.dart';
import '../widgets/teacher_detail_panel.dart';
import 'teacher_detail_screen.dart';

/// Trang chủ: danh sách giáo viên (tìm kiếm không dấu + lọc theo khoa).
/// Desktop (>= 900px): 2 cột. Mobile: danh sách -> màn hình chi tiết.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _wideBreakpoint = 900;

  // Tính 1 lần: danh sách khoa + chuỗi tìm kiếm đã bỏ dấu của từng giáo viên.
  static final List<String> _departments =
      kTeachers.map((t) => t.department).toSet().toList();
  static final Map<String, String> _searchIndex = {
    for (final t in kTeachers)
      t.id: foldVietnamese('${t.name} ${t.major} ${t.courses.join(' ')}'),
  };

  late final String _quote = kQuotes[Random().nextInt(kQuotes.length)];
  String? _department;
  Teacher? _selected;
  List<Teacher> _filtered = kTeachers;
  String _query = '';

  /// Chỉ tính lại danh sách lọc khi người dùng đổi từ khoá/khoa (không tính trong build).
  void _applyFilter() {
    final q = foldVietnamese(_query.trim());
    _filtered = kTeachers.where((t) {
      final okDept = _department == null || t.department == _department;
      final okQuery = q.isEmpty || _searchIndex[t.id]!.contains(q);
      return okDept && okQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= _wideBreakpoint;
      final list = _filtered;
      final selected = wide
          ? (list.contains(_selected)
              ? _selected
              : (list.isEmpty ? null : list.first))
          : null;

      return PetalBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: wide
              ? Row(
                  children: [
                    SizedBox(width: 420, child: _buildListColumn(list, selected, true)),
                    Expanded(
                      child: SafeArea(
                        child: selected == null
                            ? const Center(child: Text('Không có giáo viên phù hợp'))
                            // key theo id để panel tải lại dữ liệu khi đổi giáo viên
                            : TeacherDetailPanel(
                                key: ValueKey(selected.id), teacher: selected),
                      ),
                    ),
                  ],
                )
              : _buildListColumn(list, null, false),
        ),
      );
    });
  }

  Widget _buildListColumn(List<Teacher> list, Teacher? selected, bool wide) {
    return Column(
      children: [
        _Hero(quote: _quote),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Tìm thầy cô (gõ không dấu cũng được)...',
              isDense: true,
            ),
            onChanged: (v) => setState(() {
              _query = v;
              _applyFilter();
            }),
          ),
        ),
        if (_departments.length > 1)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final d in [null, ..._departments])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(d ?? 'Tất cả'),
                      selected: _department == d,
                      onSelected: (_) => setState(() {
                        _department = d;
                        _applyFilter();
                      }),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('Không tìm thấy giáo viên'))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final t = list[i];
                    return TeacherCard(
                      teacher: t,
                      selected: wide && t.id == selected?.id,
                      onTap: () {
                        if (wide) {
                          setState(() => _selected = t);
                        } else {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => TeacherDetailScreen(teacher: t)));
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Phần đầu trang: lời chào, đếm ngược 20/11 và câu tục ngữ.
class _Hero extends StatelessWidget {
  final String quote;
  const _Hero({required this.quote});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.rose, Color(0xFFF4A261)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: RepaintBoundary(child: CustomPaint(painter: _HeroDecor())),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: MuteButton(color: Colors.white),
                    ),
                    Text('Tri ân thầy cô',
                        style: scriptStyle(44, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(occasionLine(DateTime.now()),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(46),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('“$quote”',
                          style: const TextStyle(
                              color: Colors.white, fontStyle: FontStyle.italic)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chọn một thầy/cô, vượt 3 ải mê cung và gửi tặng hoa cùng lời chúc.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroDecor extends CustomPainter {
  const _HeroDecor();
  @override
  void paint(Canvas canvas, Size size) {
    const soft = Color(0x33FFFFFF);
    paintFlower(canvas, Offset(size.width - 30, 36), 46, petal: soft, core: const Color(0x44FFFFFF));
    paintFlower(canvas, Offset(size.width - 96, size.height - 22), 30, petal: soft, core: const Color(0x44FFFFFF));
    paintFlower(canvas, const Offset(24, 20), 22, petal: soft, core: const Color(0x44FFFFFF));
  }

  @override
  bool shouldRepaint(covariant _HeroDecor old) => false;
}

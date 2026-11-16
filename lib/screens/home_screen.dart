import 'package:flutter/material.dart';

import '../data/teachers.dart';
import '../models/teacher.dart';
import '../widgets/teacher_card.dart';
import '../widgets/teacher_detail_panel.dart';
import 'teacher_detail_screen.dart';

/// Trang chủ: danh sách giáo viên (tìm kiếm + lọc theo khoa).
/// Desktop (>= 900px): 2 cột (danh sách | chi tiết). Mobile: danh sách -> màn hình chi tiết.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _wideBreakpoint = 900;

  String _query = '';
  String? _department; // null = tất cả
  Teacher? _selected;

  List<String> get _departments =>
      kTeachers.map((t) => t.department).toSet().toList();

  List<Teacher> get _filtered {
    final q = _query.trim().toLowerCase();
    return kTeachers.where((t) {
      final okDept = _department == null || t.department == _department;
      final okQuery = q.isEmpty ||
          t.name.toLowerCase().contains(q) ||
          t.major.toLowerCase().contains(q) ||
          t.courses.any((c) => c.toLowerCase().contains(q));
      return okDept && okQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= _wideBreakpoint;
      final list = _filtered;
      // Desktop: luôn có 1 giáo viên được chọn (mặc định là người đầu danh sách).
      final selected = wide
          ? (list.contains(_selected)
              ? _selected
              : (list.isEmpty ? null : list.first))
          : null;

      return Scaffold(
        body: wide
            ? Row(
                children: [
                  SizedBox(width: 400, child: _buildListColumn(list, selected, true)),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: selected == null
                        ? const Center(child: Text('Không có giáo viên phù hợp'))
                        // key theo id để panel tải lại dữ liệu khi đổi giáo viên
                        : TeacherDetailPanel(
                            key: ValueKey(selected.id), teacher: selected),
                  ),
                ],
              )
            : _buildListColumn(list, null, false),
      );
    });
  }

  Widget _buildListColumn(List<Teacher> list, Teacher? selected, bool wide) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [cs.primary, Colors.orange.shade400]),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tri ân thầy cô 20/11',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Chọn một thầy/cô và chơi mê cung để gửi tặng hoa & lời chúc',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm theo tên, chuyên ngành, học phần...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // Lọc theo khoa
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: _department == null,
                    onSelected: (_) => setState(() => _department = null),
                  ),
                ),
                for (final d in _departments)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(d),
                      selected: _department == d,
                      onSelected: (_) => setState(() => _department = d),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('Không tìm thấy giáo viên'))
                : ListView.builder(
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
      ),
    );
  }
}

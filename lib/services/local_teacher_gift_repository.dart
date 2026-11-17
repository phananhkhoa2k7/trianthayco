import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/gift.dart';
import 'teacher_gift_repository.dart';

/// Lưu cục bộ bằng shared_preferences (trên web = localStorage của trình duyệt).
/// Mỗi giáo viên một key: gifts_<teacherId>, giá trị là danh sách JSON các lần tặng.
class LocalTeacherGiftRepository implements TeacherGiftRepository {
  // Lấy instance 1 lần, các lần gọi sau dùng lại (tránh await lặp lại).
  final Future<SharedPreferences> _prefsFuture = SharedPreferences.getInstance();

  String _key(String teacherId) => 'gifts_$teacherId';

  @override
  Future<void> sendGift(GiftSubmission s) async {
    final prefs = await _prefsFuture;
    final list = prefs.getStringList(_key(s.teacherId)) ?? <String>[];
    list.add(jsonEncode({
      'flowers': s.flowers,
      'wishes': s.wishes,
      'message': s.message,
      'created_at': DateTime.now().toIso8601String(),
    }));
    await prefs.setStringList(_key(s.teacherId), list);
  }

  @override
  Future<GiftSummary> getSummary(String teacherId) async {
    final prefs = await _prefsFuture;
    final list = prefs.getStringList(_key(teacherId)) ?? <String>[];
    var flowers = 0, wishes = 0;
    final messages = <GiftMessage>[];
    for (final raw in list) {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      flowers += (m['flowers'] as num).toInt();
      wishes += (m['wishes'] as num).toInt();
      final text = m['message'] as String?;
      if (text != null && text.trim().isNotEmpty) {
        messages
            .add(GiftMessage(text, DateTime.parse(m['created_at'] as String)));
      }
    }
    messages.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // mới nhất trước
    return GiftSummary(flowers: flowers, wishes: wishes, messages: messages);
  }
}

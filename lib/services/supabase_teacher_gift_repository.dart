import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/gift.dart';
import 'teacher_gift_repository.dart';

/// Lưu lên Supabase, bảng `gifts` (xem SQL trong README.md).
/// Mỗi lần tặng = 1 dòng; tổng hợp được tính phía client.
class SupabaseTeacherGiftRepository implements TeacherGiftRepository {
  final SupabaseClient _client;
  SupabaseTeacherGiftRepository(this._client);

  static const _table = 'gifts';

  @override
  Future<void> sendGift(GiftSubmission s) async {
    await _client.from(_table).insert({
      'teacher_id': s.teacherId,
      'flowers': s.flowers,
      'wishes': s.wishes,
      'message': s.message,
      // created_at do database tự điền (default now())
    });
  }

  @override
  Future<GiftSummary> getSummary(String teacherId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('teacher_id', teacherId)
        .order('created_at', ascending: false);

    var flowers = 0, wishes = 0;
    final messages = <GiftMessage>[];
    for (final r in rows) {
      flowers += (r['flowers'] as num).toInt();
      wishes += (r['wishes'] as num).toInt();
      final text = r['message'] as String?;
      if (text != null && text.trim().isNotEmpty) {
        messages.add(GiftMessage(
            text, DateTime.parse(r['created_at'] as String).toLocal()));
      }
    }
    return GiftSummary(flowers: flowers, wishes: wishes, messages: messages);
  }
}

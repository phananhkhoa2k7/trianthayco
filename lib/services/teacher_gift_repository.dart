import '../models/gift.dart';

/// Interface lưu/đọc quà tặng giáo viên.
/// Có thể thay implementation (Local / Supabase / Firebase...) mà UI không đổi.
abstract class TeacherGiftRepository {
  /// Ghi nhận một lần tặng quà.
  Future<void> sendGift(GiftSubmission submission);

  /// Lấy tổng hợp số hoa, số lời chúc và danh sách lời nhắn của giáo viên.
  Future<GiftSummary> getSummary(String teacherId);
}

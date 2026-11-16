/// Một lần gửi quà (tương ứng 1 dòng trong bảng `gifts`).
class GiftSubmission {
  final String teacherId;
  final int flowers;
  final int wishes;
  final String? message; // lời nhắn cá nhân (có thể null)

  const GiftSubmission({
    required this.teacherId,
    required this.flowers,
    required this.wishes,
    this.message,
  });
}

/// Một lời nhắn giáo viên đã nhận.
class GiftMessage {
  final String text;
  final DateTime createdAt;
  const GiftMessage(this.text, this.createdAt);
}

/// Tổng hợp quà của một giáo viên.
class GiftSummary {
  final int flowers;
  final int wishes;
  final List<GiftMessage> messages;

  const GiftSummary({
    this.flowers = 0,
    this.wishes = 0,
    this.messages = const [],
  });
}

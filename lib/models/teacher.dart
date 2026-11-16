/// Thông tin một thầy/cô.
class Teacher {
  final String id;
  final String honorific; // 'Thầy' hoặc 'Cô'
  final String name;
  final int birthYear;
  final String degree; // học vị
  final String major; // chuyên ngành
  final List<String> courses; // học phần giảng dạy
  final String department; // khoa / bộ môn
  final bool isMale; // Giới tính để hiển thị sprite
  final String? avatarUrl; // null => dùng avatar chữ cái đầu

  const Teacher({
    required this.id,
    required this.honorific,
    required this.name,
    required this.birthYear,
    required this.degree,
    required this.major,
    required this.courses,
    required this.department,
    required this.isMale,
    this.avatarUrl,
  });

  String get displayName => '$honorific $name';

  /// Chữ cái đầu của tên gọi (từ cuối của họ tên).
  String get initial => name.trim().split(RegExp(r'\s+')).last.substring(0, 1);
}

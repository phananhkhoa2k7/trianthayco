/// Bỏ dấu tiếng Việt để tìm kiếm "thang" ra được "Thắng".
const _groups = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};

final Map<String, String> _fold = {
  for (final e in _groups.entries)
    for (final ch in e.value.split('')) ch: e.key,
};

final RegExp _combining = RegExp('[\u0300-\u036f]');

String foldVietnamese(String input) {
  final lower = input.toLowerCase().replaceAll(_combining, '');
  final sb = StringBuffer();
  for (final ch in lower.split('')) {
    sb.write(_fold[ch] ?? ch);
  }
  return sb.toString();
}

/// Câu nói về ngày 20/11 tuỳ theo hôm nay.
String occasionLine(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final days = DateTime(now.year, 11, 20).difference(today).inDays;
  if (days == 0) return 'Hôm nay là 20/11 – chúc mừng ngày Nhà giáo Việt Nam!';
  if (days > 0 && days <= 30) return 'Còn $days ngày nữa là đến 20/11';
  return 'Ngày Nhà giáo Việt Nam 20/11';
}

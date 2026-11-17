import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bảng màu ấm áp, gợi không khí ngày Nhà giáo: hồng hoa, vàng nắng, xanh lá, kem giấy.
class AppColors {
  static const rose = Color(0xFFE85D75);
  static const roseDark = Color(0xFFC2415C);
  static const blush = Color(0xFFFFE3E8);
  static const cream = Color(0xFFFFF6EC);
  static const paper = Color(0xFFFFFDF8);
  static const gold = Color(0xFFF4B942);
  static const leaf = Color(0xFF5BA77A);
  static const ink = Color(0xFF5A3A3A);
}

/// Chữ viết tay mềm mại cho tiêu đề (Dancing Script hỗ trợ tiếng Việt).
TextStyle scriptStyle(double size, {Color color = AppColors.rose}) =>
    GoogleFonts.dancingScript(
        fontSize: size, fontWeight: FontWeight.w700, color: color, height: 1.1);

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.rose,
    primary: AppColors.rose,
    secondary: AppColors.gold,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.cream,
    textTheme: GoogleFonts.beVietnamProTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.roseDark,
      titleTextStyle: scriptStyle(26, color: AppColors.roseDark),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.rose,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: AppColors.rose.withAlpha(70)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: AppColors.rose.withAlpha(70)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.rose, width: 2),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: Colors.white,
      selectedColor: AppColors.blush,
      side: BorderSide(color: AppColors.rose.withAlpha(60)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

/// Bóng đổ mềm dùng chung cho các thẻ.
final List<BoxShadow> kSoftShadow = [
  BoxShadow(
      color: AppColors.rose.withAlpha(35),
      blurRadius: 18,
      offset: const Offset(0, 6)),
];

/// Cấu hình đọc từ biến môi trường lúc build/run (--dart-define).
/// Ví dụ:
///   flutter run -d chrome \
///     --dart-define=USE_SUPABASE=true \
///     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ...
/// Mặc định (không truyền gì) => dùng lưu cục bộ (shared_preferences).
class AppConfig {
  static const bool useSupabase =
      bool.fromEnvironment('USE_SUPABASE', defaultValue: false);
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get supabaseReady =>
      useSupabase && supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

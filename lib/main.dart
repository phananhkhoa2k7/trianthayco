import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'screens/home_screen.dart';
import 'services/local_teacher_gift_repository.dart';
import 'services/supabase_teacher_gift_repository.dart';
import 'services/teacher_gift_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await _createRepository();
  runApp(TriAnApp(repository: repository));
}

/// Chọn implementation theo cấu hình --dart-define (xem AppConfig).
/// Thiếu URL/key Supabase => tự động quay về lưu cục bộ.
Future<TeacherGiftRepository> _createRepository() async {
  if (AppConfig.supabaseReady) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    return SupabaseTeacherGiftRepository(Supabase.instance.client);
  }
  return LocalTeacherGiftRepository();
}

class TriAnApp extends StatelessWidget {
  final TeacherGiftRepository repository;
  const TriAnApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // UI chỉ phụ thuộc interface, không biết Local hay Supabase.
        Provider<TeacherGiftRepository>.value(value: repository),
      ],
      child: MaterialApp(
        title: 'Tri ân thầy cô 20/11',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

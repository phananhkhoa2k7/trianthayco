import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'screens/home_screen.dart';
import 'services/audio_service.dart';
import 'services/local_teacher_gift_repository.dart';
import 'services/supabase_teacher_gift_repository.dart';
import 'services/teacher_gift_repository.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await _createRepository();
  runApp(TriAnApp(repository: repository));
}

/// Chọn implementation theo --dart-define; thiếu cấu hình => lưu cục bộ.
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
        Provider<TeacherGiftRepository>.value(value: repository),
        ChangeNotifierProvider<AudioService>(create: (_) => AudioService()),
      ],
      child: MaterialApp(
        title: 'Tri ân thầy cô 20/11',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        // Trình duyệt chỉ cho phát âm thanh sau tương tác đầu tiên => bắt chạm đầu tiên ở đây.
        builder: (context, child) => Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => context.read<AudioService>().start(),
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

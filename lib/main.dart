import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

import 'config/app_config.dart';
import 'screens/home_screen.dart';
import 'services/local_teacher_gift_repository.dart';
import 'services/supabase_teacher_gift_repository.dart';
import 'services/teacher_gift_repository.dart';

// Global Audio Manager
final AudioPlayer bgmPlayer = AudioPlayer();
bool isBgmStarted = false;

void playBgmNormal() {
  if (!isBgmStarted) {
    isBgmStarted = true;
    bgmPlayer.setReleaseMode(ReleaseMode.loop);
    bgmPlayer.play(AssetSource('audio/bgm.mp3'), volume: 0.4);
  } else {
    bgmPlayer.setVolume(0.4);
  }
}

void playBgmSoft() {
  if (isBgmStarted) {
    bgmPlayer.setVolume(0.1);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await _createRepository();
  runApp(TriAnApp(repository: repository));
}

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

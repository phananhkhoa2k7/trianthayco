import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_service.dart';

/// Nút bật/tắt nhạc nền.
class MuteButton extends StatelessWidget {
  final Color? color;
  const MuteButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    return IconButton(
      tooltip: audio.muted ? 'Bật nhạc' : 'Tắt nhạc',
      color: color,
      onPressed: audio.toggleMute,
      icon: Icon(audio.muted ? Icons.music_off_rounded : Icons.music_note_rounded),
    );
  }
}

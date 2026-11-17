import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gift.dart';
import '../models/teacher.dart';
import '../services/audio_service.dart';
import '../services/teacher_gift_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/gift_summary_view.dart';
import '../widgets/mute_button.dart';
import '../widgets/petal_background.dart';
import '../widgets/sprites.dart';
import '../widgets/teacher_avatar.dart';

/// Màn hình gặp giáo viên sau 3 ải: gửi hoa + lời chúc + lời nhắn cá nhân,
/// rồi hiển thị tổng quà giáo viên đã nhận.
class TributeScreen extends StatefulWidget {
  final Teacher teacher;
  final int flowers;
  final List<String> wishes;
  const TributeScreen({
    super.key,
    required this.teacher,
    required this.flowers,
    required this.wishes,
  });

  @override
  State<TributeScreen> createState() => _TributeScreenState();
}

class _TributeScreenState extends State<TributeScreen> {
  final _controller = TextEditingController();
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 4));
  late final AudioService _audio;
  bool _sending = false;
  GiftSummary? _summary; // != null nghĩa là đã gửi xong

  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioService>()..setSoft(true); // hạ nhạc để dễ viết lời nhắn
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _confetti.play();
    });
  }

  @override
  void dispose() {
    _audio.setSoft(false);
    _confetti.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final repo = context.read<TeacherGiftRepository>();
    try {
      final msg = _controller.text.trim();
      await repo.sendGift(GiftSubmission(
        teacherId: widget.teacher.id,
        flowers: widget.flowers,
        wishes: widget.wishes.length,
        message: msg.isEmpty ? null : msg,
      ));
      final summary = await repo.getSummary(widget.teacher.id);
      if (mounted) {
        setState(() => _summary = summary);
        _confetti.play();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gửi chưa được, bạn thử lại nhé: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Chèn câu gợi ý vào ô lời nhắn.
  void _addStarter(String text) {
    final cur = _controller.text;
    _controller.text = cur.isEmpty ? '$text ' : '$cur\n$text ';
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.teacher;
    return PetalBackground(
      petals: 16,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Gặp ${t.displayName}'),
          actions: const [MuteButton()],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _summary == null
                        ? _buildForm(t)
                        : _buildThanks(t),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirection: pi / 2,
                maxBlastForce: 5,
                minBlastForce: 2,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.2,
                createParticlePath: heartPath,
                colors: const [AppColors.rose, AppColors.gold, Color(0xFFFFA8BE), AppColors.leaf],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paper({Key? key, required Widget child}) => Container(
        key: key,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.rose.withAlpha(50), width: 2),
          boxShadow: kSoftShadow,
        ),
        child: child,
      );

  Widget _buildForm(Teacher t) {
    final h = t.honorific.toLowerCase();
    final starters = [
      'Cảm ơn $h vì...',
      'Điều em nhớ nhất là...',
      'Em hứa sẽ cố gắng...',
    ];
    return _paper(
      key: const ValueKey('form'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: TeacherAvatar(teacher: t, radius: 52)),
          const SizedBox(height: 12),
          Text('Gửi ${t.displayName}',
              textAlign: TextAlign.center, style: scriptStyle(36)),
          const SizedBox(height: 6),
          Text(
            'Sau ba ải đầy hoa và thư, bạn đã tìm thấy $h. '
            'Hãy trao những điều đã gom góp và nói vài lời thật lòng nhé.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GiftSummaryView(
              summary: GiftSummary(flowers: widget.flowers, wishes: widget.wishes.length)),
          const SizedBox(height: 12),
          Text('Những lời chúc bạn đã nhặt',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final w in widget.wishes)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold.withAlpha(120)),
              ),
              child: Row(
                children: [
                  const LetterIcon(size: 28),
                  const SizedBox(width: 10),
                  Expanded(child: Text(w)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final s in starters)
                ActionChip(label: Text(s), onPressed: () => _addStarter(s)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 4,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: 'Lời nhắn riêng gửi $h (tuỳ chọn)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.favorite_rounded),
              label: const Text('Gửi tặng hoa & lời chúc'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThanks(Teacher t) {
    final h = t.honorific.toLowerCase();
    return _paper(
      key: const ValueKey('thanks'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Trái tim "đập" nhẹ khi hiện ra
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: const Icon(Icons.favorite_rounded, color: AppColors.rose, size: 64),
            ),
          ),
          const SizedBox(height: 8),
          Text('Đã gửi rồi!', textAlign: TextAlign.center, style: scriptStyle(40)),
          Text(
            'Cảm ơn bạn đã dành tình cảm cho ${t.displayName}. '
            'Những lời yêu thương này sẽ ở lại thật lâu.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text('Tổng quà $h đã nhận', style: scriptStyle(28)),
          const SizedBox(height: 8),
          GiftSummaryView(summary: _summary!),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hoàn tất'),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

import '../models/gift.dart';
import '../models/teacher.dart';
import '../services/teacher_gift_repository.dart';
import '../widgets/gift_summary_view.dart';
import '../widgets/teacher_avatar.dart';
import '../main.dart';

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
  bool _sending = false;
  GiftSummary? _summary; // != null nghĩa là đã gửi xong
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    playBgmSoft();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
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
      if (mounted) setState(() => _summary = summary);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gửi thất bại: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.teacher;
    return Scaffold(
      appBar: AppBar(title: Text('Gặp ${t.displayName}')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: _summary == null ? _buildForm(t) : _buildThanks(t),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // fall downwards
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 40,
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(Teacher t) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: TeacherAvatar(teacher: t, radius: 48)),
        const SizedBox(height: 12),
        Text('Bạn đã tìm thấy ${t.displayName}!',
            textAlign: TextAlign.center, style: text.titleLarge),
        const SizedBox(height: 16),
        GiftSummaryView(
            summary: GiftSummary(flowers: widget.flowers, wishes: widget.wishes.length)),
        const SizedBox(height: 8),
        Text('Lời chúc bạn đã thu thập', style: text.titleMedium),
        for (final w in widget.wishes)
          Card(child: ListTile(leading: const Icon(Icons.mail_outline), title: Text(w))),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          maxLines: 4,
          maxLength: 300,
          decoration: InputDecoration(
            labelText: 'Lời nhắn riêng gửi ${t.honorific.toLowerCase()} (tuỳ chọn)',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _sending ? null : _send,
          icon: _sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send),
          label: const Text('Gửi tặng hoa & lời chúc'),
        ),
      ],
    );
  }

  Widget _buildThanks(Teacher t) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.favorite, color: Colors.pink, size: 56),
        const SizedBox(height: 8),
        Text('Đã gửi! ${t.displayName} rất vui khi nhận được.',
            textAlign: TextAlign.center, style: text.titleLarge),
        const SizedBox(height: 20),
        Text('Tổng quà ${t.honorific.toLowerCase()} đã nhận', style: text.titleMedium),
        const SizedBox(height: 8),
        GiftSummaryView(summary: _summary!),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hoàn tất'),
        ),
      ],
    );
  }
}

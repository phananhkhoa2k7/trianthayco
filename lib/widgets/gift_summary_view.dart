import 'package:flutter/material.dart';

import '../models/gift.dart';
import '../theme/app_theme.dart';
import 'sprites.dart';

/// Hiển thị số hoa, số lời chúc và danh sách lời nhắn giáo viên đã nhận.
class GiftSummaryView extends StatelessWidget {
  final GiftSummary summary;
  const GiftSummaryView({super.key, required this.summary});

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: _Stat(
                    icon: const FlowerIcon(size: 36),
                    value: summary.flowers,
                    label: 'bông hoa')),
            const SizedBox(width: 12),
            Expanded(
                child: _Stat(
                    icon: const LetterIcon(size: 36),
                    value: summary.wishes,
                    label: 'lời chúc')),
          ],
        ),
        const SizedBox(height: 16),
        Text('Lời nhắn đã nhận (${summary.messages.length})',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (summary.messages.isEmpty)
          const Text('Chưa có lời nhắn nào. Hãy là người đầu tiên gửi lời yêu thương!')
        else
          for (final m in summary.messages)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                    left: BorderSide(color: AppColors.rose.withAlpha(180), width: 4)),
                boxShadow: kSoftShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.text, style: const TextStyle(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 6),
                  Text(_date(m.createdAt),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final Widget icon;
  final int value;
  final String label;
  const _Stat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Colors.white, AppColors.blush],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 4),
          Text('$value', style: scriptStyle(40, color: AppColors.roseDark)),
          Text(label),
        ],
      ),
    );
  }
}

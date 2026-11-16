import 'package:flutter/material.dart';

import '../models/gift.dart';

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
                    icon: Icons.local_florist,
                    color: Colors.pink,
                    value: summary.flowers,
                    label: 'bông hoa')),
            const SizedBox(width: 12),
            Expanded(
                child: _Stat(
                    icon: Icons.mail,
                    color: Colors.orange,
                    value: summary.wishes,
                    label: 'lời chúc')),
          ],
        ),
        const SizedBox(height: 16),
        Text('Lời nhắn đã nhận (${summary.messages.length})',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (summary.messages.isEmpty)
          const Text('Chưa có lời nhắn nào. Hãy là người đầu tiên!')
        else
          for (final m in summary.messages)
            Card(
              child: ListTile(
                leading: const Icon(Icons.format_quote),
                title: Text(m.text),
                subtitle: Text(_date(m.createdAt)),
              ),
            ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;
  const _Stat(
      {required this.icon,
      required this.color,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 4),
            Text('$value',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label),
          ],
        ),
      ),
    );
  }
}

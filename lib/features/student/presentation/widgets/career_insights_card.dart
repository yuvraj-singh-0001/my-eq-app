import 'package:flutter/material.dart';

import '../../../authentication/data/auth_api.dart';

class CareerInsightsCard extends StatelessWidget {
  const CareerInsightsCard({
    super.key,
    required this.notes,
    this.onCreateSupportPlan,
  });

  final List<JournalNoteData> notes;
  final VoidCallback? onCreateSupportPlan;

  List<JournalNoteData> get _insights =>
      notes.where((note) => note.category == 'Career Discovery').toList();

  String? _value(String text, String prefix) {
    for (final line in text.split('\n')) {
      if (line.startsWith(prefix)) {
        final value = line.substring(prefix.length).trim();
        if (value.isNotEmpty) return value;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final insights = _insights;
    final latest = insights.isEmpty ? null : insights.first;
    final subject = latest == null
        ? null
        : _value(latest.text, 'SUBJECT I AM FIGURING OUT:');
    final interest = latest == null
        ? null
        : _value(latest.text, 'WHAT I ENJOY:');
    final strength = latest == null
        ? null
        : _value(latest.text, 'WHAT I FEEL I CAN DO:');
    final feeling = latest == null
        ? null
        : _value(latest.text, 'HOW IT FEELS:');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EDFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1D8F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.explore_outlined,
                color: Color(0xFF775CB2),
                size: 23,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Career & Subject Insights',
                  style: TextStyle(
                    color: Color(0xFF39285E),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (insights.isNotEmpty)
                Text(
                  '${insights.length} note${insights.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Color(0xFF775CB2),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            latest == null
                ? 'The student’s subject difficulties, interests and strengths will appear here after they use Career Discovery.'
                : 'A friendly snapshot from the student’s own words. Use it to start a conversation, not to label the student.',
            style: const TextStyle(
              color: Color(0xFF675C7D),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (latest != null) ...[
            const SizedBox(height: 14),
            _InsightRow(
              icon: Icons.menu_book_outlined,
              label: 'Subject needing support',
              value: subject ?? 'Not mentioned yet',
            ),
            _InsightRow(
              icon: Icons.lightbulb_outline,
              label: 'Enjoys',
              value: interest ?? 'Not mentioned yet',
            ),
            _InsightRow(
              icon: Icons.emoji_events_outlined,
              label: 'Feels confident in',
              value: strength ?? 'Not mentioned yet',
            ),
            _InsightRow(
              icon: Icons.mood_outlined,
              label: 'Feels this way',
              value: feeling ?? 'Not mentioned yet',
            ),
            if (onCreateSupportPlan != null) ...[
              const SizedBox(height: 5),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onCreateSupportPlan,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Create Support Plan'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF775CB2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF775CB2), size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Color(0xFF675C7D),
                fontSize: 12,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$label\n',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';

import '../../../authentication/data/auth_api.dart';

class SharedReflectionOverview extends StatelessWidget {
  const SharedReflectionOverview({
    super.key,
    required this.notes,
    this.compact = false,
  });

  final List<JournalNoteData> notes;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final moodCounts = <String, int>{};
    final categoryCounts = <String, int>{};
    for (final note in notes) {
      final mood = note.mood?.trim();
      if (mood != null && mood.isNotEmpty) {
        moodCounts.update(mood, (count) => count + 1, ifAbsent: () => 1);
      }
      categoryCounts.update(
        note.category,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    final topMood = _mostFrequent(moodCounts);
    final topCategory = _mostFrequent(categoryCounts);
    final latest = notes.isEmpty ? null : notes.first;
    final latestText = latest == null ? '' : _reflectionText(latest);

    return Container(
      padding: EdgeInsets.all(compact ? 13 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(color: const Color(0xFFE7EEF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_outlined,
                color: Color(0xFF168C73),
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Overview from shared notes',
                  style: TextStyle(
                    color: const Color(0xFF182D4C),
                    fontSize: compact ? 13 : 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${notes.length} ${notes.length == 1 ? 'note' : 'notes'}',
                style: const TextStyle(
                  color: Color(0xFF718097),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            notes.isEmpty
                ? 'When your child shares a reflection with you, a short overview will appear here.'
                : _summary(topMood: topMood, topCategory: topCategory),
            style: TextStyle(
              color: const Color(0xFF65758D),
              fontSize: compact ? 11 : 12,
              height: 1.45,
            ),
          ),
          if (latest != null && latestText.isNotEmpty) ...[
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F9FA),
                borderRadius: BorderRadius.all(Radius.circular(11)),
              ),
              child: Text(
                '"${_excerpt(latestText, compact ? 100 : 180)}"',
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF354760),
                  fontSize: compact ? 10 : 11,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          if (!compact && (topMood != null || topCategory != null)) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 6,
              children: [
                if (topMood != null) _OverviewTag('Often shared: $topMood'),
                if (topCategory != null) _OverviewTag('Topic: $topCategory'),
              ],
            ),
          ],
          const SizedBox(height: 7),
          Text(
            'Based only on reflections your child chose to share.',
            style: TextStyle(
              color: const Color(0xFF8793A4),
              fontSize: compact ? 9 : 10,
            ),
          ),
        ],
      ),
    );
  }

  String _summary({required String? topMood, required String? topCategory}) {
    final parts = <String>['${notes.length} shared reflections'];
    if (topCategory != null) parts.add('most often about $topCategory');
    if (topMood != null) parts.add('with $topMood selected most often');
    return '${parts.join(', ')}. This is a simple pattern from the entries, not a diagnosis.';
  }

  String? _mostFrequent(Map<String, int> counts) {
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  String _reflectionText(JournalNoteData note) {
    final sections = note.sections
        .map((section) => section['customText'])
        .whereType<String>()
        .map((text) => text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    final pieces = [
      note.text.trim(),
      note.customText.trim(),
      ...sections,
    ].where((text) => text.isNotEmpty).toList();
    return pieces.isEmpty ? '' : pieces.join(' | ');
  }

  String _excerpt(String text, int limit) => text.length <= limit
      ? text
      : '${text.substring(0, limit).trimRight()}...';
}

class _OverviewTag extends StatelessWidget {
  const _OverviewTag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF6F3),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFF247A69),
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

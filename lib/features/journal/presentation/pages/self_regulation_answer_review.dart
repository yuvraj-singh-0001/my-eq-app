import 'package:flutter/material.dart';

import 'self_regulation_content.dart';

/// A live, readable preview of the answers for one reflection topic.
class SelfRegulationAnswerReview extends StatelessWidget {
  const SelfRegulationAnswerReview({
    super.key,
    required this.topic,
    required this.answer,
    this.showEmptyHint = false,
  });

  final SelfRegulationTopic topic;
  final SelfRegulationTopicAnswer answer;
  final bool showEmptyHint;

  static const _ink = Color(0xFF203454);
  static const _muted = Color(0xFF64738C);

  String _emoji(String feeling) => switch (feeling) {
    'Worried' => '\u{1F61F}',
    'Angry' => '\u{1F620}',
    'Sad' => '\u{1F61E}',
    'Disappointed' => '\u{1F614}',
    'Frustrated' => '\u{1F623}',
    'Quiet' => '\u{1F636}',
    'Confused' => '\u{1F615}',
    'Calm after some time' => '\u{1F60C}',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    final hasContent = answer.hasAnswer;
    if (!hasContent && !showEmptyHint) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: topic.color.withAlpha(75)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A203454),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.subject_rounded, size: 18, color: topic.color),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Your review',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                topic.title,
                style: TextStyle(
                  color: topic.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          if (answer.selectedStatements.isNotEmpty) ...[
            const _ReviewLabel('What I chose'),
            const SizedBox(height: 5),
            for (final statement in answer.selectedStatements)
              _ReviewLine(text: statement, color: topic.color),
          ],
          if (answer.selectedFeelings.isNotEmpty) ...[
            const SizedBox(height: 11),
            const _ReviewLabel('How it feels'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final feeling in answer.selectedFeelings)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: topic.color.withAlpha(18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_emoji(feeling)}  $feeling',
                      style: TextStyle(
                        color: topic.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (answer.customText.trim().isNotEmpty) ...[
            const SizedBox(height: 11),
            const _ReviewLabel('In my own words'),
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                answer.customText.trim(),
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (!hasContent)
            const Text(
              'Your choices and words will appear here as you add them.',
              style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
            ),
        ],
      ),
    );
  }
}

class _ReviewLabel extends StatelessWidget {
  const _ReviewLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF168D78),
      fontSize: 11,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 5, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF64738C),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

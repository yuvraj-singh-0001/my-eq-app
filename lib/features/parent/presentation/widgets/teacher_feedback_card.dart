import 'package:flutter/material.dart';

import '../../../authentication/data/auth_api.dart';

class TeacherFeedbackCard extends StatelessWidget {
  const TeacherFeedbackCard({super.key, required this.update, this.date});

  final TeacherGrowthUpdateData update;
  final String? date;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (update.progress) {
      'improving' => const Color(0xFF168C73),
      'steady' => const Color(0xFF3976A8),
      'harder' => const Color(0xFFB87525),
      _ => const Color(0xFF718097),
    };
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EEF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 17,
                backgroundColor: Color(0xFFEAF6F3),
                foregroundColor: Color(0xFF168C73),
                child: Icon(Icons.person_outline_rounded, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      update.teacherName,
                      style: const TextStyle(
                        color: Color(0xFF203454),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (date != null)
                      Text(
                        date!,
                        style: const TextStyle(
                          color: Color(0xFF8390A3),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(24),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _progressLabel(update.progress),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            _focusAreaLabel(update.focusArea),
            style: const TextStyle(
              color: Color(0xFF182D4C),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (update.observedBehaviors.isNotEmpty)
            _FeedbackLine(
              label: 'Observed',
              value: update.observedBehaviors.join(' | '),
            ),
          if (update.whatHelped.isNotEmpty)
            _FeedbackLine(label: 'What helped', value: update.whatHelped),
          if (update.whatWasHard.isNotEmpty)
            _FeedbackLine(
              label: 'What was difficult',
              value: update.whatWasHard,
            ),
          if (update.nextStep.isNotEmpty)
            _FeedbackLine(label: 'Next step', value: update.nextStep),
        ],
      ),
    );
  }

  String _progressLabel(String value) => switch (value) {
    'improving' => 'Improving',
    'steady' => 'Steady',
    'harder' => 'More challenging',
    _ => 'Follow-up suggested',
  };

  String _focusAreaLabel(String value) => switch (value) {
    'frustration' => 'Handling frustration',
    'calming_myself' => 'Calming strategies',
    'patience_waiting' => 'Patience',
    'helpful_habits' => 'Helpful habits',
    'impulses' => 'Pausing before acting',
    'changes' => 'Managing changes',
    'focus' => 'Focus',
    _ => 'Growth update',
  };
}

class _FeedbackLine extends StatelessWidget {
  const _FeedbackLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF718097),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF394A64),
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

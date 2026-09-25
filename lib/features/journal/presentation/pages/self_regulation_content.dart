import 'package:flutter/material.dart';

class SelfRegulationTopic {
  const SelfRegulationTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.statements,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> statements;
}

const selfRegulationTopics = <SelfRegulationTopic>[
  SelfRegulationTopic(
    id: 'frustration',
    title: 'Handling Frustration',
    description: 'What feels hard when things do not go as planned?',
    icon: Icons.self_improvement_rounded,
    color: Color(0xFFE45E62),
    statements: [
      'I get upset when things do not go the way I expected.',
      'I feel angry when I try hard but still cannot do something.',
      'Small things sometimes make me feel really frustrated.',
      'When someone disagrees with me, I find it hard to stay calm.',
      'I feel like giving up when something keeps going wrong.',
      'When someone corrects me, I sometimes feel bad or irritated.',
      'I become quiet when I am upset or disappointed.',
      'When I lose a game or make a mistake, I think about it for a while.',
      'Sometimes I react quickly and regret it later.',
      'Even after a problem is over, I sometimes keep thinking about it.',
    ],
  ),
  SelfRegulationTopic(
    id: 'calming_myself',
    title: 'Calming Myself',
    description: 'How do you feel better when you are upset?',
    icon: Icons.spa_rounded,
    color: Color(0xFF14A58A),
    statements: [
      'Taking a few slow breaths helps me feel calmer.',
      'I like to have a little quiet time when I feel upset.',
      'Talking to someone I trust can help me feel better.',
      'Doing something I enjoy helps me calm down.',
      'I can usually find a way to feel calm again.',
      'Sometimes I am not sure what will help me feel better.',
      'I step away for a short break when I need to calm down.',
      'Counting slowly helps me settle my thoughts.',
    ],
  ),
  SelfRegulationTopic(
    id: 'patience_waiting',
    title: 'Patience & Waiting',
    description: 'How do waiting and delays feel for you?',
    icon: Icons.hourglass_bottom_rounded,
    color: Color(0xFF6D74CE),
    statements: [
      'I can wait calmly when something takes longer than I hoped.',
      'Waiting can make me feel restless or impatient.',
      'I find it hard when plans are delayed.',
      'I can find something else to do while I wait.',
      'I get upset when I have to wait for my turn.',
      'A little reminder helps me be patient while I wait.',
      'I can wait more easily when I know how long it may take.',
      'Keeping busy helps the time pass while I wait.',
    ],
  ),
  SelfRegulationTopic(
    id: 'helpful_habits',
    title: 'Helpful Habits',
    description: 'What small habits help you feel your best?',
    icon: Icons.favorite_outline_rounded,
    color: Color(0xFFDC7B47),
    statements: [
      'I take a short break when I start to feel overwhelmed.',
      'I ask someone I trust for help when I need it.',
      'I try again after a mistake, one small step at a time.',
      'I make time for activities that help me feel good.',
      'A regular routine helps me feel ready for the day.',
      'I notice and feel proud of small things I do well.',
      'Moving my body helps me feel better.',
      'Getting enough rest helps me handle the day.',
    ],
  ),
  SelfRegulationTopic(
    id: 'impulses',
    title: 'Managing Impulses',
    description: 'Do you pause before you act?',
    icon: Icons.pause_circle_outline_rounded,
    color: Color(0xFFF0A126),
    statements: [
      'I pause and think before I act.',
      'I sometimes act without thinking about what might happen.',
      'I take a breath before I answer.',
      'I count to three before I do something.',
      'I try to think about what might happen next.',
      'I wait for my turn to speak.',
      'I sometimes speak before I am ready.',
      'I find it hard to stop when I feel excited.',
    ],
  ),
  SelfRegulationTopic(
    id: 'changes',
    title: 'Handling Changes',
    description: 'How do new plans and routines feel?',
    icon: Icons.sync_alt_rounded,
    color: Color(0xFF8A5BD1),
    statements: [
      'I adjust when plans or routines change.',
      'Unexpected changes or new routines are hard for me.',
      'I feel more ready when I hear about a change early.',
      'A new plan can make me feel unsure at first.',
      'I ask what will happen next when plans change.',
      'I can try a new routine one step at a time.',
      'I need time to get used to new plans.',
      'Once I try a change, it often feels easier.',
    ],
  ),
  SelfRegulationTopic(
    id: 'focus',
    title: 'Staying Focused',
    description: 'What helps you keep your attention?',
    icon: Icons.center_focus_strong_rounded,
    color: Color(0xFF2588D8),
    statements: [
      'I stay focused, even when I feel distracted or challenged.',
      'I find it hard to stay focused and get distracted easily.',
      'Breaking a big task into small parts helps me focus.',
      'A quiet place helps me pay attention.',
      'I take a short break and then return to my task.',
      'I focus better when I know what to do first.',
      'Noise or movement can pull my attention away.',
      'A reminder helps me return to what I was doing.',
    ],
  ),
];

String _emojiForFeeling(String feeling) => switch (feeling) {
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

class SelfRegulationTopicAnswer {
  const SelfRegulationTopicAnswer({
    required this.selectedStatements,
    required this.customText,
    this.selectedFeelings = const [],
  });

  final List<String> selectedStatements;
  final String customText;
  final List<String> selectedFeelings;

  bool get hasAnswer =>
      selectedStatements.isNotEmpty ||
      selectedFeelings.isNotEmpty ||
      customText.trim().isNotEmpty;
}

class SelfRegulationDraft {
  const SelfRegulationDraft(
    this.answers, {
    this.topics = selfRegulationTopics,
  });

  final Map<String, SelfRegulationTopicAnswer> answers;
  final List<SelfRegulationTopic> topics;

  List<Map<String, Object?>> get sections => [
    for (final topic in topics)
      if (answers[topic.id]?.hasAnswer ?? false)
        {
          'subcategoryId': topic.id,
          'subcategory': topic.title,
          'selectedStatements': answers[topic.id]!.selectedStatements,
          'feelings': answers[topic.id]!.selectedFeelings,
          'customText': answers[topic.id]!.customText.trim(),
        },
  ];

  List<String> get selectedStatements => [
    for (final topic in topics)
      for (final statement
          in answers[topic.id]?.selectedStatements ?? const <String>[])
        '${topic.title}: $statement',
  ];

  String get customText => [
    for (final topic in topics)
      if ((answers[topic.id]?.customText ?? '').trim().isNotEmpty)
        '${topic.title}: ${answers[topic.id]!.customText.trim()}',
  ].join('\n');

  String toNoteText() => [
    for (final topic in topics)
      if (answers[topic.id]?.hasAnswer ?? false) ...[
        topic.title.toUpperCase(),
        if (answers[topic.id]!.selectedStatements.isNotEmpty) 'WHAT I CHOSE',
        for (final statement in answers[topic.id]!.selectedStatements)
          '• $statement',
        if (answers[topic.id]!.selectedFeelings.isNotEmpty) ...[
          'HOW IT FEELS',
          for (final feeling in answers[topic.id]!.selectedFeelings)
            '- ${_emojiForFeeling(feeling)} $feeling',
        ],
        if (answers[topic.id]!.customText.trim().isNotEmpty) ...[
          'IN MY OWN WORDS',
          answers[topic.id]!.customText.trim(),
        ],
      ],
  ].join('\n');
}

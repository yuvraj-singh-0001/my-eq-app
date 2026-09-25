import 'package:flutter/material.dart';

import 'self_regulation_answer_review.dart';
import 'self_regulation_content.dart';
import 'self_regulation_behavior_page.dart';

class SelfRegulationTopicsPage extends StatefulWidget {
  const SelfRegulationTopicsPage({
    super.key,
    this.category = 'Self-Regulation',
    this.topics = selfRegulationTopics,
  });

  final String category;
  final List<SelfRegulationTopic> topics;

  @override
  State<SelfRegulationTopicsPage> createState() =>
      _SelfRegulationTopicsPageState();
}

class _SelfRegulationTopicsPageState extends State<SelfRegulationTopicsPage> {
  final Map<String, SelfRegulationTopicAnswer> _answers = {};

  Future<void> _openTopic(SelfRegulationTopic topic) async {
    final answer = await Navigator.of(context).push<SelfRegulationTopicAnswer>(
      MaterialPageRoute<SelfRegulationTopicAnswer>(
        builder: (_) => SelfRegulationBehaviorPage(
          topic: topic,
          initialAnswer: _answers[topic.id],
        ),
      ),
    );
    if (!mounted || answer == null) return;
    setState(() {
      if (answer.hasAnswer) {
        _answers[topic.id] = answer;
      } else {
        _answers.remove(topic.id);
      }
    });
  }

  void _continue() {
    Navigator.of(context).pop(
      SelfRegulationDraft(Map.of(_answers), topics: widget.topics),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 360 ? 16.0 : 22.0;
    final hasAnswers = _answers.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.category,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            Text(
              'Choose what you would like to reflect on',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: Color(0xFF77849A)),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Step 2 of 4',
                style: TextStyle(
                  color: Color(0xFF65728E),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          8,
          horizontalPadding,
          14,
        ),
        children: [
          const _StepProgress(currentStep: 2),
          const SizedBox(height: 14),
          for (final topic in widget.topics) ...[
            _TopicTile(
              topic: topic,
              answer: _answers[topic.id],
              onTap: () => _openTopic(topic),
            ),
            const SizedBox(height: 9),
          ],
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF168D78),
                  size: 17,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Choose what you want to talk about.\nYou can choose more than one.',
                    style: TextStyle(
                      color: Color(0xFF58736E),
                      fontSize: 10.5,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasAnswers) ...[
            const SizedBox(height: 18),
            const Text(
              'Your reflection so far',
              style: TextStyle(
                color: Color(0xFF203454),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Review your choices and words. You can still edit any topic.',
              style: TextStyle(color: Color(0xFF78859B), fontSize: 11),
            ),
            const SizedBox(height: 10),
            for (final topic in widget.topics)
              if (_answers[topic.id] != null) ...[
                SelfRegulationAnswerReview(
                  topic: topic,
                  answer: _answers[topic.id]!,
                ),
                const SizedBox(height: 9),
              ],
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            8,
            horizontalPadding,
            8,
          ),
          child: SizedBox(
            height: 46,
            child: FilledButton(
              onPressed: hasAnswers ? _continue : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF13A483),
                disabledBackgroundColor: const Color(0xFFDDE5E9),
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFF8A96A8),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Next'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({
    required this.topic,
    required this.answer,
    required this.onTap,
  });

  final SelfRegulationTopic topic;
  final SelfRegulationTopicAnswer? answer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count =
        (answer?.selectedStatements.length ?? 0) +
        (answer?.selectedFeelings.length ?? 0);
    final hasAnswer = answer?.hasAnswer ?? false;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasAnswer
                  ? topic.color.withAlpha(110)
                  : const Color(0xFFE6EBF1),
            ),
            boxShadow: [
              BoxShadow(
                color: hasAnswer
                    ? topic.color.withAlpha(25)
                    : const Color(0x0D203454),
                blurRadius: hasAnswer ? 10 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: topic.color.withAlpha(24),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(topic.icon, color: topic.color, size: 22),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF203454),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      topic.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF78859B),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: topic.color.withAlpha(22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: topic.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                hasAnswer
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: hasAnswer ? topic.color : const Color(0xFF8793A6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var index = 1; index <= 4; index++) ...[
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 4,
            decoration: BoxDecoration(
              color: index <= currentStep
                  ? const Color(0xFF13A483)
                  : const Color(0xFFE0E6EE),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        if (index < 4) const SizedBox(width: 5),
      ],
    ],
  );
}

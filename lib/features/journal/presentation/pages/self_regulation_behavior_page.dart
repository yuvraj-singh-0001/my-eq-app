import 'package:flutter/material.dart';

import 'self_regulation_answer_review.dart';
import 'self_regulation_content.dart';

class SelfRegulationBehaviorPage extends StatefulWidget {
  const SelfRegulationBehaviorPage({
    super.key,
    required this.topic,
    this.initialAnswer,
  });

  final SelfRegulationTopic topic;
  final SelfRegulationTopicAnswer? initialAnswer;

  @override
  State<SelfRegulationBehaviorPage> createState() =>
      _SelfRegulationBehaviorPageState();
}

class _SelfRegulationBehaviorPageState
    extends State<SelfRegulationBehaviorPage> {
  late final Set<String> _selected;
  late final Set<String> _selectedFeelings;
  late final TextEditingController _customController;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _selected = {...?widget.initialAnswer?.selectedStatements};
    _selectedFeelings = {...?widget.initialAnswer?.selectedFeelings};
    _customController = TextEditingController(
      text: widget.initialAnswer?.customText ?? '',
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _continue() {
    Navigator.of(context).pop(_currentAnswer);
  }

  SelfRegulationTopicAnswer get _currentAnswer => SelfRegulationTopicAnswer(
    selectedStatements: widget.topic.statements
        .where(_selected.contains)
        .toList(growable: false),
    selectedFeelings: _feelings
        .where((feeling) => _selectedFeelings.contains(feeling.$2))
        .map((feeling) => feeling.$2)
        .toList(growable: false),
    customText: _customController.text.trim(),
  );

  static const _feelings = <(String, String)>[
    ('😟', 'Worried'),
    ('😠', 'Angry'),
    ('😞', 'Sad'),
    ('😔', 'Disappointed'),
    ('😣', 'Frustrated'),
    ('😶', 'Quiet'),
    ('😕', 'Confused'),
    ('😌', 'Calm after some time'),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredStatements = widget.topic.statements
        .where(
          (statement) =>
              statement.toLowerCase().contains(_search.toLowerCase()),
        )
        .toList(growable: false);
    final canContinue =
        _selected.isNotEmpty ||
        _selectedFeelings.isNotEmpty ||
        _customController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        titleSpacing: 4,
        title: Text(
          widget.topic.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Step 3 of 4',
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
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.topic.description,
                          style: const TextStyle(
                            color: Color(0xFF66758E),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '${_selected.length + _selectedFeelings.length} selected',
                        style: TextStyle(
                          color: widget.topic.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (value) =>
                        setState(() => _search = value.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search these statements',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8EF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8EF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: widget.topic.color,
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
                children: [
                  for (final statement in filteredStatements) ...[
                    _StatementTile(
                      statement: statement,
                      selected: _selected.contains(statement),
                      color: widget.topic.color,
                      onTap: () => setState(() {
                        if (!_selected.add(statement)) {
                          _selected.remove(statement);
                        }
                      }),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (filteredStatements.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Text(
                          'No matching statements. You can write your own below.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF78859B),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  const Text(
                    'How does it feel for you?',
                    style: TextStyle(
                      color: Color(0xFF203454),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'You can write about this or anything else on your mind.',
                    style: TextStyle(color: Color(0xFF78859B), fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final feeling in _feelings)
                        _FeelingChip(
                          emoji: feeling.$1,
                          label: feeling.$2,
                          selected: _selectedFeelings.contains(feeling.$2),
                          color: widget.topic.color,
                          onTap: () => setState(() {
                            if (!_selectedFeelings.add(feeling.$2)) {
                              _selectedFeelings.remove(feeling.$2);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Or write anything else you want to share',
                    style: TextStyle(
                      color: Color(0xFF203454),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  TextField(
                    controller: _customController,
                    onChanged: (_) => setState(() {}),
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 250,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'What would you like to add?',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8994AA),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8EF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8EF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: widget.topic.color,
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SelfRegulationAnswerReview(
                    topic: widget.topic,
                    answer: _currentAnswer,
                    showEmptyHint: true,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 7, 20, 8),
          child: SizedBox(
            height: 46,
            child: FilledButton(
              onPressed: canContinue ? _continue : null,
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
                  Text('Done'),
                  SizedBox(width: 8),
                  Icon(Icons.check_rounded, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatementTile extends StatelessWidget {
  const _StatementTile({
    required this.statement,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String statement;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(18) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color.withAlpha(130) : const Color(0xFFE5EAF0),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0B203454),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                statement,
                style: const TextStyle(
                  color: Color(0xFF263754),
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Checkbox(
              value: selected,
              onChanged: (_) => onTap(),
              activeColor: color,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    ),
  );
}

class _FeelingChip extends StatelessWidget {
  const _FeelingChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text('$emoji  $label'),
    selected: selected,
    onSelected: (_) => onTap(),
    showCheckmark: false,
    backgroundColor: Colors.white,
    selectedColor: color.withAlpha(24),
    side: BorderSide(
      color: selected ? color.withAlpha(130) : const Color(0xFFE5EAF0),
    ),
    labelStyle: TextStyle(
      color: selected ? color : const Color(0xFF52617A),
      fontSize: 11,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    ),
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 3),
  );
}

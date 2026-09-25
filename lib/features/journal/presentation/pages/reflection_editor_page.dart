import 'package:flutter/material.dart';

import '../../../authentication/data/auth_api.dart';

class ReflectionEditorPage extends StatefulWidget {
  const ReflectionEditorPage({
    super.key,
    required this.token,
    required this.category,
    required this.initialText,
    this.mood,
    this.responses = const [],
    this.customText = '',
    this.sections = const [],
    this.showStepProgress = false,
  });

  final String token;
  final String category;
  final String initialText;
  final String? mood;
  final List<String> responses;
  final String customText;
  final List<Map<String, Object?>> sections;
  final bool showStepProgress;

  @override
  State<ReflectionEditorPage> createState() => _ReflectionEditorPageState();
}

class _ReflectionEditorPageState extends State<ReflectionEditorPage> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _formattedNoteText();
    if (text.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final note = await AuthApi.createJournalNote(
        token: widget.token,
        category: widget.category,
        text: text,
        mood: widget.mood,
        responses: widget.responses,
        customText: widget.customText,
        sections: widget.sections,
      );
      if (mounted) Navigator.of(context).pop(note);
    } on AuthApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool get _hasContent =>
      widget.sections.isNotEmpty || _controller.text.trim().isNotEmpty;

  String _formattedNoteText() {
    if (widget.sections.isEmpty) return _controller.text.trim();
    final lines = <String>[];
    for (final section in widget.sections) {
      final title = section['subcategory']?.toString() ?? 'Reflection';
      final statements = (section['selectedStatements'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false);
      final feelings = (section['feelings'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false);
      final ownWords = section['customText']?.toString().trim() ?? '';
      lines.add(title.toUpperCase());
      if (statements.isNotEmpty) {
        lines.addAll([
          'WHAT I CHOSE',
          for (final item in statements) '- $item',
        ]);
      }
      if (feelings.isNotEmpty) {
        lines.addAll([
          'HOW IT FEELS',
          for (final feeling in feelings)
            '- ${_feelingEmoji(feeling)} $feeling',
        ]);
      }
      if (ownWords.isNotEmpty) lines.addAll(['IN MY OWN WORDS', ownWords]);
      lines.add('');
    }
    final extraThoughts = _controller.text.trim();
    if (extraThoughts.isNotEmpty) {
      lines.addAll(['MY REFLECTION', extraThoughts]);
    }
    return lines.join('\n').trim();
  }

  String _feelingEmoji(String feeling) => switch (feeling) {
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

  String _indiaReviewTimestamp() {
    final dateTime = DateTime.now().toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}, '
        '$hour:$minute $period IST';
  }

  Widget _editorField({int maxLength = 5000}) {
    final isExpanded = maxLength == 5000;
    return TextField(
      controller: _controller,
      autofocus: widget.sections.isEmpty && widget.initialText.isEmpty,
      minLines: isExpanded ? null : 4,
      maxLines: isExpanded ? null : 5,
      expands: isExpanded,
      onChanged: (_) => setState(() {}),
      textCapitalization: TextCapitalization.sentences,
      maxLength: maxLength,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        hintText: 'Write what is on your mind…',
        filled: true,
        fillColor: Colors.white,
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDCE5F1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDCE5F1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF18A77F), width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        title: widget.showStepProgress
            ? const Row(
                children: [
                  Expanded(child: Text('Your Reflection')),
                  Text(
                    'Step 4 of 4',
                    style: TextStyle(
                      color: Color(0xFF65728E),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : const Text('Your Reflection'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFF148F73),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.category}  ·  Private',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF167F6C),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (widget.mood != null) Text(widget.mood!),
                  ],
                ),
              ),
              if (widget.sections.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: Color(0xFF75839D),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Review time  ·  ${_indiaReviewTimestamp()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF75839D),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Expanded(
                child: widget.sections.isEmpty
                    ? _editorField()
                    : ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Your reflection overview',
                                  style: TextStyle(
                                    color: Color(0xFF203454),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF7F4),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${widget.sections.length} '
                                  '${widget.sections.length == 1 ? 'topic' : 'topics'}',
                                  style: const TextStyle(
                                    color: Color(0xFF168D78),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Everything below updates from the choices you made.',
                            style: TextStyle(
                              color: Color(0xFF78859B),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (final section in widget.sections)
                            _ReflectionSectionCard(section: section),
                          const SizedBox(height: 10),
                          const Text(
                            'Add anything else you would like to share',
                            style: TextStyle(
                              color: Color(0xFF203454),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 150,
                            child: _editorField(maxLength: 2000),
                          ),
                          if (_controller.text.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _LiveOwnWordsReview(text: _controller.text.trim()),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isSaving || !_hasContent ? null : _save,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_isSaving ? 'Saving…' : 'Save note'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF13A483),
                    disabledBackgroundColor: const Color(0xFFE1E7EE),
                    disabledForegroundColor: const Color(0xFF8A96A8),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReflectionSectionCard extends StatelessWidget {
  const _ReflectionSectionCard({required this.section});

  final Map<String, Object?> section;

  String _feelingEmoji(String feeling) => switch (feeling) {
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
    final statements = (section['selectedStatements'] as List? ?? const [])
        .whereType<String>()
        .toList(growable: false);
    final feelings = (section['feelings'] as List? ?? const [])
        .whereType<String>()
        .toList(growable: false);
    final ownWords = section['customText']?.toString().trim() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EAF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080B2B4B),
            blurRadius: 9,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section['subcategory']?.toString() ?? 'Reflection',
            style: const TextStyle(
              color: Color(0xFF203454),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (statements.isNotEmpty) ...[
            const SizedBox(height: 10),
            const _SectionSubheading('What I chose'),
            const SizedBox(height: 4),
            for (final statement in statements)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  '• $statement',
                  style: const TextStyle(
                    color: Color(0xFF53627A),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
          ],
          if (feelings.isNotEmpty) ...[
            const SizedBox(height: 10),
            const _SectionSubheading('How it feels'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final feeling in feelings)
                  Chip(
                    avatar: Text(_feelingEmoji(feeling)),
                    label: Text(feeling),
                    visualDensity: VisualDensity.compact,
                    labelStyle: const TextStyle(fontSize: 11),
                    backgroundColor: const Color(0xFFEAF7F4),
                    side: BorderSide.none,
                  ),
              ],
            ),
          ],
          if (ownWords.isNotEmpty) ...[
            const SizedBox(height: 10),
            const _SectionSubheading('In my own words'),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                ownWords,
                style: const TextStyle(
                  color: Color(0xFF53627A),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionSubheading extends StatelessWidget {
  const _SectionSubheading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: Color(0xFF168D78),
      fontSize: 11,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _LiveOwnWordsReview extends StatelessWidget {
  const _LiveOwnWordsReview({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF7F4),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFD2EEE6)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your words',
          style: TextStyle(
            color: Color(0xFF168D78),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF203454),
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

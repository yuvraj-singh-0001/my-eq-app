import 'package:flutter/material.dart';

import '../../../authentication/data/auth_api.dart';
import '../widgets/parent_bottom_nav.dart';
import '../widgets/shared_reflection_overview.dart';
import '../widgets/teacher_feedback_card.dart';
import 'parent_dashboard_page.dart';
import 'parent_navigation_page.dart';

class ParentStudentPage extends StatefulWidget {
  const ParentStudentPage({
    super.key,
    required this.token,
    required this.student,
    required this.parent,
    this.initialSection = 1,
  });
  final String token;
  final GrowthConnectionData student;
  final LoginResult parent;
  final int initialSection;
  @override
  State<ParentStudentPage> createState() => _ParentStudentPageState();
}

class _ParentStudentPageState extends State<ParentStudentPage> {
  List<JournalNoteData> _notes = const [];
  StudentGrowthSummaryData? _summary;
  List<GrowthGoalData> _goals = const [];
  late int _section = widget.initialSection;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final accountId = widget.student.accountId;
      final results = await Future.wait([
        AuthApi.getParentStudentJournalNotes(
          token: widget.token,
          studentId: widget.student.id,
        ),
        if (accountId != null && accountId.isNotEmpty) ...[
          AuthApi.getParentStudentGrowthSummary(
            token: widget.token,
            studentId: accountId,
          ),
          AuthApi.getParentStudentGoals(
            token: widget.token,
            studentId: accountId,
          ),
        ],
      ]);
      final page = results[0] as JournalNotesPage;
      if (!mounted) return;
      setState(() {
        _notes = page.notes;
        if (results.length > 1) {
          _summary = results[1] as StudentGrowthSummaryData;
          _goals = results[2] as List<GrowthGoalData>;
        }
        _loading = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  String _date(DateTime date) {
    final local = date.toUtc().add(const Duration(hours: 5, minutes: 30));
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
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F9FA),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF5F9FA),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.student.fullName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          Text(
            [
              if (widget.student.className != null) widget.student.className!,
              if (widget.student.accountId != null)
                'ID ${widget.student.accountId}',
            ].join(' · '),
            style: const TextStyle(fontSize: 11, color: Color(0xFF748198)),
          ),
        ],
      ),
    ),
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(17, 12, 17, 26),
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F5F1),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_open_rounded, color: Color(0xFF168C73)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'These are reflections your child has chosen to share with you. Private notes stay private.',
                      style: TextStyle(
                        color: Color(0xFF42675F),
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Reflections'),
                  icon: Icon(Icons.menu_book_outlined),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Progress'),
                  icon: Icon(Icons.insights_outlined),
                ),
              ],
              selected: {_section},
              onSelectionChanged: (selection) =>
                  setState(() => _section = selection.first),
              style: SegmentedButton.styleFrom(
                foregroundColor: const Color(0xFF52627A),
                selectedForegroundColor: const Color(0xFF147F6A),
                selectedBackgroundColor: const Color(0xFFDFF4EE),
              ),
            ),
            const SizedBox(height: 16),
            if (_section == 1)
              ..._buildProgressContent()
            else ...[
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Shared reflections',
                      style: TextStyle(
                        color: Color(0xFF182D4C),
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${_notes.length}',
                    style: const TextStyle(
                      color: Color(0xFF159976),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_loading && _notes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF159976)),
                  ),
                )
              else if (_error != null && _notes.isEmpty)
                _StateCard(
                  text: _error!,
                  icon: Icons.cloud_off_outlined,
                  onRetry: _load,
                )
              else if (_notes.isEmpty)
                const _StateCard(
                  text: 'No reflections have been shared yet. Your child can choose to share a note while writing it.',
                  icon: Icons.menu_book_outlined,
                )
              else
                for (final note in _notes) ...[
                  _ReflectionCard(note: note, date: _date(note.createdAt)),
                  const SizedBox(height: 10),
                ],
            ],
          ],
        ),
      ),
    ),
    bottomNavigationBar: ParentBottomNav(
      currentIndex: 2,
      onTap: (index) {
        if (index == 2) return;
        if (index == 0) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => ParentDashboardPage(result: widget.parent),
            ),
          );
        } else {
          // The parent bottom menu keeps the existing signed-in context on other sections.
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => ParentNavigationPage(
                result: widget.parent,
                initialIndex: index,
              ),
            ),
          );
        }
      },
    ),
  );

  List<Widget> _buildProgressContent() {
    final summary = _summary;
    final sharedMoods = _notes
        .where((note) => note.mood?.isNotEmpty == true)
        .toList();
    final latestMood = sharedMoods.isEmpty ? null : sharedMoods.first.mood;
    return [
      SharedReflectionOverview(notes: _notes),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF6F3),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            const Icon(Icons.mood_rounded, color: Color(0xFF168C73), size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Latest shared mood',
                    style: TextStyle(color: Color(0xFF638078), fontSize: 11),
                  ),
                  Text(
                    latestMood ?? 'No shared mood yet',
                    style: const TextStyle(
                      color: Color(0xFF183B35),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${sharedMoods.length} shared',
              style: const TextStyle(
                color: Color(0xFF638078),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.track_changes_rounded,
              color: Color(0xFF168C73),
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Growth check-ins',
                    style: TextStyle(color: Color(0xFF728097), fontSize: 11),
                  ),
                  Text(
                    '${summary?.totalCheckIns ?? 0}',
                    style: const TextStyle(
                      color: Color(0xFF182D4C),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const Text(
        'Goals',
        style: TextStyle(
          color: Color(0xFF182D4C),
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 9),
      if (_goals.isEmpty)
        const _StateCard(
          text: 'No school goals are available yet.',
          icon: Icons.flag_outlined,
        )
      else
        for (final goal in _goals) ...[
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.title,
                        style: const TextStyle(
                          color: Color(0xFF203454),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '${goal.currentProgress}%',
                      style: const TextStyle(
                        color: Color(0xFF168C73),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                LinearProgressIndicator(
                  value: goal.currentProgress / 100,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF18A77F),
                  backgroundColor: const Color(0xFFE6EBF0),
                ),
                if (goal.teacherNote.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    goal.teacherNote,
                    style: const TextStyle(
                      color: Color(0xFF65758D),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 9),
        ],
      const SizedBox(height: 8),
      const Text(
        'Updates from the connected teacher',
        style: TextStyle(
          color: Color(0xFF182D4C),
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 9),
      if (summary?.teacherUpdates.isNotEmpty != true)
        const _StateCard(
          text: 'Teacher feedback will appear here when the connected teacher shares a progress update.',
          icon: Icons.chat_bubble_outline_rounded,
        )
      else
        for (final update in summary!.teacherUpdates) ...[
          TeacherFeedbackCard(
            update: update,
            date: update.createdAt == null ? null : _date(update.createdAt!),
          ),
          const SizedBox(height: 9),
        ],
      const SizedBox(height: 8),
      const Text(
        'Recent support check-ins',
        style: TextStyle(
          color: Color(0xFF182D4C),
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 9),
      if (summary?.recent.isEmpty ?? true)
        const _StateCard(
          text: 'There are no progress check-ins to show yet.',
          icon: Icons.insights_outlined,
        )
      else
        for (final item in summary!.recent.take(5)) ...[
          _StateCard(
            text:
                '${item['authorName'] ?? 'Account'} | ${(item['focusArea'] as String? ?? 'Growth').replaceAll('_', ' ')} | ${_progressName(item['progress'] as String?)}',
            icon: Icons.check_circle_outline_rounded,
          ),
          const SizedBox(height: 8),
        ],
    ];
  }

  String _progressName(String? progress) => switch (progress) {
    'improving' => 'Improving',
    'steady' => 'Steady',
    'harder' => 'More challenging',
    _ => 'Follow-up suggested',
  };
}

class _ReflectionCard extends StatelessWidget {
  const _ReflectionCard({required this.note, required this.date});
  final JournalNoteData note;
  final String date;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A183452),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                note.category,
                style: const TextStyle(
                  color: Color(0xFF182D4C),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (note.mood?.isNotEmpty == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6F3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  note.mood!,
                  style: const TextStyle(
                    color: Color(0xFF168C73),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          date,
          style: const TextStyle(color: Color(0xFF8390A3), fontSize: 11),
        ),
        const SizedBox(height: 12),
        SelectableText(
          note.text,
          style: const TextStyle(
            color: Color(0xFF394A64),
            fontSize: 13,
            height: 1.55,
          ),
        ),
      ],
    ),
  );
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.text, required this.icon, this.onRetry});
  final String text;
  final IconData icon;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF708198)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF64738A),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ),
        if (onRetry != null)
          IconButton(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
          ),
      ],
    ),
  );
}

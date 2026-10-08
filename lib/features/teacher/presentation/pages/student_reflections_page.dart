import 'package:flutter/material.dart';

import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../authentication/data/auth_api.dart';
import '../../../authentication/data/auth_session.dart';
import '../../../authentication/presentation/pages/login_page.dart';
import '../../../dashboard/presentation/pages/profile_page.dart';
import 'teacher_messages_page.dart';

class StudentReflectionsPage extends StatefulWidget {
  const StudentReflectionsPage({
    super.key,
    required this.result,
    required this.student,
  });

  final LoginResult result;
  final GrowthConnectionData student;

  @override
  State<StudentReflectionsPage> createState() => _StudentReflectionsPageState();
}

enum _ReflectionPeriod { all, week, month }

class _StudentReflectionsPageState extends State<StudentReflectionsPage> {
  static const _knownCategories = [
    'Sports',
    'Exam',
    'School',
    'Public Speaking',
    'Social',
    'Competition',
  ];
  final _scrollController = ScrollController();
  final List<JournalNoteData> _notes = [];
  String? _category;
  _ReflectionPeriod _period = _ReflectionPeriod.all;
  String? _cursor;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  String? get _token => widget.result.token;
  String? get _studentId => widget.student.accountId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 280 &&
        _hasMore &&
        !_loadingMore) {
      _load();
    }
  }

  DateTime? get _fromDate {
    final now = DateTime.now();
    return switch (_period) {
      _ReflectionPeriod.all => null,
      _ReflectionPeriod.week => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - DateTime.monday)),
      _ReflectionPeriod.month => DateTime(now.year, now.month),
    };
  }

  Future<void> _load({bool reset = false}) async {
    final token = _token;
    final studentId = _studentId;
    if (token == null ||
        token.isEmpty ||
        studentId == null ||
        studentId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Student details are unavailable. Please return to the profile and retry.';
      });
      return;
    }
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _notes.clear();
        _cursor = null;
        _hasMore = false;
      });
    } else {
      if (!_hasMore || _loadingMore) return;
      setState(() => _loadingMore = true);
    }
    try {
      final from = _fromDate;
      final now = DateTime.now();
      final page = await AuthApi.getTeacherStudentJournalNotes(
        token: token,
        studentId: studentId,
        cursor: reset ? null : _cursor,
        category: _category,
        from: from,
        to: from == null
            ? null
            : DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
      );
      if (!mounted) return;
      setState(() {
        _notes.addAll(page.notes);
        _hasMore = page.hasMore;
        _cursor = page.nextCursor;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } on AuthApiException catch (error) {
      if (error.statusCode == 401) {
        await AuthSession.clear();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil<void>(
          MaterialPageRoute<void>(
            builder: (_) => const LoginPage(initialRole: 1),
          ),
          (_) => false,
        );
        return;
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
          _error = 'Please check your connection and try again.';
        });
      }
    }
  }

  Future<void> _changeFilters({
    String? category,
    _ReflectionPeriod? period,
  }) async {
    setState(() {
      if (category != null || _category != null) _category = category;
      if (period != null) _period = period;
    });
    await _load(reset: true);
  }

  void _onNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case 1:
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        break;
      case 2:
        _showUnavailable('Insights');
        break;
      case 3:
        TeacherMessagesPage.open(context, widget.result);
        break;
      case 4:
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ProfilePage(result: widget.result),
          ),
        );
        break;
    }
  }

  void _showUnavailable(String name) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$name is not available yet.')));

  List<String> get _categories {
    final values = <String>{
      ..._knownCategories,
      ..._notes.map((note) => note.category),
    };
    return ['All', ...values.where((value) => value.toLowerCase() != 'all')];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F8FC),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF5F8FC),
      foregroundColor: const Color(0xFF203454),
      title: const Text(
        'Reflections',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.student.fullName,
                      style: const TextStyle(
                        color: Color(0xFF203454),
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _classLabel,
                      style: const TextStyle(
                        color: Color(0xFF78859B),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 17),
                    SizedBox(
                      height: 39,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final label = _categories[index];
                          final value = label == 'All' ? null : label;
                          final selected = _category == value;
                          return ChoiceChip(
                            label: Text(label),
                            selected: selected,
                            onSelected: (_) => _changeFilters(category: value),
                            showCheckmark: false,
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFF149B78),
                            side: BorderSide(
                              color: selected
                                  ? const Color(0xFF149B78)
                                  : const Color(0xFFE0E8EF),
                            ),
                            labelStyle: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF586A82),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 13),
                    Row(
                      children: [
                        const Text(
                          'Date range',
                          style: TextStyle(
                            color: Color(0xFF203454),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<_ReflectionPeriod>(
                            value: _period,
                            isDense: true,
                            borderRadius: BorderRadius.circular(12),
                            style: const TextStyle(
                              color: Color(0xFF40516A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: _ReflectionPeriod.week,
                                child: Text('This Week'),
                              ),
                              DropdownMenuItem(
                                value: _ReflectionPeriod.month,
                                child: Text('This Month'),
                              ),
                              DropdownMenuItem(
                                value: _ReflectionPeriod.all,
                                child: Text('All Time'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) _changeFilters(period: value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, index) => const _ReflectionSkeleton(),
                  childCount: 3,
                ),
              )
            else if (_error != null && _notes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _StateCard(
                  icon: Icons.cloud_off_outlined,
                  title: 'Unable to load reflections',
                  message: _error!,
                  actionLabel: 'Retry',
                  onAction: () => _load(reset: true),
                ),
              )
            else if (_notes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _StateCard(
                  icon: Icons.edit_note_rounded,
                  title: _category == null && _period == _ReflectionPeriod.all
                      ? 'No reflections yet'
                      : 'No reflections found',
                  message: _category == null && _period == _ReflectionPeriod.all
                      ? 'Student reflections will appear here when they share their experiences.'
                      : 'Try another category or date range.',
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ReflectionCard(
                      note: _notes[index],
                      onTap: () => _showDetail(_notes[index]),
                    ),
                    childCount: _notes.length,
                  ),
                ),
              ),
              if (_loadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF149B78),
                      ),
                    ),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: TextButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Could not load more. Retry'),
                    ),
                  ),
                )
              else if (_hasMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: TextButton(
                        onPressed: _load,
                        child: const Text('Load more reflections'),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    ),
    bottomNavigationBar: AppBottomNav(
      selectedIndex: 1,
      forTeacher: true,
      onDestinationSelected: _onNavigation,
    ),
  );

  String get _classLabel {
    final parts = [
      widget.student.className,
      widget.student.section,
    ].where((v) => v?.trim().isNotEmpty == true).cast<String>().toList();
    return parts.isEmpty ? 'Student' : 'Class ${parts.join('-')}';
  }

  Future<void> _showDetail(JournalNoteData note) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ReflectionDetail(note: note),
  );
}

class _ReflectionCard extends StatelessWidget {
  const _ReflectionCard({required this.note, required this.onTap});
  final JournalNoteData note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mood = note.mood;
    final feelings = note.sections
        .expand(
          (section) => (section['feelings'] as List<dynamic>? ?? const [])
              .whereType<String>(),
        )
        .toSet()
        .toList();
    final icon = switch (note.category.toLowerCase()) {
      'sports' => Icons.sports_soccer_rounded,
      'exam' => Icons.menu_book_rounded,
      'school' => Icons.school_outlined,
      'public speaking' || 'presentation' => Icons.mic_none_rounded,
      'social' || 'social situation' || 'friends' => Icons.groups_outlined,
      'competition' => Icons.emoji_events_outlined,
      _ => Icons.edit_note_rounded,
    };
    final color = _moodColor(mood);
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE6ECF2)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x070F2D4A),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F7F3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFF149B78),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.category,
                            style: const TextStyle(
                              color: Color(0xFF203454),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _dateLabel(note.createdAt),
                            style: const TextStyle(
                              color: Color(0xFF78859B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF96A3B4),
                    ),
                  ],
                ),
                if (note.text.isNotEmpty) ...[
                  const SizedBox(height: 11),
                  Text(
                    '“${note.text}”',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF40516A),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
                if (mood?.isNotEmpty == true || feelings.isNotEmpty) ...[
                  const SizedBox(height: 11),
                  Wrap(
                    spacing: 7,
                    runSpacing: 6,
                    children: [
                      if (mood?.isNotEmpty == true)
                        _Tag(text: mood!, color: color),
                      for (final feeling in feelings.take(3))
                        _Tag(text: feeling, color: const Color(0xFF596B86)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReflectionDetail extends StatelessWidget {
  const _ReflectionDetail({required this.note});
  final JournalNoteData note;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: FractionallySizedBox(
      heightFactor: .92,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.category,
                  style: const TextStyle(
                    color: Color(0xFF203454),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (note.mood?.isNotEmpty == true)
                _Tag(text: note.mood!, color: _moodColor(note.mood)),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            _dateLabel(note.createdAt, includeTime: true),
            style: const TextStyle(color: Color(0xFF78859B), fontSize: 12),
          ),
          if (note.text.isNotEmpty) ...[
            const SizedBox(height: 18),
            const _DetailHeading('Student reflection'),
            const SizedBox(height: 7),
            _DetailSurface(
              child: SelectableText(
                note.text,
                style: const TextStyle(
                  color: Color(0xFF35445D),
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ),
          ],
          for (final section in note.sections) ...[
            if ((section['subcategory'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 16),
              _DetailHeading(section['subcategory'] as String),
            ],
            if ((section['selectedStatements'] as List<dynamic>? ?? const [])
                .isNotEmpty) ...[
              const SizedBox(height: 7),
              _DetailSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final value
                        in (section['selectedStatements'] as List<dynamic>)
                            .whereType<String>())
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '•  ',
                              style: TextStyle(color: Color(0xFF149B78)),
                            ),
                            Expanded(
                              child: Text(
                                value,
                                style: const TextStyle(
                                  color: Color(0xFF40516A),
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if ((section['feelings'] as List<dynamic>? ?? const [])
                .isNotEmpty) ...[
              const SizedBox(height: 9),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final feeling
                      in (section['feelings'] as List<dynamic>)
                          .whereType<String>())
                    _Tag(text: feeling, color: const Color(0xFF596B86)),
                ],
              ),
            ],
            if ((section['customText'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 9),
              _DetailSurface(
                child: Text(
                  section['customText'] as String,
                  style: const TextStyle(
                    color: Color(0xFF40516A),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ],
          if (note.responses.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _DetailHeading('Responses'),
            const SizedBox(height: 7),
            _DetailSurface(
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final response in note.responses)
                    _Tag(text: response, color: const Color(0xFF596B86)),
                ],
              ),
            ),
          ],
          if (note.customText.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _DetailHeading('Additional words'),
            const SizedBox(height: 7),
            _DetailSurface(
              child: SelectableText(
                note.customText,
                style: const TextStyle(
                  color: Color(0xFF40516A),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _DetailHeading extends StatelessWidget {
  const _DetailHeading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF203454),
      fontSize: 14,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _DetailSurface extends StatelessWidget {
  const _DetailSurface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE5ECF2)),
    ),
    child: child,
  );
}

class _ReflectionSkeleton extends StatelessWidget {
  const _ReflectionSkeleton();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 2, 16, 10),
    height: 142,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE6ECF2)),
    ),
    child: const Center(
      child: SizedBox.square(
        dimension: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF149B78),
        ),
      ),
    ),
  );
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: const Color(0xFF149B78)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF203454),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF78859B),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

Color _moodColor(String? mood) => switch (mood) {
  'Great' || 'Good' => const Color(0xFF168064),
  'Okay' => const Color(0xFF3477A9),
  'Low' || 'Hard' => const Color(0xFFB45C39),
  _ => const Color(0xFF596B86),
};

String _dateLabel(DateTime date, {bool includeTime = false}) {
  final local = date.toLocal();
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
  final base = '${local.day} ${months[local.month - 1]} ${local.year}';
  if (!includeTime) return base;
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$base · $hour:$minute ${local.hour >= 12 ? 'PM' : 'AM'}';
}

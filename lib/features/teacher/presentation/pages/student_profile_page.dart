import 'package:flutter/material.dart';

import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../authentication/data/auth_api.dart';
import '../../../authentication/data/auth_session.dart';
import '../../../authentication/presentation/pages/login_page.dart';
import '../../../dashboard/presentation/pages/profile_page.dart';
import 'student_reflections_page.dart';
import 'goals_progress_page.dart';

class TeacherStudentProgressPage extends StatefulWidget {
  const TeacherStudentProgressPage({
    super.key,
    required this.result,
    required this.student,
  });
  final LoginResult result;
  final GrowthConnectionData student;
  @override
  State<TeacherStudentProgressPage> createState() =>
      _TeacherStudentProgressPageState();
}

class _TeacherStudentProgressPageState
    extends State<TeacherStudentProgressPage> {
  StudentGrowthSummaryData? _summary;
  JournalNotesPage? _journal;
  StudentReflectionOverviewData? _reflectionOverview;
  bool _loading = true;
  bool _overviewLoading = false;
  bool _sendingFeedback = false;
  String? _error;
  String? _overviewError;
  int _selectedTab = 0;
  int? _trendDays = 3;
  int _overviewRequestId = 0;

  String? get _token => widget.result.token;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final studentId = widget.student.accountId;
    final token = _token;
    if (studentId == null ||
        studentId.isEmpty ||
        token == null ||
        token.isEmpty) {
      setState(() {
        _error = 'Unable to load student profile. Sign in again and retry.';
        _loading = false;
      });
      return;
    }
    try {
      final values = await Future.wait<Object>([
        AuthApi.getTeacherStudentGrowthSummary(
          token: token,
          studentId: studentId,
        ),
        AuthApi.getTeacherStudentJournalNotes(
          token: token,
          studentId: studentId,
        ),
        AuthApi.getTeacherStudentReflectionOverview(
          token: token,
          studentId: studentId,
          days: _trendDays,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = values[0] as StudentGrowthSummaryData;
        _journal = values[1] as JournalNotesPage;
        _reflectionOverview = values[2] as StudentReflectionOverviewData;
        _loading = false;
        _overviewError = null;
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
          _error = error.statusCode == 403
              ? 'This student is no longer connected to your teacher account.'
              : error.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Please check your connection and try again.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _feedback() async {
    final token = _token;
    final studentId = widget.student.accountId;
    if (token == null ||
        token.isEmpty ||
        studentId == null ||
        studentId.isEmpty) {
      _showUnavailable('Teacher feedback');
      return;
    }
    final feedback = await showModalBottomSheet<_TeacherFeedbackDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _TeacherFeedbackSheet(),
    );
    if (feedback == null || !mounted) return;
    setState(() => _sendingFeedback = true);
    try {
      await AuthApi.submitTeacherStudentFeedback(
        token: token,
        studentId: studentId,
        focusArea: feedback.focusArea,
        progress: feedback.progress,
        observedBehaviors: feedback.observations,
        whatHelped: feedback.whatHelped,
        whatWasHard: feedback.whatWasHard,
        nextStep: feedback.nextStep,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your student feedback has been saved.')),
      );
      await _load();
    } on AuthApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _sendingFeedback = false);
    }
  }

  String? get _latestProgress {
    for (final entry in _summary?.recent ?? const <Map<String, dynamic>>[]) {
      if (entry['authorRole'] == 'teacher' &&
          ['improving', 'steady', 'harder'].contains(entry['progress'])) {
        return entry['progress'] as String;
      }
    }
    return null;
  }

  List<JournalNoteData> get _notes => _journal?.notes ?? const [];

  List<JournalNoteData> get _periodNotes {
    final days = _trendDays;
    if (days == null) return _notes;
    final from = DateTime.now().subtract(Duration(days: days));
    return _notes.where((note) => !note.createdAt.isBefore(from)).toList();
  }

  Future<void> _changeTrendDays(int? days, {bool force = false}) async {
    if (_trendDays == days && !force) return;
    final requestId = ++_overviewRequestId;
    setState(() {
      _trendDays = days;
      _overviewLoading = true;
      _overviewError = null;
      _reflectionOverview = null;
    });
    final token = _token;
    final studentId = widget.student.accountId;
    if (token == null || studentId == null || studentId.isEmpty) {
      setState(() {
        _overviewLoading = false;
        _overviewError = 'Student details are unavailable.';
      });
      return;
    }
    try {
      final overview = await AuthApi.getTeacherStudentReflectionOverview(
        token: token,
        studentId: studentId,
        days: days,
      );
      if (mounted && requestId == _overviewRequestId) {
        setState(() {
          _reflectionOverview = overview;
          _overviewLoading = false;
        });
      }
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
      if (mounted && requestId == _overviewRequestId) {
        setState(() {
          _overviewError = error.message;
          _overviewLoading = false;
        });
      }
    } catch (_) {
      if (mounted && requestId == _overviewRequestId) {
        setState(() {
          _overviewError = 'Please check your connection and try again.';
          _overviewLoading = false;
        });
      }
    }
  }

  Future<void> _retryOverview() => _changeTrendDays(_trendDays, force: true);

  int? get _positiveMoodPercent {
    final counts = _reflectionOverview?.moodCounts ?? const <String, int>{};
    final total = counts.values.fold<int>(0, (sum, count) => sum + count);
    if (total == 0) return null;
    return ((counts['Great'] ?? 0) + (counts['Good'] ?? 0)) * 100 ~/ total;
  }

  int? get _attentionAreas {
    final focusAreas = _summary?.byFocusArea;
    if (focusAreas == null) return null;
    var count = 0;
    var foundTeacherData = false;
    for (final value in focusAreas.values) {
      if (value is! Map<String, dynamic>) continue;
      final teacher = value['teacher'];
      if (teacher is Map<String, dynamic>) {
        foundTeacherData = true;
        if (teacher['latestProgress'] == 'harder') count++;
      }
    }
    return foundTeacherData ? count : null;
  }

  List<String> get _improvingAreas {
    final result = <String>[];
    for (final entry
        in _summary?.byFocusArea.entries ??
            const <MapEntry<String, dynamic>>[]) {
      final sources = entry.value;
      final teacher = sources is Map<String, dynamic>
          ? sources['teacher']
          : null;
      if (teacher is Map<String, dynamic> &&
          teacher['latestProgress'] == 'improving') {
        result.add(_areaLabel(entry.key));
      }
    }
    return result.take(4).toList(growable: false);
  }

  void _showUnavailable(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature is not available yet.')));
  }

  void _openReflections() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => StudentReflectionsPage(
          result: widget.result,
          student: widget.student,
        ),
      ),
    );
  }

  void _openGoals() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            GoalsProgressPage(result: widget.result, student: widget.student),
      ),
    );
  }

  void _onNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case 1:
        Navigator.of(context).pop();
        break;
      case 2:
        _showUnavailable('Insights');
        break;
      case 3:
        _showUnavailable('Messages');
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

  Future<void> _openReflection(JournalNoteData note) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    note.category,
                    style: const TextStyle(
                      color: Color(0xFF203454),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(note.createdAt),
                    style: const TextStyle(
                      color: Color(0xFF78859B),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    note.text,
                    style: const TextStyle(
                      color: Color(0xFF40516A),
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                  if (note.mood?.isNotEmpty == true) ...[
                    const SizedBox(height: 14),
                    _MoodLabel(mood: note.mood!),
                  ],
                ],
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F8FC),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF5F8FC),
      foregroundColor: const Color(0xFF203454),
      title: const Text(
        'Student Profile',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        PopupMenuButton<String>(
          enabled: !_sendingFeedback,
          tooltip: 'More student actions',
          onSelected: (action) {
            if (action == 'feedback') _feedback();
            if (action == 'call') _showUnavailable('Calling');
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'feedback',
              child: Text('Share teacher feedback'),
            ),
            PopupMenuItem(value: 'call', child: Text('Call student')),
          ],
        ),
      ],
    ),
    body: SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          children: [
            _StudentIdentityCard(
              student: widget.student,
              progress: _latestProgress,
            ),
            const SizedBox(height: 14),
            _ProfileTabs(
              selectedIndex: _selectedTab,
              onSelected: (index) {
                if (index == 1) {
                  _openReflections();
                } else if (index == 2) {
                  _openGoals();
                } else {
                  setState(() => _selectedTab = index);
                }
              },
            ),
            const SizedBox(height: 14),
            if (_loading)
              const _ProfileLoadingState()
            else if (_error != null)
              _ProfileErrorState(message: _error!, onRetry: _load)
            else if (_selectedTab == 0)
              ..._overviewContent()
            else
              _ProfileTabPlaceholder(tabIndex: _selectedTab),
          ],
        ),
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StudentContactActions(
            onMessage: () => _showUnavailable('Student messaging'),
            onCall: () => _showUnavailable('Calling'),
          ),
          AppBottomNav(
            selectedIndex: 1,
            forTeacher: true,
            onDestinationSelected: _onNavigation,
          ),
        ],
      ),
    ),
  );

  List<Widget> _overviewContent() {
    final periodNotes = _periodNotes;
    final latestNote = periodNotes.isEmpty ? null : periodNotes.first;
    final recentActivity = latestNote == null
        ? null
        : '${latestNote.category} reflection · ${_relativeDate(latestNote.createdAt)}';
    final attentionAreas = _attentionAreas;
    return [
      _CurrentOverviewCard(
        mood: latestNote?.mood,
        status: _latestProgress,
        recentActivity: recentActivity,
      ),
      const SizedBox(height: 14),
      _MoodTrendCard(
        overview: _reflectionOverview,
        days: _trendDays,
        isLoading: _overviewLoading,
        error: _overviewError,
        onDaysChanged: _changeTrendDays,
        onRetry: _retryOverview,
      ),
      const SizedBox(height: 14),
      _ReflectionOverviewCard(
        overview: _reflectionOverview,
        days: _trendDays,
        isLoading: _overviewLoading,
      ),
      const SizedBox(height: 14),
      _ProfileMetricGrid(
        values: [
          (
            Icons.sentiment_satisfied_alt_rounded,
            'Positive Mood',
            _positiveMoodPercent == null ? '--' : '$_positiveMoodPercent%',
            const Color(0xFF168064),
            const Color(0xFFE6F7F1),
          ),
          (
            Icons.track_changes_rounded,
            'Active Goals',
            '--',
            const Color(0xFF3477A9),
            const Color(0xFFEAF3FF),
          ),
          (
            Icons.edit_note_rounded,
            'Reflections',
            _reflectionOverview == null
                ? '--'
                : '${_reflectionOverview!.totalReflections}',
            const Color(0xFF775CB2),
            const Color(0xFFF1EDFA),
          ),
          (
            Icons.warning_amber_rounded,
            'Needs Attention',
            attentionAreas?.toString() ?? '--',
            const Color(0xFFB45C39),
            const Color(0xFFFFF0E8),
          ),
        ],
      ),
      const SizedBox(height: 18),
      _ProgressAreas(areas: _improvingAreas),
      const SizedBox(height: 14),
      _RecentReflections(
        notes: periodNotes.take(3).toList(growable: false),
        hasMore: _journal?.hasMore ?? false,
        onOpen: _openReflection,
        onViewAll: _openReflections,
      ),
      if (periodNotes.isNotEmpty) ...[
        const SizedBox(height: 12),
        _StudentReflectionDetails(notes: periodNotes.take(3).toList()),
      ],
      const SizedBox(height: 14),
      _GoalsCard(onTap: _openGoals),
      if (_summary?.recent.isNotEmpty == true) ...[
        const SizedBox(height: 18),
        const Text(
          'Recent growth updates',
          style: TextStyle(
            color: Color(0xFF203454),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        for (final entry in _summary!.recent.take(3))
          _FeedbackHistoryCard(entry: entry),
      ],
    ];
  }
}

class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs({required this.selectedIndex, required this.onSelected});
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const labels = ['Overview', 'Reflections', 'Goals', 'Reports'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: InkWell(
              onTap: () => onSelected(i),
              borderRadius: BorderRadius.circular(13),
              child: Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selectedIndex == i
                      ? const Color(0xFF149B78)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: selectedIndex == i
                        ? const Color(0xFF149B78)
                        : const Color(0xFFE5EBF1),
                  ),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    color: selectedIndex == i
                        ? Colors.white
                        : const Color(0xFF5E6E84),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE7EDF3)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080F2D4A),
          blurRadius: 12,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

class _ProfileLoadingState extends StatelessWidget {
  const _ProfileLoadingState();
  @override
  Widget build(BuildContext context) => const Column(
    children: [
      SizedBox(height: 12),
      _ProfilePanel(
        child: SizedBox(
          height: 72,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF149B78),
            ),
          ),
        ),
      ),
      SizedBox(height: 12),
      _ProfilePanel(
        child: SizedBox(
          height: 150,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF149B78),
            ),
          ),
        ),
      ),
    ],
  );
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => _ProfilePanel(
    child: Column(
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          color: Color(0xFFC3695F),
          size: 30,
        ),
        const SizedBox(height: 8),
        const Text(
          'Unable to load student profile',
          style: TextStyle(
            color: Color(0xFF203454),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF78859B), fontSize: 12),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 17),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}

class _ProfileTabPlaceholder extends StatelessWidget {
  const _ProfileTabPlaceholder({required this.tabIndex});
  final int tabIndex;
  @override
  Widget build(BuildContext context) {
    final (icon, title, message) = switch (tabIndex) {
      1 => (
        Icons.edit_note_rounded,
        'Student reflections',
        'Recent reflections are shown in Overview. The full reflection timeline will be available here.',
      ),
      2 => (
        Icons.track_changes_rounded,
        'Goal tracking unavailable',
        'Goal data is not available in the current backend yet.',
      ),
      _ => (
        Icons.insert_chart_outlined_rounded,
        'Reports are not available yet',
        'Student reports will appear here when report data is available.',
      ),
    };
    return _ProfilePanel(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF149B78), size: 29),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF203454),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF78859B),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodLabel extends StatelessWidget {
  const _MoodLabel({required this.mood});
  final String mood;
  @override
  Widget build(BuildContext context) {
    final (icon, color, tint) = switch (mood) {
      'Great' => (
        Icons.sentiment_very_satisfied_rounded,
        const Color(0xFF168064),
        const Color(0xFFE6F7F1),
      ),
      'Good' => (
        Icons.sentiment_satisfied_alt_rounded,
        const Color(0xFF168064),
        const Color(0xFFE6F7F1),
      ),
      'Okay' => (
        Icons.sentiment_neutral_rounded,
        const Color(0xFFAE7A13),
        const Color(0xFFFFF5DA),
      ),
      'Low' => (
        Icons.sentiment_dissatisfied_rounded,
        const Color(0xFFB45C39),
        const Color(0xFFFFF0E8),
      ),
      _ => (
        Icons.sentiment_very_dissatisfied_rounded,
        const Color(0xFFB45C39),
        const Color(0xFFFFF0E8),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            mood,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentOverviewCard extends StatelessWidget {
  const _CurrentOverviewCard({
    required this.mood,
    required this.status,
    required this.recentActivity,
  });
  final String? mood;
  final String? status;
  final String? recentActivity;
  @override
  Widget build(BuildContext context) => _ProfilePanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current overview',
          style: TextStyle(
            color: Color(0xFF203454),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current mood',
                    style: TextStyle(color: Color(0xFF8793A6), fontSize: 10),
                  ),
                  const SizedBox(height: 5),
                  if (mood == null || mood!.isEmpty)
                    const Text(
                      'No recent mood update',
                      style: TextStyle(color: Color(0xFF78859B), fontSize: 12),
                    )
                  else
                    _MoodLabel(mood: mood!),
                ],
              ),
            ),
            if (status != null) _ProfileStatusBadge(progress: status!),
          ],
        ),
        if (recentActivity != null) ...[
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEAF0F4)),
          const SizedBox(height: 8),
          Text(
            recentActivity!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF5D6D83), fontSize: 11),
          ),
        ],
      ],
    ),
  );
}

class _ProfileMetricGrid extends StatelessWidget {
  const _ProfileMetricGrid({required this.values});
  final List<(IconData, String, String, Color, Color)> values;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - 10) / 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final (icon, label, value, color, tint) in values)
            SizedBox(
              width: width,
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE7EDF3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: tint,
                      child: Icon(icon, size: 16, color: color),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF68768C),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            value,
                            style: TextStyle(
                              color: color,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _RecentReflections extends StatelessWidget {
  const _RecentReflections({
    required this.notes,
    required this.hasMore,
    required this.onOpen,
    required this.onViewAll,
  });
  final List<JournalNoteData> notes;
  final bool hasMore;
  final ValueChanged<JournalNoteData> onOpen;
  final VoidCallback onViewAll;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Recent reflections',
              style: TextStyle(
                color: Color(0xFF203454),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (notes.isNotEmpty || hasMore)
            TextButton(onPressed: onViewAll, child: const Text('View all')),
        ],
      ),
      if (notes.isEmpty)
        const _ProfilePanel(
          child: Column(
            children: [
              Icon(Icons.edit_note_rounded, color: Color(0xFF149B78), size: 28),
              SizedBox(height: 7),
              Text(
                'No reflections yet',
                style: TextStyle(
                  color: Color(0xFF203454),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Student reflections will appear here when they share their experiences.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF78859B),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        )
      else
        for (final note in notes)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE7EDF3)),
            ),
            child: InkWell(
              onTap: () => onOpen(note),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.edit_note_rounded,
                          color: Color(0xFF149B78),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            note.category,
                            style: const TextStyle(
                              color: Color(0xFF203454),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(note.createdAt),
                          style: const TextStyle(
                            color: Color(0xFF8793A6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      note.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF56647A),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    if (note.mood?.isNotEmpty == true) ...[
                      const SizedBox(height: 7),
                      _MoodLabel(mood: note.mood!),
                    ],
                  ],
                ),
              ),
            ),
          ),
    ],
  );
}

class _MoodTrendCard extends StatelessWidget {
  const _MoodTrendCard({
    required this.overview,
    required this.days,
    required this.isLoading,
    required this.error,
    required this.onDaysChanged,
    required this.onRetry,
  });
  final StudentReflectionOverviewData? overview;
  final int? days;
  final bool isLoading;
  final String? error;
  final ValueChanged<int?> onDaysChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final points = overview?.trend ?? const <MoodTrendPointData>[];
    final selected = days?.toString() ?? 'all';
    return _ProfilePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Mood Trend',
                  style: TextStyle(
                    color: Color(0xFF203454),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '3', label: Text('3 days')),
                  ButtonSegment(value: '5', label: Text('5 days')),
                  ButtonSegment(value: 'all', label: Text('All')),
                ],
                selected: {selected},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  final value = selection.first;
                  onDaysChanged(value == 'all' ? null : int.parse(value));
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 10)),
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (error != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: Color(0xFFAB4F3A),
                      fontSize: 11,
                    ),
                  ),
                ),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            )
          else if (isLoading && overview == null)
            const SizedBox(
              height: 90,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF149B78),
                ),
              ),
            )
          else if (points.isEmpty)
            const SizedBox(
              height: 78,
              child: Center(
                child: Text(
                  'No mood entries in this date range yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF8793A6), fontSize: 11),
                ),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 108,
                  width: double.infinity,
                  child: CustomPaint(painter: _MoodTrendPainter(points)),
                ),
                Row(
                  children: [
                    Text(
                      _shortDate(points.first.date),
                      style: const TextStyle(
                        color: Color(0xFF8793A6),
                        fontSize: 9,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${points.length} days with mood entries',
                      style: const TextStyle(
                        color: Color(0xFF8793A6),
                        fontSize: 9,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _shortDate(points.last.date),
                      style: const TextStyle(
                        color: Color(0xFF8793A6),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ReflectionOverviewCard extends StatelessWidget {
  const _ReflectionOverviewCard({
    required this.overview,
    required this.days,
    required this.isLoading,
  });
  final StudentReflectionOverviewData? overview;
  final int? days;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final data = overview;
    if (data == null && isLoading) {
      return const _ProfilePanel(
        child: SizedBox(
          height: 72,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF149B78),
            ),
          ),
        ),
      );
    }
    if (data == null) return const SizedBox.shrink();
    final moodEntries = data.moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topMood = moodEntries.isEmpty ? null : moodEntries.first;
    final topics = data.categoryCounts
        .take(3)
        .map((item) => item.label)
        .toList();
    final feelings = data.feelings.take(3).map((item) => item.label).toList();
    final period = days == null
        ? 'all recorded reflections'
        : 'the last $days days';
    return _ProfilePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reflection overview',
            style: TextStyle(
              color: Color(0xFF203454),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'A summary of the student’s shared entries for this range.',
            style: TextStyle(color: Color(0xFF8793A6), fontSize: 10),
          ),
          const SizedBox(height: 10),
          if (data.totalReflections == 0)
            Text(
              'No reflections were recorded in $period.',
              style: const TextStyle(
                color: Color(0xFF56647A),
                fontSize: 12,
                height: 1.45,
              ),
            )
          else ...[
            Text(
              'The student shared ${data.totalReflections} ${data.totalReflections == 1 ? 'reflection' : 'reflections'} in $period.',
              style: const TextStyle(
                color: Color(0xFF40516A),
                fontSize: 12,
                height: 1.45,
              ),
            ),
            if (topMood != null) ...[
              const SizedBox(height: 7),
              Text(
                'Most recorded mood: ${topMood.key} (${topMood.value} ${topMood.value == 1 ? 'entry' : 'entries'}).',
                style: const TextStyle(
                  color: Color(0xFF40516A),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
            if (topics.isNotEmpty) ...[
              const SizedBox(height: 9),
              const _OverviewSubheading('Topics appearing in entries'),
              const SizedBox(height: 5),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final topic in topics) _OverviewTag(topic)],
              ),
            ],
            if (feelings.isNotEmpty) ...[
              const SizedBox(height: 9),
              const _OverviewSubheading('Feelings selected'),
              const SizedBox(height: 5),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final feeling in feelings) _OverviewTag(feeling),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _StudentReflectionDetails extends StatelessWidget {
  const _StudentReflectionDetails({required this.notes});
  final List<JournalNoteData> notes;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(
          'Student’s reflection details',
          style: TextStyle(
            color: Color(0xFF203454),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      for (final note in notes)
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: _ProfilePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.category,
                        style: const TextStyle(
                          color: Color(0xFF203454),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(note.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF8793A6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                if (note.mood?.isNotEmpty == true) ...[
                  const SizedBox(height: 7),
                  _MoodLabel(mood: note.mood!),
                ],
                if (note.text.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  const _OverviewSubheading('Student’s note'),
                  const SizedBox(height: 4),
                  SelectableText(
                    note.text,
                    style: const TextStyle(
                      color: Color(0xFF40516A),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
                for (final section in note.sections)
                  _ReflectionSectionDetails(section: section),
                if (note.responses.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  const _OverviewSubheading('Selected responses'),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final response in note.responses)
                        _OverviewTag(response),
                    ],
                  ),
                ],
                if (note.customText.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  const _OverviewSubheading('Additional words'),
                  const SizedBox(height: 4),
                  SelectableText(
                    note.customText,
                    style: const TextStyle(
                      color: Color(0xFF40516A),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
    ],
  );
}

class _ReflectionSectionDetails extends StatelessWidget {
  const _ReflectionSectionDetails({required this.section});
  final Map<String, dynamic> section;

  @override
  Widget build(BuildContext context) {
    final heading = section['subcategory'] as String? ?? '';
    final statements =
        (section['selectedStatements'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList();
    final feelings = (section['feelings'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList();
    final ownWords = section['customText'] as String? ?? '';
    if (heading.isEmpty &&
        statements.isEmpty &&
        feelings.isEmpty &&
        ownWords.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (heading.isNotEmpty) _OverviewSubheading(heading),
          if (feelings.isNotEmpty) ...[
            const SizedBox(height: 5),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final feeling in feelings) _OverviewTag(feeling)],
            ),
          ],
          if (statements.isNotEmpty) ...[
            const SizedBox(height: 5),
            for (final statement in statements)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '•  $statement',
                  style: const TextStyle(
                    color: Color(0xFF56647A),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
          ],
          if (ownWords.isNotEmpty) ...[
            const SizedBox(height: 5),
            _OverviewSubheading(
              feelings.isNotEmpty
                  ? 'Student’s context for these feelings'
                  : 'Student’s own words',
            ),
            const SizedBox(height: 3),
            SelectableText(
              ownWords,
              style: const TextStyle(
                color: Color(0xFF40516A),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OverviewSubheading extends StatelessWidget {
  const _OverviewSubheading(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: Color(0xFF203454),
      fontSize: 11,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _OverviewTag extends StatelessWidget {
  const _OverviewTag(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF7F3),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFF168064),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

String _shortDate(DateTime date) => '${date.day}/${date.month}';

class _MoodTrendPainter extends CustomPainter {
  const _MoodTrendPainter(this.points);
  final List<MoodTrendPointData> points;
  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const inset = 12.0;
    final chartHeight = size.height - inset * 2;
    final chartWidth = size.width - inset * 2;
    final grid = Paint()
      ..color = const Color(0xFFEAF0F4)
      ..strokeWidth = 1;
    for (var row = 0; row < 3; row++) {
      final y = inset + chartHeight * row / 2;
      canvas.drawLine(Offset(inset, y), Offset(size.width - inset, y), grid);
    }
    final offsets = <Offset>[];
    final firstDate = points.first.date;
    final lastDate = points.last.date;
    final totalDays = lastDate.difference(firstDate).inDays;
    for (final item in points) {
      final x = totalDays == 0
          ? size.width / 2
          : inset +
                chartWidth * item.date.difference(firstDate).inDays / totalDays;
      final y = inset + chartHeight * (5 - item.average) / 4;
      offsets.add(Offset(x, y));
    }
    final paint = Paint()
      ..color = const Color(0xFF1CA985)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final point in offsets.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
    final dot = Paint()..color = const Color(0xFF149B78);
    for (final point in offsets) {
      canvas.drawCircle(point, 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _MoodTrendPainter oldDelegate) =>
      oldDelegate.points != points;
}

class _StudentContactActions extends StatelessWidget {
  const _StudentContactActions({required this.onMessage, required this.onCall});
  final VoidCallback onMessage;
  final VoidCallback onCall;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 7),
    color: const Color(0xFFF5F8FC),
    child: Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onMessage,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
            label: const Text('Message'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF149B78),
              minimumSize: const Size.fromHeight(43),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCall,
            icon: const Icon(Icons.call_outlined, size: 17),
            label: const Text('Call'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF287ACB),
              side: const BorderSide(color: Color(0xFFD9E6F2)),
              backgroundColor: Colors.white,
              minimumSize: const Size.fromHeight(43),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _StudentIdentityCard extends StatelessWidget {
  const _StudentIdentityCard({required this.student, required this.progress});
  final GrowthConnectionData student;
  final String? progress;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE7EDF3)),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 27,
          backgroundColor: Colors.white,
          child: Text(
            student.fullName.isEmpty ? '?' : student.fullName[0].toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF149B78),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.fullName,
                style: const TextStyle(
                  color: Color(0xFF203454),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              const _ConnectionStatusBadge(),
              if (progress != null) ...[
                const SizedBox(height: 6),
                _ProfileStatusBadge(progress: progress!),
              ],
              const SizedBox(height: 3),
              Text(
                [
                  if (student.accountId?.isNotEmpty == true)
                    'ID ${student.accountId}',
                  if (student.className?.isNotEmpty == true) student.className!,
                  if (student.section?.isNotEmpty == true)
                    'Section ${student.section}',
                ].join(' · '),
                style: const TextStyle(color: Color(0xFF718097), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String _formatDate(DateTime value) {
  final date = value.toLocal();
  return '${date.day}/${date.month}/${date.year}';
}

String _relativeDate(DateTime value) {
  final days = DateTime.now().difference(value).inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  return '$days days ago';
}

class _ConnectionStatusBadge extends StatelessWidget {
  const _ConnectionStatusBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFE6F7F1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 7, color: Color(0xFF1A9B75)),
        SizedBox(width: 5),
        Text(
          'Connected',
          style: TextStyle(
            color: Color(0xFF168064),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _ProfileStatusBadge extends StatelessWidget {
  const _ProfileStatusBadge({required this.progress});
  final String progress;
  @override
  Widget build(BuildContext context) {
    final (label, color, tint) = switch (progress) {
      'improving' => (
        'IMPROVING',
        const Color(0xFF287ACB),
        const Color(0xFFEAF3FF),
      ),
      'steady' => ('AVERAGE', const Color(0xFFAE7A13), const Color(0xFFFFF5DA)),
      'harder' => (
        'NEEDS ATTENTION',
        const Color(0xFFB45C51),
        const Color(0xFFFFEDEE),
      ),
      _ => ('GOOD PROGRESS', const Color(0xFF168064), const Color(0xFFE6F7F1)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProgressAreas extends StatelessWidget {
  const _ProgressAreas({required this.areas});
  final List<String> areas;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Areas showing progress',
        style: TextStyle(
          color: Color(0xFF203454),
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      if (areas.isEmpty)
        const Text(
          'No positive growth areas have been recorded yet.',
          style: TextStyle(color: Color(0xFF78859B), fontSize: 12),
        )
      else
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final area in areas)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  area,
                  style: const TextStyle(
                    color: Color(0xFF168064),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
    ],
  );
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => _ProfilePanel(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFFEAF3FF),
            child: Icon(Icons.track_changes_rounded, color: Color(0xFF3477A9)),
          ),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goals & Progress',
                  style: TextStyle(
                    color: Color(0xFF203454),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'View and support this student’s growth goals.',
                  style: TextStyle(color: Color(0xFF78859B), fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Color(0xFF96A3B4)),
        ],
      ),
    ),
  );
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.value});
  final String value;
  @override
  Widget build(BuildContext context) {
    final (label, color, tint) = switch (value) {
      'improving' => (
        'Improving',
        const Color(0xFF13876B),
        const Color(0xFFE6F7F1),
      ),
      'steady' => ('Steady', const Color(0xFF2977BA), const Color(0xFFEAF3FF)),
      'harder' => (
        'Needs support',
        const Color(0xFFB45C39),
        const Color(0xFFFFF0E8),
      ),
      _ => ('Still learning', const Color(0xFF7462A6), const Color(0xFFF1EDFA)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FeedbackHistoryCard extends StatelessWidget {
  const _FeedbackHistoryCard({required this.entry});
  final Map<String, dynamic> entry;
  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(entry['createdAt'] as String? ?? '')
        ?.toLocal();
    final dateLabel = date == null
        ? ''
        : '${date.day}/${date.month}/${date.year}';
    final observations =
        (entry['observedBehaviors'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .take(2)
            .join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE7EDF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _areaLabel(entry['focusArea'] as String? ?? ''),
                  style: const TextStyle(
                    color: Color(0xFF203454),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              _ProgressBadge(value: entry['progress'] as String? ?? 'not_sure'),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${entry['authorName'] ?? 'Account'} · ${_roleLabel(entry['authorRole'] as String? ?? '')}${dateLabel.isEmpty ? '' : ' · $dateLabel'}',
            style: const TextStyle(color: Color(0xFF8793A6), fontSize: 10),
          ),
          if (observations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              observations,
              style: const TextStyle(
                color: Color(0xFF56647A),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
          if ((entry['nextStep'] as String? ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Next step: ${entry['nextStep']}',
              style: const TextStyle(
                color: Color(0xFF56647A),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeacherFeedbackDraft {
  const _TeacherFeedbackDraft({
    required this.focusArea,
    required this.progress,
    required this.observations,
    required this.whatHelped,
    required this.whatWasHard,
    required this.nextStep,
  });
  final String focusArea;
  final String progress;
  final List<String> observations;
  final String whatHelped;
  final String whatWasHard;
  final String nextStep;
}

class _TeacherFeedbackSheet extends StatefulWidget {
  const _TeacherFeedbackSheet();
  @override
  State<_TeacherFeedbackSheet> createState() => _TeacherFeedbackSheetState();
}

class _TeacherFeedbackSheetState extends State<_TeacherFeedbackSheet> {
  static const _areas = <(String, String)>[
    ('frustration', 'Handling frustration'),
    ('calming_myself', 'Calming myself'),
    ('patience_waiting', 'Patience and waiting'),
    ('helpful_habits', 'Helpful habits'),
    ('impulses', 'Managing impulses'),
    ('changes', 'Handling changes'),
    ('focus', 'Staying focused'),
  ];
  final _observed = TextEditingController();
  final _helped = TextEditingController();
  final _hard = TextEditingController();
  final _next = TextEditingController();
  String _area = 'frustration';
  String _progress = 'improving';

  @override
  void dispose() {
    _observed.dispose();
    _helped.dispose();
    _hard.dispose();
    _next.dispose();
    super.dispose();
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextField(
      controller: controller,
      maxLines: lines,
      maxLength: lines > 1 ? 500 : null,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: lines > 1,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share thoughtful feedback',
              style: TextStyle(
                color: Color(0xFF203454),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'A short, specific note helps the student see their progress.',
              style: TextStyle(color: Color(0xFF78859B), fontSize: 12),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _area,
              decoration: const InputDecoration(
                labelText: 'Focus area',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final area in _areas)
                  DropdownMenuItem(value: area.$1, child: Text(area.$2)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _area = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _progress,
              decoration: const InputDecoration(
                labelText: 'How is it going?',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'improving',
                  child: Text('Making progress'),
                ),
                DropdownMenuItem(
                  value: 'steady',
                  child: Text('Taking steady steps'),
                ),
                DropdownMenuItem(
                  value: 'harder',
                  child: Text('Needs more support'),
                ),
                DropdownMenuItem(
                  value: 'not_sure',
                  child: Text('Not sure yet'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _progress = value);
              },
            ),
            _field(
              _observed,
              'What did you notice? (one point per line)',
              lines: 3,
            ),
            _field(_helped, 'What helped?', lines: 2),
            _field(_hard, 'What felt difficult?', lines: 2),
            _field(_next, 'One helpful next step', lines: 2),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  final observations = _observed.text
                      .split('\n')
                      .map((line) => line.trim())
                      .where((line) => line.isNotEmpty)
                      .take(12)
                      .map(
                        (line) =>
                            line.length > 160 ? line.substring(0, 160) : line,
                      )
                      .toList();
                  final nextStep = _next.text.trim();
                  Navigator.pop(
                    context,
                    _TeacherFeedbackDraft(
                      focusArea: _area,
                      progress: _progress,
                      observations: observations,
                      whatHelped: _helped.text.trim(),
                      whatWasHard: _hard.text.trim(),
                      nextStep: nextStep.substring(
                        0,
                        nextStep.length > 300 ? 300 : nextStep.length,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save feedback'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF149B78),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _areaLabel(String key) => switch (key) {
  'frustration' => 'Handling frustration',
  'calming_myself' => 'Calming myself',
  'patience_waiting' => 'Patience and waiting',
  'helpful_habits' => 'Helpful habits',
  'impulses' => 'Managing impulses',
  'changes' => 'Handling changes',
  'focus' => 'Staying focused',
  _ => key.isEmpty ? 'Growth update' : key,
};

String _roleLabel(String role) => switch (role) {
  'teacher' => 'Teacher',
  'parent' => 'Parent / guardian',
  'student' => 'Student',
  _ => 'Account',
};

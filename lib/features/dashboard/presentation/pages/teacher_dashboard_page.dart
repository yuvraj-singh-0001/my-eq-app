import 'package:flutter/material.dart';

import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../authentication/data/auth_api.dart';
import '../../../teacher/presentation/pages/my_students_page.dart';
import '../../../teacher/presentation/pages/student_profile_page.dart';
import '../../../teacher/presentation/pages/teacher_feedback_history_page.dart';
import '../../../teacher/presentation/pages/teacher_requests_review_page.dart';
import '../../../teacher/presentation/pages/teacher_messages_page.dart';
import 'profile_page.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key, required this.result});

  final LoginResult result;

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  List<GrowthConnectionData> _students = const [];
  List<GrowthConnectionRequestData> _incoming = const [];
  TeacherActivityData? _activity;
  Map<String, TeacherStudentOverviewData> _overview = const {};
  final _scrollController = ScrollController();
  final _insightsKey = GlobalKey();
  final _requestsKey = GlobalKey();
  final _studentsKey = GlobalKey();
  int _selectedNavIndex = 0;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  String? _workingRequest;

  String? get _token => widget.result.token;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    final token = _token;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Sign in again to load your teacher dashboard.';
      });
      return;
    }
    if (_refreshing) return;
    _refreshing = true;
    if (!refresh && _students.isEmpty) setState(() => _loading = true);
    try {
      final values = await Future.wait<Object>([
        AuthApi.getGrowthConnections(token: token, role: 'teacher'),
        AuthApi.getGrowthConnectionRequests(token: token, role: 'teacher'),
        AuthApi.getTeacherActivitySummary(token),
        AuthApi.getTeacherClassOverview(token),
      ]);
      if (!mounted) return;
      setState(() {
        _students = values[0] as List<GrowthConnectionData>;
        _incoming = (values[1] as GrowthConnectionRequests).incoming;
        _activity = values[2] as TeacherActivityData;
        _overview = {
          for (final item in values[3] as List<TeacherStudentOverviewData>)
            item.studentId: item,
        };
        _loading = false;
        _error = null;
      });
    } on AuthApiException catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.message;
        });
      }
    } finally {
      _refreshing = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onNavigation(int index) {
    setState(() => _selectedNavIndex = index);
    if (index == 1) {
      Navigator.of(context)
          .push<void>(
            MaterialPageRoute<void>(
              builder: (_) => MyStudentsPage(result: widget.result),
            ),
          )
          .then((_) {
            if (mounted) setState(() => _selectedNavIndex = 0);
          });
      return;
    }
    if (index == 4) {
      _openProfile();
      return;
    }
    if (index == 3) {
      TeacherMessagesPage.open(context, widget.result);
      return;
    }
    final target = switch (index) {
      0 => null,
      2 => _insightsKey,
      _ => null,
    };
    if (index == 0) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    final targetContext = target?.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        alignment: .06,
      );
    }
  }

  Future<void> _respond(
    GrowthConnectionRequestData request,
    String decision,
  ) async {
    final token = _token;
    if (token == null) return;
    setState(() => _workingRequest = request.id);
    try {
      await AuthApi.respondToGrowthConnectionRequest(
        token: token,
        role: 'teacher',
        requestId: request.id,
        decision: decision,
      );
      if (!mounted) return;
      await _load(refresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              decision == 'accept'
                  ? '${request.person.fullName} is now connected.'
                  : 'Request declined.',
            ),
          ),
        );
      }
    } on AuthApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _workingRequest = null);
    }
  }

  void _openPeople() {
    final token = _token;
    if (token == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ConnectionRequestsPage(
          token: token,
          role: 'teacher',
          onConnectionsChanged: () => _load(refresh: true),
        ),
      ),
    );
  }

  Future<void> _openFeedbackHistory() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TeacherFeedbackHistoryPage(result: widget.result),
      ),
    );
    if (mounted) _load(refresh: true);
  }

  Future<void> _openRequestsReview() async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TeacherRequestsReviewPage(
          result: widget.result,
          onRequestsChanged: () => _load(refresh: true),
        ),
      ),
    );
    if (mounted) _load(refresh: true);
  }

  Future<void> _openConnectedStudents() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MyStudentsPage(result: widget.result),
      ),
    );
    if (mounted) _load(refresh: true);
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProfilePage(result: widget.result),
      ),
    );
    if (mounted) setState(() => _selectedNavIndex = 0);
  }

  void _openStudent(GrowthConnectionData student) {
    final token = _token;
    if (token == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            TeacherStudentProgressPage(result: widget.result, student: student),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 390;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F8FC),
        foregroundColor: const Color(0xFF172A4D),
        elevation: 0,
        title: const Text(
          'Teacher dashboard',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: () => _load(refresh: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'My profile',
            onPressed: _openProfile,
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(refresh: true),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 940),
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 22,
                  8,
                  compact ? 16 : 22,
                  28,
                ),
                children: [
                  _WelcomeCard(
                    name: widget.result.fullName,
                    teacherId: widget.result.teacherId,
                    onManage: _openPeople,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    _ErrorCard(
                      message: _error!,
                      onRetry: () => _load(refresh: true),
                    )
                  else if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    KeyedSubtree(
                      key: _insightsKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DashboardHeading(
                            title: 'Class at a glance',
                            subtitle:
                                'A quick view of the students you support.',
                          ),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = constraints.maxWidth >= 760
                                  ? 3
                                  : (constraints.maxWidth >= 500 ? 2 : 1);
                              final spacing = 10.0;
                              final cardWidth =
                                  (constraints.maxWidth -
                                      spacing * (columns - 1)) /
                                  columns;
                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: [
                                  SizedBox(
                                    width: cardWidth,
                                    child: _MetricCard(
                                      label: 'Students connected',
                                      value: '${_students.length}',
                                      icon: Icons.groups_rounded,
                                      color: const Color(0xFF149B78),
                                      tint: const Color(0xFFE6F7F2),
                                      onTap: _openConnectedStudents,
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: _MetricCard(
                                      label: 'Feedback shared',
                                      value:
                                          '${_activity?.totalFeedbackEntries ?? 0}',
                                      icon: Icons.forum_outlined,
                                      color: const Color(0xFF287ACB),
                                      tint: const Color(0xFFEAF3FF),
                                      onTap: _openFeedbackHistory,
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: _MetricCard(
                                      label: 'Requests to review',
                                      value: '${_incoming.length}',
                                      icon: Icons.mark_email_unread_outlined,
                                      color: const Color(0xFF8752C8),
                                      tint: const Color(0xFFF2ECFF),
                                      onTap: _openRequestsReview,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _GrowthPulseCard(
                            improving: _overview.values
                                .where(
                                  (item) => item.latestProgress == 'improving',
                                )
                                .length,
                            needsSupport: _overview.values
                                .where(
                                  (item) => item.latestProgress == 'harder',
                                )
                                .length,
                            waiting: _overview.values
                                .where((item) => item.checkIns == 0)
                                .length,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    KeyedSubtree(
                      key: _requestsKey,
                      child: _DashboardHeading(
                        title: 'Connection requests',
                        subtitle: 'Accept students you are ready to support.',
                        trailing: TextButton(
                          onPressed: _openPeople,
                          child: const Text('Manage'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_incoming.isEmpty)
                      const _EmptyCard(
                        icon: Icons.check_circle_outline_rounded,
                        text: 'You are all caught up. New student requests will appear here.',
                      )
                    else
                      for (final request in _incoming.take(3))
                        _RequestCard(
                          request: request,
                          busy: _workingRequest == request.id,
                          onAccept: () => _respond(request, 'accept'),
                          onDecline: () => _respond(request, 'decline'),
                        ),
                    if (_incoming.length > 3)
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: _openPeople,
                          child: Text('View all ${_incoming.length} requests'),
                        ),
                      ),
                    const SizedBox(height: 14),
                    KeyedSubtree(
                      key: _studentsKey,
                      child: _DashboardHeading(
                        title: 'Your students',
                        subtitle: 'Open a student profile to review progress and share feedback.',
                        trailing: TextButton.icon(
                          onPressed: _openPeople,
                          icon: const Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 17,
                          ),
                          label: const Text('Add'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_students.isEmpty)
                      _EmptyCard(
                        icon: Icons.school_outlined,
                        text: 'Connected students will appear here. You can find students by ID or username.',
                        action: OutlinedButton.icon(
                          onPressed: _openPeople,
                          icon: const Icon(Icons.search_rounded, size: 18),
                          label: const Text('Find students'),
                        ),
                      )
                    else
                      for (final student in _students)
                        _StudentCard(
                          student: student,
                          overview: _overview[student.accountId],
                          onTap: () => _openStudent(student),
                        ),
                    const SizedBox(height: 10),
                    const _PrivacyHint(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _selectedNavIndex,
        forTeacher: true,
        onDestinationSelected: _onNavigation,
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.name,
    required this.teacherId,
    required this.onManage,
  });
  final String name;
  final String? teacherId;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final imageWidth = (constraints.maxWidth * .57)
          .clamp(140.0, 230.0)
          .toDouble();
      return Container(
        height: 222,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE2F8F2), Color(0xFFEAF2FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD8EEE9)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 2,
              bottom: 2,
              width: imageWidth,
              height: 214,
              child: Image.asset(
                'lib/assets/images/teachers-singup.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.co_present_rounded,
                  size: 120,
                  color: Color(0xFF20A484),
                ),
              ),
            ),
            Positioned(
              left: 19,
              top: 19,
              bottom: 15,
              width: constraints.maxWidth - imageWidth - 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: Color(0xFF587084),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF183057),
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (teacherId?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Teacher ID  $teacherId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF63758C),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'You inspire. You guide.\nYou help bright futures grow.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF496477),
                      fontSize: constraints.maxWidth < 380 ? 9 : 10,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: onManage,
                    icon: const Icon(Icons.groups_2_rounded, size: 16),
                    label: Text(
                      constraints.maxWidth < 380 ? 'Manage' : 'Manage students',
                    ),
                    style: FilledButton.styleFrom(
                      foregroundColor: const Color(0xFF13886D),
                      backgroundColor: Colors.white.withValues(alpha: .88),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _DashboardHeading extends StatelessWidget {
  const _DashboardHeading({
    required this.title,
    required this.subtitle,
    this.trailing,
  });
  final String title;
  final String subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF203454),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF78859B),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
      ?trailing,
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.tint,
    required this.onTap,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color tint;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7EDF3)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF78859B),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withValues(alpha: .72),
              size: 18,
            ),
          ],
        ),
      ),
    ),
  );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });
  final GrowthConnectionRequestData request;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE7EDF3)),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          backgroundColor: Color(0xFFF2ECFF),
          child: Icon(
            Icons.person_add_alt_1_rounded,
            color: Color(0xFF8752C8),
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.person.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF203454),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                [
                      if (request.person.accountId?.isNotEmpty == true)
                        request.person.accountId!,
                      if (request.person.className?.isNotEmpty == true)
                        request.person.className!,
                    ].join(' · ').isEmpty
                    ? 'Student connection request'
                    : [
                        if (request.person.accountId?.isNotEmpty == true)
                          request.person.accountId!,
                        if (request.person.className?.isNotEmpty == true)
                          request.person.className!,
                      ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF78859B), fontSize: 10),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: busy ? null : onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF149B78),
                      minimumSize: const Size(88, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: busy
                        ? const SizedBox.square(
                            dimension: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Accept', style: TextStyle(fontSize: 11)),
                  ),
                  OutlinedButton(
                    onPressed: busy ? null : onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF68768C),
                      minimumSize: const Size(88, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.overview,
    required this.onTap,
  });
  final GrowthConnectionData student;
  final TeacherStudentOverviewData? overview;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE7EDF3)),
    ),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE6F7F2),
        child: Text(
          student.fullName.trim().isEmpty
              ? '?'
              : student.fullName.trim()[0].toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF149B78),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      title: Text(
        student.fullName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF203454),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              if (student.accountId?.isNotEmpty == true) student.accountId!,
              if (student.className?.isNotEmpty == true) student.className!,
              if (student.section?.isNotEmpty == true)
                'Section ${student.section}',
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF78859B), fontSize: 10),
          ),
          const SizedBox(height: 5),
          _StudentProgressStatus(overview: overview),
        ],
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF8B98AA),
      ),
    ),
  );
}

class _StudentProgressStatus extends StatelessWidget {
  const _StudentProgressStatus({required this.overview});
  final TeacherStudentOverviewData? overview;
  @override
  Widget build(BuildContext context) {
    final latestProgress = overview?.latestProgress;
    final (label, color, tint, icon) = switch (latestProgress) {
      'improving' => (
        'Making progress',
        const Color(0xFF13876B),
        const Color(0xFFE6F7F1),
        Icons.trending_up_rounded,
      ),
      'steady' => (
        'Taking steady steps',
        const Color(0xFF2977BA),
        const Color(0xFFEAF3FF),
        Icons.trending_flat_rounded,
      ),
      'harder' => (
        'Could use more support',
        const Color(0xFFB45C39),
        const Color(0xFFFFF0E8),
        Icons.volunteer_activism_outlined,
      ),
      _ => (
        'No check-ins yet',
        const Color(0xFF7462A6),
        const Color(0xFFF1EDFA),
        Icons.hourglass_empty_rounded,
      ),
    };
    return Wrap(
      spacing: 7,
      runSpacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if ((overview?.checkIns ?? 0) > 0)
          Text(
            '${overview!.checkIns} updates',
            style: const TextStyle(color: Color(0xFF8995A7), fontSize: 9),
          ),
      ],
    );
  }
}

class _GrowthPulseCard extends StatelessWidget {
  const _GrowthPulseCard({
    required this.improving,
    required this.needsSupport,
    required this.waiting,
  });
  final int improving;
  final int needsSupport;
  final int waiting;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFF183057),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14203050),
          blurRadius: 14,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.insights_rounded, color: Color(0xFF79D8BD), size: 19),
            SizedBox(width: 8),
            Text(
              'Growth pulse',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'A helpful snapshot from the latest student, family and teacher updates.',
          style: TextStyle(color: Color(0xFFC4D0E0), fontSize: 10, height: 1.4),
        ),
        const SizedBox(height: 13),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PulsePill(
              label: '$improving making progress',
              color: const Color(0xFF85E0C2),
            ),
            _PulsePill(
              label: '$needsSupport may need support',
              color: const Color(0xFFFFC39E),
            ),
            _PulsePill(
              label: '$waiting without check-ins',
              color: const Color(0xFFD4C4FF),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PulsePill extends StatelessWidget {
  const _PulsePill({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE7EDF3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF149B78), size: 21),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF78859B),
            fontSize: 12,
            height: 1.45,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 10), action!],
      ],
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => _EmptyCard(
    icon: Icons.cloud_off_rounded,
    text: message,
    action: TextButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Try again'),
    ),
  );
}

class _PrivacyHint extends StatelessWidget {
  const _PrivacyHint();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF7F4),
      borderRadius: BorderRadius.circular(15),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, color: Color(0xFF149B78), size: 18),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'Student growth details are available only for students connected to your teacher account.',
            style: TextStyle(
              color: Color(0xFF52736B),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

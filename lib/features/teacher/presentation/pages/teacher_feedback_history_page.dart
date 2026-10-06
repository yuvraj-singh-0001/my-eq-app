import 'package:flutter/material.dart';

import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../authentication/data/auth_api.dart';
import '../../../authentication/data/auth_session.dart';
import '../../../authentication/presentation/pages/login_page.dart';
import '../../../dashboard/presentation/pages/profile_page.dart';
import 'my_students_page.dart';
import 'student_profile_page.dart';

class TeacherFeedbackHistoryPage extends StatefulWidget {
  const TeacherFeedbackHistoryPage({super.key, required this.result});

  final LoginResult result;

  @override
  State<TeacherFeedbackHistoryPage> createState() =>
      _TeacherFeedbackHistoryPageState();
}

class _TeacherFeedbackHistoryPageState
    extends State<TeacherFeedbackHistoryPage> {
  List<TeacherFeedbackActivityData> _activities = const [];
  List<GrowthConnectionData> _students = const [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = widget.result.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Sign in again to view shared feedback.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait<Object>([
        AuthApi.getTeacherActivityHistory(token),
        AuthApi.getGrowthConnections(token: token, role: 'teacher'),
      ]);
      if (!mounted) return;
      setState(() {
        _activities = values[0] as List<TeacherFeedbackActivityData>;
        _students = (values[1] as List<GrowthConnectionData>)
            .where((student) => student.role == 'student')
            .toList(growable: false);
        _loading = false;
      });
    } on AuthApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
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
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Please check your connection and try again.';
        });
      }
    }
  }

  List<TeacherFeedbackActivityData> get _visibleActivities {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return _activities;
    return _activities
        .where((item) {
          return [
            item.studentName ?? '',
            item.studentId ?? '',
            item.focusArea,
            item.progress,
          ].join(' ').toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _openStudent(TeacherFeedbackActivityData activity) async {
    final matches = _students.where(
      (student) => student.accountId == activity.studentId,
    );
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This student is no longer connected to your account.'),
        ),
      );
      return;
    }
    final student = matches.first;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            TeacherStudentProgressPage(result: widget.result, student: student),
      ),
    );
  }

  void _onNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case 1:
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => MyStudentsPage(result: widget.result),
          ),
        );
        break;
      case 2:
      case 3:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              index == 2
                  ? 'Insights are on the teacher dashboard.'
                  : 'Messages are not available yet.',
            ),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final activities = _visibleActivities;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F8FC),
        foregroundColor: const Color(0xFF203454),
        title: const Text(
          'Feedback shared',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh feedback history',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_activities.length} feedback ${_activities.length == 1 ? 'entry' : 'entries'}',
                    style: const TextStyle(
                      color: Color(0xFF78859B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (value) => setState(() => _search = value),
                    decoration: InputDecoration(
                      hintText: 'Search student or focus area',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFFE5EBF2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFFE5EBF2)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _FeedbackState(
                      icon: Icons.cloud_off_outlined,
                      message: _error!,
                      action: TextButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try again'),
                      ),
                    )
                  : activities.isEmpty
                  ? _FeedbackState(
                      icon: Icons.forum_outlined,
                      message: _search.isEmpty
                          ? 'Feedback you share with students will appear here.'
                          : 'No feedback matches this search.',
                      action: _search.isEmpty
                          ? TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        MyStudentsPage(result: widget.result),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.groups_outlined),
                              label: const Text('Find a student'),
                            )
                          : null,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          final activity = activities[index];
                          return _FeedbackActivityCard(
                            activity: activity,
                            onTap: () => _openStudent(activity),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: 0,
        forTeacher: true,
        onDestinationSelected: _onNavigation,
      ),
    );
  }
}

class _FeedbackActivityCard extends StatelessWidget {
  const _FeedbackActivityCard({required this.activity, required this.onTap});

  final TeacherFeedbackActivityData activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = activity.studentName?.trim().isNotEmpty == true
        ? activity.studentName!.trim()
        : 'Student';
    final date = activity.createdAt?.toLocal();
    final dateLabel = date == null
        ? ''
        : '${date.day}/${date.month}/${date.year}';
    final (progressLabel, color, tint) = switch (activity.progress) {
      'improving' => (
        'Making progress',
        const Color(0xFF168064),
        const Color(0xFFE6F7F1),
      ),
      'steady' => (
        'Taking steady steps',
        const Color(0xFF287ACB),
        const Color(0xFFEAF3FF),
      ),
      'harder' => (
        'Needs more support',
        const Color(0xFFB45C39),
        const Color(0xFFFFF0E8),
      ),
      _ => (
        'Check-in shared',
        const Color(0xFF7462A6),
        const Color(0xFFF1EDFA),
      ),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE7EDF3)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(14, 7, 10, 7),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEAF3FF),
          child: Text(
            name.isEmpty ? '?' : name[0].toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF287ACB),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF203454),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  activity.focusArea.replaceAll('_', ' '),
                  if (activity.studentId?.isNotEmpty == true)
                    activity.studentId!,
                  if (activity.className?.isNotEmpty == true)
                    activity.className!,
                  if (activity.section?.isNotEmpty == true)
                    'Section ${activity.section}',
                  if (dateLabel.isNotEmpty) dateLabel,
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF78859B), fontSize: 10),
              ),
              if (activity.observedBehaviors.isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  'Observed: ${activity.observedBehaviors.take(2).join(' · ')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF40516A),
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ],
              if (activity.whatHelped.trim().isNotEmpty)
                _FeedbackDetailLine(
                  label: 'Helped',
                  value: activity.whatHelped,
                ),
              if (activity.whatWasHard.trim().isNotEmpty)
                _FeedbackDetailLine(
                  label: 'Difficult',
                  value: activity.whatWasHard,
                ),
              if (activity.nextStep.trim().isNotEmpty)
                _FeedbackDetailLine(
                  label: 'Next step',
                  value: activity.nextStep,
                ),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  progressLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Open student profile to share another feedback update',
                style: TextStyle(color: Color(0xFF168064), fontSize: 10),
              ),
            ],
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF8793A6),
        ),
      ),
    );
  }
}

class _FeedbackDetailLine extends StatelessWidget {
  const _FeedbackDetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Text(
      '$label: $value',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF56647A),
        fontSize: 10,
        height: 1.35,
      ),
    ),
  );
}

class _FeedbackState extends StatelessWidget {
  const _FeedbackState({
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF149B78), size: 34),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF78859B), fontSize: 12),
          ),
          ?action,
        ],
      ),
    ),
  );
}

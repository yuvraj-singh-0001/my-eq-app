import 'package:flutter/material.dart';

import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../authentication/data/auth_api.dart';
import '../../../authentication/data/auth_session.dart';
import '../../../authentication/presentation/pages/login_page.dart';
import '../../../dashboard/presentation/pages/profile_page.dart';
import 'create_goal_page.dart';
import 'goal_detail_page.dart';
import 'teacher_messages_page.dart';

class GoalsProgressPage extends StatefulWidget {
  const GoalsProgressPage({
    super.key,
    required this.result,
    required this.student,
  });

  final LoginResult result;
  final GrowthConnectionData student;

  @override
  State<GoalsProgressPage> createState() => _GoalsProgressPageState();
}

class _GoalsProgressPageState extends State<GoalsProgressPage> {
  int _tab = 0;
  bool _loading = true;
  String? _error;
  List<GrowthGoalData> _goals = const [];

  String? get _token => widget.result.token;
  String? get _studentId => widget.student.accountId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final goals = await AuthApi.getTeacherStudentGoals(
        token: token,
        studentId: studentId,
      );
      if (!mounted) return;
      setState(() {
        _goals = goals;
        _loading = false;
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
          _error = error.message;
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

  Future<void> _createGoal() async {
    final token = _token;
    final studentId = _studentId;
    if (token == null || studentId == null) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CreateGoalPage(token: token, studentId: studentId),
      ),
    );
    if (created == true && mounted) await _load();
  }

  Future<void> _openGoal(GrowthGoalData goal) async {
    final token = _token;
    final studentId = _studentId;
    if (token == null || studentId == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            GoalDetailPage(token: token, studentId: studentId, goal: goal),
      ),
    );
    if (mounted) _load();
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

  List<GrowthGoalData> get _visibleGoals => _goals
      .where((goal) => goal.status == (_tab == 0 ? 'active' : 'completed'))
      .toList(growable: false);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F8FC),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF5F8FC),
      foregroundColor: const Color(0xFF203454),
      title: const Text(
        'Goals & Progress',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
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
              style: const TextStyle(color: Color(0xFF78859B), fontSize: 13),
            ),
            const SizedBox(height: 17),
            _GoalTabs(
              selectedIndex: _tab,
              onSelected: (index) => setState(() => _tab = index),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Column(children: [_GoalSkeleton(), _GoalSkeleton()])
            else if (_error != null)
              _GoalStateCard(
                icon: Icons.cloud_off_outlined,
                title: 'Unable to load goals',
                message: _error!,
                action: 'Retry',
                onAction: _load,
              )
            else if (_visibleGoals.isEmpty)
              _GoalStateCard(
                icon: _tab == 0 ? Icons.flag_outlined : Icons.task_alt_rounded,
                title: _tab == 0
                    ? 'No active goals yet'
                    : 'No completed goals yet',
                message: _tab == 0
                    ? 'Create a small goal to help this student grow.'
                    : 'Completed goals will appear here.',
              )
            else
              for (final goal in _visibleGoals)
                _GoalCard(goal: goal, onTap: () => _openGoal(goal)),
          ],
        ),
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_tab == 0 && !_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 9),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _createGoal,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Add New Goal',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF149B78),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
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

  String get _classLabel {
    final parts = [widget.student.className, widget.student.section]
        .where((value) => value?.trim().isNotEmpty == true)
        .cast<String>()
        .toList();
    return parts.isEmpty ? 'Student' : 'Class ${parts.join('-')}';
  }
}

class _GoalTabs extends StatelessWidget {
  const _GoalTabs({required this.selectedIndex, required this.onSelected});
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var index = 0; index < 2; index++) ...[
        if (index > 0) const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(13),
            child: Container(
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selectedIndex == index
                    ? const Color(0xFF149B78)
                    : Colors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: selectedIndex == index
                      ? const Color(0xFF149B78)
                      : const Color(0xFFE2E9F0),
                ),
              ),
              child: Text(
                index == 0 ? 'Active' : 'Completed',
                style: TextStyle(
                  color: selectedIndex == index
                      ? Colors.white
                      : const Color(0xFF586A82),
                  fontSize: 13,
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

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.onTap});
  final GrowthGoalData goal;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final done = goal.status == 'completed';
    final status = done ? 'Completed' : 'Active';
    final color = done ? const Color(0xFF168064) : const Color(0xFF3477A9);
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
              border: Border.all(color: const Color(0xFFE5ECF2)),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F7F3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _goalIcon(goal.category),
                        color: const Color(0xFF149B78),
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF203454),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            goal.category,
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
                if (goal.description.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Text(
                    goal.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF65748A),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Progress',
                      style: const TextStyle(
                        color: Color(0xFF586A82),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${goal.currentProgress}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: (goal.currentProgress / 100).clamp(0, 1),
                    minHeight: 7,
                    backgroundColor: const Color(0xFFEAF0F4),
                    color: color,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    if (goal.currentValue != null && goal.targetValue != null)
                      Text(
                        '${_number(goal.currentValue!)} / ${_number(goal.targetValue!)}',
                        style: const TextStyle(
                          color: Color(0xFF78859B),
                          fontSize: 11,
                        ),
                      ),
                    const Spacer(),
                    _StatusBadge(label: status, color: color),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  done
                      ? 'Completed ${_date(goal.completedAt ?? goal.updatedAt)}'
                      : 'Updated ${_date(goal.updatedAt)}',
                  style: const TextStyle(
                    color: Color(0xFF8A96A7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}

class _GoalSkeleton extends StatelessWidget {
  const _GoalSkeleton();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 11),
    height: 166,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE5ECF2)),
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

class _GoalStateCard extends StatelessWidget {
  const _GoalStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE5ECF2)),
    ),
    child: Column(
      children: [
        Icon(icon, size: 34, color: const Color(0xFF149B78)),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
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
        if (action != null && onAction != null) ...[
          const SizedBox(height: 11),
          OutlinedButton(onPressed: onAction, child: Text(action!)),
        ],
      ],
    ),
  );
}

IconData _goalIcon(String category) => switch (category) {
  'Confidence' || 'Public Speaking' => Icons.record_voice_over_outlined,
  'Self-Regulation' => Icons.self_improvement_rounded,
  'Communication' || 'Social Skills' => Icons.forum_outlined,
  'Sports' => Icons.sports_soccer_rounded,
  'Study Habits' => Icons.menu_book_rounded,
  'Participation' => Icons.groups_outlined,
  _ => Icons.flag_outlined,
};
String _number(num value) =>
    value % 1 == 0 ? value.toInt().toString() : value.toString();
String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')} ${_months[date.month - 1]} ${date.year}';
const _months = [
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

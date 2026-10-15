import 'package:flutter/material.dart';

import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../authentication/data/auth_api.dart';
import '../../../dashboard/presentation/pages/profile_page.dart';
import '../../../journal/presentation/pages/journal_page.dart';
import 'career_discovery_page.dart';
import 'student_growth_profile_page.dart';

class StudentGoalsPage extends StatefulWidget {
  const StudentGoalsPage({super.key, required this.result});
  final LoginResult result;

  @override
  State<StudentGoalsPage> createState() => _StudentGoalsPageState();
}

class _StudentGoalsPageState extends State<StudentGoalsPage> {
  List<GrowthGoalData> _goals = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = widget.result.token;
    if (token == null || token.isEmpty) return;
    try {
      final goals = await AuthApi.getOwnStudentGoals(token, status: 'active');
      if (!mounted) return;
      setState(() {
        _goals = goals;
        _loading = false;
        _error = null;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  void _navigate(int index) {
    if (index == 3) return;
    final page = switch (index) {
      1 => JournalPage(result: widget.result),
      2 => StudentGrowthProfilePage(result: widget.result),
      4 => ProfilePage(result: widget.result),
      _ => CareerDiscoveryPage(result: widget.result),
    };
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FBFC),
    appBar: AppBar(title: const Text('My Support Plans')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(child: Text(_error!))
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF6F3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.groups_rounded, color: Color(0xFF149B78)),
                      SizedBox(height: 10),
                      Text(
                        'Small steps, together',
                        style: TextStyle(
                          color: Color(0xFF183B35),
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Your teacher creates these plans with you. Your parent can see them and support your next step.',
                        style: TextStyle(
                          color: Color(0xFF52736C),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (_goals.isEmpty)
                  const _EmptyGoals()
                else
                  for (final goal in _goals) ...[
                    _GoalCard(goal: goal),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
    bottomNavigationBar: AppBottomNav(
      selectedIndex: 3,
      onDestinationSelected: _navigate,
    ),
  );
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});
  final GrowthGoalData goal;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes_rounded, color: Color(0xFF149B78)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(
                    color: Color(0xFF203454),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${goal.currentProgress}%',
                style: const TextStyle(
                  color: Color(0xFF149B78),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (goal.currentProgress / 100).clamp(0, 1),
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF18A77F),
            backgroundColor: const Color(0xFFE2EBE8),
          ),
          if (goal.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              goal.description,
              style: const TextStyle(color: Color(0xFF65758D), height: 1.4),
            ),
          ],
          if (goal.teacherNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Your next steps',
              style: TextStyle(
                color: Color(0xFF203454),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              goal.teacherNote,
              style: const TextStyle(color: Color(0xFF65758D), height: 1.45),
            ),
          ],
        ],
      ),
    ),
  );
}

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(30),
    child: Column(
      children: [
        Icon(Icons.auto_awesome_outlined, size: 42, color: Color(0xFF149B78)),
        SizedBox(height: 12),
        Text(
          'No support plan yet',
          style: TextStyle(
            color: Color(0xFF203454),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Keep sharing what feels difficult and interesting. Your teacher can create a plan with you.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF65758D), height: 1.4),
        ),
      ],
    ),
  );
}

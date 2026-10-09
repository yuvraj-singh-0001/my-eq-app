import 'package:flutter/material.dart';

import '../../../authentication/data/auth_api.dart';
import '../../../authentication/data/auth_session.dart';
import '../../../dashboard/presentation/pages/profile_page.dart';
import '../widgets/parent_bottom_nav.dart';
import 'parent_dashboard_page.dart';
import 'parent_settings_page.dart';
import 'parent_student_page.dart';

class ParentNavigationPage extends StatefulWidget {
  const ParentNavigationPage({
    super.key,
    required this.result,
    required this.initialIndex,
  });
  final LoginResult result;
  final int initialIndex;
  @override
  State<ParentNavigationPage> createState() => _ParentNavigationPageState();
}

class _ParentNavigationPageState extends State<ParentNavigationPage> {
  late int _index = widget.initialIndex.clamp(1, 4);
  List<GrowthConnectionData> _students = const [];
  List<GrowthConnectionData> _teachers = const [];
  bool _loading = true;
  String? _error;
  String? get _token => widget.result.token;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = _token;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = 'Sign in again to view your connections.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait([
        AuthApi.getGrowthConnections(token: token, role: 'parent'),
        AuthApi.getParentConnectedTeachers(token: token),
      ]);
      if (!mounted) return;
      setState(() {
        _students = values[0];
        _teachers = values[1];
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

  void _navigate(int index) {
    if (index == _index) return;
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ParentDashboardPage(result: widget.result),
        ),
      );
    } else {
      setState(() => _index = index);
      _load();
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: Color(0xFFCB5D5D)),
        title: const Text('Log out?'),
        content: const Text('You can sign in again whenever you are ready.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay signed in'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFCB5D5D),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthSession.clear();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _openProfileSettings() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => ParentSettingsPage(
        result: widget.result,
        onNavigate: (index) {
          Navigator.of(context).pop();
          if (mounted) _navigate(index);
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final title = switch (_index) {
      1 => 'My Students',
      2 => 'Student Progress',
      3 => 'Connected Teachers',
      _ => 'More',
    };
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F9FA),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF162B4A),
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (_index == 1)
            IconButton(
              tooltip: 'Connection requests',
              onPressed: () async {
                final token = _token;
                if (token == null) return;
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ConnectionRequestsPage(
                      token: token,
                      role: 'parent',
                      onConnectionsChanged: _load,
                    ),
                  ),
                );
                if (mounted) _load();
              },
              icon: const Icon(Icons.mark_email_unread_outlined),
            ),
          if (_index == 4)
            IconButton(
              tooltip: 'Profile and settings',
              onPressed: _openProfileSettings,
              icon: const Icon(Icons.settings_outlined),
            )
          else
            IconButton(
              tooltip: 'Refresh',
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(key: ValueKey(_index), child: _buildContent()),
        ),
      ),
      bottomNavigationBar: ParentBottomNav(
        currentIndex: _index,
        onTap: _navigate,
      ),
    );
  }

  Widget _buildContent() {
    if (_index == 4) return _buildMore();
    if (_loading && _students.isEmpty && _teachers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF159976)),
      );
    }
    if (_error != null && _students.isEmpty && _teachers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64738A)),
              ),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_index == 3) return _buildTeachers();
    if (_students.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'No students are connected yet. Use Home to request a connection by student ID or username.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64738A), height: 1.5),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_index == 2)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Progress, goals and shared reflections for each connected student.',
                style: TextStyle(color: Color(0xFF718097), fontSize: 12),
              ),
            ),
          for (final student in _students) ...[
            _ConnectionCard(
              person: student,
              subtitle: _index == 2
                  ? 'Open progress, goals and shared reflections'
                  : 'Class ${student.className ?? '—'} · ID ${student.accountId ?? '—'}',
              icon: Icons.school_outlined,
              onTap: () {
                final token = _token;
                if (token == null) return;
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ParentStudentPage(
                      token: token,
                      student: student,
                      parent: widget.result,
                      initialSection: _index == 2 ? 1 : 0,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildTeachers() {
    if (_teachers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'A teacher appears here after your child is connected with a teacher in the school system.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64738A), height: 1.5),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Teachers assigned to your connected children',
          style: TextStyle(color: Color(0xFF718097), fontSize: 12),
        ),
        const SizedBox(height: 12),
        for (final teacher in _teachers) ...[
          _ConnectionCard(
            person: teacher,
            subtitle: [
              if (teacher.teachingSubject != null) teacher.teachingSubject!,
              if (teacher.schoolName != null) teacher.schoolName!,
              if (teacher.studentName != null) 'For ${teacher.studentName}',
            ].join(' · '),
            icon: Icons.groups_outlined,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildMore() => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFE5F5F1),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF168C73),
              child: Icon(Icons.person_outline),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.result.fullName,
                    style: const TextStyle(
                      color: Color(0xFF183B35),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Parent ID ${widget.result.parentId ?? '—'}',
                    style: const TextStyle(
                      color: Color(0xFF557168),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _MoreRow(
        icon: Icons.family_restroom_outlined,
        title: 'Connected children',
        value: '${_students.length}',
      ),
      _MoreRow(
        icon: Icons.groups_outlined,
        title: 'Connected teachers',
        value: '${_teachers.length}',
      ),
      const SizedBox(height: 12),
      _SettingsShortcut(
        icon: Icons.manage_accounts_outlined,
        title: 'Profile & settings',
        subtitle: 'Account details, privacy and notifications',
        onTap: _openProfileSettings,
      ),
      const SizedBox(height: 10),
      _SettingsShortcut(
        icon: Icons.school_outlined,
        title: 'My students',
        subtitle: 'Open a connected student profile',
        onTap: () => _navigate(1),
      ),
      if (_students.isNotEmpty) ...[
        const SizedBox(height: 8),
        for (final student in _students.take(3))
          _ConnectionCard(
            person: student,
            subtitle: [
              if (student.className != null) student.className!,
              if (student.accountId != null) 'ID ${student.accountId}',
            ].join(' · '),
            icon: Icons.school_outlined,
            onTap: () => _openStudent(student),
          ),
      ],
      const SizedBox(height: 18),
      ListTile(
        leading: const Icon(Icons.logout_rounded, color: Color(0xFFCB5D5D)),
        title: const Text(
          'Log out',
          style: TextStyle(
            color: Color(0xFFAD4747),
            fontWeight: FontWeight.w700,
          ),
        ),
        onTap: _logout,
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ],
  );

  Future<void> _openStudent(GrowthConnectionData student) async {
    final token = _token;
    if (token == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ParentStudentPage(
          token: token,
          student: student,
          parent: widget.result,
        ),
      ),
    );
  }
}

class _SettingsShortcut extends StatelessWidget {
  const _SettingsShortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(15),
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF168C73)),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF283A56),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF7A879B), fontSize: 11),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF9AA7B8),
      ),
      dense: true,
    ),
  );
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.person,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });
  final GrowthConnectionData person;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE5F5F1),
              foregroundColor: const Color(0xFF168C73),
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF182D4C),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF728097),
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF748299)),
          ],
        ),
      ),
    ),
  );
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: const Color(0xFF168C73)),
    title: Text(
      title,
      style: const TextStyle(color: Color(0xFF283A56), fontSize: 13),
    ),
    trailing: Text(
      value,
      style: const TextStyle(
        color: Color(0xFF168C73),
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

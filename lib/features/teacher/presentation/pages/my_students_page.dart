import 'package:flutter/material.dart';

import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../authentication/data/auth_api.dart';
import '../../../authentication/data/auth_session.dart';
import '../../../authentication/presentation/pages/login_page.dart';
import '../../../dashboard/presentation/pages/profile_page.dart';
import '../services/teacher_student_contact.dart';
import 'student_profile_page.dart';

enum _StudentFilter { all, needsAttention, goodProgress }

class MyStudentsPage extends StatefulWidget {
  const MyStudentsPage({super.key, required this.result});

  final LoginResult result;

  @override
  State<MyStudentsPage> createState() => _MyStudentsPageState();
}

class _MyStudentsPageState extends State<MyStudentsPage> {
  final _searchController = TextEditingController();
  List<GrowthConnectionData> _students = const [];
  Map<String, TeacherStudentOverviewData> _overview = const {};
  _StudentFilter _filter = _StudentFilter.all;
  bool _loading = true;
  String? _error;

  String? get _token => widget.result.token;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshView);
    _load();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshView)
      ..dispose();
    super.dispose();
  }

  void _refreshView() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final token = _token;
    if (token == null || token.isEmpty) {
      await _handleUnauthorized();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait<Object>([
        AuthApi.getGrowthConnections(token: token, role: 'teacher'),
        AuthApi.getTeacherClassOverview(token),
      ]);
      if (!mounted) return;
      setState(() {
        _students = (values[0] as List<GrowthConnectionData>)
            .where((student) => student.role == 'student')
            .toList(growable: false);
        _overview = {
          for (final item in values[1] as List<TeacherStudentOverviewData>)
            item.studentId: item,
        };
        _loading = false;
      });
    } on AuthApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _handleUnauthorized();
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

  Future<void> _handleUnauthorized() async {
    await AuthSession.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const LoginPage(initialRole: 1)),
      (_) => false,
    );
  }

  List<GrowthConnectionData> get _visibleStudents {
    final query = _searchController.text.trim().toLowerCase();
    return _students
        .where((student) {
          final overview = _studentOverview(student);
          final progress = overview?.latestProgress;
          final matchesFilter = switch (_filter) {
            _StudentFilter.all => true,
            _StudentFilter.needsAttention => progress == 'harder',
            _StudentFilter.goodProgress => progress == 'improving',
          };
          final searchable = [
            student.fullName,
            student.accountId ?? '',
            student.className ?? '',
            student.section ?? '',
            if (student.className?.isNotEmpty == true &&
                student.section?.isNotEmpty == true)
              '${student.className}-${student.section}',
          ].join(' ').toLowerCase();
          return matchesFilter && (query.isEmpty || searchable.contains(query));
        })
        .toList(growable: false);
  }

  TeacherStudentOverviewData? _studentOverview(GrowthConnectionData student) {
    final id = student.accountId;
    return id == null ? null : _overview[id];
  }

  Future<void> _openStudent(GrowthConnectionData student) async {
    final studentId = student.accountId;
    final token = _token;
    if (token == null || studentId == null || studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This student profile is unavailable.')),
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            TeacherStudentProgressPage(result: widget.result, student: student),
      ),
    );
  }

  Future<void> _messageStudent(GrowthConnectionData student) =>
      TeacherStudentContact.message(context: context, result: widget.result, student: student);

  Future<void> _callStudent(GrowthConnectionData student) =>
      TeacherStudentContact.call(context: context, result: widget.result, student: student);

  Future<void> _openConnectStudents() async {
    final token = _token;
    if (token == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ConnectionRequestsPage(token: token, role: 'teacher'),
      ),
    );
    if (mounted) _load();
  }

  void _onNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pop();
      case 1:
        break;
      case 2:
      case 3:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              index == 2
                  ? 'Insights are available from the Teacher dashboard.'
                  : 'Teacher messages are not available yet.',
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
    final students = _visibleStudents;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F8FC),
        foregroundColor: const Color(0xFF172A4D),
        elevation: 0,
        title: const Text(
          'My Students',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton.icon(
            onPressed: _openConnectStudents,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text('Connect'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF149B78),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  children: [
                    Text(
                      '${_students.length} ${_students.length == 1 ? 'Student' : 'Students'}',
                      style: const TextStyle(
                        color: Color(0xFF52627B),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search by name, class, or ID...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: _searchController.clear,
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE4EAF0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE4EAF0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF149B78),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _StudentFilters(
                      selected: _filter,
                      onSelected: (filter) => setState(() => _filter = filter),
                    ),
                    const SizedBox(height: 16),
                    if (_loading)
                      const _LoadingStudents()
                    else if (_error != null)
                      _StudentsError(message: _error!, onRetry: _load)
                    else if (_students.isEmpty)
                      _NoStudents(onConnect: _openConnectStudents)
                    else if (students.isEmpty)
                      const _NoSearchResults()
                    else
                      for (final student in students)
                        _StudentListCard(
                          student: student,
                          overview: _studentOverview(student),
                          onTap: () => _openStudent(student),
                          onMessage: () => _messageStudent(student),
                          onCall: () => _callStudent(student),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: 1,
        forTeacher: true,
        onDestinationSelected: _onNavigation,
      ),
    );
  }
}

class _StudentFilters extends StatelessWidget {
  const _StudentFilters({required this.selected, required this.onSelected});

  final _StudentFilter selected;
  final ValueChanged<_StudentFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    const filters = [
      (_StudentFilter.all, 'All'),
      (_StudentFilter.needsAttention, 'Need Attention'),
      (_StudentFilter.goodProgress, 'Good Progress'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (filter, label) in filters) ...[
            ChoiceChip(
              label: Text(label),
              selected: selected == filter,
              onSelected: (_) => onSelected(filter),
              selectedColor: const Color(0xFFDDF4EB),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected == filter
                    ? const Color(0xFF117A61)
                    : const Color(0xFF596981),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              side: BorderSide(
                color: selected == filter
                    ? const Color(0xFF9BDCC6)
                    : const Color(0xFFE3E9EF),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _StudentListCard extends StatelessWidget {
  const _StudentListCard({
    required this.student,
    required this.overview,
    required this.onTap,
    required this.onMessage,
    required this.onCall,
  });

  final GrowthConnectionData student;
  final TeacherStudentOverviewData? overview;
  final VoidCallback onTap;
  final VoidCallback onMessage;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle(overview?.latestProgress);
    final classLabel = [
      student.className,
      if (student.section?.isNotEmpty == true) student.section,
    ].whereType<String>().where((part) => part.isNotEmpty).join('-');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE7EDF3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFFE6F7F2),
                child: Text(
                  student.fullName.trim().isEmpty
                      ? '?'
                      : student.fullName.trim()[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF149B78),
                    fontSize: 16,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF203454),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (classLabel.isNotEmpty) classLabel,
                        if (student.accountId?.isNotEmpty == true)
                          'ID ${student.accountId}',
                      ].join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF78859B),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: status.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status.label,
                        style: TextStyle(
                          color: status.foreground,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Message ${student.fullName}',
                    onPressed: onMessage,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon: const Icon(Icons.sms_outlined, color: Color(0xFF149B78), size: 20),
                  ),
                  IconButton(
                    tooltip: 'Call ${student.fullName}',
                    onPressed: onCall,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon: const Icon(Icons.call_outlined, color: Color(0xFF287ACB), size: 20),
                  ),
                ],
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8B98AA)),
            ],
          ),
        ),
      ),
    );
  }
}

({String label, Color foreground, Color background}) _statusStyle(
  String? progress,
) => switch (progress) {
  'harder' => (
    label: 'Needs Attention',
    foreground: const Color(0xFFB34F51),
    background: const Color(0xFFFFEDEE),
  ),
  'improving' => (
    label: 'Good Progress',
    foreground: const Color(0xFF168064),
    background: const Color(0xFFE6F7F1),
  ),
  'steady' => (
    label: 'Stable',
    foreground: const Color(0xFF3477A9),
    background: const Color(0xFFEAF3FF),
  ),
  _ => (
    label: 'No recent updates',
    foreground: const Color(0xFF79649C),
    background: const Color(0xFFF1EDFA),
  ),
};

class _LoadingStudents extends StatelessWidget {
  const _LoadingStudents();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 54),
    child: Center(
      child: Column(
        children: [
          SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF149B78),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Loading your students...',
            style: TextStyle(color: Color(0xFF68768C), fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _NoStudents extends StatelessWidget {
  const _NoStudents({required this.onConnect});

  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) => _StateCard(
    icon: Icons.groups_2_outlined,
    title: 'No students connected yet',
    message: 'Connect with a student using their Student ID.',
    action: OutlinedButton.icon(
      onPressed: onConnect,
      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
      label: const Text('Connect with a student'),
    ),
  );
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults();

  @override
  Widget build(BuildContext context) => const _StateCard(
    icon: Icons.search_off_rounded,
    title: 'No students found',
    message: 'Try another name, class, or ID.',
  );
}

class _StudentsError extends StatelessWidget {
  const _StudentsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _StateCard(
    icon: Icons.cloud_off_outlined,
    title: 'Something went wrong',
    message: message,
    action: FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
  );
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE7EDF3)),
    ),
    child: Column(
      children: [
        Icon(icon, size: 34, color: const Color(0xFF149B78)),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF203454),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF78859B),
            fontSize: 12,
            height: 1.4,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}

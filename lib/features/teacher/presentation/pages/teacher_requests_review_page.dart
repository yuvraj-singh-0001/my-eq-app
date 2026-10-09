import 'package:flutter/material.dart';

import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../authentication/data/auth_api.dart';
import '../../../authentication/data/auth_session.dart';
import '../../../authentication/presentation/pages/login_page.dart';
import '../../../dashboard/presentation/pages/profile_page.dart';
import 'my_students_page.dart';
import 'teacher_messages_page.dart';

class TeacherRequestsReviewPage extends StatefulWidget {
  const TeacherRequestsReviewPage({
    super.key,
    required this.result,
    this.onRequestsChanged,
  });

  final LoginResult result;
  final VoidCallback? onRequestsChanged;

  @override
  State<TeacherRequestsReviewPage> createState() =>
      _TeacherRequestsReviewPageState();
}

class _TeacherRequestsReviewPageState extends State<TeacherRequestsReviewPage> {
  final _searchController = TextEditingController();
  List<GrowthConnectionRequestData> _requests = const [];
  List<GrowthConnectionData> _students = const [];
  bool _loading = true;
  bool _searching = false;
  bool _hasSearched = false;
  String? _error;
  String? _searchError;
  String? _workingId;
  int _searchRequestId = 0;

  String? get _token => widget.result.token;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      _load(),
      if (_searchController.text.trim().isNotEmpty)
        _searchStudents(_searchController.text),
    ]);
  }

  Future<void> _searchStudents([String? value]) async {
    final query = (value ?? _searchController.text).trim();
    final requestId = ++_searchRequestId;
    if (query.isEmpty) {
      setState(() {
        _students = const [];
        _searchError = null;
        _searching = false;
        _hasSearched = false;
      });
      return;
    }
    final token = _token;
    if (token == null || token.isEmpty) return;
    setState(() {
      _searching = true;
      _searchError = null;
      _hasSearched = true;
    });
    try {
      final result = await AuthApi.searchGrowthPeople(
        token: token,
        role: 'teacher',
        search: query,
      );
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _students = result.people;
        _searching = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _searchError = error.message;
        _searching = false;
      });
    } catch (_) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _searchError = 'Please check your connection and try again.';
        _searching = false;
      });
    }
  }

  Future<void> _sendRequest(GrowthConnectionData student) async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    final identity = student.username ?? student.accountId ?? student.id;
    setState(() => _workingId = student.id);
    try {
      await AuthApi.sendGrowthConnectionRequest(
        token: token,
        role: 'teacher',
        identity: identity,
      );
      if (!mounted) return;
      await Future.wait([_load(), _searchStudents(_searchController.text)]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request sent to ${student.fullName}.')),
      );
      widget.onRequestsChanged?.call();
    } on AuthApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = _token;
      if (token == null || token.isEmpty) {
        throw const AuthApiException('Sign in again to review requests.');
      }
      final requests = await AuthApi.getGrowthConnectionRequests(
        token: token,
        role: 'teacher',
      );
      if (!mounted) return;
      setState(() {
        _requests = requests.incoming;
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

  Future<void> _respond(
    GrowthConnectionRequestData request,
    String decision,
  ) async {
    setState(() => _workingId = request.id);
    try {
      await AuthApi.respondToGrowthConnectionRequest(
        token: _token!,
        role: 'teacher',
        requestId: request.id,
        decision: decision,
      );
      if (!mounted) return;
      await Future.wait([
        _load(),
        if (_searchController.text.trim().isNotEmpty)
          _searchStudents(_searchController.text),
      ]);
      widget.onRequestsChanged?.call();
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insights are on the teacher dashboard.'),
          ),
        );
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

  Widget _searchSection() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE7EDF3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Find a student',
          style: TextStyle(
            color: Color(0xFF203454),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Search by student ID or username, then send a connection request.',
          style: TextStyle(color: Color(0xFF78859B), fontSize: 11, height: 1.4),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: _searchStudents,
          onChanged: (_) => setState(() {
            _students = const [];
            _searchError = null;
            _hasSearched = false;
          }),
          decoration: InputDecoration(
            hintText: 'Enter student ID or username',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              tooltip: 'Search students',
              onPressed: _searching ? null : () => _searchStudents(),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Color(0xFFE5EBF2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Color(0xFFE5EBF2)),
            ),
          ),
        ),
        if (_searching) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(
            minHeight: 2,
            color: Color(0xFF149B78),
            backgroundColor: Color(0xFFE7F3EF),
          ),
        ],
        if (_searchError != null) ...[
          const SizedBox(height: 8),
          Text(
            _searchError!,
            style: const TextStyle(color: Color(0xFFB45C39), fontSize: 11),
          ),
        ],
        if (_hasSearched &&
            !_searching &&
            _searchError == null &&
            _searchController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 9),
          if (_students.isEmpty)
            const Text(
              'No available student matched that ID or username.',
              style: TextStyle(color: Color(0xFF78859B), fontSize: 11),
            )
          else
            for (final student in _students)
              _StudentSearchResultCard(
                student: student,
                busy: _workingId == student.id,
                onConnect: () => _sendRequest(student),
              ),
        ],
      ],
    ),
  );

  Widget _requestsSection() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(22),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return _RequestListState(
        icon: Icons.cloud_off_outlined,
        title: 'Requests could not be loaded',
        message: _error!,
        action: TextButton.icon(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      );
    }
    if (_requests.isEmpty) {
      return const _RequestListState(
        icon: Icons.inbox_outlined,
        title: 'You’re all caught up',
        message: 'New student connection requests will appear here for you to review.',
      );
    }
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${_requests.length} pending ${_requests.length == 1 ? 'request' : 'requests'}',
              style: const TextStyle(
                color: Color(0xFF78859B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        for (final request in _requests)
          _RequestReviewCard(
            request: request,
            busy: _workingId == request.id,
            onAccept: () => _respond(request, 'accept'),
            onDecline: () => _respond(request, 'decline'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F8FC),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF5F8FC),
      foregroundColor: const Color(0xFF203454),
      title: const Text(
        'Requests to review',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh requests',
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            _searchSection(),
            const SizedBox(height: 18),
            const Text(
              'Incoming requests',
              style: TextStyle(
                color: Color(0xFF203454),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            _requestsSection(),
          ],
        ),
      ),
    ),
    bottomNavigationBar: AppBottomNav(
      selectedIndex: 0,
      forTeacher: true,
      onDestinationSelected: _onNavigation,
    ),
  );
}

class _StudentSearchResultCard extends StatelessWidget {
  const _StudentSearchResultCard({
    required this.student,
    required this.busy,
    required this.onConnect,
  });

  final GrowthConnectionData student;
  final bool busy;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (student.accountId?.isNotEmpty == true) 'ID ${student.accountId}',
      if (student.className?.isNotEmpty == true) student.className!,
      if (student.schoolName?.isNotEmpty == true) student.schoolName!,
    ].join(' · ');
    final (status, color, tint) = switch (student.status) {
      'request_sent' => (
        'Request sent',
        const Color(0xFF287ACB),
        const Color(0xFFEAF3FF),
      ),
      'request_received' => (
        'Request received · review below',
        const Color(0xFF8752C8),
        const Color(0xFFF2ECFF),
      ),
      'unavailable' => (
        'Already connected to a teacher',
        const Color(0xFF78859B),
        const Color(0xFFF0F2F5),
      ),
      _ => (
        'Available to request',
        const Color(0xFF168064),
        const Color(0xFFE6F7F1),
      ),
    };
    final canRequest = student.status == 'suggested';
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.fromLTRB(10, 9, 7, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFD),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE7EDF3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE6F7F2),
            child: Text(
              student.fullName.trim().isEmpty
                  ? '?'
                  : student.fullName.trim()[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF149B78),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 9),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    details,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF78859B),
                      fontSize: 9,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          if (canRequest)
            TextButton(
              onPressed: busy ? null : onConnect,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF149B78),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: busy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Request', style: TextStyle(fontSize: 10)),
            ),
        ],
      ),
    );
  }
}

class _RequestReviewCard extends StatelessWidget {
  const _RequestReviewCard({
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
  Widget build(BuildContext context) {
    final student = request.person;
    final details = [
      if (student.accountId?.isNotEmpty == true) 'ID ${student.accountId}',
      if (student.className?.isNotEmpty == true) student.className!,
      if (student.section?.isNotEmpty == true) 'Section ${student.section}',
      if (student.schoolName?.isNotEmpty == true) student.schoolName!,
    ].join(' · ');
    final requestedDate = request.createdAt?.toLocal();
    final dateLabel = requestedDate == null
        ? ''
        : 'Requested ${requestedDate.day}/${requestedDate.month}/${requestedDate.year}';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE7EDF3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFF2ECFF),
                  child: Text(
                    student.fullName.trim().isEmpty
                        ? '?'
                        : student.fullName.trim()[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF8752C8),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
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
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          details,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF78859B),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (dateLabel.isNotEmpty) ...[
              const SizedBox(height: 9),
              Text(
                dateLabel,
                style: const TextStyle(color: Color(0xFF8793A6), fontSize: 10),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF68768C),
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF149B78),
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: busy
                        ? const SizedBox.square(
                            dimension: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Accept connection'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestListState extends StatelessWidget {
  const _RequestListState({
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
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF149B78), size: 38),
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
          ?action,
        ],
      ),
    ),
  );
}

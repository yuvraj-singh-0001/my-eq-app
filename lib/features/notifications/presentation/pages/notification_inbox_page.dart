import 'package:flutter/material.dart';

import '../../../authentication/data/auth_api.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../dashboard/presentation/pages/profile_page.dart';
import '../../../journal/presentation/pages/journal_page.dart';
import '../../../parent/presentation/pages/parent_student_page.dart';
import '../../../teacher/presentation/pages/student_reflections_page.dart';
import '../../../teacher/presentation/pages/student_profile_page.dart';

class NotificationInboxPage extends StatefulWidget {
  const NotificationInboxPage({super.key, required this.result});

  final LoginResult result;

  @override
  State<NotificationInboxPage> createState() => _NotificationInboxPageState();
}

class _NotificationInboxPageState extends State<NotificationInboxPage> {
  AppNotificationsData? _data;
  bool _loading = true;
  String? _error;
  String? _openingId;

  String? get _token => widget.result.token;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = _token;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Sign in again to load notifications.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AuthApi.getNotifications(token);
      if (!mounted) return;
      setState(() {
        _data = data;
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

  Future<void> _markAllRead() async {
    final token = _token;
    if (token == null || (_data?.unreadCount ?? 0) == 0) return;
    try {
      await AuthApi.markAllNotificationsRead(token);
      await _load();
    } on AuthApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _openNotification(AppNotificationData item) async {
    final token = _token;
    if (token == null || _openingId != null) return;
    setState(() => _openingId = item.id);
    try {
      if (!item.isRead) {
        await AuthApi.markNotificationRead(
          token: token,
          notificationId: item.id,
        );
      }
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      final destination = item.payload['destination'] as String?;
      if (destination == 'connection_requests' ||
          destination == 'connections') {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) =>
                ConnectionRequestsPage(token: token, role: widget.result.role),
          ),
        );
      } else if (destination == 'student_reflections' ||
          destination == 'shared_reflections' ||
          destination == 'parent_progress' ||
          destination == 'teacher_progress') {
        await _openStudent(item, destination!);
      } else if (destination == 'student_progress') {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => DashboardPage(result: widget.result),
          ),
        );
      } else if (destination == 'student_check_in' &&
          widget.result.role == 'student') {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => JournalPage(result: widget.result),
          ),
        );
      }
    } on AuthApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }

  Future<void> _openStudent(
    AppNotificationData item,
    String destination,
  ) async {
    final token = _token;
    if (token == null) return;
    final students = await AuthApi.getGrowthConnections(
      token: token,
      role: widget.result.role,
    );
    final studentId = item.payload['studentId']?.toString();
    GrowthConnectionData? student;
    for (final connection in students) {
      if (connection.id == studentId) {
        student = connection;
        break;
      }
    }
    if (!mounted) return;
    if (student == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This student is no longer connected to your account.'),
        ),
      );
      return;
    }

    if (widget.result.role == 'teacher') {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => destination == 'teacher_progress'
              ? TeacherStudentProgressPage(
                  result: widget.result,
                  student: student!,
                )
              : StudentReflectionsPage(
                  result: widget.result,
                  student: student!,
                ),
        ),
      );
    } else if (widget.result.role == 'parent') {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ParentStudentPage(
            token: token,
            student: student!,
            parent: widget.result,
            initialSection: destination == 'shared_reflections' ? 0 : 1,
          ),
        ),
      );
    } else {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => JournalPage(result: widget.result),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F9FA),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF5F9FA),
      title: const Text(
        'Notifications',
        style: TextStyle(color: Color(0xFF162B4A), fontWeight: FontWeight.w800),
      ),
      actions: [
        if ((_data?.unreadCount ?? 0) > 0)
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Mark all read'),
          ),
      ],
    ),
    body: SafeArea(
      child: RefreshIndicator(onRefresh: _load, child: _buildList()),
    ),
  );

  Widget _buildList() {
    if (_loading && _data == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF168C73)),
      );
    }
    if (_error != null && _data == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _EmptyState(
            message: _error!,
            icon: Icons.cloud_off_outlined,
            action: TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ),
        ],
      );
    }
    final notifications = _data?.notifications ?? const [];
    if (notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          _EmptyState(
            message: 'Connection requests and shared growth updates will appear here.',
            icon: Icons.notifications_none_rounded,
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        final item = notifications[index];
        return _NotificationTile(
          item: item,
          opening: _openingId == item.id,
          onTap: () => _openNotification(item),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.opening,
    required this.onTap,
  });

  final AppNotificationData item;
  final bool opening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = item.type.startsWith('connection_request')
        ? const Color(0xFF5478BC)
        : const Color(0xFF168C73);
    return Material(
      color: item.isRead ? Colors.white : const Color(0xFFEAF6F3),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: opening ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withAlpha(24),
                foregroundColor: color,
                child: Icon(_iconFor(item.type), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              color: Color(0xFF182D4C),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4, left: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF168C73),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: const TextStyle(
                        color: Color(0xFF65758D),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _timeAgo(item.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF8793A4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (opening)
                const Padding(
                  padding: EdgeInsets.only(left: 6, top: 12),
                  child: SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8190A6),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String type) => switch (type) {
    'student_note_saved' => Icons.menu_book_outlined,
    'teacher_feedback_received' => Icons.insights_outlined,
    'growth_feedback_received' => Icons.forum_outlined,
    'daily_digest' => Icons.auto_awesome_outlined,
    'connection_request_accepted' => Icons.link_rounded,
    'connection_request_declined' => Icons.link_off_rounded,
    _ => Icons.person_add_alt_1_rounded,
  };

  String _timeAgo(DateTime date) {
    final elapsed = DateTime.now().difference(date.toLocal());
    if (elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inHours < 1) return '${elapsed.inMinutes} min ago';
    if (elapsed.inDays < 1) return '${elapsed.inHours} hr ago';
    if (elapsed.inDays == 1) return 'Yesterday';
    return '${date.toLocal().day}/${date.toLocal().month}/${date.toLocal().year}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.icon, this.action});

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF168C73), size: 27),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF65758D),
            fontSize: 12,
            height: 1.45,
          ),
        ),
            ?action,
      ],
    ),
  );
}

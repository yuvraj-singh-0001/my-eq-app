import 'package:flutter/material.dart';

import '../../../authentication/data/auth_api.dart';
import '../../../dashboard/presentation/pages/profile_page.dart';
import '../widgets/parent_bottom_nav.dart';
import '../widgets/shared_reflection_overview.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import 'parent_navigation_page.dart';
import 'parent_settings_page.dart';
import 'parent_student_page.dart';

class ParentDashboardPage extends StatefulWidget {
  const ParentDashboardPage({super.key, required this.result});
  final LoginResult result;
  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  final _identityController = TextEditingController();
  List<GrowthConnectionData> _children = const [];
  Map<String, List<JournalNoteData>> _sharedNotes = const {};
  bool _loading = true;
  bool _connecting = false;
  bool _searching = false;
  String? _error;
  String? get _token => widget.result.token;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  @override
  void dispose() {
    _identityController.dispose();
    super.dispose();
  }

  Future<void> _loadChildren() async {
    final token = _token;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Please sign in again to load your family.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final people = await AuthApi.getGrowthConnections(
        token: token,
        role: 'parent',
      );
      final sharedNotes = <String, List<JournalNoteData>>{};
      await Future.wait(
        people.map((child) async {
          try {
            final page = await AuthApi.getParentStudentJournalNotes(
              token: token,
              studentId: child.id,
            );
            sharedNotes[child.id] = page.notes;
          } on AuthApiException {
            // A child card remains available if shared reflections cannot load.
          }
        }),
      );
      if (!mounted) return;
      setState(() {
        _children = people;
        _sharedNotes = sharedNotes;
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

  Future<void> _requestChildConnection() async {
    final token = _token;
    final identity = _identityController.text.trim();
    if (token == null || identity.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the student ID or username.')),
      );
      return;
    }
    setState(() {
      _connecting = true;
      _searching = true;
    });
    try {
      final result = await AuthApi.searchGrowthPeople(
        token: token,
        role: 'parent',
        search: identity,
      );
      if (result.people.isEmpty) {
        throw const AuthApiException('No student matched that ID or username.');
      }
      final student = result.people.first;
      if (student.role != 'student') {
        throw const AuthApiException(
          'Parents can connect with a student account using its ID or username.',
        );
      }
      if (student.status == 'connected') {
        throw const AuthApiException(
          'This student is already connected to your parent account.',
        );
      }
      if (student.status == 'request_sent') {
        throw const AuthApiException(
          'Your connection request is already waiting for the student.',
        );
      }
      await AuthApi.sendGrowthConnectionRequest(
        token: token,
        role: 'parent',
        identity: student.accountId ?? student.username ?? identity,
      );
      _identityController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Connection request sent to ${student.fullName}. The student must accept it first.',
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
      if (mounted) {
        setState(() {
          _connecting = false;
          _searching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    final id = widget.result.parentId;
    final token = _token;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F9FA),
        title: const Text(
          'Parent Home',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF162B4A),
          ),
        ),
        actions: [
          NotificationBell(result: widget.result),
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
                    onConnectionsChanged: _loadChildren,
                  ),
                ),
              );
              if (mounted) _loadChildren();
            },
            icon: const Icon(Icons.mark_email_unread_outlined),
          ),
          IconButton(
            tooltip: 'Profile and settings',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => ParentSettingsPage(
                  result: widget.result,
                  onNavigate: (index) {
                    if (index == 0) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => ParentNavigationPage(
                            result: widget.result,
                            initialIndex: index,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadChildren,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 22,
              10,
              compact ? 16 : 22,
              28,
            ),
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F5F1),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.family_restroom_rounded,
                        color: Color(0xFF168C73),
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome,',
                            style: TextStyle(
                              color: Color(0xFF557168),
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            widget.result.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF163A35),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (id != null)
                            Text(
                              'Parent ID  $id',
                              style: const TextStyle(
                                color: Color(0xFF557168),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Your children',
                style: TextStyle(
                  color: Color(0xFF182D4C),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'A secure connection lets you view reflections they choose to share.',
                style: TextStyle(
                  color: Color(0xFF6D7B91),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              if (_loading && _children.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF159976)),
                  ),
                )
              else if (_error != null && _children.isEmpty)
                _MessageCard(
                  text: _error!,
                  icon: Icons.cloud_off_outlined,
                  onRetry: _loadChildren,
                )
              else if (_children.isEmpty)
                const _MessageCard(
                  text: 'No children connected yet. Search using the student ID or username below. The student will review the request.',
                  icon: Icons.link_rounded,
                )
              else
                for (final child in _children) ...[
                  _ChildCard(
                    child: child,
                    sharedNotes: _sharedNotes[child.id] ?? const [],
                    onTap: () {
                      if (token == null) return;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ParentStudentPage(
                            token: token,
                            student: child,
                            parent: widget.result,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D1A3855),
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
                        Icon(Icons.vpn_key_outlined, color: Color(0xFF159976)),
                        SizedBox(width: 8),
                        Text(
                          'Request a student connection',
                          style: TextStyle(
                            color: Color(0xFF182D4C),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Search by student ID or username. The student reviews and accepts the request.',
                      style: TextStyle(
                        color: Color(0xFF718097),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 13),
                    TextField(
                      controller: _identityController,
                      decoration: InputDecoration(
                        hintText: 'Student ID or username',
                        helperText: 'No phone number required',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: const Color(0xFFF6F9FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _connecting ? null : _requestChildConnection,
                        icon: _connecting
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.link_rounded),
                        label: Text(
                          _searching
                              ? 'Searching…'
                              : _connecting
                              ? 'Sending request…'
                              : 'Find and send request',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF159976),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _PrivacyHint(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ParentBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => ParentNavigationPage(
                result: widget.result,
                initialIndex: index,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.child,
    required this.sharedNotes,
    required this.onTap,
  });
  final GrowthConnectionData child;
  final List<JournalNoteData> sharedNotes;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFE5F5F1),
              foregroundColor: Color(0xFF168C73),
              child: Icon(Icons.school_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF182D4C),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (child.className != null) child.className!,
                      if (child.accountId != null) 'ID ${child.accountId}',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF728097),
                      fontSize: 11,
                    ),
                  ),
                  if (sharedNotes.isNotEmpty) ...[
                    const SizedBox(height: 9),
                    SharedReflectionOverview(notes: sharedNotes, compact: true),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF748299)),
          ],
        ),
      ),
    ),
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.text, required this.icon, this.onRetry});
  final String text;
  final IconData icon;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF648092)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF617087),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ),
        if (onRetry != null)
          IconButton(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
          ),
      ],
    ),
  );
}

class _PrivacyHint extends StatelessWidget {
  const _PrivacyHint();
  @override
  Widget build(BuildContext context) => const Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.shield_outlined, size: 17, color: Color(0xFF74849A)),
      SizedBox(width: 8),
      Expanded(
        child: Text(
          'Only students connected through a valid invite appear here. A parent can read a reflection only when the student chooses to share it.',
          style: TextStyle(color: Color(0xFF74849A), fontSize: 11, height: 1.4),
        ),
      ),
    ],
  );
}

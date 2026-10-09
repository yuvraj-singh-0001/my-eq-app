import 'package:flutter/material.dart';

import '../../../authentication/data/auth_api.dart';
import '../../../authentication/data/auth_session.dart';
import '../../../dashboard/presentation/pages/profile_edit_page.dart';
import '../../../notifications/presentation/pages/notification_inbox_page.dart';
import '../widgets/parent_bottom_nav.dart';
import 'parent_student_page.dart';

class ParentSettingsPage extends StatefulWidget {
  const ParentSettingsPage({
    super.key,
    required this.result,
    required this.onNavigate,
  });

  final LoginResult result;
  final ValueChanged<int> onNavigate;

  @override
  State<ParentSettingsPage> createState() => _ParentSettingsPageState();
}

class _ParentSettingsPageState extends State<ParentSettingsPage> {
  UserProfileData? _profile;
  List<GrowthConnectionData> _students = const [];
  bool _loading = true;
  String? _error;

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
        _error = 'Please sign in again to open account settings.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait<Object>([
        AuthApi.getProfile(token),
        AuthApi.getGrowthConnections(token: token, role: 'parent'),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = values[0] as UserProfileData;
        _students = values[1] as List<GrowthConnectionData>;
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

  Future<void> _editProfile() async {
    final token = widget.result.token;
    final profile = _profile;
    if (token == null || profile == null) return;
    final updated = await Navigator.of(context).push<UserProfileData>(
      MaterialPageRoute<UserProfileData>(
        builder: (_) => ProfileEditPage(token: token, profile: profile),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() => _profile = updated);
    await AuthSession.save(
      LoginResult(
        fullName: updated.fullName,
        role: updated.role,
        parentId: updated.parentId ?? widget.result.parentId,
        email: updated.email,
        username: updated.username,
        token: token,
      ),
    );
  }

  Future<void> _openStudent(GrowthConnectionData student) async {
    final token = widget.result.token;
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

  Future<void> _openNotifications() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => NotificationInboxPage(result: widget.result),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F9FA),
        title: const Text(
          'Profile & settings',
          style: TextStyle(
            color: Color(0xFF162B4A),
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh profile',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(17, 8, 17, 28),
            children: [
              _ParentProfileCard(
                name: profile?.fullName ?? widget.result.fullName,
                id: profile?.parentId ?? widget.result.parentId,
                email: profile?.email ?? widget.result.email,
                mobile: profile?.mobileNumber,
                username: profile?.username ?? widget.result.username,
                onEdit: profile == null ? null : _editProfile,
              ),
              const SizedBox(height: 14),
              if (_loading && profile == null)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF159976)),
                  ),
                )
              else if (_error != null && profile == null)
                _ParentStateCard(message: _error!, onRetry: _load)
              else ...[
                _SettingsSection(
                  title: 'Account',
                  children: [
                    _SettingsTile(
                      icon: Icons.manage_accounts_outlined,
                      title: 'Edit profile',
                      subtitle: 'Name, email, mobile and username',
                      onTap: _editProfile,
                    ),
                    _SettingsTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'Requests and family updates',
                      onTap: _openNotifications,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SettingsSection(
                  title: 'Connected students',
                  trailing: Text(
                    '${_students.length}',
                    style: const TextStyle(
                      color: Color(0xFF168C73),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  children: [
                    if (_students.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Connected students will appear here.',
                          style: TextStyle(
                            color: Color(0xFF718097),
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      for (final student in _students)
                        _SettingsTile(
                          icon: Icons.school_outlined,
                          title: student.fullName,
                          subtitle: [
                            if (student.className != null) student.className!,
                            if (student.accountId != null)
                              'ID ${student.accountId}',
                          ].join(' · '),
                          onTap: () => _openStudent(student),
                        ),
                    _SettingsTile(
                      icon: Icons.person_add_alt_1_rounded,
                      title: 'Connect a student',
                      subtitle: 'Use their student ID or username',
                      onTap: () => widget.onNavigate(0),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF6F3),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF168C73),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You can view reflections your child chooses to share. Private notes stay private.',
                          style: TextStyle(
                            color: Color(0xFF42675F),
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: ParentBottomNav(
        currentIndex: 4,
        onTap: widget.onNavigate,
      ),
    );
  }
}

class _ParentProfileCard extends StatelessWidget {
  const _ParentProfileCard({
    required this.name,
    required this.id,
    required this.email,
    required this.mobile,
    required this.username,
    required this.onEdit,
  });

  final String name;
  final String? id;
  final String? email;
  final String? mobile;
  final String? username;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => Container(
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
    child: Row(
      children: [
        const CircleAvatar(
          radius: 27,
          backgroundColor: Color(0xFFE5F5F1),
          foregroundColor: Color(0xFF168C73),
          child: Icon(Icons.person_rounded, size: 27),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF182D4C),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (id?.isNotEmpty == true)
                Text(
                  'Parent ID · $id',
                  style: const TextStyle(
                    color: Color(0xFF718097),
                    fontSize: 11,
                  ),
                ),
              if (email?.isNotEmpty == true)
                Text(
                  email!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF718097),
                    fontSize: 11,
                  ),
                ),
              if (mobile?.isNotEmpty == true)
                Text(
                  mobile!,
                  style: const TextStyle(
                    color: Color(0xFF718097),
                    fontSize: 11,
                  ),
                ),
              if (username?.isNotEmpty == true)
                Text(
                  '@$username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF718097),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Edit profile',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, color: Color(0xFF168C73)),
        ),
      ],
    ),
  );
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 14, 15, 7),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF182D4C),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        ...children,
      ],
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
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
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFF168C73), size: 20),
    ),
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF283A56),
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
    subtitle: Text(
      subtitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Color(0xFF7A879B), fontSize: 11),
    ),
    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA7B8)),
    dense: true,
  );
}

class _ParentStateCard extends StatelessWidget {
  const _ParentStateCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    child: ListTile(
      title: Text(message, style: const TextStyle(fontSize: 12)),
      trailing: IconButton(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ),
  );
}

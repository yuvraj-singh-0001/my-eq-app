import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../authentication/data/auth_api.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import 'profile_edit_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.result});

  final LoginResult result;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfileData? _profile;
  final List<JournalNoteData> _notes = [];
  List<GrowthConnectionData> _connections = const [];
  bool _isLoading = false;
  bool _isLoadingNotes = false;
  bool _isLoadingMoreNotes = false;
  bool _isLoadingConnections = false;
  bool _hasMoreNotes = false;
  String? _notesCursor;
  String? _notesError;
  String? _error;
  String? _connectionsError;
  bool _showAllConnections = false;
  int _connectionReloadKey = 0;

  @override
  void initState() {
    super.initState();
    _profile = _cachedProfile;
    _loadProfile();
    _loadNotes();
    _loadConnections();
  }

  UserProfileData get _cachedProfile => UserProfileData(
    id: '',
    fullName: widget.result.fullName,
    role: widget.result.role,
    studentId: widget.result.studentId,
    teacherId: widget.result.teacherId,
    email: widget.result.email,
    username: widget.result.username,
  );

  Future<void> _loadProfile() async {
    final token = widget.result.token;
    if (token == null || token.isEmpty) {
      setState(() => _error = 'Sign in again to load your full profile.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final profile = await AuthApi.getProfile(token);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNotes() async {
    if (widget.result.role != 'student') return;
    final token = widget.result.token;
    if (token == null || token.isEmpty) return;
    setState(() {
      _isLoadingNotes = true;
      _notesError = null;
    });
    try {
      final page = await AuthApi.getJournalNotes(token);
      if (!mounted) return;
      setState(() {
        _notes
          ..clear()
          ..addAll(page.notes);
        _notesCursor = page.nextCursor;
        _hasMoreNotes = page.hasMore;
        _isLoadingNotes = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _notesError = error.message;
        _isLoadingNotes = false;
      });
    }
  }

  Future<void> _loadConnections() async {
    final token = widget.result.token;
    if (token == null || token.isEmpty) return;
    final role = _profile?.role ?? widget.result.role;
    if (!const {'student', 'teacher', 'parent'}.contains(role)) return;
    setState(() {
      _isLoadingConnections = true;
      _connectionsError = null;
    });
    try {
      final people = await AuthApi.getGrowthConnections(
        token: token,
        role: role,
      );
      if (!mounted) return;
      setState(() {
        _connections = people;
        _isLoadingConnections = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _connectionsError = error.message;
        _isLoadingConnections = false;
      });
    }
  }

  Future<void> _connectPeople() async {
    final token = widget.result.token;
    if (token == null || token.isEmpty) return;
    final role = _profile?.role ?? widget.result.role;
    if (role == 'student') {
      final action = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Connect with someone'),
                subtitle: Text('Search for a student or teacher, or invite a parent.'),
              ),
              ListTile(
                leading: const Icon(Icons.person_search_rounded),
                title: const Text('Find a student or teacher'),
                subtitle: const Text('Send a request using their ID or username'),
                onTap: () => Navigator.pop(sheetContext, 'search'),
              ),
              ListTile(
                leading: const Icon(Icons.family_restroom_outlined),
                title: const Text('Invite a parent / guardian'),
                subtitle: const Text('Create a one-time invite code'),
                onTap: () => Navigator.pop(sheetContext, 'parent'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
      if (!mounted || action == null) return;
      if (action == 'search') {
        await _sendRequestByIdentity(token);
      } else {
        await _inviteParent(token);
      }
    } else if (role == 'parent') {
      await _connectWithStudentCode(token);
    }
  }

  Future<void> _sendRequestByIdentity(String token) async {
    final controller = TextEditingController();
    final teacherId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Find a student or teacher'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Student / teacher ID or username',
            hintText: 'Enter an account ID or username',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || teacherId == null || teacherId.isEmpty) return;
    try {
      await AuthApi.sendGrowthConnectionRequest(
        token: token,
        role: 'student',
        identity: teacherId,
      );
      await _loadConnections();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request sent.')),
        );
        setState(() => _connectionReloadKey++);
      }
    } on AuthApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _inviteParent(String token) async {
    try {
      final code = await AuthApi.createParentInvite(token);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Parent invite code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Share this code with your parent. It expires in 20 minutes.'),
              const SizedBox(height: 14),
              SelectableText(
                code,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite code copied.')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy code'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } on AuthApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _connectWithStudentCode(String token) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Connect with a student'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Student invite code'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || code == null || code.isEmpty) return;
    try {
      await AuthApi.connectParentWithCode(token: token, inviteCode: code);
      await _loadConnections();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student connected to your account.')),
        );
      }
    } on AuthApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _loadMoreNotes() async {
    final token = widget.result.token;
    final cursor = _notesCursor;
    if (_isLoadingMoreNotes || !_hasMoreNotes || token == null || cursor == null) {
      return;
    }
    setState(() {
      _isLoadingMoreNotes = true;
      _notesError = null;
    });
    try {
      final page = await AuthApi.getJournalNotes(token, cursor: cursor);
      if (!mounted) return;
      final knownIds = _notes.map((note) => note.id).toSet();
      setState(() {
        _notes.addAll(page.notes.where((note) => !knownIds.contains(note.id)));
        _notesCursor = page.nextCursor;
        _hasMoreNotes = page.hasMore;
        _isLoadingMoreNotes = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _notesError = error.message;
        _isLoadingMoreNotes = false;
      });
    }
  }

  Future<void> _editProfile() async {
    final token = widget.result.token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in again to update your profile.')),
      );
      return;
    }
    final updated = await Navigator.of(context).push<UserProfileData>(
      MaterialPageRoute<UserProfileData>(
        builder: (_) => ProfileEditPage(
          token: token,
          profile: _profile ?? _cachedProfile,
        ),
      ),
    );
    if (mounted && updated != null) setState(() => _profile = updated);
  }

  String get _roleName {
    final role = (_profile?.role ?? widget.result.role).toLowerCase();
    return switch (role) {
      'teacher' => 'Teacher',
      'parent' => 'Parent',
      'admin' => 'Administrator',
      _ => 'Student',
    };
  }

  String? get _accountId =>
      _profile?.teacherId ??
      _profile?.studentId ??
      widget.result.teacherId ??
      widget.result.studentId;

  String _displayDate(DateTime date) {
    final local = date.toUtc().add(const Duration(hours: 5, minutes: 30));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile ?? _cachedProfile;
    final isStudent = profile.role == 'student';
    final details = <(String, String?)>[
      ('Email address', profile.email),
      ('Mobile number', profile.mobileNumber),
      ('Username', profile.username),
      ('Member since', profile.createdAt == null ? null : _displayDate(profile.createdAt!)),
    ];
    final studentDetails = <(String, String?)>[
      ('Class', profile.className),
      ('Section', profile.section),
      ('Gender', profile.gender),
      ('School', profile.schoolName),
    ];
    final teacherDetails = <(String, String?)>[
      ('School', profile.schoolName),
      ('Teaching subject', profile.teachingSubject),
    ];
    final familyDetails = <(String, String?)>[
      ('Father', profile.fatherName),
      ('Father’s email', profile.fatherEmail),
      ('Father’s mobile', profile.fatherMobileNumber),
      ('Mother', profile.motherName),
      ('Mother’s email', profile.motherEmail),
      ('Mother’s mobile', profile.motherMobileNumber),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('My Profile'),
            Text(
              'Your personal information and settings',
              style: TextStyle(fontSize: 11, color: Color(0xFF78859B)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF6F9FC),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            onPressed: _editProfile,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Refresh profile',
            onPressed: _isLoading ? null : _loadProfile,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              _ProfileHero(
                name: profile.fullName,
                roleName: _roleName,
                accountId: _accountId,
                isLoading: _isLoading,
              ),
              if (isStudent) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ProfileMetric(
                        icon: Icons.menu_book_rounded,
                        label: 'Journal notes',
                        value: _isLoadingNotes && _notes.isEmpty
                            ? '...'
                            : '${_notes.length}${_hasMoreNotes ? '+' : ''}',
                        color: const Color(0xFF149B78),
                        background: const Color(0xFFE7F7F2),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _ProfileMetric(
                        icon: Icons.groups_rounded,
                        label: 'Connected people',
                        value: _isLoadingConnections && _connections.isEmpty
                            ? '...'
                            : '${_connections.length}',
                        color: const Color(0xFF2682D8),
                        background: const Color(0xFFEAF3FF),
                      ),
                    ),
                  ],
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Material(
                  color: const Color(0xFFFFF5E7),
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    leading: const Icon(
                      Icons.cloud_off_rounded,
                      color: Color(0xFFB66A12),
                    ),
                    title: Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFF714B1D),
                        fontSize: 12,
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'Try again',
                      onPressed: _isLoading ? null : _loadProfile,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _ProfileInfoCard(
                title: 'Account details',
                icon: Icons.verified_user_outlined,
                rows: [
                  ...details,
                ],
                onEdit: _editProfile,
              ),
              if (isStudent) ...[
                const SizedBox(height: 12),
                _ProfileInfoCard(
                  title: 'School information',
                  icon: Icons.school_outlined,
                  rows: studentDetails,
                  onEdit: _editProfile,
                ),
              ],
              if (!isStudent && profile.role == 'teacher') ...[
                const SizedBox(height: 12),
                _ProfileInfoCard(
                  title: 'Work information',
                  icon: Icons.work_outline_rounded,
                  rows: teacherDetails,
                  onEdit: _editProfile,
                ),
              ],
              if (isStudent) ...[
                const SizedBox(height: 12),
                _ProfileInfoCard(
                  title: 'Family contacts',
                  icon: Icons.family_restroom_outlined,
                  rows: familyDetails,
                  onEdit: _editProfile,
                ),
              ],
              if (const {'student', 'teacher', 'parent'}.contains(profile.role)) ...[
                const SizedBox(height: 12),
                _ConnectedPeopleCard(
                  people: _showAllConnections
                      ? _connections
                      : _connections.take(2).toList(growable: false),
                  totalCount: _connections.length,
                  showAll: _showAllConnections,
                  onShowAll: () => setState(
                    () => _showAllConnections = !_showAllConnections,
                  ),
                  isLoading: _isLoadingConnections,
                  error: _connectionsError,
                  onRetry: _loadConnections,
                  onConnect: profile.role == 'student' || profile.role == 'parent'
                      ? _connectPeople
                      : null,
                ),
              ],
              if (profile.role == 'student' || profile.role == 'teacher') ...[
                const SizedBox(height: 12),
                _ConnectionRequestsAndSuggestions(
                  key: ValueKey(_connectionReloadKey),
                  token: widget.result.token ?? '',
                  role: profile.role,
                  onConnectionsChanged: () {
                    if (!mounted) return;
                    _loadConnections();
                    setState(() => _connectionReloadKey++);
                  },
                ),
              ],
              const SizedBox(height: 12),
              const _PrivacyCard(),
              if (isStudent) ...[
                const SizedBox(height: 18),
                _buildJournalHistory(),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, color: Color(0xFF168D78)),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'These details belong to your account. Your private journal notes stay private.',
                        style: TextStyle(
                          color: Color(0xFF456B65),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isStudent
          ? AppBottomNav(
              selectedIndex: 4,
              onDestinationSelected: (index) {
                if (index == 1 || index == 0) {
                  Navigator.of(context).maybePop();
                } else if (index != 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('This section will be available soon.'),
                    ),
                  );
                }
              },
            )
          : null,
    );
  }

  Widget _buildJournalHistory() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Journal history',
              style: TextStyle(
                color: Color(0xFF203454),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (_notes.isNotEmpty)
            Text(
              '${_notes.length}${_hasMoreNotes ? '+' : ''} notes',
              style: const TextStyle(
                color: Color(0xFF78859B),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
      const SizedBox(height: 4),
      const Text(
        'Your notes stay private. Dates and topics are shown here.',
        style: TextStyle(color: Color(0xFF78859B), fontSize: 11),
      ),
      const SizedBox(height: 10),
      if (_isLoadingNotes && _notes.isEmpty)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(22),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
      else if (_notesError != null && _notes.isEmpty)
        _JournalHistoryMessage(
          text: _notesError!,
          buttonText: 'Try again',
          onPressed: _loadNotes,
        )
      else if (_notes.isEmpty)
        const _JournalHistoryMessage(
          text: 'Your saved reflections will appear here.',
        )
      else ...[
        for (final note in _notes) _JournalHistoryCard(note: note),
        if (_notesError != null)
          _JournalHistoryMessage(
            text: _notesError!,
            buttonText: 'Try again',
            onPressed: _loadMoreNotes,
          ),
        if (_hasMoreNotes)
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: _isLoadingMoreNotes ? null : _loadMoreNotes,
              icon: _isLoadingMoreNotes
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more_rounded),
              label: Text(_isLoadingMoreNotes ? 'Loading…' : 'Load more notes'),
            ),
          ),
      ],
    ],
  );
}

class _JournalHistoryCard extends StatelessWidget {
  const _JournalHistoryCard({required this.note});

  final JournalNoteData note;

  String _timestamp(DateTime date) {
    final indiaTime = date.toUtc().add(const Duration(hours: 5, minutes: 30));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = indiaTime.hour % 12 == 0 ? 12 : indiaTime.hour % 12;
    final minute = indiaTime.minute.toString().padLeft(2, '0');
    final period = indiaTime.hour < 12 ? 'AM' : 'PM';
    return '${indiaTime.day} ${months[indiaTime.month - 1]} ${indiaTime.year}  ·  '
        '$hour:$minute $period IST';
  }

  @override
  Widget build(BuildContext context) {
    final topics = note.sections
        .map((section) => section['subcategory'] as String? ?? '')
        .where((topic) => topic.trim().isNotEmpty)
        .toList(growable: false);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE7ECF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x070B2B4B),
            blurRadius: 9,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                color: Color(0xFF149B78),
                size: 19,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  note.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF203454),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF8793A6),
                size: 15,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            _timestamp(note.createdAt),
            style: const TextStyle(
              color: Color(0xFF78859B),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (topics.isNotEmpty) ...[
            const SizedBox(height: 9),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final topic in topics)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7F4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      topic,
                      style: const TextStyle(
                        color: Color(0xFF168D78),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _JournalHistoryMessage extends StatelessWidget {
  const _JournalHistoryMessage({
    required this.text,
    this.buttonText,
    this.onPressed,
  });

  final String text;
  final String? buttonText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE7ECF2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF78859B),
            fontSize: 12,
            height: 1.4,
          ),
        ),
        if (buttonText != null && onPressed != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onPressed, child: Text(buttonText!)),
          ),
      ],
    ),
  );
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.roleName,
    required this.accountId,
    required this.isLoading,
  });

  final String name;
  final String roleName;
  final String? accountId;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final bannerHeight = (width / 3.13).clamp(88.0, 145.0).toDouble();
      final compact = width < 330;
      return Container(
        height: bannerHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F8F3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFDCEFEA)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0B2B4B),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'lib/assets/images/profile-image.jpeg',
              fit: BoxFit.cover,
              cacheWidth: 900,
              errorBuilder: (context, error, stackTrace) => const ColoredBox(
                color: Color(0xFFE8F8F3),
              ),
            ),
            Positioned(
              left: width * 0.34,
              top: bannerHeight * 0.12,
              width: width * 0.32,
              height: bannerHeight * 0.72,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF10234B),
                      fontSize: compact ? 12 : 15,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: compact ? 3 : 6),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 7 : 9,
                      vertical: compact ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(220),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      roleName,
                      style: TextStyle(
                        color: Color(0xFF168D78),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (accountId != null && accountId!.isNotEmpty) ...[
                    SizedBox(height: compact ? 3 : 6),
                    Text(
                      'ID: $accountId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF526681),
                        fontSize: compact ? 8 : 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: SizedBox(
                        width: 56,
                        child: LinearProgressIndicator(minHeight: 2),
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

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({
    required this.title,
    required this.icon,
    required this.rows,
    this.onEdit,
  });

  final String title;
  final IconData icon;
  final List<(String, String?)> rows;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows;
    if (visibleRows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7ECF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080B2B4B),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: const Color(0xFF149B78)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF203454),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onEdit != null)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF149B78),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var index = 0; index < visibleRows.length; index++) ...[
            if (index > 0) const Divider(height: 1, color: Color(0xFFF0F2F6)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      visibleRows[index].$1,
                      style: const TextStyle(
                        color: Color(0xFF78859B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: SelectableText(
                      visibleRows[index].$2?.trim().isNotEmpty == true
                          ? visibleRows[index].$2!.trim()
                          : 'Not added · Edit profile',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: visibleRows[index].$2?.trim().isNotEmpty == true
                            ? const Color(0xFF203454)
                            : const Color(0xFF9AA5B5),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConnectedPeopleCard extends StatelessWidget {
  const _ConnectedPeopleCard({
    required this.people,
    required this.totalCount,
    required this.showAll,
    required this.onShowAll,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    this.onConnect,
  });

  final List<GrowthConnectionData> people;
  final int totalCount;
  final bool showAll;
  final VoidCallback onShowAll;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback? onConnect;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE7ECF2)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080B2B4B),
          blurRadius: 12,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.groups_rounded, color: Color(0xFF149B78), size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Connected people',
                style: TextStyle(
                  color: Color(0xFF203454),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (totalCount > 2)
              TextButton(
                onPressed: onShowAll,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF149B78),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                child: Text(showAll ? 'Show less' : 'See all'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (isLoading && people.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (error != null && people.isEmpty)
          Row(
            children: [
              Expanded(
                child: Text(
                  error!,
                  style: const TextStyle(color: Color(0xFF78859B), fontSize: 11),
                ),
              ),
              IconButton(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded)),
            ],
          )
        else if (people.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 9),
            child: Text(
              'No accounts are connected yet. Connected people will appear here.',
              style: TextStyle(color: Color(0xFF78859B), fontSize: 11, height: 1.4),
            ),
          )
        else
          for (var i = 0; i < people.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFF0F2F6)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE7F7F2),
                child: Icon(
                  people[i].role == 'teacher'
                      ? Icons.school_outlined
                      : people[i].role == 'parent'
                      ? Icons.family_restroom_outlined
                      : Icons.person_outline_rounded,
                  color: const Color(0xFF149B78),
                  size: 19,
                ),
              ),
              title: Text(
                people[i].fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF203454),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                '${_relationship(people[i].role)}${people[i].accountId == null ? '' : ' · ${people[i].accountId}'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF78859B), fontSize: 10),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F8F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Connected',
                  style: TextStyle(
                    color: Color(0xFF149B78),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        if (onConnect != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onConnect,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
            label: const Text('Find and connect with people'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF149B78),
              side: const BorderSide(color: Color(0xFFBDE9DF)),
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
            ),
          ),
        ],
      ],
    ),
  );

  String _relationship(String role) => switch (role) {
    'teacher' => 'Teacher',
    'parent' => 'Parent / Guardian',
    _ => 'Student',
  };
}

class _ConnectionRequestsAndSuggestions extends StatefulWidget {
  const _ConnectionRequestsAndSuggestions({
    super.key,
    required this.token,
    required this.role,
    required this.onConnectionsChanged,
  });

  final String token;
  final String role;
  final VoidCallback onConnectionsChanged;

  @override
  State<_ConnectionRequestsAndSuggestions> createState() =>
      _ConnectionRequestsAndSuggestionsState();
}

class _ConnectionRequestsAndSuggestionsState
    extends State<_ConnectionRequestsAndSuggestions> {
  final _searchController = TextEditingController();
  List<GrowthConnectionData> _people = const [];
  GrowthConnectionRequests _requests = const GrowthConnectionRequests(
    incoming: [],
    outgoing: [],
  );
  bool _loadingPeople = true;
  bool _loadingRequests = true;
  String? _peopleError;
  String? _requestsError;
  String? _workingId;
  bool _needsSchool = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([_loadPeople(), _loadRequests()]);
  }

  Future<void> _loadPeople([String search = '']) async {
    setState(() {
      _loadingPeople = true;
      _peopleError = null;
    });
    try {
      final result = await AuthApi.searchGrowthPeople(
        token: widget.token,
        role: widget.role,
        search: search,
      );
      if (!mounted) return;
      setState(() {
        _people = result.people;
        _needsSchool = result.needsSchool;
        _loadingPeople = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _peopleError = error.message;
        _loadingPeople = false;
      });
    }
  }

  Future<void> _loadRequests() async {
    setState(() {
      _loadingRequests = true;
      _requestsError = null;
    });
    try {
      final result = await AuthApi.getGrowthConnectionRequests(
        token: widget.token,
        role: widget.role,
      );
      if (!mounted) return;
      setState(() {
        _requests = result;
        _loadingRequests = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _requestsError = error.message;
        _loadingRequests = false;
      });
    }
  }

  Future<void> _sendRequest(GrowthConnectionData person) async {
    final identity = person.username ?? person.accountId ?? person.id;
    setState(() => _workingId = person.id);
    try {
      await AuthApi.sendGrowthConnectionRequest(
        token: widget.token,
        role: widget.role,
        identity: identity,
      );
      if (!mounted) return;
      await Future.wait([_loadPeople(_searchController.text), _loadRequests()]);
      widget.onConnectionsChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request sent to ${person.fullName}.')),
        );
      }
    } on AuthApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  Future<void> _respond(GrowthConnectionRequestData request, String decision) async {
    setState(() => _workingId = request.id);
    try {
      await AuthApi.respondToGrowthConnectionRequest(
        token: widget.token,
        role: widget.role,
        requestId: request.id,
        decision: decision,
      );
      if (!mounted) return;
      await Future.wait([_loadRequests(), _loadPeople(_searchController.text)]);
      widget.onConnectionsChanged();
    } on AuthApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE7ECF2)),
      boxShadow: const [
        BoxShadow(color: Color(0x080B2B4B), blurRadius: 12, offset: Offset(0, 3)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.person_search_rounded, color: Color(0xFF149B78)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Find people',
                style: TextStyle(
                  color: Color(0xFF203454),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Refresh suggestions and requests',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 19),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          widget.role == 'student'
              ? 'Suggested students and teachers from your school'
              : 'Search for a student by ID or username',
          style: const TextStyle(color: Color(0xFF78859B), fontSize: 11),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: _loadPeople,
          decoration: InputDecoration(
            hintText: 'Search by ID or username',
            isDense: true,
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: IconButton(
              tooltip: 'Search',
              onPressed: () => _loadPeople(_searchController.text),
              icon: const Icon(Icons.arrow_forward_rounded, size: 19),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5EBF2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5EBF2)),
            ),
          ),
        ),
        if (_needsSchool && _searchController.text.trim().isEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Add your school name in Edit profile to get school suggestions. You can still search by ID or username.',
            style: TextStyle(color: Color(0xFF78859B), fontSize: 10, height: 1.4),
          ),
        ],
        const SizedBox(height: 8),
        if (_loadingPeople && _people.isEmpty)
          const Center(child: CircularProgressIndicator(strokeWidth: 2))
        else if (_peopleError != null)
          _SmallConnectionMessage(_peopleError!, onRetry: () => _loadPeople(_searchController.text))
        else if (_people.isEmpty)
          Text(
            _searchController.text.trim().isEmpty
                ? 'No school suggestions yet.'
                : 'No matching student or teacher found.',
            style: const TextStyle(color: Color(0xFF78859B), fontSize: 11),
          )
        else
          for (final person in _people) _personRow(person),
        if (_requests.incoming.isNotEmpty || _requests.outgoing.isNotEmpty || _requestsError != null) ...[
          const Divider(height: 22),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Connection requests',
                  style: TextStyle(
                    color: Color(0xFF203454),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_loadingRequests)
                const SizedBox.square(
                  dimension: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (_requestsError != null)
            _SmallConnectionMessage(_requestsError!, onRetry: _loadRequests),
          for (final request in _requests.incoming)
            _requestRow(request, incoming: true),
          for (final request in _requests.outgoing)
            _requestRow(request, incoming: false),
        ] else if (_loadingRequests) ...[
          const SizedBox(height: 4),
          const LinearProgressIndicator(minHeight: 2),
        ],
      ],
    ),
  );

  Widget _personRow(GrowthConnectionData person) {
    final subtitle = [
      person.role == 'teacher' ? 'Teacher' : 'Student',
      if (person.className != null) person.className!,
      if (person.accountId != null) person.accountId!,
    ].join(' · ');
    final statusText = switch (person.status) {
      'connected' => 'Connected',
      'request_sent' => 'Requested',
      'request_received' => 'Respond below',
      _ => '',
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: CircleAvatar(
        radius: 19,
        backgroundColor: person.role == 'teacher'
            ? const Color(0xFFFFF1E6)
            : const Color(0xFFE7F7F2),
        child: Icon(
          person.role == 'teacher' ? Icons.school_outlined : Icons.person_outline_rounded,
          color: const Color(0xFF149B78),
          size: 18,
        ),
      ),
      title: Text(
        person.fullName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFF203454), fontSize: 12, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF78859B), fontSize: 10)),
      trailing: person.status == 'suggested'
          ? TextButton(
              onPressed: _workingId == person.id ? null : () => _sendRequest(person),
              child: Text(_workingId == person.id ? 'Sending...' : 'Connect'),
            )
          : Text(statusText, style: const TextStyle(color: Color(0xFF149B78), fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  Widget _requestRow(GrowthConnectionRequestData request, {required bool incoming}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.person.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF203454), fontSize: 11, fontWeight: FontWeight.w700)),
                  Text(
                    incoming ? 'Wants to connect with you' : 'Request sent · Waiting for response',
                    style: const TextStyle(color: Color(0xFF78859B), fontSize: 10),
                  ),
                ],
              ),
            ),
            if (incoming) ...[
              TextButton(
                onPressed: _workingId == request.id ? null : () => _respond(request, 'decline'),
                child: const Text('Decline'),
              ),
              FilledButton.tonal(
                onPressed: _workingId == request.id ? null : () => _respond(request, 'accept'),
                child: Text(_workingId == request.id ? '...' : 'Accept'),
              ),
            ] else
              const Icon(Icons.schedule_rounded, color: Color(0xFF8895A7), size: 17),
          ],
        ),
      );
}

class _SmallConnectionMessage extends StatelessWidget {
  const _SmallConnectionMessage(this.text, {required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF78859B), fontSize: 10))),
      IconButton(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 17)),
    ],
  );
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE7ECF2)),
      boxShadow: const [
        BoxShadow(color: Color(0x080B2B4B), blurRadius: 12, offset: Offset(0, 3)),
      ],
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: Color(0xFFE5F1FF),
          child: Icon(Icons.shield_outlined, color: Color(0xFF2682D8), size: 21),
        ),
        SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy & Safety',
                style: TextStyle(
                  color: Color(0xFF203454),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Journal entries are private and visible only to you.',
                style: TextStyle(color: Color(0xFF78859B), fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
        SizedBox(width: 8),
        Icon(Icons.lock_outline_rounded, color: Color(0xFF149B78), size: 19),
      ],
    ),
  );
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF526681), fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

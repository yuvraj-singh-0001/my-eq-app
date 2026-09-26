import 'package:flutter/material.dart';

import '../../../authentication/data/auth_api.dart';
import '../../../journal/presentation/pages/journal_page.dart';
import 'profile_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.result});

  final LoginResult result;

  @override
  Widget build(BuildContext context) {
    final isTeacher = result.role == 'teacher';
    final isParent = result.role == 'parent';
    final roleName = isTeacher
        ? 'Teacher'
        : (isParent ? 'Parent' : 'Student');
    final accountId = result.teacherId ?? result.studentId;
    final roleIcon = isTeacher
        ? Icons.groups_outlined
        : (isParent ? Icons.family_restroom_outlined : Icons.school_outlined);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 380;

    final actions = isTeacher
        ? <(IconData, Color, Color, String, String)>[
            (Icons.groups_outlined, const Color(0xFFE2F7F0), const Color(0xFF149B78), 'View Your Students', 'See the students connected to your class'),
            (Icons.insights_outlined, const Color(0xFFE6F2FF), const Color(0xFF2682D8), 'Track Class Progress', 'Support each student’s growth'),
            (Icons.forum_outlined, const Color(0xFFF0E8FF), const Color(0xFF8151C8), 'Connect with Parents', 'Keep families involved in the journey'),
            (Icons.person_outline, const Color(0xFFFFF5D9), const Color(0xFFD19A00), 'Your Profile', 'Review your teacher account details'),
          ]
        : isParent
        ? <(IconData, Color, Color, String, String)>[
            (Icons.child_care_outlined, const Color(0xFFE2F7F0), const Color(0xFF149B78), 'Support Your Child', 'Find ways to encourage daily growth'),
            (Icons.insights_outlined, const Color(0xFFE6F2FF), const Color(0xFF2682D8), 'View Progress', 'Follow your child’s wellbeing journey'),
            (Icons.forum_outlined, const Color(0xFFF0E8FF), const Color(0xFF8151C8), 'Connect with Teacher', 'Stay in touch with the school'),
            (Icons.person_outline, const Color(0xFFFFF5D9), const Color(0xFFD19A00), 'Your Profile', 'Review your parent account details'),
          ]
        : <(IconData, Color, Color, String, String)>[
            (Icons.edit_note_rounded, const Color(0xFFE2F7F0), const Color(0xFF149B78), 'Write Your First Reflection', 'Share how you are feeling today'),
            (Icons.track_changes_rounded, const Color(0xFFE6F2FF), const Color(0xFF2682D8), 'Set Your First Goal', 'Take a small step toward a bigger you'),
            (Icons.groups_rounded, const Color(0xFFF0E8FF), const Color(0xFF8151C8), 'Connect with Teacher/Parent', 'Get support from people you trust'),
            (Icons.person_outline, const Color(0xFFFFF5D9), const Color(0xFFD19A00), 'Your Profile', 'Review your student account details'),
          ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFC),
      appBar: AppBar(
        title: const Text('MyEQ Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: isCompact ? 205 : 235,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 24,
                      width: isCompact ? 145 : 190,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              color: const Color(0xFF10234B),
                              fontSize: isCompact ? 21 : 25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.fullName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF149B78),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Signed in as a $roleName',
                            style: const TextStyle(
                              color: Color(0xFF627087),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: isCompact ? -8 : -12,
                      bottom: -12,
                      width: isCompact ? 155 : 205,
                      child: Image.asset(
                        'lib/assets/images/studentslogin3step1.png',
                        cacheWidth: 500,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFE2F7F0),
                            foregroundColor: const Color(0xFF149B78),
                            child: Icon(roleIcon),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '$roleName Account',
                              style: const TextStyle(
                                color: Color(0xFF10234B),
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (accountId != null && accountId.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Text(
                          '${isTeacher ? 'Teacher' : 'Student'} ID',
                          style: const TextStyle(
                            color: Color(0xFF627087),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          accountId,
                          style: const TextStyle(
                            color: Color(0xFF10234B),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                      if (result.username != null &&
                          result.username!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        const Text(
                          'Username',
                          style: TextStyle(
                            color: Color(0xFF627087),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          result.username!,
                          style: const TextStyle(
                            color: Color(0xFF10234B),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "What's Next?",
                style: TextStyle(
                  color: Color(0xFF10234B),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose a step to get started',
                style: TextStyle(color: Color(0xFF627087), fontSize: 13),
              ),
              const SizedBox(height: 12),
              for (final action in actions) ...[
                _DashboardActionTile(
                  icon: action.$1,
                  iconBg: action.$2,
                  iconColor: action.$3,
                  title: action.$4,
                  subtitle: action.$5,
                  onTap: () {
                    if (action.$4 == 'Your Profile') {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProfilePage(result: result),
                        ),
                      );
                      return;
                    }
                    if (!isTeacher && !isParent &&
                        action.$4 == 'Write Your First Reflection') {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => JournalPage(result: result),
                        ),
                      );
                      return;
                    }
                    _showActionInfo(context, action.$4, action.$5);
                  },
                ),
                const SizedBox(height: 8),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF8F4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC7EFE7)),
                ),
                child: Text(
                  isTeacher
                      ? 'Small moments of support can make a big difference.'
                      : 'Every small step counts. You are on your way to becoming a better you!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF2C3E5A),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showActionInfo(BuildContext context, String title, String subtitle) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF10234B),
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF627087),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This section will open here when its tools are connected.',
              style: TextStyle(color: Color(0xFF627087), fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DashboardActionTile extends StatelessWidget {
  const _DashboardActionTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF5)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: CircleAvatar(
          backgroundColor: iconBg,
          foregroundColor: iconColor,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF10234B),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF627087), fontSize: 11),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF8E909A),
          size: 22,
        ),
      ),
    );
  }
}

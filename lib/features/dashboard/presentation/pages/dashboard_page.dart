import 'package:flutter/material.dart';

import '../../../authentication/data/auth_api.dart';

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
              Text(
                'Welcome, ${result.fullName}',
                style: const TextStyle(
                  color: Color(0xFF10234B),
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You are signed in as a $roleName.',
                style: const TextStyle(
                  color: Color(0xFF627087),
                  fontSize: 15,
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
                    ],
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

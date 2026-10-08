import 'package:flutter/material.dart';

import '../../../authentication/data/auth_api.dart';

class TeacherStudentCompactRow extends StatelessWidget {
  const TeacherStudentCompactRow({
    super.key,
    required this.student,
    required this.overview,
    required this.onTap,
  });

  final GrowthConnectionData student;
  final TeacherStudentOverviewData? overview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle(overview?.latestProgress);
    final classLabel = [
      student.className,
      if (student.section?.isNotEmpty == true) student.section,
    ].whereType<String>().where((part) => part.isNotEmpty).join('-');
    final studentLabel = [
      if (classLabel.isNotEmpty) classLabel,
      if (student.accountId?.isNotEmpty == true) 'ID ${student.accountId}',
    ].join(' | ');

    return Card(
      margin: const EdgeInsets.only(bottom: 7),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE7EDF3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  student.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF203454),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 6,
                child: Text(
                  studentLabel.isEmpty ? '—' : studentLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF78859B),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Container(
                constraints: const BoxConstraints(maxWidth: 86),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  color: status.background,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  status.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: status.foreground,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFF9AA7B8),
              ),
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
    label: 'Needs Support',
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
    label: 'No update',
    foreground: const Color(0xFF79649C),
    background: const Color(0xFFF1EDFA),
  ),
};

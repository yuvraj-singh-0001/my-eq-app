import 'package:flutter/material.dart';

class TeacherFeedbackShortcutCard extends StatelessWidget {
  const TeacherFeedbackShortcutCard({
    super.key,
    required this.onTap,
    this.entryCount,
  });

  final VoidCallback onTap;
  final int? entryCount;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: const BorderSide(color: Color(0xFFE3EBF1)),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F7F2),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.rate_review_outlined,
                color: Color(0xFF149B78),
                size: 20,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Share student feedback',
                    style: TextStyle(
                      color: Color(0xFF203454),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entryCount == null
                        ? 'Open the student feedback page'
                        : '$entryCount feedback ${entryCount == 1 ? 'entry' : 'entries'} shared | Open feedback history',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF78859B),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8B98AA)),
          ],
        ),
      ),
    ),
  );
}

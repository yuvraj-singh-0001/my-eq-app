import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../authentication/data/auth_api.dart';
import '../../../authentication/presentation/pages/login_page.dart';

/// Opens the system SMS composer or dialer after an explicit teacher action.
/// Reflection wording and mood are never copied into the external message.
class TeacherStudentContact {
  const TeacherStudentContact._();

  static Future<void> message({
    required BuildContext context,
    required LoginResult result,
    required GrowthConnectionData student,
  }) async {
    final contact = await _loadContact(context, result, student);
    if (contact == null || !context.mounted) return;
    final phone = _normalizedPhone(contact.mobileNumber);
    if (phone == null) {
      _show(context, 'No student mobile number is available.');
      return;
    }

    JournalNotesPage notes;
    try {
      notes = await AuthApi.getTeacherStudentJournalNotes(
        token: result.token!,
        studentId: student.accountId!,
      );
    } on AuthApiException catch (error) {
      if (!context.mounted) return;
      _show(context, error.message);
      return;
    }
    if (!context.mounted) return;
    final controller = TextEditingController(
      text: _draft(student.fullName, notes.notes),
    );
    final approvedDraft = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Message ${student.fullName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              'Review and edit this supportive draft before opening Messages.',
              style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF5F8FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) Navigator.pop(sheetContext, text);
                },
                icon: const Icon(Icons.sms_outlined),
                label: const Text('Review in Messages'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF149B78),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (approvedDraft == null || !context.mounted) return;
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': approvedDraft},
    );
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          context.mounted) {
        _show(context, 'No messaging app is available on this device.');
      }
    } catch (_) {
      if (context.mounted) _show(context, 'Could not open the messaging app.');
    }
  }

  static Future<void> call({
    required BuildContext context,
    required LoginResult result,
    required GrowthConnectionData student,
  }) async {
    final contact = await _loadContact(context, result, student);
    if (contact == null || !context.mounted) return;
    final phone = _normalizedPhone(contact.mobileNumber);
    if (phone == null) {
      _show(context, 'No student mobile number is available.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Call ${student.fullName}?'),
        content: const Text(
          'Your phone app will open so you can review and place the call.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.call_outlined),
            label: const Text('Open phone'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      if (!await launchUrl(
            Uri(scheme: 'tel', path: phone),
            mode: LaunchMode.externalApplication,
          ) &&
          context.mounted) {
        _show(context, 'No phone app is available on this device.');
      }
    } catch (_) {
      if (context.mounted) _show(context, 'Could not open the phone app.');
    }
  }

  static Future<TeacherStudentContactData?> _loadContact(
    BuildContext context,
    LoginResult result,
    GrowthConnectionData student,
  ) async {
    final token = result.token;
    final studentId = student.accountId;
    if (token == null || token.isEmpty || studentId == null || studentId.isEmpty) {
      _show(context, 'Student contact is unavailable.');
      return null;
    }
    try {
      return await AuthApi.getTeacherStudentContact(
        token: token,
        studentId: studentId,
      );
    } on AuthApiException catch (error) {
      if (context.mounted) _show(context, error.message);
    } catch (_) {
      if (context.mounted) _show(context, 'Could not load student contact details.');
    }
    return null;
  }

  static String? _normalizedPhone(String? value) {
    if (value == null) return null;
    final phone = value.replaceAll(RegExp(r'[^0-9+]'), '');
    return phone.replaceAll('+', '').isEmpty ? null : phone;
  }

  static String _draft(String name, List<JournalNoteData> notes) {
    final names = name.trim().split(RegExp(r'\s+'));
    final firstName = names.isEmpty ? null : names.first;
    final greeting = firstName == null || firstName.isEmpty
        ? 'Hi'
        : 'Hi $firstName';
    final mood = notes.isEmpty ? '' : (notes.first.mood ?? '').toLowerCase();
    if (['sad', 'angry', 'stressed', 'nervous', 'worried', 'scared']
        .any(mood.contains)) {
      return '$greeting, I wanted to check in and see how you are doing today. '
          'No pressure to reply or share more than you want to. I am here if '
          'you would like to talk.';
    }
    if (['happy', 'excited', 'proud', 'calm', 'confident']
        .any(mood.contains)) {
      return '$greeting, thanks for sharing your reflection. I noticed the '
          'effort you put in. What part are you most proud of? I am cheering '
          'you on.';
    }
    return '$greeting, thanks for sharing your reflection. How are you feeling '
        'about things today? If you would like, we can talk through one small '
        'next step together.';
  }

  static void _show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

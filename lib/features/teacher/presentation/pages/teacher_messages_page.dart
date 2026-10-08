import 'package:flutter/material.dart';

import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../authentication/data/auth_api.dart';
import 'teacher_feedback_history_page.dart';
import '../widgets/teacher_feedback_shortcut_card.dart';

enum _CommunicationFilter { messages, calls }

class TeacherMessagesPage extends StatefulWidget {
  const TeacherMessagesPage({super.key, required this.result});

  final LoginResult result;

  static Future<void> open(BuildContext context, LoginResult result) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => TeacherMessagesPage(result: result),
        ),
      );

  @override
  State<TeacherMessagesPage> createState() => _TeacherMessagesPageState();
}

class _TeacherMessagesPageState extends State<TeacherMessagesPage> {
  List<TeacherCommunicationData> _entries = const [];
  _CommunicationFilter _filter = _CommunicationFilter.messages;
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
        _error = 'Sign in again to load communication history.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await AuthApi.getTeacherCommunications(token);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Communication history could not be loaded.';
        _loading = false;
      });
    }
  }

  List<TeacherCommunicationData> get _visibleEntries => _entries
      .where(
        (entry) =>
            entry.channel ==
            (_filter == _CommunicationFilter.messages ? 'whatsapp' : 'call'),
      )
      .toList(growable: false);

  void _onNavigation(int index) {
    if (index == 3) return;
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (index) {
            1 => 'Open Students from the Teacher dashboard.',
            2 => 'Open Insights from the Teacher dashboard.',
            _ => 'Open More from the Teacher dashboard.',
          }),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _visibleEntries;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F8FC),
        foregroundColor: const Color(0xFF203454),
        elevation: 0,
        title: const Text(
          'Messages & Calls',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh history',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TeacherFeedbackShortcutCard(
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        TeacherFeedbackHistoryPage(result: widget.result),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFE5ECF2)),
                ),
                child: Row(
                  children: [
                    _FilterTab(
                      label: 'Messages',
                      count: _entries
                          .where((entry) => entry.channel == 'whatsapp')
                          .length,
                      selected: _filter == _CommunicationFilter.messages,
                      onTap: () => setState(
                        () => _filter = _CommunicationFilter.messages,
                      ),
                    ),
                    _FilterTab(
                      label: 'Calls',
                      count: _entries
                          .where((entry) => entry.channel == 'call')
                          .length,
                      selected: _filter == _CommunicationFilter.calls,
                      onTap: () =>
                          setState(() => _filter = _CommunicationFilter.calls),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _loading && _entries.isEmpty
                    ? const _MessagesLoading()
                    : _error != null && _entries.isEmpty
                    ? _MessagesError(message: _error!, onRetry: _load)
                    : entries.isEmpty
                    ? _MessagesEmpty(
                        isCall: _filter == _CommunicationFilter.calls,
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 20),
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, index) =>
                            _CommunicationCard(entry: entries[index]),
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: 3,
        forTeacher: true,
        onDestinationSelected: _onNavigation,
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE5F6F0) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF117A61)
                      : const Color(0xFF66758B),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF117A61)
                      : const Color(0xFF8793A5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CommunicationCard extends StatelessWidget {
  const _CommunicationCard({required this.entry});

  final TeacherCommunicationData entry;

  @override
  Widget build(BuildContext context) {
    final isCall = entry.channel == 'call';
    final timestamp = entry.createdAt?.toLocal();
    final dateLabel = timestamp == null
        ? 'Date unavailable'
        : '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    final classLabel = [
      entry.className,
      if (entry.section?.isNotEmpty == true) entry.section,
    ].whereType<String>().where((value) => value.isNotEmpty).join('-');
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE5ECF2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isCall
                  ? const Color(0xFFEAF3FF)
                  : const Color(0xFFE7F7F2),
              child: Icon(
                isCall ? Icons.call_outlined : Icons.chat_outlined,
                color: isCall
                    ? const Color(0xFF287ACB)
                    : const Color(0xFF149B78),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.studentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF203454),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (classLabel.isNotEmpty) classLabel,
                      if (entry.studentId?.isNotEmpty == true)
                        'ID ${entry.studentId}',
                    ].join(' · '),
                    style: const TextStyle(
                      color: Color(0xFF7A879A),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _OutcomeBadge(completed: entry.completed),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          dateLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF8793A5),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutcomeBadge extends StatelessWidget {
  const _OutcomeBadge({required this.completed});
  final bool completed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: completed ? const Color(0xFFE7F7F2) : const Color(0xFFFFF2E0),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      completed ? 'Completed' : 'Not completed',
      style: TextStyle(
        color: completed ? const Color(0xFF117A61) : const Color(0xFF9A641F),
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _MessagesLoading extends StatelessWidget {
  const _MessagesLoading();

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: const [
      SizedBox(height: 180),
      Center(child: CircularProgressIndicator(color: Color(0xFF149B78))),
    ],
  );
}

class _MessagesError extends StatelessWidget {
  const _MessagesError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(20),
    children: [
      const SizedBox(height: 100),
      Icon(Icons.cloud_off_outlined, size: 38, color: Colors.blueGrey.shade300),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center),
      Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      ),
    ],
  );
}

class _MessagesEmpty extends StatelessWidget {
  const _MessagesEmpty({required this.isCall});
  final bool isCall;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 26),
    children: [
      const SizedBox(height: 100),
      Icon(
        isCall ? Icons.call_outlined : Icons.chat_bubble_outline_rounded,
        size: 42,
        color: const Color(0xFF8EA0B2),
      ),
      const SizedBox(height: 14),
      Text(
        isCall ? 'No calls recorded yet' : 'No messages recorded yet',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF203454),
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        isCall
            ? 'Confirmed call outcomes will appear here.'
            : 'Confirmed WhatsApp message outcomes will appear here.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF78859B), fontSize: 12),
      ),
    ],
  );
}

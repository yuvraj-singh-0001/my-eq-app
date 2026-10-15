import 'package:flutter/material.dart';

import '../../../authentication/data/auth_api.dart';
import '../../../dashboard/presentation/pages/profile_page.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../journal/presentation/pages/journal_page.dart';
import 'career_discovery_page.dart';

class StudentGrowthProfilePage extends StatefulWidget {
  const StudentGrowthProfilePage({super.key, required this.result});

  final LoginResult result;

  @override
  State<StudentGrowthProfilePage> createState() =>
      _StudentGrowthProfilePageState();
}

class _StudentGrowthProfilePageState extends State<StudentGrowthProfilePage> {
  List<JournalNoteData> _notes = const [];
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
        _error = 'Please sign in again to see your growth profile.';
      });
      return;
    }
    try {
      final page = await AuthApi.getJournalNotes(token);
      if (!mounted) return;
      setState(() {
        _notes = page.notes;
        _loading = false;
        _error = null;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  Map<String, int> get _moods {
    final counts = <String, int>{};
    for (final note in _notes) {
      final mood = note.mood;
      if (mood != null) counts[mood] = (counts[mood] ?? 0) + 1;
    }
    return counts;
  }

  List<String> get _topics {
    final counts = <String, int>{};
    for (final note in _notes) {
      counts[note.category] = (counts[note.category] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).map((entry) => entry.key).toList();
  }

  String get _message {
    if (_notes.isEmpty) {
      return 'Write a few reflections and this space will gently show what is helping you grow.';
    }
    final topMood = _moods.entries.isEmpty
        ? null
        : (_moods.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;
    if (topMood == 'Low' || topMood == 'Hard') {
      return 'Some recent check-ins feel heavy. You do not have to handle everything alone—talk to someone you trust.';
    }
    return 'You are building self-awareness by noticing your feelings and putting them into words.';
  }

  void _navigate(int index) {
    if (index == 2) return;
    if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => JournalPage(result: widget.result),
        ),
      );
    } else if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => CareerDiscoveryPage(result: widget.result),
        ),
      );
    } else if (index == 4) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProfilePage(result: widget.result),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFC),
      appBar: AppBar(title: const Text('My Growth Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _WelcomeCard(name: widget.result.fullName, message: _message),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'What I am exploring',
                    icon: Icons.explore_outlined,
                    child: _topics.isEmpty
                        ? const Text('Your topics will appear here as you reflect.')
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _topics
                                .map((topic) => Chip(label: Text(topic)))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'My check-in rhythm',
                    icon: Icons.calendar_today_outlined,
                    child: Text(
                      '${_notes.length} reflections saved. Keep going at your own pace.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'A kind reminder',
                    icon: Icons.favorite_outline,
                    child: const Text(
                      'This is a reflection snapshot, not a label or diagnosis. Your feelings can change, and your voice matters most.',
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: 2,
        onDestinationSelected: _navigate,
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.name, required this.message});
  final String name;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF1E376C),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome, color: Color(0xFF9DE4D0)),
        const SizedBox(height: 12),
        Text(
          'Hello, $name',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(color: Color(0xFFE6F5F1), height: 1.45),
        ),
      ],
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF149B78)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF203454),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

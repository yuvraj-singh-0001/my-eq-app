import 'package:flutter/material.dart';

import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../authentication/data/auth_api.dart';
import '../../../dashboard/presentation/pages/profile_page.dart';
import '../../../journal/presentation/pages/journal_page.dart';
import 'student_growth_profile_page.dart';

class CareerDiscoveryPage extends StatefulWidget {
  const CareerDiscoveryPage({super.key, required this.result});
  final LoginResult result;

  @override
  State<CareerDiscoveryPage> createState() => _CareerDiscoveryPageState();
}

class _CareerDiscoveryPageState extends State<CareerDiscoveryPage> {
  final _subjectController = TextEditingController();
  final _interestController = TextEditingController();
  final _strengthController = TextEditingController();
  String? _selectedFeeling;
  bool _saving = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _interestController.dispose();
    _strengthController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final subject = _subjectController.text.trim();
    final interest = _interestController.text.trim();
    final strength = _strengthController.text.trim();
    if (subject.isEmpty && interest.isEmpty && strength.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tell us one small thing first.')),
      );
      return;
    }
    final token = widget.result.token;
    if (token == null || token.isEmpty) return;
    setState(() => _saving = true);
    final lines = [
      'CAREER DISCOVERY',
      if (subject.isNotEmpty) 'SUBJECT I AM FIGURING OUT: $subject',
      if (_selectedFeeling != null) 'HOW IT FEELS: $_selectedFeeling',
      if (interest.isNotEmpty) 'WHAT I ENJOY: $interest',
      if (strength.isNotEmpty) 'WHAT I FEEL I CAN DO: $strength',
    ];
    try {
      await AuthApi.createJournalNote(
        token: token,
        category: 'Career Discovery',
        text: lines.join('\n'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved. Your support team can understand you better now.')),
      );
      _subjectController.clear();
      _interestController.clear();
      _strengthController.clear();
      setState(() => _selectedFeeling = null);
    } on AuthApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _navigate(int index) {
    if (index == 3) return;
    final page = switch (index) {
      1 => JournalPage(result: widget.result),
      2 => StudentGrowthProfilePage(result: widget.result),
      4 => ProfilePage(result: widget.result),
      _ => null,
    };
    if (page != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => page),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FBFC),
    appBar: AppBar(title: const Text('Career Discovery')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Let’s figure it out together',
          style: TextStyle(
            color: Color(0xFF203454),
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'No marks, no right answer and no pressure. Just tell us what feels easy, interesting or difficult.',
          style: TextStyle(color: Color(0xFF687791), height: 1.45),
        ),
        const SizedBox(height: 20),
        _QuestionCard(
          icon: Icons.menu_book_outlined,
          title: 'Which subject feels a little difficult today?',
          hint: 'For example: Maths word problems, reading, science experiments…',
          controller: _subjectController,
        ),
        _QuestionCard(
          icon: Icons.lightbulb_outline,
          title: 'What do you enjoy doing?',
          hint: 'Making things, helping people, drawing, sports, computers…',
          controller: _interestController,
        ),
        _QuestionCard(
          icon: Icons.emoji_events_outlined,
          title: 'What feels like one of your strengths?',
          hint: 'Listening, explaining, trying again, imagining, leading…',
          controller: _strengthController,
        ),
        const SizedBox(height: 6),
        const Text(
          'When you face that subject, how does it feel?',
          style: TextStyle(
            color: Color(0xFF203454),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['Curious', 'Confused', 'Worried', 'Ready to try']
              .map(
                (value) => ChoiceChip(
                  label: Text(value),
                  selected: _selectedFeeling == value,
                  onSelected: (_) => setState(() => _selectedFeeling = value),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.favorite_border),
          label: const Text('Save this thought'),
        ),
      ],
    ),
    bottomNavigationBar: AppBottomNav(
      selectedIndex: 3,
      onDestinationSelected: _navigate,
    ),
  );
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.icon,
    required this.title,
    required this.hint,
    required this.controller,
  });
  final IconData icon;
  final String title;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF149B78)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF203454),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF7FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

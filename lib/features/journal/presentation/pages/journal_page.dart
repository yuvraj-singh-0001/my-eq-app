import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../authentication/data/auth_api.dart';
import 'reflection_editor_page.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key, required this.result});

  final LoginResult result;

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final _noteController = TextEditingController();
  final _categories = const <_JournalCategory>[
    _JournalCategory('Self-Regulation', Icons.psychology_alt_rounded, Color(0xFF149B78), Color(0xFFEAF8F4)),
    _JournalCategory('Empathy', Icons.volunteer_activism_rounded, Color(0xFFEF4B5B), Color(0xFFFFF0F2)),
    _JournalCategory('Social Skills', Icons.groups_rounded, Color(0xFF1689E8), Color(0xFFEEF7FF)),
    _JournalCategory('Self-Awareness', Icons.person_rounded, Color(0xFF8C4DDA), Color(0xFFF5F0FF)),
    _JournalCategory('Relationships', Icons.people_alt_rounded, Color(0xFFF1A000), Color(0xFFFFF8E9)),
    _JournalCategory('Exam Fears', Icons.menu_book_rounded, Color(0xFFEF4B5B), Color(0xFFFFF0F2)),
    _JournalCategory('Someone Misbehaves', Icons.sentiment_dissatisfied_rounded, Color(0xFFEF4B5B), Color(0xFFFFF0F2)),
    _JournalCategory('Bad Habits', Icons.do_not_disturb_on_rounded, Color(0xFF1689E8), Color(0xFFEEF7FF)),
    _JournalCategory('Sports', Icons.directions_run_rounded, Color(0xFF149B78), Color(0xFFEAF8F4)),
    _JournalCategory('School', Icons.school_rounded, Color(0xFF8C4DDA), Color(0xFFF5F0FF)),
    _JournalCategory('Presentation', Icons.co_present_rounded, Color(0xFF1689E8), Color(0xFFEEF7FF)),
    _JournalCategory('Competition', Icons.emoji_events_rounded, Color(0xFFF1A000), Color(0xFFFFF8E9)),
    _JournalCategory('Family', Icons.family_restroom_rounded, Color(0xFFEF4B5B), Color(0xFFFFF0F2)),
    _JournalCategory('Friends', Icons.diversity_3_rounded, Color(0xFF1689E8), Color(0xFFEEF7FF)),
    _JournalCategory('Screen Time', Icons.laptop_chromebook_rounded, Color(0xFF1689E8), Color(0xFFEEF7FF)),
    _JournalCategory('Other', Icons.more_horiz_rounded, Color(0xFF65728E), Color(0xFFF3F5F8)),
  ];

  final List<JournalNoteData> _notes = [];
  String? _selectedCategory;
  String? _selectedMood;
  bool _isLoadingNotes = true;
  String? _notesError;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final token = widget.result.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoadingNotes = false;
        _notesError = 'Please sign in again to load your notes.';
      });
      return;
    }
    if (mounted) {
      setState(() {
        _isLoadingNotes = true;
        _notesError = null;
      });
    }
    try {
      final notes = await AuthApi.getJournalNotes(token);
      if (!mounted) return;
      setState(() {
        _notes
          ..clear()
          ..addAll(notes);
        _isLoadingNotes = false;
        _notesError = null;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingNotes = false;
        _notesError = error.message;
      });
    }
  }

  Future<void> _goToNext() async {
    final token = widget.result.token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again before creating a note.')),
      );
      return;
    }
    final note = await Navigator.of(context).push<JournalNoteData>(
      MaterialPageRoute<JournalNoteData>(
        builder: (_) => ReflectionEditorPage(
          token: token,
          category: _selectedCategory ?? 'Reflection',
          mood: _selectedMood,
          initialText: _noteController.text.trim(),
        ),
      ),
    );
    if (!mounted || note == null) return;
    setState(() {
      _notes.insert(0, note);
      _noteController.clear();
      _selectedCategory = null;
      _selectedMood = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your private note was saved.')),
    );
  }

  void _onNavigation(int index) {
    if (index == 1) return;
    final label = const ['Home', 'Journal', 'Progress', 'Goals', 'Profile'][index];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label will be available here soon.')),
    );
  }

  void _showAllNotes() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.75,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: _notes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _NoteCard(
              note: _notes[index],
              category: _categoryFor(_notes[index].category),
            ),
          ),
        ),
      ),
    );
  }

  _JournalCategory? _categoryFor(String name) {
    for (final category in _categories) {
      if (category.name == name) return category;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 360 ? 16.0 : 24.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _loadNotes,
            child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 0),
                sliver: SliverToBoxAdapter(child: _buildTopBar(context)),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 0),
                sliver: SliverToBoxAdapter(child: _buildHero(width, context)),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 18, horizontalPadding, 0),
                sliver: SliverToBoxAdapter(child: _buildTitleAndPrivacy()),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 9, horizontalPadding, 0),
                sliver: SliverToBoxAdapter(child: _buildPrivacyMode()),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 0),
                sliver: SliverToBoxAdapter(child: _buildCategoryGrid(width)),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 0),
                sliver: SliverToBoxAdapter(child: _buildFreeWrite()),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 0),
                sliver: SliverToBoxAdapter(child: _buildNextButton()),
              ),
              if (_notes.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 18, horizontalPadding, 16),
                  sliver: SliverToBoxAdapter(child: _buildRecentNotes()),
                )
              else if (_notesError != null)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 18, horizontalPadding, 16),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      '$_notesError  Pull down to try again.',
                      style: const TextStyle(color: Color(0xFF8290A7), fontSize: 12),
                    ),
                  ),
                )
              else if (_isLoadingNotes)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                )
              else
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
            ),
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          selectedIndex: 1,
          onDestinationSelected: _onNavigation,
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final studentId = widget.result.studentId?.trim();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, ${widget.result.fullName.trim()} 👋',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF10234B), fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              if (studentId != null && studentId.isNotEmpty)
                Text(
                  'ID: $studentId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF8290A7), fontSize: 11, height: 1.25),
                ),
            ],
          ),
        ),
        _RoundAction(icon: Icons.search_rounded, label: 'Search', onTap: () => _showSearch(context)),
        const SizedBox(width: 8),
        _RoundAction(icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: () {}),
      ],
    );
  }

  Widget _buildHero(double width, BuildContext context) {
    final horizontalInset = width < 360 ? 32.0 : 48.0;
    final bannerWidth = width - horizontalInset;
    final height = (bannerWidth / 2.54).clamp(112.0, 190.0).toDouble();
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: const Color(0xFFDFF6F0), borderRadius: BorderRadius.circular(24)),
      child: Image.asset(
        'lib/assets/images/Firstnotewrite.png',
        fit: BoxFit.contain,
        semanticLabel: 'It is okay to feel, to share, and to grow. Your thoughts matter.',
      ),
    );
  }

  Widget _buildTitleAndPrivacy() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: const Color(0xFF12A483), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 25),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Create a New Note', style: TextStyle(color: Color(0xFF10234B), fontSize: 15, fontWeight: FontWeight.w800)),
            Text('Choose a topic to get started', style: TextStyle(color: Color(0xFF72809B), fontSize: 10.5)),
          ]),
        ),
      ],
    );
  }

  Widget _buildPrivacyMode() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6F0E8)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: Color(0xFF148F73), size: 17),
          SizedBox(width: 8),
          Text(
            'Private Mode',
            style: TextStyle(color: Color(0xFF167F6C), fontSize: 11, fontWeight: FontWeight.w700),
          ),
          Expanded(
            child: Text(
              'Only you can see your notes',
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Color(0xFF728B86), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(double width) {
    final columns = width < 350 ? 3 : 4;
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
            childAspectRatio: width < 350 ? 1.12 : 1.22,
          ),
          itemBuilder: (context, index) {
            final item = _categories[index];
            final selected = _selectedCategory == item.name;
            return Semantics(
              button: true,
              selected: selected,
              label: item.name,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(17),
                child: InkWell(
                  onTap: () => setState(() => _selectedCategory = selected ? null : item.name),
                  borderRadius: BorderRadius.circular(17),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: selected ? item.color.withAlpha(30) : item.background,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: selected ? item.color.withAlpha(170) : Colors.transparent,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selected
                              ? item.color.withAlpha(35)
                              : const Color(0x10203454),
                          blurRadius: selected ? 9 : 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: selected ? 1.08 : 1,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          child: Icon(item.icon, size: 23, color: item.color),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF203454),
                            fontSize: 9.5,
                            height: 1.08,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Row(children: [
          const Icon(Icons.chat_bubble_rounded, size: 24, color: Color(0xFF118F7A)),
          const SizedBox(width: 9),
          const Text('Or tell me freely…', style: TextStyle(color: Color(0xFF10234B), fontSize: 18, fontWeight: FontWeight.w800)),
          const Spacer(),
          _MoodPicker(value: _selectedMood, onChanged: (mood) => setState(() => _selectedMood = mood)),
        ]),
      ],
    );
  }

  Widget _buildFreeWrite() {
    return TextField(
      controller: _noteController,
      minLines: 2,
      maxLines: 3,
      onChanged: (_) => setState(() {}),
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: 'Write anything on your mind…',
        hintStyle: const TextStyle(color: Color(0xFF8994AA), fontSize: 12, height: 1.35),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 12, right: 8, top: 10),
          child: Icon(Icons.edit_outlined, color: Color(0xFF72809B), size: 23),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFFDCE5F1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFFDCE5F1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFF18A77F), width: 1.4),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final hasDraft = _selectedCategory != null || _noteController.text.trim().isNotEmpty;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: hasDraft
          ? SizedBox(
              key: const ValueKey('next-button'),
              height: 44,
              child: FilledButton(
                onPressed: _goToNext,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF13A483),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Next'),
                    SizedBox(width: 7),
                    Icon(Icons.arrow_forward_rounded, size: 17),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(key: ValueKey('next-button-hidden')),
    );
  }

  Widget _buildRecentNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF12A483), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.library_books_outlined, color: Colors.white)),
          const SizedBox(width: 10),
          const Expanded(child: Text('Recent Notes', style: TextStyle(color: Color(0xFF10234B), fontSize: 18, fontWeight: FontWeight.w800))),
          TextButton(
            onPressed: _showAllNotes,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('View All'),
                SizedBox(width: 3),
                Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 8),
        for (final note in _notes.take(2)) ...[
          _NoteCard(note: note, category: _categoryFor(note.category)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  void _showSearch(BuildContext context) {
    showSearch<void>(context: context, delegate: _JournalSearchDelegate(_notes));
  }
}

class _JournalCategory {
  const _JournalCategory(this.name, this.icon, this.color, this.background);
  final String name;
  final IconData icon;
  final Color color;
  final Color background;
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: label,
    onPressed: onTap,
    style: IconButton.styleFrom(backgroundColor: const Color(0xFFF0F4FA), foregroundColor: const Color(0xFF203454), fixedSize: const Size(46, 46)),
    icon: Icon(icon, size: 23),
  );
}

class _MoodPicker extends StatelessWidget {
  const _MoodPicker({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  static const moods = <(String, String)>[
    ('Great', '😊'), ('Good', '🙂'), ('Okay', '😐'), ('Low', '😔'), ('Hard', '😟'),
  ];

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Choose how you feel',
    onSelected: onChanged,
    itemBuilder: (context) => [for (final mood in moods) PopupMenuItem(value: mood.$1, child: Text('${mood.$2}  ${mood.$1}'))],
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: const Color(0xFFF0F4FA), borderRadius: BorderRadius.circular(22)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Text(value == null ? '🙂' : moods.firstWhere((mood) => mood.$1 == value).$2, style: const TextStyle(fontSize: 18)), const SizedBox(width: 4), const Icon(Icons.keyboard_arrow_down_rounded, size: 17, color: Color(0xFF65728E))]),
    ),
  );
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.category});
  final JournalNoteData note;
  final _JournalCategory? category;

  @override
  Widget build(BuildContext context) {
    final localDate = note.createdAt.toLocal();
    final date = '${localDate.day} ${_month(localDate.month)}';
    final color = category?.color ?? const Color(0xFF149B78);
    final background = category?.background ?? const Color(0xFFEAF8F4);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x080B2B4B), blurRadius: 12, offset: Offset(0, 3))]),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 54, height: 58, decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(13)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('${localDate.day}', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)), Text(_month(localDate.month), style: TextStyle(color: color, fontSize: 11))])),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(category?.icon ?? Icons.edit_note_rounded, color: color, size: 19), const SizedBox(width: 6), Expanded(child: Text(note.category, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF203454), fontWeight: FontWeight.w700, fontSize: 13))), if (note.mood != null) Text(note.mood!, style: const TextStyle(color: Color(0xFF60718D), fontSize: 11))]),
          const SizedBox(height: 5),
          Text(note.text, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF75839D), fontSize: 12, height: 1.35)),
          const SizedBox(height: 4),
          Text(date, style: const TextStyle(color: Color(0xFF9AA4B5), fontSize: 10)),
        ])),
      ]),
    );
  }
}

String _month(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];

class _JournalSearchDelegate extends SearchDelegate<void> {
  _JournalSearchDelegate(this.notes);

  final List<JournalNoteData> notes;
  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(onPressed: () => close(context, null), icon: const Icon(Icons.arrow_back));
  @override
  Widget buildResults(BuildContext context) {
    final matches = notes.where((note) => '${note.category} ${note.text}'.toLowerCase().contains(query.toLowerCase())).toList();
    if (matches.isEmpty) return const Center(child: Text('No matching reflections yet.'));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(matches[index].category),
        subtitle: Text(matches[index].text, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
  @override
  Widget buildSuggestions(BuildContext context) => const SizedBox.shrink();
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../authentication/data/auth_api.dart';

class JournalNoteDetailPage extends StatefulWidget {
  const JournalNoteDetailPage({
    super.key,
    required this.token,
    required this.initialNote,
  });

  final String token;
  final JournalNoteData initialNote;

  @override
  State<JournalNoteDetailPage> createState() => _JournalNoteDetailPageState();
}

class _JournalNoteDetailPageState extends State<JournalNoteDetailPage> {
  late JournalNoteData _note = widget.initialNote;
  List<JournalNoteViewerData> _viewers = const [];
  int _viewCount = 0;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final detail = await AuthApi.getJournalNoteDetail(
        token: widget.token,
        noteId: widget.initialNote.id,
      );
      if (!mounted) return;
      setState(() {
        _note = detail.note;
        _viewCount = detail.viewCount;
        _viewers = detail.viewers;
        _loading = false;
        _error = null;
      });
    } on AuthApiException catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.message;
        });
      }
    } finally {
      _refreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final date = _indiaTime(_note.createdAt);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F8FB),
        foregroundColor: const Color(0xFF203454),
        elevation: 0,
        title: const Text('Your Reflection', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Refresh views',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: EdgeInsets.fromLTRB(width < 380 ? 16 : 22, 8, width < 380 ? 16 : 22, 28),
            children: [
              _NoteSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.edit_note_rounded, color: Color(0xFF119B7A)),
                      const SizedBox(width: 9),
                      Expanded(child: Text(_note.category, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF203454)))),
                      if (_note.mood?.isNotEmpty == true) _Tag(_note.mood!, icon: Icons.mood_rounded),
                    ]),
                    const SizedBox(height: 7),
                    Text(_dateLabel(date), style: const TextStyle(color: Color(0xFF77859C), fontSize: 12)),
                    const SizedBox(height: 18),
                    if (_note.sections.isNotEmpty)
                      for (final section in _note.sections) _ReflectionSection(section: section)
                    else
                      _LegacyReflection(text: _note.text),
                    if (_note.customText.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const _SectionHeading('In my own words'),
                      const SizedBox(height: 6),
                      Text(_note.customText.trim(), style: _bodyStyle),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _NoteSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.visibility_outlined, color: Color(0xFF119B7A)),
                      const SizedBox(width: 9),
                      Expanded(child: Text('Seen by $_viewCount ${_viewCount == 1 ? 'person' : 'people'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF203454)))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0xFFE7F7F2), borderRadius: BorderRadius.circular(30)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.circle, size: 7, color: Color(0xFF13A37F)), SizedBox(width: 5), Text('LIVE', style: TextStyle(color: Color(0xFF118568), fontSize: 10, fontWeight: FontWeight.w800))]),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    const Text('People connected to you who have opened this reflection.', style: TextStyle(color: Color(0xFF78859B), fontSize: 12)),
                    const SizedBox(height: 12),
                    if (_loading && _viewers.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(14), child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))))
                    else if (_viewers.isEmpty)
                      const _EmptyViewers()
                    else
                      for (final viewer in _viewers)
                        _ViewerRow(viewer: viewer),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Color(0xFFB44B52), fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _bodyStyle = TextStyle(color: Color(0xFF35445D), fontSize: 15, height: 1.55);

class _NoteSurface extends StatelessWidget {
  const _NoteSurface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE5ECF2)), boxShadow: const [BoxShadow(color: Color(0x080B2B4B), blurRadius: 15, offset: Offset(0, 4))]),
    child: child,
  );
}

class _ReflectionSection extends StatelessWidget {
  const _ReflectionSection({required this.section});
  final Map<String, dynamic> section;
  @override
  Widget build(BuildContext context) {
    final title = section['subcategory'] as String? ?? 'Reflection';
    final selected = (section['selectedStatements'] as List<dynamic>? ?? const []).whereType<String>().toList();
    final feelings = (section['feelings'] as List<dynamic>? ?? const []).whereType<String>().toList();
    final ownWords = section['customText'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHeading(title),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final item in selected) Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('•  ', style: TextStyle(color: Color(0xFF149B78), fontSize: 16, fontWeight: FontWeight.bold)), Expanded(child: Text(item, style: _bodyStyle))])),
        ],
        if (feelings.isNotEmpty) ...[
          const SizedBox(height: 8),
          const _SectionHeading('How it feels'),
          const SizedBox(height: 6),
          Wrap(spacing: 7, runSpacing: 7, children: [for (final feeling in feelings) _Tag(feeling, icon: Icons.favorite_border_rounded)]),
        ],
        if (ownWords.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          const _SectionHeading('In my own words'),
          const SizedBox(height: 5),
          Text(ownWords.trim(), style: _bodyStyle),
        ],
      ]),
    );
  }
}

class _LegacyReflection extends StatelessWidget {
  const _LegacyReflection({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.trim(), style: _bodyStyle);
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(label, style: const TextStyle(color: Color(0xFF203454), fontSize: 14, fontWeight: FontWeight.w800));
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, {required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFEAF7F3), borderRadius: BorderRadius.circular(30)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: const Color(0xFF149B78)), const SizedBox(width: 4), Text(label, style: const TextStyle(color: Color(0xFF16876E), fontSize: 11, fontWeight: FontWeight.w700))]));
}

class _ViewerRow extends StatelessWidget {
  const _ViewerRow({required this.viewer});
  final JournalNoteViewerData viewer;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: const Color(0xFFE7F7F2),
          child: Text(
            viewer.fullName.trim().isEmpty
                ? '?'
                : viewer.fullName.trim()[0].toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF118568),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                viewer.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF203454),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                [
                  if (viewer.role.isNotEmpty) _titleCase(viewer.role),
                  if (viewer.accountId.isNotEmpty) viewer.accountId,
                ].join(' · '),
                style: const TextStyle(
                  color: Color(0xFF8490A3),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Text(
          viewer.lastViewedAt == null
              ? 'Viewed'
              : _dateLabel(_indiaTime(viewer.lastViewedAt!)),
          textAlign: TextAlign.end,
          style: const TextStyle(color: Color(0xFF8490A3), fontSize: 10),
        ),
      ],
    ),
  );
}

class _EmptyViewers extends StatelessWidget {
  const _EmptyViewers();
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF6F9FB), borderRadius: BorderRadius.circular(15)), child: const Text('No one has opened this reflection yet.', style: TextStyle(color: Color(0xFF78859B), fontSize: 13)));
}

String _dateLabel(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  return '${date.day} ${months[date.month - 1]} ${date.year} · $hour:${date.minute.toString().padLeft(2, '0')} ${date.hour < 12 ? 'AM' : 'PM'}';
}

DateTime _indiaTime(DateTime date) =>
    date.toUtc().add(const Duration(hours: 5, minutes: 30));

String _titleCase(String value) => value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

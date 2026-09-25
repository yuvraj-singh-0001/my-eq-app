import 'package:flutter/material.dart';

import '../../../authentication/data/auth_api.dart';

class ReflectionEditorPage extends StatefulWidget {
  const ReflectionEditorPage({
    super.key,
    required this.token,
    required this.category,
    required this.initialText,
    this.mood,
  });

  final String token;
  final String category;
  final String initialText;
  final String? mood;

  @override
  State<ReflectionEditorPage> createState() => _ReflectionEditorPageState();
}

class _ReflectionEditorPageState extends State<ReflectionEditorPage> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final note = await AuthApi.createJournalNote(
        token: widget.token,
        category: widget.category,
        text: text,
        mood: widget.mood,
      );
      if (mounted) Navigator.of(context).pop(note);
    } on AuthApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        title: const Text('Your Reflection'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, color: Color(0xFF148F73), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.category}  ·  Private',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF167F6C),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (widget.mood != null) Text(widget.mood!),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: widget.initialText.isEmpty,
                  minLines: null,
                  maxLines: null,
                  expands: true,
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 5000,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'Write what is on your mind…',
                    filled: true,
                    fillColor: Colors.white,
                    alignLabelWithHint: true,
                    contentPadding: const EdgeInsets.all(18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFFDCE5F1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFFDCE5F1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFF18A77F), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isSaving || _controller.text.trim().isEmpty
                      ? null
                      : _save,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_isSaving ? 'Saving…' : 'Save note'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF13A483),
                    disabledBackgroundColor: const Color(0xFFE1E7EE),
                    disabledForegroundColor: const Color(0xFF8A96A8),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
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

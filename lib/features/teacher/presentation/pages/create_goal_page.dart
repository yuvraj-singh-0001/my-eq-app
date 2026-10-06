import 'package:flutter/material.dart';

import '../../../authentication/data/auth_api.dart';
import '../../../authentication/data/auth_session.dart';
import '../../../authentication/presentation/pages/login_page.dart';

class CreateGoalPage extends StatefulWidget {
  const CreateGoalPage({
    super.key,
    required this.token,
    required this.studentId,
  });
  final String token;
  final String studentId;

  @override
  State<CreateGoalPage> createState() => _CreateGoalPageState();
}

class _CreateGoalPageState extends State<CreateGoalPage> {
  static const _categories = [
    'Confidence',
    'Self-Regulation',
    'Communication',
    'Social Skills',
    'Sports',
    'Study Habits',
    'Public Speaking',
    'Participation',
    'Other',
  ];
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _currentController = TextEditingController();
  final _targetController = TextEditingController();
  final _noteController = TextEditingController();
  String _category = _categories.first;
  DateTime _startDate = DateTime.now();
  DateTime? _reviewDate;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _currentController.dispose();
    _targetController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool review}) async {
    final initial = review
        ? (_reviewDate ?? _startDate.add(const Duration(days: 30)))
        : _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: review ? _startDate : DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme
              .copyWith(primary: const Color(0xFF149B78)),
        ),
        child: child!,
      ),
    );
    if (!mounted || picked == null) return;
    setState(() {
      if (review) {
        _reviewDate = picked;
      } else {
        _startDate = picked;
        if (_reviewDate != null && _reviewDate!.isBefore(picked)) {
          _reviewDate = null;
        }
      }
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final currentText = _currentController.text.trim();
    final targetText = _targetController.text.trim();
    if (currentText.isNotEmpty != targetText.isNotEmpty) {
      setState(
        () =>
            _error = 'Add both current and target values, or leave both blank.',
      );
      return;
    }
    if (currentText.isNotEmpty &&
        num.parse(currentText) > num.parse(targetText)) {
      setState(
        () => _error = 'Current value cannot be greater than the target.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final goal = await AuthApi.createTeacherStudentGoal(
        token: widget.token,
        studentId: widget.studentId,
        title: _titleController.text,
        category: _category,
        description: _descriptionController.text,
        teacherNote: _noteController.text,
        startDate: _startDate,
        reviewDate: _reviewDate,
        currentValue: currentText.isEmpty ? null : num.parse(currentText),
        targetValue: targetText.isEmpty ? null : num.parse(targetText),
      );
      if (mounted) Navigator.of(context).pop(goal.id.isNotEmpty);
    } on AuthApiException catch (error) {
      if (error.statusCode == 401) {
        await AuthSession.clear();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil<void>(
          MaterialPageRoute<void>(
            builder: (_) => const LoginPage(initialRole: 1),
          ),
          (_) => false,
        );
        return;
      }
      if (mounted) {
        setState(() {
          _error = error.message.isEmpty
              ? 'Could not create this goal.'
              : error.message;
          _saving = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not create this goal. Please try again.';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F8FC),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF5F8FC),
      foregroundColor: const Color(0xFF203454),
      title: const Text(
        'Create Goal',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _GoalFormSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Goal title'),
                  TextFormField(
                    controller: _titleController,
                    maxLength: 120,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _inputDecoration(
                      'e.g. Speak confidently in class',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a goal title.'
                        : null,
                  ),
                  const SizedBox(height: 15),
                  _FieldLabel('Category'),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: _inputDecoration('Select category'),
                    items: [
                      for (final category in _categories)
                        DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _category = value);
                            }
                          },
                  ),
                  const SizedBox(height: 15),
                  _FieldLabel('Description'),
                  TextFormField(
                    controller: _descriptionController,
                    maxLength: 1000,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _inputDecoration(
                      'What would you like the student to work on?',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _GoalFormSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progress target (optional)',
                    style: TextStyle(
                      color: Color(0xFF203454),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Leave blank to track progress as a percentage.',
                    style: TextStyle(color: Color(0xFF78859B), fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _currentController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _inputDecoration('Current value'),
                          validator: _validateNumber,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '/',
                          style: TextStyle(
                            color: Color(0xFF78859B),
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _targetController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _inputDecoration('Target value'),
                          validator: (value) {
                            final error = _validateNumber(value);
                            final parsed = num.tryParse(value?.trim() ?? '');
                            return error ??
                                (value?.trim().isNotEmpty == true && parsed == 0
                                    ? 'Target must be greater than zero.'
                                    : null);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _GoalFormSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dates',
                    style: TextStyle(
                      color: Color(0xFF203454),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DateButton(
                    label: 'Start date',
                    value: _formatDate(_startDate),
                    onTap: _saving ? null : () => _pickDate(review: false),
                  ),
                  const SizedBox(height: 8),
                  _DateButton(
                    label: 'Review date',
                    value: _reviewDate == null
                        ? 'Add date'
                        : _formatDate(_reviewDate!),
                    onTap: _saving ? null : () => _pickDate(review: true),
                    onClear: _reviewDate == null
                        ? null
                        : () => setState(() => _reviewDate = null),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _GoalFormSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Teacher note (optional)'),
                  TextFormField(
                    controller: _noteController,
                    maxLength: 1000,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _inputDecoration('Why is this goal important?'),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _ErrorNotice(message: _error!),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 49,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF149B78),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Goal',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = num.tryParse(value.trim());
    if (parsed == null || !parsed.isFinite || parsed < 0) {
      return 'Enter a valid positive number.';
    }
    return null;
  }
}

class _GoalFormSection extends StatelessWidget {
  const _GoalFormSection({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE5ECF2)),
    ),
    child: child,
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFF203454),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });
  final String label;
  final String value;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5ECF2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 17,
            color: Color(0xFF149B78),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF65748A), fontSize: 12),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF203454),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onClear != null)
            IconButton(
              onPressed: onClear,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.close_rounded, size: 17),
            ),
        ],
      ),
    ),
  );
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0EB),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      message,
      style: const TextStyle(color: Color(0xFFAB4F3A), fontSize: 12),
    ),
  );
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFFA0AABB), fontSize: 12),
  filled: true,
  fillColor: const Color(0xFFF9FAFC),
  counterText: '',
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFE3E9F0)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFE3E9F0)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFF149B78)),
  ),
);
String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../authentication/data/auth_api.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({
    super.key,
    required this.token,
    required this.profile,
  });

  final String token;
  final UserProfileData profile;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _mobile;
  late final TextEditingController _username;
  late final TextEditingController _school;
  late final TextEditingController _fatherName;
  late final TextEditingController _fatherEmail;
  late final TextEditingController _fatherMobile;
  late final TextEditingController _motherName;
  late final TextEditingController _motherEmail;
  late final TextEditingController _motherMobile;
  String? _className;
  String? _section;
  String? _gender;
  String? _subject;
  bool _isSaving = false;

  bool get _isStudent => widget.profile.role == 'student';
  bool get _isTeacher => widget.profile.role == 'teacher';

  static const _classes = [
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
  ];
  static const _sections = ['A', 'B', 'C', 'D'];
  static const _genders = ['Male', 'Female', 'Other'];
  static const _subjects = [
    'Mathematics', 'Science', 'English', 'Hindi', 'Social Science',
    'Computer Science', 'Physics', 'Chemistry', 'Biology', 'History',
    'Geography', 'Physical Education',
  ];

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _name = TextEditingController(text: profile.fullName);
    _email = TextEditingController(text: profile.email ?? '');
    _mobile = TextEditingController(text: profile.mobileNumber ?? '');
    _username = TextEditingController(text: profile.username ?? '');
    _school = TextEditingController(text: profile.schoolName ?? '');
    _fatherName = TextEditingController(text: profile.fatherName ?? '');
    _fatherEmail = TextEditingController(text: profile.fatherEmail ?? '');
    _fatherMobile = TextEditingController(
      text: profile.fatherMobileNumber ?? '',
    );
    _motherName = TextEditingController(text: profile.motherName ?? '');
    _motherEmail = TextEditingController(text: profile.motherEmail ?? '');
    _motherMobile = TextEditingController(
      text: profile.motherMobileNumber ?? '',
    );
    _className = profile.className;
    _section = profile.section;
    _gender = profile.gender;
    _subject = profile.teachingSubject;
  }

  @override
  void dispose() {
    for (final controller in [
      _name, _email, _mobile, _username, _school,
      _fatherName, _fatherEmail, _fatherMobile,
      _motherName, _motherEmail, _motherMobile,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  String? _emailValidator(String? value, {required bool requiredField}) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return requiredField ? 'Email is required' : null;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
        ? null
        : 'Enter a valid email address';
  }

  String? _mobileValidator(String? value, {required bool requiredField}) {
    final mobile = value?.trim() ?? '';
    if (mobile.isEmpty) return requiredField ? 'Mobile number is required' : null;
    if (!RegExp(r'^\d{10}$').hasMatch(mobile)) {
      return 'Enter exactly 10 digits';
    }
    return null;
  }

  String? _usernameValidator(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty) return 'Username is required';
    if (username.length < 3 || username.length > 40) {
      return 'Username must be 3 to 40 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(username)) {
      return 'Use letters, numbers, dot, underscore, or hyphen';
    }
    return null;
  }

  String? _maxLength(String? value, int max, String label) =>
      (value?.trim().length ?? 0) > max ? '$label must be $max characters or less' : null;

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isSaving = true);
    try {
      final updated = await AuthApi.updateProfile(
        token: widget.token,
        profile: {
          'fullName': _name.text.trim(),
          'email': _email.text.trim(),
          'mobileNumber': _mobile.text.trim(),
          'username': _username.text.trim(),
          'className': _className,
          'section': _section,
          'gender': _gender,
          'schoolName': _school.text.trim(),
          'teachingSubject': _subject,
          'father': {
            'name': _fatherName.text.trim(),
            'email': _fatherEmail.text.trim(),
            'mobileNumber': _fatherMobile.text.trim(),
          },
          'mother': {
            'name': _motherName.text.trim(),
            'email': _motherEmail.text.trim(),
            'mobileNumber': _motherMobile.text.trim(),
          },
        },
      );
      if (mounted) Navigator.of(context).pop(updated);
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F9FC),
    appBar: AppBar(
      title: const Text('Edit profile'),
      backgroundColor: const Color(0xFFF6F9FC),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          _sectionTitle('Basic information', Icons.person_outline_rounded),
          _textField(
            label: 'Full name',
            controller: _name,
            validator: (value) => _required(value) ?? _maxLength(value, 100, 'Name'),
            capitalization: TextCapitalization.words,
            maxLength: 100,
          ),
          _textField(
            label: 'Email address',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => _emailValidator(value, requiredField: true),
          ),
          _textField(
            label: 'Mobile number',
            controller: _mobile,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            digitsOnly: true,
            validator: (value) => _mobileValidator(value, requiredField: true),
          ),
          _textField(
            label: 'Username',
            controller: _username,
            maxLength: 40,
            validator: _usernameValidator,
          ),
          if (_isStudent) ...[
            _sectionTitle('School information', Icons.school_outlined),
            _dropdown(
              label: 'Class',
              value: _className,
              items: _classes,
              requiredField: true,
              onChanged: (value) => setState(() => _className = value),
            ),
            _dropdown(
              label: 'Section',
              value: _section,
              items: _sections,
              onChanged: (value) => setState(() => _section = value),
            ),
            _dropdown(
              label: 'Gender',
              value: _gender,
              items: _genders,
              onChanged: (value) => setState(() => _gender = value),
            ),
            _textField(
              label: 'School name (optional)',
              controller: _school,
              capitalization: TextCapitalization.words,
              maxLength: 150,
              validator: (value) => _maxLength(value, 150, 'School name'),
            ),
            _sectionTitle('Family contacts', Icons.family_restroom_outlined),
            _textField(
              label: 'Father’s name',
              controller: _fatherName,
              capitalization: TextCapitalization.words,
              maxLength: 100,
              validator: (value) => _required(value) ?? _maxLength(value, 100, 'Name'),
            ),
            _textField(
              label: 'Father’s email (optional)',
              controller: _fatherEmail,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => _emailValidator(value, requiredField: false),
            ),
            _textField(
              label: 'Father’s mobile number',
              controller: _fatherMobile,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              digitsOnly: true,
              validator: (value) => _mobileValidator(value, requiredField: true),
            ),
            _textField(
              label: 'Mother’s name (optional)',
              controller: _motherName,
              capitalization: TextCapitalization.words,
              maxLength: 100,
              validator: (value) => _maxLength(value, 100, 'Name'),
            ),
            _textField(
              label: 'Mother’s email (optional)',
              controller: _motherEmail,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => _emailValidator(value, requiredField: false),
            ),
            _textField(
              label: 'Mother’s mobile number (optional)',
              controller: _motherMobile,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              digitsOnly: true,
              validator: (value) => _mobileValidator(value, requiredField: false),
            ),
          ],
          if (_isTeacher) ...[
            _sectionTitle('Work information', Icons.work_outline_rounded),
            _textField(
              label: 'School name',
              controller: _school,
              capitalization: TextCapitalization.words,
              maxLength: 150,
              validator: (value) => _required(value) ?? _maxLength(value, 150, 'School name'),
            ),
            _dropdown(
              label: 'Teaching subject',
              value: _subject,
              items: _subjects,
              requiredField: true,
              onChanged: (value) => setState(() => _subject = value),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(_isSaving ? 'Saving…' : 'Save changes'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF13A483),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _sectionTitle(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 10),
    child: Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFF149B78)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF203454),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _textField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    int? maxLength,
    bool digitsOnly = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      maxLength: maxLength,
      inputFormatters: [
        if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF18A77F), width: 1.4),
        ),
      ),
    ),
  );

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool requiredField = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      onChanged: onChanged,
      validator: requiredField
          ? (selected) => selected == null ? '$label is required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8EF)),
        ),
      ),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
    ),
  );
}

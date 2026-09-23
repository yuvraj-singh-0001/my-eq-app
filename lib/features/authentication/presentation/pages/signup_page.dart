import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/auth_api.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _fatherEmailController = TextEditingController();
  final _fatherMobileController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _motherEmailController = TextEditingController();
  final _motherMobileController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _teachingSubjectController = TextEditingController();

  int _step = 0;
  String _role = 'student';
  String? _className;
  String? _section;
  String? _gender;
  String? _assignedTeacher;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _usernameError;
  String? _studentId;

  @override
  void initState() {
    super.initState();
    _loadAccountId();
  }

  Future<void> _loadAccountId() async {
    try {
      final accountId = await AuthApi.previewAccountId(_role);
      if (mounted) setState(() => _studentId = accountId);
    } on AuthApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _fullNameController,
      _emailController,
      _mobileController,
      _fatherNameController,
      _fatherEmailController,
      _fatherMobileController,
      _motherNameController,
      _motherEmailController,
      _motherMobileController,
      _usernameController,
      _passwordController,
      _schoolNameController,
      _teachingSubjectController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _goToNextStep() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (_step == 0) {
      if (_usernameController.text.isEmpty) {
        _usernameController.text = _emailController.text
            .trim()
            .split('@')
            .first
            .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '');
      }
      setState(() => _step = 1);
    } else if (!_isSubmitting) {
      setState(() => _isSubmitting = true);
      try {
        final result = await AuthApi.signup(
          role: _role,
          fullName: _fullNameController.text,
          email: _emailController.text,
          mobileNumber: _mobileController.text,
          className: _className,
          section: _section,
          gender: _gender,
          fatherName: _fatherNameController.text,
          fatherEmail: _fatherEmailController.text,
          fatherMobileNumber: _fatherMobileController.text,
          motherName: _motherNameController.text,
          motherEmail: _motherEmailController.text,
          motherMobileNumber: _motherMobileController.text,
          username: _usernameController.text,
          password: _passwordController.text,
          schoolName: _schoolNameController.text,
          teachingSubject: _teachingSubjectController.text,
        );
        if (!mounted) return;
        setState(() => _studentId = result.accountId);
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Account created'),
            content: Text(
              '${result.message}\n\nYour ${_role == 'teacher' ? 'Teacher ID' : 'Student ID'}\n${result.accountId}',
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      } on AuthApiException catch (error) {
        if (!mounted) return;
        if (error.message.toLowerCase().contains('username')) {
          setState(() => _usernameError = error.message);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 760;
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
                ),
                child: Column(
                  children: [
                    _SignupHeader(
                      isCompact: isCompact,
                      step: _step,
                      role: _role,
                    ),
                    _SignupFormPanel(
                      step: _step,
                      role: _role,
                      fullNameController: _fullNameController,
                      emailController: _emailController,
                      mobileController: _mobileController,
                      fatherNameController: _fatherNameController,
                      fatherEmailController: _fatherEmailController,
                      fatherMobileController: _fatherMobileController,
                      motherNameController: _motherNameController,
                      motherEmailController: _motherEmailController,
                      motherMobileController: _motherMobileController,
                      usernameController: _usernameController,
                      usernameError: _usernameError,
                      studentId: _studentId,
                      passwordController: _passwordController,
                      schoolNameController: _schoolNameController,
                      teachingSubjectController: _teachingSubjectController,
                      section: _section,
                      gender: _gender,
                      assignedTeacher: _assignedTeacher,
                      obscurePassword: _obscurePassword,
                      isSubmitting: _isSubmitting,
                      className: _className,
                      onClassChanged: (value) =>
                          setState(() => _className = value),
                      onSectionChanged: (value) =>
                          setState(() => _section = value),
                      onGenderChanged: (value) =>
                          setState(() => _gender = value),
                      onTeacherChanged: (value) =>
                          setState(() => _assignedTeacher = value),
                      onPasswordVisibilityChanged: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onUsernameErrorChanged: () =>
                          setState(() => _usernameError = null),
                      onNext: _goToNextStep,
                      onRoleChanged: (role) {
                        setState(() {
                          _role = role;
                          _studentId = null;
                          _step = 0;
                        });
                        _loadAccountId();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SignupHeader extends StatelessWidget {
  const _SignupHeader({
    required this.isCompact,
    required this.step,
    required this.role,
  });

  final bool isCompact;
  final int step;
  final String role;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isCompact ? 270 : 305,
      child: Stack(
        children: [
          Positioned(
            left: 24,
            top: 20,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Color(0xFF203454)),
            ),
          ),
          const Positioned(left: 0, right: 0, top: 20, child: _SignupBrand()),
          Positioned(
            right: 24,
            top: 24,
            child: Text(
              'Step ${step + 1} of 2',
              style: const TextStyle(color: Color(0xFF53647C), fontSize: 12),
            ),
          ),
          Positioned(
            left: 30,
            top: 82,
            right: 30,
            child: _ProgressIndicator(step: step),
          ),
          Positioned(
            left: 24,
            top: isCompact ? 132 : 145,
            child: Text(
              role == 'teacher'
                  ? (step == 0 ? 'Join as a\nTeacher' : 'Teacher\nAccount')
                  : (step == 0 ? 'Create Your\nAccount' : 'Family &\nAccount'),
              style: const TextStyle(
                color: Color(0xFF10234B),
                fontSize: 30,
                height: 1.03,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Positioned(
            left: 24,
            top: isCompact ? 202 : 215,
            child: Text(
              step == 0
                  ? (role == 'teacher'
                    ? 'Share your details and\nstart teaching with MyEQ.'
                    : "Let's get to know you better\nso we can support your journey.")
                  : (role == 'teacher'
                    ? 'Create your secure teacher\naccount to continue.'
                    : 'Add family details and secure\nyour MyEQ App account.'),
              style: const TextStyle(
                color: Color(0xFF627087),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          Positioned(
            right: -18,
            bottom: -45,
            width: role == 'teacher'
                ? (isCompact ? 205 : 245)
                : (isCompact ? 225 : 270),
            child: Image.asset(
              role == 'teacher'
                  ? 'lib/assets/images/teachers-singup.png'
                  : 'lib/assets/images/sign-up-image.png',
              cacheWidth: 650,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignupBrand extends StatelessWidget {
  const _SignupBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.spa_outlined, color: Color(0xFF159976), size: 32),
        const SizedBox(width: 4),
        RichText(
          text: const TextSpan(
            text: 'MyEQ',
            style: TextStyle(
              color: Color(0xFF101C38),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            children: [
              TextSpan(
                text: ' App',
                style: TextStyle(color: Color(0xFF159976)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ProgressDot(active: true, label: 'Basic Info'),
        Expanded(child: _ProgressLine(active: step > 0)),
        _ProgressDot(active: step > 0, label: 'Family Details'),
        Expanded(child: _ProgressLine(active: false)),
        const _ProgressDot(active: false, label: 'Complete'),
      ],
    );
  }
}

class _ProgressDot extends StatelessWidget {
  const _ProgressDot({required this.active, required this.label});

  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 7,
          backgroundColor: active
              ? const Color(0xFF18A77F)
              : const Color(0xFFD8DFEB),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF159976) : const Color(0xFF7A879A),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Divider(
        color: active ? const Color(0xFF18A77F) : const Color(0xFFD8DFEB),
        thickness: 1.5,
      ),
    );
  }
}

class _SignupFormPanel extends StatelessWidget {
  const _SignupFormPanel({
    required this.step,
    required this.role,
    required this.fullNameController,
    required this.emailController,
    required this.mobileController,
    required this.className,
    required this.fatherNameController,
    required this.fatherEmailController,
    required this.fatherMobileController,
    required this.motherNameController,
    required this.motherEmailController,
    required this.motherMobileController,
    required this.usernameController,
    required this.usernameError,
    required this.studentId,
    required this.passwordController,
    required this.schoolNameController,
    required this.teachingSubjectController,
    required this.section,
    required this.gender,
    required this.assignedTeacher,
    required this.obscurePassword,
    required this.isSubmitting,
    required this.onSectionChanged,
    required this.onClassChanged,
    required this.onGenderChanged,
    required this.onTeacherChanged,
    required this.onPasswordVisibilityChanged,
    required this.onUsernameErrorChanged,
    required this.onNext,
    required this.onRoleChanged,
  });

  final int step;
  final String role;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController mobileController;
  final String? className;
  final TextEditingController fatherNameController;
  final TextEditingController fatherEmailController;
  final TextEditingController fatherMobileController;
  final TextEditingController motherNameController;
  final TextEditingController motherEmailController;
  final TextEditingController motherMobileController;
  final TextEditingController usernameController;
  final String? usernameError;
  final String? studentId;
  final TextEditingController passwordController;
  final TextEditingController schoolNameController;
  final TextEditingController teachingSubjectController;
  final String? section;
  final String? gender;
  final String? assignedTeacher;
  final bool obscurePassword;
  final bool isSubmitting;
  final ValueChanged<String?> onSectionChanged;
  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<String?> onTeacherChanged;
  final VoidCallback onPasswordVisibilityChanged;
  final VoidCallback onUsernameErrorChanged;
  final VoidCallback onNext;
  final ValueChanged<String> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x160B5E55),
            blurRadius: 18,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: role == 'teacher'
                ? (step == 0 ? 'Teacher Information' : 'Teacher Account')
                : (step == 0
                      ? 'Basic Information'
                      : 'Family & Account Details'),
            subtitle: step == 0
                ? 'Tell us about yourself'
                : 'Keep your account secure',
          ),
          const SizedBox(height: 18),
          _SignupRoleSelector(role: role, onChanged: onRoleChanged),
          const SizedBox(height: 14),
          _StudentIdField(
            studentId: studentId,
            label: role == 'teacher' ? 'Teacher ID' : 'Student ID',
          ),
          const SizedBox(height: 14),
          if (step == 0)
            ..._basicFields()
          else if (role == 'teacher')
            ..._teacherFields()
          else
            ..._accountFields(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: isSubmitting ? null : onNext,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF18A77F),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSubmitting)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else ...[
                    Text(step == 0 ? 'Next' : 'Create Account'),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text.rich(
                TextSpan(
                  text: 'Already have an account?  ',
                  style: TextStyle(color: Color(0xFF53647C), fontSize: 12),
                  children: [
                    TextSpan(
                      text: 'Sign In',
                      style: TextStyle(
                        color: Color(0xFF149B78),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _basicFields() {
    if (role == 'teacher') return _teacherBasicFields();
    return [
      _SignupInput(
        label: 'Full Name',
        hint: 'Enter your full name',
        controller: fullNameController,
        icon: Icons.person_outline,
        textCapitalization: TextCapitalization.words,
        inputFormatters: const [_CapitalizeWordsFormatter()],
        requiredField: true,
        validator: _requiredValidator,
      ),
      const SizedBox(height: 12),
      _SignupInput(
        label: 'Gmail',
        hint: 'Enter your Gmail address',
        controller: emailController,
        icon: Icons.mail_outline,
        keyboardType: TextInputType.emailAddress,
        requiredField: true,
        validator: _emailValidator,
      ),
      const SizedBox(height: 12),
      _SignupInput(
        label: 'Mobile Number',
        hint: 'Enter 10-digit mobile number',
        controller: mobileController,
        icon: Icons.phone_outlined,
        prefixText: '+91 ',
        keyboardType: TextInputType.phone,
        maxLength: 10,
        requiredField: true,
        validator: _mobileValidator,
      ),
      const SizedBox(height: 12),
      _SignupDropdown(
        label: 'Class',
        value: className,
        hint: 'Select your class',
        items: const ['Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5'],
        onChanged: onClassChanged,
        icon: Icons.school_outlined,
        requiredField: true,
      ),
      const SizedBox(height: 12),
      _SignupDropdown(
        label: 'Section',
        value: section,
        hint: 'Select section (A-D) - optional',
        items: const ['A', 'B', 'C', 'D'],
        onChanged: onSectionChanged,
        icon: Icons.view_agenda_outlined,
      ),
      const SizedBox(height: 12),
      _SignupDropdown(
        label: 'Gender',
        value: gender,
        hint: 'Select gender - optional',
        items: const ['Male', 'Female', 'Other'],
        onChanged: onGenderChanged,
        icon: Icons.wc_outlined,
      ),
      const SizedBox(height: 12),
      _SignupDropdown(
        label: 'Assigned Teacher',
        value: assignedTeacher,
        hint: 'Assigned after teacher login',
        items: const ['Will be assigned by school'],
        onChanged: onTeacherChanged,
        icon: Icons.groups_outlined,
        enabled: false,
      ),
      const SizedBox(height: 10),
    ];
  }

  List<Widget> _teacherBasicFields() {
    return [
      _SignupInput(
        label: 'Full Name',
        hint: 'Enter your full name',
        controller: fullNameController,
        icon: Icons.person_outline,
        textCapitalization: TextCapitalization.words,
        inputFormatters: const [_CapitalizeWordsFormatter()],
        requiredField: true,
        validator: _requiredValidator,
      ),
      const SizedBox(height: 12),
      _SignupInput(
        label: 'Gmail',
        hint: 'Enter your Gmail address',
        controller: emailController,
        icon: Icons.mail_outline,
        keyboardType: TextInputType.emailAddress,
        requiredField: true,
        validator: _emailValidator,
      ),
      const SizedBox(height: 12),
      _SignupInput(
        label: 'Mobile Number',
        hint: 'Enter 10-digit mobile number',
        controller: mobileController,
        icon: Icons.phone_outlined,
        prefixText: '+91 ',
        keyboardType: TextInputType.phone,
        maxLength: 10,
        requiredField: true,
        validator: _mobileValidator,
      ),
      const SizedBox(height: 12),
      _SignupInput(
        label: 'School Name',
        hint: 'Enter your school name',
        controller: schoolNameController,
        icon: Icons.school_outlined,
        textCapitalization: TextCapitalization.words,
        inputFormatters: const [_CapitalizeWordsFormatter()],
        requiredField: true,
        validator: _requiredValidator,
      ),
      const SizedBox(height: 12),
      _SignupDropdown(
        label: 'Teaching Subject',
        value: teachingSubjectController.text.isEmpty
            ? null
            : teachingSubjectController.text,
        hint: 'Select your subject',
        items: const [
          'Mathematics',
          'Science',
          'English',
          'Hindi',
          'Social Science',
          'Computer Science',
          'Physics',
          'Chemistry',
          'Biology',
          'History',
          'Geography',
          'Physical Education',
        ],
        onChanged: (value) {
          teachingSubjectController.text = value ?? '';
        },
        icon: Icons.menu_book_outlined,
        requiredField: true,
      ),
    ];
  }

  List<Widget> _teacherFields() {
    return [
      const _FormGroupLabel('Your Account'),
      _SignupInput(
        label: 'Username',
        hint: 'Create your username',
        controller: usernameController,
        icon: Icons.alternate_email,
        requiredField: true,
        errorText: usernameError,
        onChanged: (_) {
          if (usernameError != null) onUsernameErrorChanged();
        },
        validator: _usernameValidator,
      ),
      const SizedBox(height: 10),
      _SignupInput(
        label: 'Password',
        hint: 'Create a strong password',
        controller: passwordController,
        icon: Icons.lock_outline,
        obscureText: obscurePassword,
        suffixIcon: IconButton(
          onPressed: onPasswordVisibilityChanged,
          icon: Icon(
            obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
        requiredField: true,
        validator: _passwordValidator,
      ),
      const SizedBox(height: 8),
      _PasswordRequirements(controller: passwordController),
    ];
  }

  List<Widget> _accountFields() {
    return [
      const _FormGroupLabel('Father\'s Details'),
      _SignupInput(
        label: 'Father\'s Name',
        hint: 'Enter father\'s name',
        controller: fatherNameController,
        icon: Icons.person_outline,
        textCapitalization: TextCapitalization.words,
        inputFormatters: const [_CapitalizeWordsFormatter()],
        requiredField: true,
        validator: _requiredValidator,
      ),
      const SizedBox(height: 10),
      _SignupInput(
        label: 'Father\'s Gmail (Optional)',
        hint: 'Enter father\'s email if available',
        controller: fatherEmailController,
        icon: Icons.mail_outline,
        keyboardType: TextInputType.emailAddress,
        validator: _optionalEmailValidator,
      ),
      const SizedBox(height: 10),
      _SignupInput(
        label: 'Father\'s Mobile',
        hint: 'Enter 10-digit mobile number',
        controller: fatherMobileController,
        icon: Icons.phone_outlined,
        prefixText: '+91 ',
        keyboardType: TextInputType.phone,
        maxLength: 10,
        requiredField: true,
        validator: _mobileValidator,
      ),
      const SizedBox(height: 14),
      const _FormGroupLabel('Mother\'s Details'),
      _SignupInput(
        label: 'Mother\'s Name (Optional)',
        hint: 'Enter mother\'s name if available',
        controller: motherNameController,
        icon: Icons.person_outline,
        textCapitalization: TextCapitalization.words,
        inputFormatters: const [_CapitalizeWordsFormatter()],
      ),
      const SizedBox(height: 10),
      _SignupInput(
        label: 'Mother\'s Gmail (Optional)',
        hint: 'Enter mother\'s email if available',
        controller: motherEmailController,
        icon: Icons.mail_outline,
        keyboardType: TextInputType.emailAddress,
        validator: _optionalEmailValidator,
      ),
      const SizedBox(height: 10),
      _SignupInput(
        label: 'Mother\'s Mobile (Optional)',
        hint: 'Enter 10-digit mobile number if available',
        controller: motherMobileController,
        icon: Icons.phone_outlined,
        prefixText: '+91 ',
        keyboardType: TextInputType.phone,
        maxLength: 10,
        validator: _optionalMobileValidator,
      ),
      const SizedBox(height: 14),
      const _FormGroupLabel('Your Account'),
      _SignupInput(
        label: 'Username',
        hint: 'Create your username',
        controller: usernameController,
        icon: Icons.alternate_email,
        requiredField: true,
        errorText: usernameError,
        onChanged: (_) {
          if (usernameError != null) {
            onUsernameErrorChanged();
          }
        },
        validator: _usernameValidator,
      ),
      const SizedBox(height: 10),
      _SignupInput(
        label: 'Password',
        hint: 'Create a strong password',
        controller: passwordController,
        icon: Icons.lock_outline,
        obscureText: obscurePassword,
        suffixIcon: IconButton(
          onPressed: onPasswordVisibilityChanged,
          icon: Icon(
            obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
        requiredField: true,
        validator: _passwordValidator,
      ),
      const SizedBox(height: 8),
      _PasswordRequirements(controller: passwordController),
    ];
  }

  String? _mobileValidator(String? value) {
    if (value == null || value.length != 10) {
      return 'Mobile number must be exactly 10 digits';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Use digits only';
    }
    return null;
  }

  String? _optionalMobileValidator(String? value) {
    if (value == null || value.isEmpty) return null;
    return _mobileValidator(value);
  }

  String? _requiredValidator(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  String? _usernameValidator(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty) return 'Username is required';
    if (username.length < 3) return 'Username must be at least 3 characters';
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(username)) {
      return 'Use only letters, numbers, dot, underscore, or hyphen';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Gmail is required';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())
        ? null
        : 'Enter a valid Gmail address';
  }

  String? _optionalEmailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())
        ? null
        : 'Enter a valid Gmail address';
  }

  String? _passwordValidator(String? value) {
    final password = value ?? '';
    return password.length >= 8 &&
            RegExp(r'[A-Z]').hasMatch(password) &&
            RegExp(r'[a-z]').hasMatch(password) &&
            RegExp(r'\d').hasMatch(password) &&
            RegExp(r'[^A-Za-z0-9]').hasMatch(password)
        ? null
        : 'Password does not meet all requirements';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          backgroundColor: Color(0xFFE2F7F0),
          child: Icon(Icons.person_outline, color: Color(0xFF159976)),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF172C4E),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF6B7890), fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _FormGroupLabel extends StatelessWidget {
  const _FormGroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF159976),
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _SignupRoleSelector extends StatelessWidget {
  const _SignupRoleSelector({required this.role, required this.onChanged});

  final String role;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SignupRoleButton(
            label: 'Student',
            icon: Icons.school_outlined,
            selected: role == 'student',
            onPressed: () => onChanged('student'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SignupRoleButton(
            label: 'Teacher',
            icon: Icons.groups_outlined,
            selected: role == 'teacher',
            onPressed: () => onChanged('teacher'),
          ),
        ),
      ],
    );
  }
}

class _SignupRoleButton extends StatelessWidget {
  const _SignupRoleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: TextButton.styleFrom(
          backgroundColor: selected
              ? const Color(0xFF18A77F)
              : const Color(0xFFF1F4F9),
          foregroundColor: selected ? Colors.white : const Color(0xFF657189),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _StudentIdField extends StatelessWidget {
  const _StudentIdField({required this.studentId, required this.label});

  final String? studentId;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF1D2D4A),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          key: ValueKey(studentId),
          readOnly: true,
          initialValue: studentId,
          decoration: InputDecoration(
            hintText: 'Generating your Student ID...',
            hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF8994A8)),
            prefixIcon: const Icon(
              Icons.badge_outlined,
              size: 19,
              color: Color(0xFF159976),
            ),
            filled: true,
            fillColor: const Color(0xFFEFFAF6),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFBCEBDD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFBCEBDD)),
            ),
          ),
          style: const TextStyle(
            color: Color(0xFF159976),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PasswordRequirements extends StatelessWidget {
  const _PasswordRequirements({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final password = value.text;
        final requirements = <String, bool>{
          'At least 8 characters': password.length >= 8,
          'One uppercase letter': RegExp(r'[A-Z]').hasMatch(password),
          'One lowercase letter': RegExp(r'[a-z]').hasMatch(password),
          'One number': RegExp(r'\d').hasMatch(password),
          'One special character': RegExp(r'[^A-Za-z0-9]').hasMatch(password),
        };
        final remaining = requirements.entries
            .where((requirement) => !requirement.value)
            .map((requirement) => requirement.key)
            .toList();

        if (remaining.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Password needs:',
              style: TextStyle(color: Color(0xFF53647C), fontSize: 11),
            ),
            for (final requirement in remaining)
              Text(
                requirement,
                style: const TextStyle(color: Color(0xFF7B8799), fontSize: 10),
              ),
          ],
        );
      },
    );
  }
}

class _SignupInput extends StatelessWidget {
  const _SignupInput({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.prefixText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLength,
    this.obscureText = false,
    this.suffixIcon,
    this.errorText,
    this.onChanged,
    this.validator,
    this.requiredField = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final String? prefixText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: const TextStyle(
              color: Color(0xFF1D2D4A),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            children: requiredField
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ]
                : const [],
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          obscureText: obscureText,
          onChanged: onChanged,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(fontSize: 12, color: Color(0xFF1D2D4A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF8994A8)),
            prefixIcon: Icon(icon, size: 19, color: const Color(0xFF6D7B92)),
            prefixText: prefixText,
            prefixStyle: const TextStyle(
              color: Color(0xFF1D2D4A),
              fontSize: 12,
            ),
            suffixIcon: suffixIcon,
            errorText: errorText,
            counterText: '',
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF8F9FC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE1E6EF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE1E6EF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF18A77F),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _CapitalizeWordsFormatter extends TextInputFormatter {
  const _CapitalizeWordsFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final capitalized = newValue.text.replaceAllMapped(
      RegExp(r'(^|\s)([a-z])'),
      (match) => '${match.group(1)}${match.group(2)!.toUpperCase()}',
    );
    return newValue.copyWith(
      text: capitalized,
      selection: TextSelection.collapsed(offset: capitalized.length),
    );
  }
}

class _SignupDropdown extends StatelessWidget {
  const _SignupDropdown({
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    required this.icon,
    this.enabled = true,
    this.requiredField = false,
  });

  final String label;
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData icon;
  final bool enabled;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    final selectedValue = items.contains(value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: const TextStyle(
              color: Color(0xFF1D2D4A),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            children: requiredField
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ]
                : const [],
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          initialValue: selectedValue,
          onChanged: enabled ? onChanged : null,
          validator: requiredField
              ? (value) => value == null ? 'This field is required' : null
              : null,
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8994A8)),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 19, color: const Color(0xFF6D7B92)),
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF8F9FC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE1E6EF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE1E6EF)),
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 12)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

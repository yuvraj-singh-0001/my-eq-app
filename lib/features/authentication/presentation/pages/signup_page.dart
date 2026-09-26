import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/top_notification.dart';
import '../../data/auth_api.dart';
import '../../data/auth_session.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../journal/presentation/pages/journal_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key, this.initialRole = 'student'});

  final String initialRole;

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
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole == 'teacher' ? 'teacher' : 'student';
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
        setState(() {
          _studentId = result.accountId;
          _authToken = result.token;
        });
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => _AccountCreatedDialog(
            role: _role,
            fullName: _fullNameController.text,
            accountId: result.accountId,
            message: result.message,
          ),
        );
        if (mounted) {
          setState(() => _step = 2);
        }
      } on AuthApiException catch (error) {
        if (!mounted) return;
        if (error.message.toLowerCase().contains('username')) {
          setState(() => _usernameError = error.message);
        } else {
          showTopErrorNotification(context, error.message);
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  void _handleBack() {
    if (_step == 1) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() => _step = 0);
      return;
    }
    Navigator.of(context).maybePop();
  }

  Future<void> _openDashboard() async {
    await AuthSession.save(_loginResult());
    if (!mounted) return;
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) => DashboardPage(result: _loginResult()),
      ),
    );
  }

  void _openJournal() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => JournalPage(result: _loginResult()),
      ),
    );
  }

  LoginResult _loginResult() => LoginResult(
    fullName: _fullNameController.text.trim(),
    role: _role,
    teacherId: _role == 'teacher' ? _studentId : null,
    studentId: _role == 'teacher' ? null : _studentId,
    email: _emailController.text.trim(),
    username: _usernameController.text.trim(),
    token: _authToken,
  );

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _step != 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step == 1) _handleBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FBFC),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, _) {
              return Form(
                key: _formKey,
                child: _step == 2
                    ? Column(
                        children: [
                          _SignupHeader(
                            step: _step,
                            role: _role,
                            onBack: _handleBack,
                          ),
                          Expanded(
                            child: _Step3Panel(
                              role: _role,
                              onGoToDashboard: _openDashboard,
                              onWriteReflection: _openJournal,
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
                        ),
                        child: Column(
                          children: [
                            _SignupHeader(
                              step: _step,
                              role: _role,
                              onBack: _handleBack,
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
                              teachingSubjectController:
                                  _teachingSubjectController,
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
                              onPasswordVisibilityChanged: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
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
      ),
    );
  }
}

class _SignupHeader extends StatelessWidget {
  const _SignupHeader({
    required this.step,
    required this.role,
    required this.onBack,
  });

  final int step;
  final String role;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenWidth < 360 || screenHeight < 700;

    final headerHeight = step == 2
        ? (screenHeight < 680 ? 230.0 : (isSmallScreen ? 250.0 : 300.0))
        : (isSmallScreen ? 265.0 : 300.0);

    final textWidth = step == 2
        ? (screenWidth * 0.48).clamp(155.0, 195.0)
        : (screenWidth * 0.52).clamp(160.0, 220.0);

    final heroWidth = screenWidth < 380
        ? screenWidth * 0.38
        : (step == 2
              ? (screenWidth * 0.58).clamp(215.0, 275.0)
              : (role == 'teacher'
                    ? (screenWidth * 0.52).clamp(190.0, 250.0)
                    : (screenWidth * 0.55).clamp(200.0, 275.0)));

    return SizedBox(
      height: headerHeight,
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 18,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: Color(0xFF203454)),
            ),
          ),
          const Positioned(left: 0, right: 0, top: 20, child: _SignupBrand()),
          Positioned(
            right: 20,
            top: 24,
            child: Text(
              'Step ${step + 1} of 3',
              style: const TextStyle(
                color: Color(0xFF53647C),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 72,
            right: 20,
            child: _ProgressIndicator(step: step, role: role),
          ),
          Positioned(
            left: 20,
            top: isSmallScreen ? 116.0 : 128.0,
            width: textWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (step == 2)
                  RichText(
                    text: TextSpan(
                      text: "You're\n",
                      style: TextStyle(
                        color: const Color(0xFF10234B),
                        fontSize: isSmallScreen ? 28.0 : 33.0,
                        height: 1.02,
                        fontWeight: FontWeight.w800,
                      ),
                      children: const [
                        TextSpan(
                          text: 'All Set! 🎉',
                          style: TextStyle(color: Color(0xFF149B78)),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    role == 'teacher'
                        ? (step == 0
                              ? 'Join as a\nTeacher'
                              : 'Teacher\nAccount')
                        : (step == 0
                              ? 'Create Your\nAccount'
                              : 'Family &\nAccount'),
                    style: TextStyle(
                      color: const Color(0xFF10234B),
                      fontSize: isSmallScreen ? 26.0 : 30.0,
                      height: 1.03,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  step == 2
                      ? 'Your account is ready. Your journey starts now.'
                      : (step == 0
                            ? (role == 'teacher'
                                  ? 'Share your details and\nstart teaching with MyEQ.'
                                  : "Let's get to know you better\nso we can support your journey.")
                            : (role == 'teacher'
                                  ? 'Create your secure teacher\naccount to continue.'
                                  : 'Add family details and secure\nyour MyEQ App account.')),
                  style: TextStyle(
                    color: const Color(0xFF627087),
                    fontSize: isSmallScreen ? 11.0 : 12.0,
                    height: 1.38,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: screenWidth < 380 ? 0 : (step == 2 ? -8.0 : -18.0),
            bottom: step == 2 ? -10.0 : -40.0,
            width: heroWidth,
            child: Image.asset(
              step == 2
                  ? 'lib/assets/images/studentslogin3step1.png'
                  : (role == 'teacher'
                        ? 'lib/assets/images/teachers-singup.png'
                        : 'lib/assets/images/sign-up-image.png'),
              cacheWidth: 800,
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
  const _ProgressIndicator({required this.step, required this.role});

  final int step;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ProgressDot(active: true, completed: step >= 0, label: 'Basic Info'),
        Expanded(child: _ProgressLine(active: step > 0)),
        _ProgressDot(
          active: step > 0,
          completed: step >= 1,
          label: role == 'teacher' ? 'Account Details' : 'Additional Info',
        ),
        Expanded(child: _ProgressLine(active: step > 1)),
        _ProgressDot(active: step > 1, completed: step >= 2, label: 'Complete'),
      ],
    );
  }
}

class _ProgressDot extends StatelessWidget {
  const _ProgressDot({
    required this.active,
    required this.completed,
    required this.label,
  });

  final bool active;
  final bool completed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 9,
          backgroundColor: active
              ? const Color(0xFF18A77F)
              : const Color(0xFFD8DFEB),
          child: completed
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF159976) : const Color(0xFF7A879A),
            fontSize: 9,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
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
          style: const TextStyle(
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
            hintText: 'Generating $label...',
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

class _AccountCreatedDialog extends StatefulWidget {
  const _AccountCreatedDialog({
    required this.role,
    required this.fullName,
    required this.accountId,
    required this.message,
  });

  final String role;
  final String fullName;
  final String accountId;
  final String message;

  @override
  State<_AccountCreatedDialog> createState() => _AccountCreatedDialogState();
}

class _AccountCreatedDialogState extends State<_AccountCreatedDialog> {
  void _proceed() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.role == 'teacher';
    final roleTitle = isTeacher ? 'Teacher' : 'Student';
    final idTitle = isTeacher ? 'TEACHER ID' : 'STUDENT ID';
    final themeColor = isTeacher
        ? const Color(0xFF0F8A6B)
        : const Color(0xFF149B78);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFE2F7F0),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withAlpha(51),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: themeColor,
                size: 46,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '$roleTitle Account Created!',
              style: const TextStyle(
                color: Color(0xFF10234B),
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Welcome, ${widget.fullName}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF53647C),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF627087), fontSize: 12),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF7F3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isTeacher ? Icons.groups_outlined : Icons.school_outlined,
                    size: 15,
                    color: themeColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$roleTitle Account',
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1FAF7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBCEBDD)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isTeacher
                            ? Icons.badge_outlined
                            : Icons.credit_card_outlined,
                        size: 16,
                        color: themeColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'YOUR OFFICIAL $idTitle',
                        style: TextStyle(
                          color: themeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    widget.accountId,
                    style: const TextStyle(
                      color: Color(0xFF10234B),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: widget.accountId),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$roleTitle ID copied to clipboard!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy ID'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: themeColor,
                        side: BorderSide(color: themeColor),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Save your $idTitle. You can use it to log in anytime.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7A879A), fontSize: 11),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _proceed,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF18A77F),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Continue'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

class _Step3Panel extends StatelessWidget {
  const _Step3Panel({
    required this.role,
    required this.onGoToDashboard,
    required this.onWriteReflection,
  });

  final String role;
  final VoidCallback onGoToDashboard;
  final VoidCallback onWriteReflection;

  void _showFeatureInfo(BuildContext context, String title, String message) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF10234B),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF627087),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 760;
    final firstTitle = role == 'teacher'
        ? 'View Your Students'
        : 'Write Your First Reflection';
    final secondTitle = role == 'teacher'
        ? 'Connect with Parents'
        : 'Connect with Teacher/Parent';

    return Container(
      width: double.infinity,
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
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          compact ? 10 : 14,
          16,
          compact ? 12 : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What's Next?",
              style: TextStyle(
                color: Color(0xFF10234B),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              role == 'teacher'
                  ? 'Your teacher account is ready. Choose a next step.'
                  : 'Choose a small step to get started.',
              style: const TextStyle(color: Color(0xFF627087), fontSize: 12),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: [
                  _WhatsNextTile(
                    icon: Icons.home_rounded,
                    iconBg: const Color(0xFFE2F7F0),
                    iconColor: const Color(0xFF149B78),
                    title: 'Go to Dashboard',
                    subtitle: 'Start exploring your personal space',
                    onTap: onGoToDashboard,
                  ),
                  const SizedBox(height: 8),
                  _WhatsNextTile(
                    icon: Icons.edit_note_rounded,
                    iconBg: const Color(0xFFE6F2FF),
                    iconColor: const Color(0xFF2682D8),
                    title: firstTitle,
                    subtitle: role == 'teacher'
                        ? 'See your connected class'
                        : 'Share how you feel today',
                    onTap: role == 'student'
                        ? onWriteReflection
                        : () => _showFeatureInfo(
                            context,
                            firstTitle,
                            'These tools will be available from your dashboard.',
                          ),
                  ),
                  const SizedBox(height: 8),
                  _WhatsNextTile(
                    icon: Icons.groups_rounded,
                    iconBg: const Color(0xFFF0E8FF),
                    iconColor: const Color(0xFF8151C8),
                    title: secondTitle,
                    subtitle: 'Get support from people you trust',
                    onTap: () => _showFeatureInfo(
                      context,
                      secondTitle,
                      'Your school can help connect the right people to your account.',
                    ),
                  ),
                ],
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF8F4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFC7EFE7)),
                ),
                child: const Text(
                  'Every small step counts. You are on your way to becoming a better you!  - MYEQApp',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF2C3E5A),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: onGoToDashboard,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF18A77F),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Go to Dashboard'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsNextTile extends StatelessWidget {
  const _WhatsNextTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EEF5)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF10234B),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF627087),
                          fontSize: 10,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8E909A),
                  size: 17,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

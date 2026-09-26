import 'package:flutter/material.dart';

import '../../../../core/widgets/top_notification.dart';
import '../../data/auth_api.dart';
import '../../data/auth_session.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../journal/presentation/pages/journal_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _hasLoginError = false;
  String _errorMessage = '';
  int _selectedRole = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _clearLoginError() {
    if (_hasLoginError) {
      setState(() {
        _hasLoginError = false;
        _errorMessage = '';
      });
    }
  }

  Future<void> _submitLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _hasLoginError = false;
      _errorMessage = '';
    });
    final roleString = _selectedRole == 1
        ? 'teacher'
        : (_selectedRole == 2 ? 'parent' : 'student');
    try {
      final result = await AuthApi.login(
        identifier: _emailController.text,
        password: _passwordController.text,
        role: roleString,
      );
      if (!mounted) return;
      await AuthSession.save(result);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _LoginSuccessDialog(result: result),
      );
      if (!mounted) return;
      final destination = result.role.trim().toLowerCase() == 'student'
          ? JournalPage(result: result)
          : DashboardPage(result: result);
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(builder: (_) => destination),
      );
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _hasLoginError = true;
        _errorMessage = error.message;
      });
      showTopErrorNotification(context, error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.viewInsetsOf(context).bottom +
                    (isCompact ? 12 : 24),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: isCompact ? 288 : 330,
                    child: Stack(
                      children: [
                        const Positioned(
                          left: 24,
                          top: 22,
                          child: _BrandMark(),
                        ),
                        const Positioned(
                          right: 22,
                          top: 22,
                          child: _LanguageButton(),
                        ),
                        Positioned(
                          right: 0,
                          bottom: -46,
                          width: isCompact ? 260 : 300,
                          child: Image.asset(
                            'lib/assets/images/login-image.png',
                            cacheWidth: 700,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned(
                          left: 30,
                          top: isCompact ? 90 : 105,
                          child: SizedBox(
                            width: isCompact ? 155 : 170,
                            child: _WelcomeCopy(isCompact: isCompact),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _LoginFormPanel(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    formKey: _formKey,
                    emailFocusNode: _emailFocusNode,
                    passwordFocusNode: _passwordFocusNode,
                    obscurePassword: _obscurePassword,
                    isSubmitting: _isSubmitting,
                    rememberMe: _rememberMe,
                    selectedRole: _selectedRole,
                    hasLoginError: _hasLoginError,
                    errorMessage: _errorMessage,
                    onInputChanged: _clearLoginError,
                    onRoleChanged: (role) {
                      _clearLoginError();
                      setState(() => _selectedRole = role);
                    },
                    onRememberChanged: (value) =>
                        setState(() => _rememberMe = value ?? false),
                    onPasswordVisibilityChanged: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onLogin: _submitLogin,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeCopy extends StatelessWidget {
  const _WelcomeCopy({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome',
          style: TextStyle(
            color: const Color(0xFF10234B),
            fontSize: isCompact ? 31 : 35,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          'Back!',
          style: TextStyle(
            color: const Color(0xFF149B78),
            fontSize: isCompact ? 31 : 35,
            height: 1.05,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Glad to see you again.\nLet’s continue your journey\ntowards a better you.',
          style: TextStyle(
            color: Color(0xFF627087),
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.spa_outlined, color: Color(0xFF159976), size: 30),
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

class _LanguageButton extends StatelessWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FA),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 16, color: Color(0xFF213557)),
            SizedBox(width: 6),
            Text(
              'English',
              style: TextStyle(
                color: Color(0xFF213557),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF213557)),
          ],
        ),
      ),
    );
  }
}

class _LoginFormPanel extends StatelessWidget {
  const _LoginFormPanel({
    required this.emailController,
    required this.passwordController,
    required this.formKey,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.obscurePassword,
    required this.isSubmitting,
    required this.rememberMe,
    required this.selectedRole,
    required this.hasLoginError,
    required this.errorMessage,
    required this.onInputChanged,
    required this.onRoleChanged,
    required this.onRememberChanged,
    required this.onPasswordVisibilityChanged,
    required this.onLogin,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool obscurePassword;
  final bool isSubmitting;
  final bool rememberMe;
  final int selectedRole;
  final bool hasLoginError;
  final String errorMessage;
  final VoidCallback onInputChanged;
  final ValueChanged<int> onRoleChanged;
  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback onPasswordVisibilityChanged;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final fieldLabel = selectedRole == 1
        ? 'Teacher ID, Username, Email, or Mobile'
        : (selectedRole == 0
              ? 'Student ID, Username, Email, or Mobile'
              : 'Mobile Number or Email');

    final hintText = selectedRole == 1
        ? 'Enter Teacher ID, email, or mobile'
        : (selectedRole == 0
              ? 'Enter Student ID, email, or mobile'
              : 'Enter mobile number or email');

    final prefixIcon = selectedRole == 1
        ? Icons.badge_outlined
        : (selectedRole == 0 ? Icons.school_outlined : Icons.phone_outlined);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
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
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RoleSelector(selectedRole: selectedRole, onChanged: onRoleChanged),
            const SizedBox(height: 20),
            Text(fieldLabel, style: _FieldLabelStyle.value),
            const SizedBox(height: 7),
            _InputField(
              controller: emailController,
              focusNode: emailFocusNode,
              hintText: hintText,
              prefixIcon: prefixIcon,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              hasError: hasLoginError,
              onChanged: (_) => onInputChanged(),
              onSubmitted: (_) => passwordFocusNode.requestFocus(),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Please enter your login credential'
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Password', style: _FieldLabelStyle.value),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Color(0xFF149B78),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            _InputField(
              controller: passwordController,
              focusNode: passwordFocusNode,
              hintText: 'Enter your password',
              prefixIcon: Icons.lock_outline,
              obscureText: obscurePassword,
              hasError: hasLoginError,
              onChanged: (_) => onInputChanged(),
              suffixIcon: IconButton(
                onPressed: onPasswordVisibilityChanged,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onLogin(),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter your password' : null,
            ),
            if (hasLoginError && errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 14,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: rememberMe,
                  onChanged: onRememberChanged,
                  activeColor: const Color(0xFF149B78),
                  visualDensity: VisualDensity.compact,
                ),
                const Text('Remember me', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: isSubmitting ? null : onLogin,
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
                      const Text('Login'),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _OrDivider(),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(
                  child: _SocialButton(
                    icon: Icons.g_mobiledata,
                    label: 'Google',
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _SocialButton(icon: Icons.apple, label: 'Apple'),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _SocialButton(icon: Icons.window, label: 'Microsoft'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () {
                  if (selectedRole == 2) {
                    showTopErrorNotification(
                      context,
                      'Parent accounts are provided by your school. Please contact your school administrator.',
                    );
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SignupPage(
                        initialRole: selectedRole == 1 ? 'teacher' : 'student',
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF1FAF7),
                  foregroundColor: const Color(0xFF31415C),
                  shape: const StadiumBorder(),
                ),
                child: const Text.rich(
                  TextSpan(
                    text: 'Don’t have an account?  ',
                    children: [
                      TextSpan(
                        text: 'Create Account  →',
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
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.selectedRole, required this.onChanged});

  final int selectedRole;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const roles = [
      (Icons.school_outlined, 'Student'),
      (Icons.groups_outlined, 'Teacher'),
      (Icons.person_outlined, 'Parent'),
    ];

    return Row(
      children: [
        for (var index = 0; index < roles.length; index++) ...[
          Expanded(
            child: _RoleButton(
              icon: roles[index].$1,
              label: roles[index].$2,
              selected: selectedRole == index,
              onPressed: () => onChanged(index),
            ),
          ),
          if (index != roles.length - 1) const SizedBox(width: 7),
        ],
      ],
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
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

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    this.focusNode,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.hasError = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      validator: validator,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 13, color: Color(0xFF1D2D4A)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF8994A8)),
        prefixIcon: Icon(
          prefixIcon,
          size: 20,
          color: hasError ? Colors.redAccent : const Color(0xFF6D7B92),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: hasError ? const Color(0xFFFFF5F5) : const Color(0xFFF8F9FC),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: hasError ? Colors.redAccent : const Color(0xFFE1E6EF),
            width: hasError ? 1.5 : 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: hasError ? Colors.redAccent : const Color(0xFFE1E6EF),
            width: hasError ? 1.5 : 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: hasError ? Colors.redAccent : const Color(0xFF18A77F),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFD9DFE8))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR CONTINUE WITH',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF8A94A6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFD9DFE8))),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: const Color(0xFF101C38)),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF31415C)),
          ),
        ],
      ),
    );
  }
}

abstract final class _FieldLabelStyle {
  static const value = TextStyle(
    color: Color(0xFF1D2D4A),
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
}

class _LoginSuccessDialog extends StatelessWidget {
  const _LoginSuccessDialog({required this.result});

  final LoginResult result;

  @override
  Widget build(BuildContext context) {
    final isTeacher = result.role == 'teacher';
    final roleLabel = isTeacher
        ? 'Teacher'
        : (result.role == 'parent' ? 'Parent' : 'Student');
    final accountId = result.teacherId ?? result.studentId;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE2F7F0),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF18A77F).withAlpha(51),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF149B78),
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Welcome Back!',
              style: TextStyle(
                color: Color(0xFF10234B),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              result.fullName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF149B78),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isTeacher
                        ? Icons.groups_outlined
                        : (result.role == 'parent'
                              ? Icons.family_restroom_outlined
                              : Icons.school_outlined),
                    size: 16,
                    color: const Color(0xFF53647C),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Logged in as $roleLabel',
                    style: const TextStyle(
                      color: Color(0xFF53647C),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (accountId != null && accountId.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE1E6EF)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${isTeacher ? "Teacher ID" : "Student ID"}: ',
                      style: const TextStyle(
                        color: Color(0xFF657189),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      accountId,
                      style: const TextStyle(
                        color: Color(0xFF10234B),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
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
                    Text('Continue to Dashboard'),
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

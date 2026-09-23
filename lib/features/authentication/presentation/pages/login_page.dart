import 'package:flutter/material.dart';

import '../../data/auth_api.dart';
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
  int _selectedRole = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final name = await AuthApi.login(
        identifier: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Aapne apna account successfully bana liya hai. Welcome back, $name.',
          ),
        ),
      );
    } on AuthApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.redAccent,
        ),
      );
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
                    onRoleChanged: (role) =>
                        setState(() => _selectedRole = role),
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
  final ValueChanged<int> onRoleChanged;
  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback onPasswordVisibilityChanged;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
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
            const Text('Email or Mobile Number', style: _FieldLabelStyle.value),
            const SizedBox(height: 7),
            _InputField(
              controller: emailController,
              focusNode: emailFocusNode,
              hintText: 'Enter your email or mobile number',
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => passwordFocusNode.requestFocus(),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your email or mobile number'
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
            const Row(
              children: [
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
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SignupPage()),
                ),
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

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 13, color: Color(0xFF1D2D4A)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF8994A8)),
        prefixIcon: Icon(prefixIcon, size: 20, color: const Color(0xFF6D7B92)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE1E6EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE1E6EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFF18A77F), width: 1.5),
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

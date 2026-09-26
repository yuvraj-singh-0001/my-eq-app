import 'package:flutter/material.dart';

import 'core/theme/application_theme.dart';
import 'features/authentication/data/auth_api.dart';
import 'features/authentication/data/auth_session.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/journal/presentation/pages/journal_page.dart';

class Application extends StatefulWidget {
  const Application({super.key});

  @override
  State<Application> createState() => _ApplicationState();
}

class _ApplicationState extends State<Application> {
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MyEQ App',
    theme: ApplicationTheme.light,
    debugShowCheckedModeBanner: false,
    home: const _SessionStartup(),
  );
}

class _SessionStartup extends StatefulWidget {
  const _SessionStartup();

  @override
  State<_SessionStartup> createState() => _SessionStartupState();
}

class _SessionStartupState extends State<_SessionStartup> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSession());
  }

  Future<void> _restoreSession() async {
    String? token;
    try {
      token = await AuthSession.readToken();
    } catch (_) {
      return;
    }
    if (token == null || token.isEmpty) return;
    final cached = await _readSavedProfile(token);
    if (cached != null) {
      _openSession(cached);
      return;
    }
    LoginResult? result;
    try {
      final profile = await AuthApi.getProfile(token);
      result = LoginResult(
        fullName: profile.fullName,
        role: profile.role,
        teacherId: profile.teacherId,
        studentId: profile.studentId,
        email: profile.email,
        username: profile.username,
        token: token,
      );
      await AuthSession.save(result);
    } on AuthApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await AuthSession.clear();
        return;
      }
      result = await _readSavedProfile(token);
    } catch (_) {
      result = await _readSavedProfile(token);
    }
    if (!mounted || result == null) return;
    _openSession(result);
  }

  void _openSession(LoginResult result) {
    if (!mounted) return;
    final destination = result.role == 'student'
        ? JournalPage(result: result)
        : DashboardPage(result: result);
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => destination),
      (_) => false,
    );
  }

  Future<LoginResult?> _readSavedProfile(String token) async {
    try {
      return await AuthSession.readProfile(token);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => const HomePage();
}

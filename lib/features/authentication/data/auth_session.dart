import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'auth_api.dart';

abstract final class AuthSession {
  static const _tokenKey = 'myeq.auth.token';
  static const _profileKey = 'myeq.auth.profile';

  static Future<void> save(LoginResult result) async {
    final preferences = await SharedPreferences.getInstance();
    final token = result.token;
    if (token == null || token.isEmpty) return;
    await preferences.setString(_tokenKey, token);
    await preferences.setString(
      _profileKey,
      jsonEncode({
        'fullName': result.fullName,
        'role': result.role,
        'teacherId': result.teacherId,
        'studentId': result.studentId,
        'email': result.email,
        'username': result.username,
      }),
    );
  }

  static Future<String?> readToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_tokenKey);
  }

  static Future<LoginResult?> readProfile(String token) async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_profileKey);
    if (stored == null) return null;
    final json = jsonDecode(stored) as Map<String, dynamic>;
    return LoginResult(
      fullName: json['fullName'] as String? ?? 'Student',
      role: json['role'] as String? ?? 'student',
      teacherId: json['teacherId'] as String?,
      studentId: json['studentId'] as String?,
      email: json['email'] as String?,
      username: json['username'] as String?,
      token: token,
    );
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    await preferences.remove(_profileKey);
  }
}

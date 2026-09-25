import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;
}

class SignupResult {
  const SignupResult({required this.message, required this.accountId});

  final String message;
  final String accountId;
}

class LoginResult {
  const LoginResult({
    required this.fullName,
    required this.role,
    this.teacherId,
    this.studentId,
    this.email,
    this.username,
  });

  final String fullName;
  final String role;
  final String? teacherId;
  final String? studentId;
  final String? email;
  final String? username;
}

class AuthApi {
  static const _configuredBaseUrl = String.fromEnvironment('MYEQ_API_BASE_URL');

  static String get _baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    }
    if (Platform.isAndroid) return 'http://10.0.2.2:4000/api';
    return 'http://127.0.0.1:4000/api';
  }

  static Future<String> previewAccountId(String role) async {
    final accountType = role == 'teacher' ? 'Teacher' : 'Student';
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/auth/account-id?role=$role'))
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException('$accountType ID could not be generated.');
      }
      final accountId = body['data']?['accountId'] as String?;
      if (accountId == null || accountId.isEmpty) {
        throw AuthApiException('$accountType ID could not be generated.');
      }
      return accountId;
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw AuthApiException('Cannot connect to the server.');
    } on http.ClientException {
      throw AuthApiException('Cannot connect to the server.');
    } on TimeoutException {
      throw AuthApiException(
        '$accountType ID request timed out.',
      );
    } catch (_) {
      throw AuthApiException('$accountType ID could not be generated.');
    }
  }

  static Future<SignupResult> signup({
    required String role,
    required String fullName,
    required String email,
    required String mobileNumber,
    required String? className,
    required String? section,
    required String? gender,
    required String fatherName,
    required String fatherEmail,
    required String fatherMobileNumber,
    required String motherName,
    required String motherEmail,
    required String motherMobileNumber,
    required String username,
    required String password,
    required String schoolName,
    required String teachingSubject,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'role': role,
              'fullName': fullName.trim(),
              'email': email.trim(),
              'mobileNumber': mobileNumber.trim(),
              'className': className,
              'schoolName': schoolName.trim(),
              'teachingSubject': teachingSubject,
              'section': section,
              'gender': gender,
              'father': {
                'name': fatherName.trim(),
                'email': fatherEmail.trim(),
                'mobileNumber': fatherMobileNumber.trim(),
              },
              'mother': {
                'name': motherName.trim(),
                'email': motherEmail.trim(),
                'mobileNumber': motherMobileNumber.trim(),
              },
              'username': username.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? 'Signup failed. Please try again.',
        );
      }

      final user = body['data']?['user'];
      final accountId = user is Map<String, dynamic>
          ? (role == 'teacher' ? user['teacherId'] : user['studentId'])
                as String?
          : null;
      if (accountId == null || accountId.isEmpty) {
        throw const AuthApiException('Student ID could not be generated.');
      }
      return SignupResult(
        message: body['message'] as String? ?? 'Account created successfully.',
        accountId: accountId,
      );
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException(
        'Cannot connect to the server. Start the backend and check the API address.',
      );
    } on http.ClientException {
      throw const AuthApiException(
        'Cannot connect to the server. Start the backend and check the API address.',
      );
    } on HttpException {
      throw const AuthApiException(
        'The server connection failed. Please try again.',
      );
    } on FormatException {
      throw const AuthApiException('The server returned an invalid response.');
    } catch (_) {
      throw const AuthApiException('Signup failed. Please try again.');
    }
  }

  static Future<LoginResult> login({
    required String identifier,
    required String password,
    String? role,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'identifier': identifier.trim(),
              'password': password,
              'role': ?role,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? 'Login failed. Please try again.',
        );
      }

      final user = body['data']?['user'] as Map<String, dynamic>? ?? {};
      return LoginResult(
        fullName: user['fullName'] as String? ?? 'User',
        role: user['role'] as String? ?? 'student',
        teacherId: user['teacherId'] as String?,
        studentId: user['studentId'] as String?,
        email: user['email'] as String?,
        username: user['username'] as String?,
      );
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException(
        'Cannot connect to the server. Start the backend and check the API address.',
      );
    } on http.ClientException {
      throw const AuthApiException(
        'Cannot connect to the server. Start the backend and check the API address.',
      );
    } on HttpException {
      throw const AuthApiException(
        'The server connection failed. Please try again.',
      );
    } on FormatException {
      throw const AuthApiException('The server returned an invalid response.');
    } catch (_) {
      throw const AuthApiException('Login failed. Please try again.');
    }
  }

  static Map<String, dynamic> _decodeBody(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('Expected a JSON object');
  }
}

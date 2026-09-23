import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;
}

class SignupResult {
  const SignupResult({required this.message, required this.studentId});

  final String message;
  final String studentId;
}

class AuthApi {
  static String get _baseUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:4000/api';
    return 'http://127.0.0.1:4000/api';
  }

  static Future<String> reserveStudentId() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/auth/student-id'))
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException('Student ID could not be generated.');
      }
      final studentId = body['data']?['studentId'] as String?;
      if (studentId == null || studentId.isEmpty) {
        throw const AuthApiException('Student ID could not be generated.');
      }
      return studentId;
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException('Cannot connect to the server.');
    } on TimeoutException {
      throw const AuthApiException('Student ID request timed out.');
    } catch (_) {
      throw const AuthApiException('Student ID could not be generated.');
    }
  }

  static Future<SignupResult> signup({
    required String studentId,
    required String fullName,
    required String email,
    required String mobileNumber,
    required String className,
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
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'studentId': studentId,
              'fullName': fullName.trim(),
              'email': email.trim(),
              'mobileNumber': mobileNumber.trim(),
              'className': className,
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
        final responseStudentId = user is Map<String, dynamic>
          ? user['studentId'] as String?
          : null;
        if (responseStudentId == null || responseStudentId.isEmpty) {
        throw const AuthApiException('Student ID could not be generated.');
      }
      return SignupResult(
        message: body['message'] as String? ?? 'Account created successfully.',
        studentId: responseStudentId,
      );
    } on AuthApiException {
      rethrow;
    } on SocketException {
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

  static Future<String> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'identifier': identifier.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? 'Login failed. Please try again.',
        );
      }

      return body['data']?['user']?['fullName'] as String? ??
          'Login completed successfully.';
    } on AuthApiException {
      rethrow;
    } on SocketException {
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

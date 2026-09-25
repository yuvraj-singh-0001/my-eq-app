import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;
}

class SignupResult {
  const SignupResult({
    required this.message,
    required this.accountId,
    this.token,
  });

  final String message;
  final String accountId;
  final String? token;
}

class LoginResult {
  const LoginResult({
    required this.fullName,
    required this.role,
    this.teacherId,
    this.studentId,
    this.email,
    this.username,
    this.token,
  });

  final String fullName;
  final String role;
  final String? teacherId;
  final String? studentId;
  final String? email;
  final String? username;
  final String? token;
}

class JournalNoteData {
  const JournalNoteData({
    required this.id,
    required this.category,
    required this.text,
    required this.createdAt,
    this.mood,
    this.responses = const [],
    this.customText = '',
    this.sections = const [],
  });

  final String id;
  final String category;
  final String text;
  final DateTime createdAt;
  final String? mood;
  final List<String> responses;
  final String customText;
  final List<Map<String, dynamic>> sections;

  factory JournalNoteData.fromJson(Map<String, dynamic> json) {
    return JournalNoteData(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? 'Reflection',
      text: json['text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      mood: json['mood'] as String?,
      responses: (json['responses'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      customText: json['customText'] as String? ?? '',
      sections: (json['sections'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false),
    );
  }
}

class JournalNotesPage {
  const JournalNotesPage({
    required this.notes,
    required this.hasMore,
    this.nextCursor,
  });

  final List<JournalNoteData> notes;
  final bool hasMore;
  final String? nextCursor;
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
      throw AuthApiException('$accountType ID request timed out.');
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
      final token = body['data']?['token'] as String?;
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
        token: token,
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
        token: body['data']?['token'] as String?,
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

  static Future<JournalNotesPage> getJournalNotes(
    String token, {
    String? cursor,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/auth/student/journal/notes')
                .replace(queryParameters: {'limit': '20', 'cursor': ?cursor}),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? 'Notes could not be loaded.',
        );
      }
      final notes = body['data']?['notes'] as List<dynamic>? ?? const [];
      return JournalNotesPage(
        notes: notes
            .whereType<Map<String, dynamic>>()
            .map(JournalNoteData.fromJson)
            .toList(growable: false),
        hasMore: body['data']?['hasMore'] as bool? ?? false,
        nextCursor: body['data']?['nextCursor'] as String?,
      );
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException(
        'Cannot connect to the server to load notes.',
      );
    } on http.ClientException {
      throw const AuthApiException(
        'Cannot connect to the server to load notes.',
      );
    } on TimeoutException {
      throw const AuthApiException(
        'Loading notes timed out. Please try again.',
      );
    } on FormatException {
      throw const AuthApiException('The server returned invalid notes data.');
    }
  }

  static Future<JournalNoteData> createJournalNote({
    required String token,
    required String category,
    required String text,
    String? mood,
    List<String> responses = const [],
    String customText = '',
    List<Map<String, Object?>> sections = const [],
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/student/journal/notes'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'category': category,
              'text': text,
              'mood': mood,
              'isPrivate': true,
              'responses': responses,
              'customText': customText,
              'sections': sections,
            }),
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? 'Note could not be saved.',
        );
      }
      final note = body['data']?['note'] as Map<String, dynamic>?;
      if (note == null) {
        throw const AuthApiException('The saved note was not returned.');
      }
      return JournalNoteData.fromJson(note);
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException(
        'Cannot connect to the server to save your note.',
      );
    } on http.ClientException {
      throw const AuthApiException(
        'Cannot connect to the server to save your note.',
      );
    } on TimeoutException {
      throw const AuthApiException(
        'Saving the note timed out. Please try again.',
      );
    } on FormatException {
      throw const AuthApiException('The server returned invalid note data.');
    }
  }

  static Map<String, dynamic> _decodeBody(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('Expected a JSON object');
  }
}

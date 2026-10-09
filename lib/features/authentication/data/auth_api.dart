import 'dart:async';
import 'dart:convert';
import 'dart:io';
// ignore : depender

import 'package:http/http.dart' as http;

class AuthApiException implements Exception {
  const AuthApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;
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
    this.parentId,
    this.studentId,
    this.email,
    this.username,
    this.token,
  });

  final String fullName;
  final String role;
  final String? teacherId;
  final String? parentId;
  final String? studentId;
  final String? email;
  final String? username;
  final String? token;
}

class AppNotificationData {
  const AppNotificationData({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.actorName,
    required this.actorRole,
    required this.payload,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String actorName;
  final String actorRole;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  factory AppNotificationData.fromJson(Map<String, dynamic> json) =>
      AppNotificationData(
        id: json['id']?.toString() ?? '',
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? 'MindGrow update',
        body: json['body'] as String? ?? '',
        actorName: json['actorName'] as String? ?? '',
        actorRole: json['actorRole'] as String? ?? '',
        payload: json['payload'] as Map<String, dynamic>? ?? const {},
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        readAt: DateTime.tryParse(json['readAt'] as String? ?? ''),
      );
}

class AppNotificationsData {
  const AppNotificationsData({
    required this.notifications,
    required this.unreadCount,
  });

  final List<AppNotificationData> notifications;
  final int unreadCount;
}

class UserProfileData {
  const UserProfileData({
    required this.id,
    required this.fullName,
    required this.role,
    this.studentId,
    this.teacherId,
    this.parentId,
    this.email,
    this.mobileNumber,
    this.username,
    this.className,
    this.section,
    this.gender,
    this.schoolName,
    this.teachingSubject,
    this.fatherName,
    this.fatherEmail,
    this.fatherMobileNumber,
    this.motherName,
    this.motherEmail,
    this.motherMobileNumber,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String role;
  final String? studentId;
  final String? teacherId;
  final String? parentId;
  final String? email;
  final String? mobileNumber;
  final String? username;
  final String? className;
  final String? section;
  final String? gender;
  final String? schoolName;
  final String? teachingSubject;
  final String? fatherName;
  final String? fatherEmail;
  final String? fatherMobileNumber;
  final String? motherName;
  final String? motherEmail;
  final String? motherMobileNumber;
  final DateTime? createdAt;

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    final father = json['father'] as Map<String, dynamic>? ?? const {};
    final mother = json['mother'] as Map<String, dynamic>? ?? const {};
    return UserProfileData(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] as String? ?? 'User',
      role: json['role'] as String? ?? 'student',
      studentId: json['studentId'] as String?,
      teacherId: json['teacherId'] as String?,
      parentId: json['parentId'] as String?,
      email: json['email'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      username: json['username'] as String?,
      className: json['className'] as String?,
      section: json['section'] as String?,
      gender: json['gender'] as String?,
      schoolName: json['schoolName'] as String?,
      teachingSubject: json['teachingSubject'] as String?,
      fatherName: father['name'] as String?,
      fatherEmail: father['email'] as String?,
      fatherMobileNumber: father['mobileNumber'] as String?,
      motherName: mother['name'] as String?,
      motherEmail: mother['email'] as String?,
      motherMobileNumber: mother['mobileNumber'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

class GrowthConnectionData {
  const GrowthConnectionData({
    required this.id,
    required this.fullName,
    required this.role,
    this.accountId,
    this.username,
    this.className,
    this.section,
    this.schoolName,
    this.teachingSubject,
    this.studentName,
    this.noteHeadings = const [],
    this.status = 'connected',
  });

  final String id;
  final String fullName;
  final String role;
  final String? accountId;
  final String? username;
  final String? className;
  final String? section;
  final String? schoolName;
  final String? teachingSubject;
  final String? studentName;
  final List<ConnectionNoteHeading> noteHeadings;
  final String status;

  factory GrowthConnectionData.fromJson(Map<String, dynamic> json) =>
      GrowthConnectionData(
        id: json['id']?.toString() ?? '',
        fullName: json['fullName'] as String? ?? 'Connected account',
        role: json['role'] as String? ?? 'student',
        accountId: json['accountId'] as String?,
        username: json['username'] as String?,
        className: json['className'] as String?,
        section: json['section'] as String?,
        schoolName: json['schoolName'] as String?,
        teachingSubject: json['teachingSubject'] as String?,
        studentName: json['studentName'] as String?,
        noteHeadings: (json['noteHeadings'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ConnectionNoteHeading.fromJson)
            .toList(growable: false),
        status: json['status'] as String? ?? 'suggested',
      );
}

class ConnectionNoteHeading {
  const ConnectionNoteHeading({
    required this.category,
    required this.subheadings,
  });

  final String category;
  final List<String> subheadings;

  factory ConnectionNoteHeading.fromJson(Map<String, dynamic> json) =>
      ConnectionNoteHeading(
        category: json['category'] as String? ?? 'Reflection',
        subheadings: (json['subheadings'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(growable: false),
      );
}

class GrowthConnectionRequestData {
  const GrowthConnectionRequestData({
    required this.id,
    required this.person,
    this.createdAt,
  });

  final String id;
  final GrowthConnectionData person;
  final DateTime? createdAt;

  factory GrowthConnectionRequestData.fromJson(Map<String, dynamic> json) =>
      GrowthConnectionRequestData(
        id: json['id']?.toString() ?? '',
        person: GrowthConnectionData.fromJson(
          json['person'] as Map<String, dynamic>? ?? const {},
        ),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}

class GrowthPeopleResult {
  const GrowthPeopleResult({required this.people, required this.needsSchool});

  final List<GrowthConnectionData> people;
  final bool needsSchool;
}

class GrowthConnectionRequests {
  const GrowthConnectionRequests({
    required this.incoming,
    required this.outgoing,
  });

  final List<GrowthConnectionRequestData> incoming;
  final List<GrowthConnectionRequestData> outgoing;
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
    this.sharedWithParents = false,
  });

  final String id;
  final String category;
  final String text;
  final DateTime createdAt;
  final String? mood;
  final List<String> responses;
  final String customText;
  final List<Map<String, dynamic>> sections;
  final bool sharedWithParents;

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
      sharedWithParents: json['sharedWithParents'] as bool? ?? false,
    );
  }
}

class TeacherStudentContactData {
  const TeacherStudentContactData({this.mobileNumber});
  final String? mobileNumber;

  factory TeacherStudentContactData.fromJson(Map<String, dynamic> json) =>
      TeacherStudentContactData(mobileNumber: json['mobileNumber'] as String?);
}

class TeacherActivityData {
  const TeacherActivityData({
    required this.totalFeedbackEntries,
    required this.studentsSupported,
  });

  final int totalFeedbackEntries;
  final int studentsSupported;

  factory TeacherActivityData.fromJson(Map<String, dynamic> json) =>
      TeacherActivityData(
        totalFeedbackEntries: json['totalFeedbackEntries'] as int? ?? 0,
        studentsSupported: json['studentsSupported'] as int? ?? 0,
      );
}

class TeacherCommunicationData {
  const TeacherCommunicationData({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.channel,
    required this.completed,
    required this.createdAt,
    this.className,
    this.section,
  });

  final String id;
  final String? studentId;
  final String studentName;
  final String channel;
  final bool completed;
  final DateTime? createdAt;
  final String? className;
  final String? section;

  factory TeacherCommunicationData.fromJson(Map<String, dynamic> json) =>
      TeacherCommunicationData(
        id: json['id'] as String? ?? '',
        studentId: json['studentId'] as String?,
        studentName: json['studentName'] as String? ?? 'Student',
        channel: json['channel'] as String? ?? 'message',
        completed: json['completed'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        className: json['className'] as String?,
        section: json['section'] as String?,
      );
}

class TeacherFeedbackActivityData {
  const TeacherFeedbackActivityData({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.section,
    required this.focusArea,
    required this.progress,
    required this.observedBehaviors,
    required this.whatHelped,
    required this.whatWasHard,
    required this.nextStep,
    required this.createdAt,
  });

  final String? studentId;
  final String? studentName;
  final String? className;
  final String? section;
  final String focusArea;
  final String progress;
  final List<String> observedBehaviors;
  final String whatHelped;
  final String whatWasHard;
  final String nextStep;
  final DateTime? createdAt;

  factory TeacherFeedbackActivityData.fromJson(Map<String, dynamic> json) =>
      TeacherFeedbackActivityData(
        studentId: json['studentId'] as String?,
        studentName: json['studentName'] as String?,
        className: json['className'] as String?,
        section: json['section'] as String?,
        focusArea: json['focusArea'] as String? ?? '',
        progress: json['progress'] as String? ?? 'not_sure',
        observedBehaviors:
            (json['observedBehaviors'] as List<dynamic>? ?? const [])
                .whereType<String>()
                .toList(growable: false),
        whatHelped: json['whatHelped'] as String? ?? '',
        whatWasHard: json['whatWasHard'] as String? ?? '',
        nextStep: json['nextStep'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}

class TeacherStudentOverviewData {
  const TeacherStudentOverviewData({
    required this.studentId,
    required this.checkIns,
    required this.improvingCount,
    required this.harderCount,
    this.latestProgress,
    this.latestFocusArea,
    this.latestAt,
  });

  final String studentId;
  final int checkIns;
  final int improvingCount;
  final int harderCount;
  final String? latestProgress;
  final String? latestFocusArea;
  final DateTime? latestAt;

  factory TeacherStudentOverviewData.fromJson(Map<String, dynamic> json) =>
      TeacherStudentOverviewData(
        studentId: json['studentId'] as String? ?? '',
        checkIns: json['checkIns'] as int? ?? 0,
        improvingCount: json['improvingCount'] as int? ?? 0,
        harderCount: json['harderCount'] as int? ?? 0,
        latestProgress: json['latestProgress'] as String?,
        latestFocusArea: json['latestFocusArea'] as String?,
        latestAt: DateTime.tryParse(json['latestAt'] as String? ?? ''),
      );
}

class StudentGrowthSummaryData {
  const StudentGrowthSummaryData({
    required this.totalCheckIns,
    required this.byFocusArea,
    required this.recent,
    this.teacherUpdates = const [],
  });

  final int totalCheckIns;
  final Map<String, dynamic> byFocusArea;
  final List<Map<String, dynamic>> recent;
  final List<TeacherGrowthUpdateData> teacherUpdates;

  factory StudentGrowthSummaryData.fromJson(Map<String, dynamic> json) =>
      StudentGrowthSummaryData(
        totalCheckIns: json['totalCheckIns'] as int? ?? 0,
        byFocusArea: json['byFocusArea'] as Map<String, dynamic>? ?? const {},
        recent: (json['recent'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false),
        teacherUpdates: (json['teacherUpdates'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(TeacherGrowthUpdateData.fromJson)
            .toList(growable: false),
      );
}

class TeacherGrowthUpdateData {
  const TeacherGrowthUpdateData({
    required this.id,
    required this.teacherName,
    required this.focusArea,
    required this.progress,
    required this.observedBehaviors,
    required this.whatHelped,
    required this.whatWasHard,
    required this.nextStep,
    this.createdAt,
  });

  final String id;
  final String teacherName;
  final String focusArea;
  final String progress;
  final List<String> observedBehaviors;
  final String whatHelped;
  final String whatWasHard;
  final String nextStep;
  final DateTime? createdAt;

  factory TeacherGrowthUpdateData.fromJson(Map<String, dynamic> json) =>
      TeacherGrowthUpdateData(
        id: json['id']?.toString() ?? '',
        teacherName: json['teacherName'] as String? ?? 'Connected teacher',
        focusArea: json['focusArea'] as String? ?? '',
        progress: json['progress'] as String? ?? 'not_sure',
        observedBehaviors:
            (json['observedBehaviors'] as List<dynamic>? ?? const [])
                .whereType<String>()
                .toList(growable: false),
        whatHelped: json['whatHelped'] as String? ?? '',
        whatWasHard: json['whatWasHard'] as String? ?? '',
        nextStep: json['nextStep'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}

class JournalNoteViewerData {
  const JournalNoteViewerData({
    required this.id,
    required this.fullName,
    required this.role,
    required this.accountId,
    required this.lastViewedAt,
  });

  final String id;
  final String fullName;
  final String role;
  final String accountId;
  final DateTime? lastViewedAt;

  factory JournalNoteViewerData.fromJson(Map<String, dynamic> json) =>
      JournalNoteViewerData(
        id: json['id']?.toString() ?? '',
        fullName: json['fullName'] as String? ?? 'Connected person',
        role: json['role'] as String? ?? '',
        accountId: json['accountId'] as String? ?? '',
        lastViewedAt: DateTime.tryParse(json['lastViewedAt'] as String? ?? ''),
      );
}

class JournalNoteDetailData {
  const JournalNoteDetailData({
    required this.note,
    required this.viewCount,
    required this.viewers,
  });

  final JournalNoteData note;
  final int viewCount;
  final List<JournalNoteViewerData> viewers;
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

class ReflectionCountData {
  const ReflectionCountData({required this.label, required this.count});
  final String label;
  final int count;

  factory ReflectionCountData.fromJson(
    Map<String, dynamic> json, {
    required String labelKey,
  }) => ReflectionCountData(
    label: json[labelKey] as String? ?? '',
    count: (json['count'] as num?)?.toInt() ?? 0,
  );
}

class MoodTrendPointData {
  const MoodTrendPointData({
    required this.date,
    required this.average,
    required this.entries,
  });
  final DateTime date;
  final double average;
  final int entries;

  factory MoodTrendPointData.fromJson(Map<String, dynamic> json) =>
      MoodTrendPointData(
        date:
            DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        average: (json['average'] as num?)?.toDouble() ?? 0,
        entries: (json['entries'] as num?)?.toInt() ?? 0,
      );
}

class StudentReflectionOverviewData {
  const StudentReflectionOverviewData({
    required this.days,
    required this.totalReflections,
    required this.moodCounts,
    required this.trend,
    required this.categoryCounts,
    required this.feelings,
    required this.autoOverview,
  });

  final String days;
  final int totalReflections;
  final Map<String, int> moodCounts;
  final List<MoodTrendPointData> trend;
  final List<ReflectionCountData> categoryCounts;
  final List<ReflectionCountData> feelings;
  final String autoOverview;

  factory StudentReflectionOverviewData.fromJson(Map<String, dynamic> json) {
    final rawMoods = json['moodCounts'] as Map<String, dynamic>? ?? const {};
    return StudentReflectionOverviewData(
      days: json['days'] as String? ?? '3',
      totalReflections: (json['totalReflections'] as num?)?.toInt() ?? 0,
      moodCounts: rawMoods.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      trend: (json['trend'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MoodTrendPointData.fromJson)
          .toList(growable: false),
      categoryCounts: (json['categoryCounts'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (value) =>
                ReflectionCountData.fromJson(value, labelKey: 'category'),
          )
          .toList(growable: false),
      feelings: (json['feelings'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (value) => ReflectionCountData.fromJson(value, labelKey: 'feeling'),
          )
          .toList(growable: false),
      autoOverview: json['autoOverview'] as String? ?? '',
    );
  }
}

class GrowthGoalData {
  const GrowthGoalData({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.title,
    required this.category,
    required this.currentProgress,
    required this.status,
    required this.startDate,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.reviewDate,
    this.currentValue,
    this.targetValue,
    this.teacherNote = '',
    this.completedAt,
    this.history = const [],
  });

  final String id;
  final String studentId;
  final String teacherId;
  final String title;
  final String category;
  final String description;
  final DateTime startDate;
  final DateTime? reviewDate;
  final int currentProgress;
  final num? currentValue;
  final num? targetValue;
  final String teacherNote;
  final String status;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<GrowthGoalProgressData> history;

  factory GrowthGoalData.fromJson(Map<String, dynamic> json) => GrowthGoalData(
    id: json['id']?.toString() ?? '',
    studentId: json['studentId']?.toString() ?? '',
    teacherId: json['teacherId']?.toString() ?? '',
    title: json['title'] as String? ?? 'Growth goal',
    category: json['category'] as String? ?? 'Other',
    description: json['description'] as String? ?? '',
    startDate:
        DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime.now(),
    reviewDate: DateTime.tryParse(json['reviewDate'] as String? ?? ''),
    currentProgress: json['currentProgress'] as int? ?? 0,
    currentValue: json['currentValue'] as num?,
    targetValue: json['targetValue'] as num?,
    teacherNote: json['teacherNote'] as String? ?? '',
    status: json['status'] as String? ?? 'active',
    completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    history: (json['history'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(GrowthGoalProgressData.fromJson)
        .toList(growable: false),
  );
}

class GrowthGoalProgressData {
  const GrowthGoalProgressData({
    required this.id,
    required this.goalId,
    required this.studentId,
    required this.teacherId,
    required this.progress,
    required this.createdAt,
    this.note = '',
  });

  final String id;
  final String goalId;
  final String studentId;
  final String teacherId;
  final int progress;
  final String note;
  final DateTime createdAt;

  factory GrowthGoalProgressData.fromJson(Map<String, dynamic> json) =>
      GrowthGoalProgressData(
        id: json['id']?.toString() ?? '',
        goalId: json['goalId']?.toString() ?? '',
        studentId: json['studentId']?.toString() ?? '',
        teacherId: json['teacherId']?.toString() ?? '',
        progress: json['progress'] as int? ?? 0,
        note: json['note'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
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

  static Future<http.Response> _sendLoginRequest({
    required String identifier,
    required String password,
    String? role,
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
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
        if (attempt == 0 &&
            const {502, 503, 504}.contains(response.statusCode)) {
          await Future<void>.delayed(const Duration(milliseconds: 350));
          continue;
        }
        return response;
      } on SocketException {
        if (attempt == 1) rethrow;
      } on http.ClientException {
        if (attempt == 1) rethrow;
      } on TimeoutException {
        if (attempt == 1) rethrow;
      }
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    throw const AuthApiException('Login request could not be completed.');
  }

  static Future<List<GrowthConnectionData>> getGrowthConnections({
    required String token,
    required String role,
  }) async {
    final path = switch (role) {
      'teacher' => 'teacher/growth/connections',
      'parent' => 'parent/growth/connections',
      _ => 'student/growth/connections',
    };
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/auth/$path'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? 'Connected people could not be loaded.',
          statusCode: response.statusCode,
        );
      }
      final people = body['data']?['connections'] as List<dynamic>? ?? const [];
      return people
          .whereType<Map<String, dynamic>>()
          .map(GrowthConnectionData.fromJson)
          .toList(growable: false);
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException('Cannot connect to load connected people.');
    } on http.ClientException {
      throw const AuthApiException('Cannot connect to load connected people.');
    } on TimeoutException {
      throw const AuthApiException('Loading connected people timed out.');
    } on FormatException {
      throw const AuthApiException(
        'The server returned invalid connection data.',
      );
    }
  }

  static String _connectionRolePath(String role) => switch (role) {
    'teacher' => 'teacher/growth',
    'parent' => 'parent/growth',
    _ => 'student/growth',
  };

  static Future<GrowthPeopleResult> searchGrowthPeople({
    required String token,
    required String role,
    String search = '',
  }) async {
    try {
      final uri =
          Uri.parse('$_baseUrl/auth/${_connectionRolePath(role)}/people')
              .replace(
                queryParameters: search.trim().isEmpty
                    ? null
                    : {'search': search.trim()},
              );
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? 'People could not be loaded.',
        );
      }
      final data = body['data'] as Map<String, dynamic>? ?? const {};
      final rows = data['people'] as List<dynamic>? ?? const [];
      return GrowthPeopleResult(
        people: rows
            .whereType<Map<String, dynamic>>()
            .map(GrowthConnectionData.fromJson)
            .toList(growable: false),
        needsSchool: data['needsSchool'] as bool? ?? false,
      );
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException('Cannot connect to search for people.');
    } on http.ClientException {
      throw const AuthApiException('Cannot connect to search for people.');
    } on TimeoutException {
      throw const AuthApiException('Searching for people timed out.');
    } on FormatException {
      throw const AuthApiException('The server returned invalid people data.');
    }
  }

  static Future<void> sendGrowthConnectionRequest({
    required String token,
    required String role,
    required String identity,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/auth/${_connectionRolePath(role)}/connection-requests',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'identity': identity}),
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? 'The request could not be sent.',
        );
      }
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException('Cannot connect to send the request.');
    } on http.ClientException {
      throw const AuthApiException('Cannot connect to send the request.');
    } on TimeoutException {
      throw const AuthApiException('Sending the request timed out.');
    } on FormatException {
      throw const AuthApiException('The server returned an invalid response.');
    }
  }

  static Future<GrowthConnectionRequests> getGrowthConnectionRequests({
    required String token,
    required String role,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl/auth/${_connectionRolePath(role)}/connection-requests',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? 'Requests could not be loaded.',
        );
      }
      final data = body['data'] as Map<String, dynamic>? ?? const {};
      List<GrowthConnectionRequestData> parse(String key) =>
          (data[key] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(GrowthConnectionRequestData.fromJson)
              .toList(growable: false);
      return GrowthConnectionRequests(
        incoming: parse('incoming'),
        outgoing: parse('outgoing'),
      );
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException('Cannot connect to load requests.');
    } on http.ClientException {
      throw const AuthApiException('Cannot connect to load requests.');
    } on TimeoutException {
      throw const AuthApiException('Loading requests timed out.');
    } on FormatException {
      throw const AuthApiException('The server returned invalid request data.');
    }
  }

  static Future<void> respondToGrowthConnectionRequest({
    required String token,
    required String role,
    required String requestId,
    required String decision,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/auth/${_connectionRolePath(role)}/connection-requests/$requestId/respond',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'decision': decision}),
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? 'The request could not be updated.',
        );
      }
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException('Cannot connect to update the request.');
    } on http.ClientException {
      throw const AuthApiException('Cannot connect to update the request.');
    } on TimeoutException {
      throw const AuthApiException('Updating the request timed out.');
    } on FormatException {
      throw const AuthApiException('The server returned an invalid response.');
    }
  }

  static Future<String> createParentInvite(String token) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/student/growth/connect/parent/invite'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? 'A parent invite could not be created.',
        );
      }
      final code = body['data']?['inviteCode'] as String?;
      if (code == null || code.isEmpty) {
        throw const AuthApiException(
          'The parent invite code was not returned.',
        );
      }
      return code;
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException('Cannot connect to the server.');
    } on http.ClientException {
      throw const AuthApiException('Cannot connect to the server.');
    } on TimeoutException {
      throw const AuthApiException('Creating the parent invite timed out.');
    } on FormatException {
      throw const AuthApiException('The server returned an invalid invite.');
    }
  }

  static Future<void> connectParentWithCode({
    required String token,
    required String inviteCode,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/parent/connect/student'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'inviteCode': inviteCode}),
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? 'The student could not be connected.',
        );
      }
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException('Cannot connect to the server.');
    } on http.ClientException {
      throw const AuthApiException('Cannot connect to the server.');
    } on TimeoutException {
      throw const AuthApiException('Connecting the student timed out.');
    } on FormatException {
      throw const AuthApiException('The server returned an invalid response.');
    }
  }

  static Future<UserProfileData> getProfile(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/auth/me'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? 'Your profile could not be loaded.',
          statusCode: response.statusCode,
        );
      }
      final user = body['data']?['user'] as Map<String, dynamic>?;
      if (user == null) {
        throw const AuthApiException('Your profile details were not returned.');
      }
      return UserProfileData.fromJson(user);
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException('Cannot connect to load your profile.');
    } on http.ClientException {
      throw const AuthApiException('Cannot connect to load your profile.');
    } on TimeoutException {
      throw const AuthApiException('Loading your profile timed out.');
    } on FormatException {
      throw const AuthApiException('The server returned invalid profile data.');
    }
  }

  static Future<UserProfileData> updateProfile({
    required String token,
    required Map<String, Object?> profile,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$_baseUrl/auth/me'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(profile),
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? 'Your profile could not be updated.',
        );
      }
      final user = body['data']?['user'] as Map<String, dynamic>?;
      if (user == null) {
        throw const AuthApiException('The updated profile was not returned.');
      }
      return UserProfileData.fromJson(user);
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException('Cannot connect to update your profile.');
    } on http.ClientException {
      throw const AuthApiException('Cannot connect to update your profile.');
    } on TimeoutException {
      throw const AuthApiException('Updating your profile timed out.');
    } on FormatException {
      throw const AuthApiException('The server returned invalid profile data.');
    }
  }

  static Future<String> previewAccountId(String role) async {
    final accountType = switch (role) {
      'teacher' => 'Teacher',
      'parent' => 'Parent',
      _ => 'Student',
    };
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
      final accountType = switch (role) {
        'teacher' => 'Teacher',
        'parent' => 'Parent',
        _ => 'Student',
      };
      final accountId = user is Map<String, dynamic>
          ? (role == 'teacher'
                    ? user['teacherId']
                    : role == 'parent'
                    ? user['parentId']
                    : user['studentId'])
                as String?
          : null;
      if (accountId == null || accountId.isEmpty) {
        throw AuthApiException('$accountType ID could not be generated.');
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
      final response = await _sendLoginRequest(
        identifier: identifier,
        password: password,
        role: role,
      );

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
        parentId: user['parentId'] as String?,
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

  static Future<TeacherActivityData> getTeacherActivitySummary(
    String token,
  ) async {
    final data = await _getGrowthData(
      token: token,
      path: 'teacher/activity/summary',
      fallbackMessage: 'Teacher activity could not be loaded.',
    );
    return TeacherActivityData.fromJson(data);
  }

  static Future<List<TeacherFeedbackActivityData>> getTeacherActivityHistory(
    String token,
  ) async {
    final data = await _getGrowthData(
      token: token,
      path: 'teacher/activity/history',
      fallbackMessage: 'Feedback history could not be loaded.',
    );
    return (data['activities'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TeacherFeedbackActivityData.fromJson)
        .toList(growable: false);
  }

  static Future<List<TeacherStudentOverviewData>> getTeacherClassOverview(
    String token,
  ) async {
    final data = await _getGrowthData(
      token: token,
      path: 'teacher/class/overview',
      fallbackMessage: 'Class progress could not be loaded.',
    );
    return (data['students'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TeacherStudentOverviewData.fromJson)
        .toList(growable: false);
  }

  static Future<StudentGrowthSummaryData> getTeacherStudentGrowthSummary({
    required String token,
    required String studentId,
  }) async {
    final data = await _getGrowthData(
      token: token,
      path: 'teacher/students/$studentId/growth-summary',
      fallbackMessage: 'Student progress could not be loaded.',
    );
    return StudentGrowthSummaryData.fromJson(data);
  }

  static Future<StudentGrowthSummaryData> getParentStudentGrowthSummary({
    required String token,
    required String studentId,
  }) async {
    final data = await _getGrowthData(
      token: token,
      path: 'parent/students/$studentId/growth-summary',
      fallbackMessage: 'Student progress could not be loaded.',
    );
    return StudentGrowthSummaryData.fromJson(data);
  }

  static Future<List<GrowthGoalData>> getParentStudentGoals({
    required String token,
    required String studentId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/auth/parent/students/$studentId/goals'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? 'Student goals could not be loaded.',
        );
      }
      return (body['data']?['goals'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(GrowthGoalData.fromJson)
          .toList(growable: false);
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException('Cannot connect to load student goals.');
    } on http.ClientException {
      throw const AuthApiException('Cannot connect to load student goals.');
    } on TimeoutException {
      throw const AuthApiException('Loading student goals timed out.');
    } on FormatException {
      throw const AuthApiException('The server returned invalid goal data.');
    }
  }

  static Future<List<GrowthConnectionData>> getParentConnectedTeachers({
    required String token,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/auth/parent/growth/teachers'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ??
              'Connected teachers could not be loaded.',
        );
      }
      return (body['data']?['teachers'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(GrowthConnectionData.fromJson)
          .toList(growable: false);
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException(
        'Cannot connect to load connected teachers.',
      );
    } on http.ClientException {
      throw const AuthApiException(
        'Cannot connect to load connected teachers.',
      );
    } on TimeoutException {
      throw const AuthApiException('Loading connected teachers timed out.');
    } on FormatException {
      throw const AuthApiException('The server returned invalid teacher data.');
    }
  }

  static Future<List<GrowthGoalData>> getTeacherStudentGoals({
    required String token,
    required String studentId,
    String? status,
  }) async {
    final data = await _teacherGoalRequest(
      token: token,
      studentId: studentId,
      status: status,
    );
    return (data['goals'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(GrowthGoalData.fromJson)
        .toList(growable: false);
  }

  static Future<GrowthGoalData> createTeacherStudentGoal({
    required String token,
    required String studentId,
    required String title,
    required String category,
    required String description,
    required String teacherNote,
    DateTime? startDate,
    DateTime? reviewDate,
    num? currentValue,
    num? targetValue,
  }) async {
    final data = await _teacherGoalRequest(
      token: token,
      studentId: studentId,
      method: 'POST',
      body: {
        'title': title,
        'category': category,
        'description': description,
        'teacherNote': teacherNote,
        'startDate': ?startDate?.toUtc().toIso8601String(),
        'reviewDate': ?reviewDate?.toUtc().toIso8601String(),
        'currentValue': ?currentValue,
        'targetValue': ?targetValue,
      },
    );
    return GrowthGoalData.fromJson(
      data['goal'] as Map<String, dynamic>? ?? const {},
    );
  }

  static Future<GrowthGoalData> getTeacherStudentGoal({
    required String token,
    required String studentId,
    required String goalId,
  }) async {
    final data = await _teacherGoalRequest(
      token: token,
      studentId: studentId,
      goalId: goalId,
    );
    return GrowthGoalData.fromJson(
      data['goal'] as Map<String, dynamic>? ?? const {},
    );
  }

  static Future<void> updateTeacherStudentGoalProgress({
    required String token,
    required String studentId,
    required String goalId,
    required int progress,
    required String note,
    num? currentValue,
  }) async {
    await _teacherGoalRequest(
      token: token,
      studentId: studentId,
      goalId: goalId,
      leaf: 'progress',
      method: 'PATCH',
      body: {'progress': progress, 'note': note, 'currentValue': ?currentValue},
    );
  }

  static Future<GrowthGoalData> completeTeacherStudentGoal({
    required String token,
    required String studentId,
    required String goalId,
  }) async {
    final data = await _teacherGoalRequest(
      token: token,
      studentId: studentId,
      goalId: goalId,
      leaf: 'complete',
      method: 'POST',
    );
    return GrowthGoalData.fromJson(
      data['goal'] as Map<String, dynamic>? ?? const {},
    );
  }

  static Future<Map<String, dynamic>> _teacherGoalRequest({
    required String token,
    required String studentId,
    String? goalId,
    String? leaf,
    String method = 'GET',
    String? status,
    Map<String, Object?>? body,
  }) async {
    try {
      final segments = [
        '$_baseUrl/auth/teacher/students/${Uri.encodeComponent(studentId)}/goals',
        if (goalId != null) Uri.encodeComponent(goalId),
        if (leaf != null) Uri.encodeComponent(leaf),
      ];
      final query = status == null ? null : {'status': status};
      final uri = Uri.parse(segments.join('/')).replace(queryParameters: query);
      final headers = {
        'Authorization': 'Bearer $token',
        if (body != null) 'Content-Type': 'application/json',
      };
      final response = switch (method) {
        'POST' =>
          await http
              .post(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 10)),
        'PATCH' =>
          await http
              .patch(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 10)),
        _ =>
          await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 10)),
      };
      final decoded = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          decoded['message'] as String? ?? 'Goals could not be loaded.',
          statusCode: response.statusCode,
        );
      }
      return decoded['data'] as Map<String, dynamic>? ?? const {};
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException('Cannot connect to load or save goals.');
    } on http.ClientException {
      throw const AuthApiException('Cannot connect to load or save goals.');
    } on TimeoutException {
      throw const AuthApiException(
        'The goal request timed out. Please try again.',
      );
    } on FormatException {
      throw const AuthApiException('The server returned invalid goal data.');
    }
  }

  static Future<JournalNotesPage> getTeacherStudentJournalNotes({
    required String token,
    required String studentId,
    String? cursor,
    String? category,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final query = <String, String>{'limit': '20'};
      if (cursor != null && cursor.isNotEmpty) query['cursor'] = cursor;
      if (category != null && category.isNotEmpty) query['category'] = category;
      if (from != null) query['from'] = from.toUtc().toIso8601String();
      if (to != null) query['to'] = to.toUtc().toIso8601String();
      final uri = Uri.parse(
        '$_baseUrl/auth/teacher/students/${Uri.encodeComponent(studentId)}/reflections',
      ).replace(queryParameters: query);
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ??
              'Student reflections could not be loaded.',
          statusCode: response.statusCode,
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
        'Cannot connect to load student reflections.',
      );
    } on http.ClientException {
      throw const AuthApiException(
        'Cannot connect to load student reflections.',
      );
    } on TimeoutException {
      throw const AuthApiException('Loading student reflections timed out.');
    } on FormatException {
      throw const AuthApiException(
        'The server returned invalid reflection data.',
      );
    }
  }

  static Future<List<TeacherCommunicationData>> getTeacherCommunications(
    String token,
  ) async {
    final data = await _getGrowthData(
      token: token,
      path: 'teacher/communications',
      fallbackMessage: 'Communication history could not be loaded.',
    );
    return (data['communications'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TeacherCommunicationData.fromJson)
        .toList(growable: false);
  }

  static Future<void> createTeacherCommunication({
    required String token,
    required String studentId,
    required String channel,
    required bool completed,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/auth/teacher/students/${Uri.encodeComponent(studentId)}/communications',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'channel': channel, 'completed': completed}),
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ??
              'Communication history could not be saved.',
          statusCode: response.statusCode,
        );
      }
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException(
        'Cannot connect to save communication history.',
      );
    } on http.ClientException {
      throw const AuthApiException(
        'Cannot connect to save communication history.',
      );
    } on TimeoutException {
      throw const AuthApiException('Saving communication history timed out.');
    } on FormatException {
      throw const AuthApiException('The server returned an invalid response.');
    }
  }

  static Future<TeacherStudentContactData> getTeacherStudentContact({
    required String token,
    required String studentId,
  }) async {
    final data = await _getGrowthData(
      token: token,
      path: 'teacher/students/${Uri.encodeComponent(studentId)}/contact',
      fallbackMessage: 'Student contact details could not be loaded.',
    );
    return TeacherStudentContactData.fromJson(data);
  }

  static Future<StudentReflectionOverviewData>
  getTeacherStudentReflectionOverview({
    required String token,
    required String studentId,
    int? days,
  }) async {
    try {
      final range = days?.toString() ?? 'all';
      final uri = Uri.parse(
        '$_baseUrl/auth/teacher/students/${Uri.encodeComponent(studentId)}/reflection-overview',
      ).replace(queryParameters: {'days': range});
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ??
              'Student reflection overview could not be loaded.',
          statusCode: response.statusCode,
        );
      }
      return StudentReflectionOverviewData.fromJson(
        body['data'] as Map<String, dynamic>? ?? const {},
      );
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException(
        'Cannot connect to load the reflection overview.',
      );
    } on http.ClientException {
      throw const AuthApiException(
        'Cannot connect to load the reflection overview.',
      );
    } on TimeoutException {
      throw const AuthApiException(
        'Loading the reflection overview timed out.',
      );
    } on FormatException {
      throw const AuthApiException(
        'The server returned invalid reflection overview data.',
      );
    }
  }

  static Future<void> submitTeacherStudentFeedback({
    required String token,
    required String studentId,
    required String focusArea,
    required String progress,
    List<String> observedBehaviors = const [],
    String whatHelped = '',
    String whatWasHard = '',
    String nextStep = '',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/auth/teacher/students/$studentId/growth-feedback',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'focusArea': focusArea,
              'progress': progress,
              'observedBehaviors': observedBehaviors,
              'whatHelped': whatHelped,
              'whatWasHard': whatWasHard,
              'nextStep': nextStep,
            }),
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? 'Feedback could not be saved.',
        );
      }
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException('Cannot connect to save feedback.');
    } on http.ClientException {
      throw const AuthApiException('Cannot connect to save feedback.');
    } on TimeoutException {
      throw const AuthApiException('Saving feedback timed out.');
    } on FormatException {
      throw const AuthApiException('The server returned an invalid response.');
    }
  }

  static Future<Map<String, dynamic>> _getGrowthData({
    required String token,
    required String path,
    required String fallbackMessage,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/auth/$path'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? fallbackMessage,
          statusCode: response.statusCode,
        );
      }
      return body['data'] as Map<String, dynamic>? ?? const {};
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw AuthApiException('Cannot connect to load this information.');
    } on http.ClientException {
      throw AuthApiException('Cannot connect to load this information.');
    } on TimeoutException {
      throw AuthApiException('Loading this information timed out.');
    } on FormatException {
      throw AuthApiException(fallbackMessage);
    }
  }

  static Future<JournalNoteDetailData> getJournalNoteDetail({
    required String token,
    required String noteId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/auth/student/journal/notes/$noteId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? 'This note could not be loaded.',
        );
      }
      final data = body['data'] as Map<String, dynamic>? ?? const {};
      final views = data['views'] as Map<String, dynamic>? ?? const {};
      final note = data['note'] as Map<String, dynamic>? ?? const {};
      return JournalNoteDetailData(
        note: JournalNoteData.fromJson(note),
        viewCount: views['count'] as int? ?? 0,
        viewers: (views['viewers'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(JournalNoteViewerData.fromJson)
            .toList(growable: false),
      );
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException('Cannot connect to load this note.');
    } on http.ClientException {
      throw const AuthApiException('Cannot connect to load this note.');
    } on TimeoutException {
      throw const AuthApiException('Loading the note timed out.');
    } on FormatException {
      throw const AuthApiException('The server returned invalid note data.');
    }
  }

  static Future<JournalNotesPage> getConnectedStudentJournalNotes({
    required String token,
    required String studentId,
    String? cursor,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/auth/student/growth/connections/$studentId/journal-notes',
      ).replace(queryParameters: {'limit': '20', 'cursor': ?cursor});
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ??
              'This student’s reflections could not be loaded.',
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
        'Cannot connect to load this student’s reflections.',
      );
    } on http.ClientException {
      throw const AuthApiException(
        'Cannot connect to load this student’s reflections.',
      );
    } on TimeoutException {
      throw const AuthApiException('Loading reflections timed out.');
    } on FormatException {
      throw const AuthApiException(
        'The server returned invalid reflection data.',
      );
    }
  }

  static Future<JournalNotesPage> getParentStudentJournalNotes({
    required String token,
    required String studentId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/auth/parent/students/$studentId/reflections'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? 'Shared notes could not be loaded.',
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
      throw const AuthApiException('Cannot connect to load shared notes.');
    } on http.ClientException {
      throw const AuthApiException('Cannot connect to load shared notes.');
    } on TimeoutException {
      throw const AuthApiException('Loading shared notes timed out.');
    } on FormatException {
      throw const AuthApiException(
        'The server returned invalid reflection data.',
      );
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
    bool sharedWithParents = false,
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
              'sharedWithParents': sharedWithParents,
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

  static Future<AppNotificationsData> getNotifications(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/auth/notifications'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? 'Notifications could not be loaded.',
          statusCode: response.statusCode,
        );
      }
      final data = body['data'] as Map<String, dynamic>? ?? const {};
      final raw = data['notifications'] as List<dynamic>? ?? const [];
      return AppNotificationsData(
        notifications: raw
            .whereType<Map<String, dynamic>>()
            .map(AppNotificationData.fromJson)
            .toList(growable: false),
        unreadCount: data['unreadCount'] as int? ?? 0,
      );
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException('Cannot connect to load notifications.');
    } on http.ClientException {
      throw const AuthApiException('Cannot connect to load notifications.');
    } on TimeoutException {
      throw const AuthApiException('Loading notifications timed out.');
    } on FormatException {
      throw const AuthApiException(
        'The server returned invalid notifications.',
      );
    }
  }

  static Future<void> markNotificationRead({
    required String token,
    required String notificationId,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$_baseUrl/auth/notifications/$notificationId/read'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? 'Notification could not be updated.',
          statusCode: response.statusCode,
        );
      }
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException(
        'Cannot connect to update the notification.',
      );
    } on http.ClientException {
      throw const AuthApiException(
        'Cannot connect to update the notification.',
      );
    } on TimeoutException {
      throw const AuthApiException('Updating the notification timed out.');
    } on FormatException {
      throw const AuthApiException('The server returned an invalid response.');
    }
  }

  static Future<void> markAllNotificationsRead(String token) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$_baseUrl/auth/notifications/read-all'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          body['message'] as String? ?? 'Notifications could not be updated.',
          statusCode: response.statusCode,
        );
      }
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException('Cannot connect to update notifications.');
    } on http.ClientException {
      throw const AuthApiException('Cannot connect to update notifications.');
    } on TimeoutException {
      throw const AuthApiException('Updating notifications timed out.');
    } on FormatException {
      throw const AuthApiException('The server returned an invalid response.');
    }
  }

  static Map<String, dynamic> _decodeBody(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('Expected a JSON object');
  }
}

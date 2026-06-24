import 'package:dio/dio.dart';
import 'package:dipl/features/courses/presentation/models/course_models.dart';
import 'package:dipl/features/personalization/data/placement_test_models.dart';
import 'package:dipl/services/auth_service.dart';

class UserApiService {
  UserApiService._()
    : _dio = Dio(
        BaseOptions(
          baseUrl: const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'https://enesai-backend.onrender.com',
          ),
          connectTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 45),
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );

  static final UserApiService instance = UserApiService._();

  final Dio _dio;

  Future<UserProfile> getMyProfile() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/users/me',
        options: await _authorizedOptions(),
      );
      return UserProfile.fromJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw UserApiException(_extractErrorMessage(error));
    }
  }

  Future<UserProfile> updateMyProfile({
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? languageLevel,
    String? goalType,
  }) async {
    try {
      final Response<dynamic> response = await _dio.put<dynamic>(
        '/api/v1/users/me',
        data: <String, dynamic>{
          if ((firstName ?? '').trim().isNotEmpty)
            'firstName': firstName!.trim(),
          if ((lastName ?? '').trim().isNotEmpty) 'lastName': lastName!.trim(),
          if ((avatarUrl ?? '').trim().isNotEmpty)
            'avatarUrl': avatarUrl!.trim(),
          if ((languageLevel ?? '').trim().isNotEmpty)
            'languageLevel': languageLevel!.trim().toUpperCase(),
          if ((goalType ?? '').trim().isNotEmpty)
            'goalType': goalType!.trim().toUpperCase(),
        },
        options: await _authorizedOptions(),
      );
      return UserProfile.fromJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw UserApiException(_extractErrorMessage(error));
    }
  }

  Future<UserAnalytics> getMyAnalytics() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/analytics/me',
        options: await _authorizedOptions(),
      );
      return UserAnalytics.fromJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw UserApiException(_extractErrorMessage(error));
    }
  }

  Future<UserStats> getMyStats() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/stats',
        options: await _authorizedOptions(),
      );
      return UserStats.fromJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw UserApiException(_extractErrorMessage(error));
    }
  }

  Future<List<AchievementInfo>> getAchievements() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/achievements',
        options: await _authorizedOptions(),
      );
      return _extractList(response.data)
          .map((dynamic item) => AchievementInfo.fromJson(_asMap(item)))
          .where((AchievementInfo achievement) => achievement.id.isNotEmpty)
          .toList();
    } on DioException catch (error) {
      throw UserApiException(_extractErrorMessage(error));
    }
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/leaderboard',
        options: await _authorizedOptions(),
      );
      return _extractList(
        response.data,
      ).map((dynamic item) => LeaderboardEntry.fromJson(_asMap(item))).toList();
    } on DioException catch (error) {
      throw UserApiException(_extractErrorMessage(error));
    }
  }

  Future<List<CertificateInfo>> getMyCertificates() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/certificates/my',
        options: await _authorizedOptions(),
      );
      return _extractList(response.data)
          .map((dynamic item) => CertificateInfo.fromJson(_asMap(item)))
          .where((CertificateInfo certificate) => certificate.id.isNotEmpty)
          .toList();
    } on DioException catch (error) {
      throw UserApiException(_extractErrorMessage(error));
    }
  }

  Future<CertificateInfo> issueCertificate(String courseId) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/v1/certificates',
        data: <String, dynamic>{'courseId': courseId},
        options: await _authorizedOptions(),
      );
      return CertificateInfo.fromJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw UserApiException(_extractErrorMessage(error));
    }
  }

  Future<CertificateInfo> getCertificate(String certificateId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/certificates/$certificateId',
        options: await _authorizedOptions(),
      );
      return CertificateInfo.fromJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw UserApiException(_extractErrorMessage(error));
    }
  }

  Future<CertificateVerifyInfo> verifyCertificate(
    String verificationCode,
  ) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/certificates/verify/$verificationCode',
      );
      return CertificateVerifyInfo.fromJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw UserApiException(_extractErrorMessage(error));
    }
  }

  Future<CertificateInfo> revokeCertificate(String certificateId) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/v1/certificates/$certificateId/revoke',
        options: await _authorizedOptions(),
      );
      return CertificateInfo.fromJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw UserApiException(_extractErrorMessage(error));
    }
  }

  Future<CertificateInfo> restoreCertificate(String certificateId) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/v1/certificates/$certificateId/restore',
        options: await _authorizedOptions(),
      );
      return CertificateInfo.fromJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw UserApiException(_extractErrorMessage(error));
    }
  }

  Future<OnboardingInfo> completeOnboarding({
    required String goalType,
    String? selectedLevel,
    bool skipTest = false,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/v1/onboarding/complete',
        data: <String, dynamic>{
          'goalType': goalType.trim().toUpperCase(),
          'skipTest': skipTest,
          if ((selectedLevel ?? '').trim().isNotEmpty)
            'selectedLevel': selectedLevel!.trim().toUpperCase(),
        },
        options: await _authorizedOptions(),
      );
      return OnboardingInfo.fromJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw UserApiException(_extractErrorMessage(error));
    }
  }

  Future<OnboardingInfo> getRecommendations() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/onboarding/recommendations',
        options: await _authorizedOptions(),
      );
      return OnboardingInfo.fromJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw UserApiException(_extractErrorMessage(error));
    }
  }

  Future<PlacementTestResult> getMyPlacementResult() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/placement-test/result',
        options: await _authorizedOptions(),
      );
      return PlacementTestResult.fromJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw UserApiException(_extractErrorMessage(error));
    }
  }

  Future<Options> _authorizedOptions() async {
    final String? accessToken = await AuthService.instance.getAccessToken();
    return Options(
      headers: <String, dynamic>{
        if ((accessToken ?? '').trim().isNotEmpty)
          'Authorization': 'Bearer ${accessToken!.trim()}',
      },
    );
  }

  Map<String, dynamic> _extractMap(dynamic payload) {
    final Map<String, dynamic> root = _asMap(payload);
    final dynamic data = root.containsKey('data') ? root['data'] : payload;
    return _asMap(data);
  }

  List<dynamic> _extractList(dynamic payload) {
    final dynamic data = _asMap(payload).containsKey('data')
        ? _asMap(payload)['data']
        : payload;
    if (data is List<dynamic>) return data;
    final Map<String, dynamic> map = _asMap(data);
    if (map['content'] is List<dynamic>) return map['content'] as List<dynamic>;
    return const <dynamic>[];
  }

  Map<String, dynamic> _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }

  String _extractErrorMessage(DioException error) {
    final dynamic responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final dynamic message = responseData['message'];
      if (message is String && message.trim().isNotEmpty) return message.trim();
    }
    if (error.message != null && error.message!.trim().isNotEmpty) {
      return error.message!.trim();
    }
    return 'Request failed';
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.avatarUrl = '',
    this.languageLevel = '',
    this.goalType = '',
    this.onboardingCompleted = false,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String avatarUrl;
  final String role;
  final String languageLevel;
  final String goalType;
  final bool onboardingCompleted;

  String get fullName {
    final String name = <String>[
      firstName,
      lastName,
    ].where((String part) => part.trim().isNotEmpty).join(' ').trim();
    return name.isEmpty ? email : name;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: _asString(json['id']),
      email: _asString(json['email']),
      firstName: _asString(json['firstName']),
      lastName: _asString(json['lastName']),
      avatarUrl: _asString(json['avatarUrl']),
      role: _asString(json['role']),
      languageLevel: _asString(json['languageLevel']),
      goalType: _asString(json['goalType']),
      onboardingCompleted: json['onboardingCompleted'] == true,
    );
  }
}

class UserAnalytics {
  const UserAnalytics({
    required this.xp,
    required this.level,
    required this.xpToNextLevel,
    required this.streakDays,
    required this.coursesEnrolled,
    required this.coursesCompleted,
    required this.lessonsCompleted,
    required this.testsPassed,
    required this.totalWords,
    required this.learnedWords,
    required this.certificatesEarned,
    required this.activeCourses,
    this.leaderboardRank = 0,
  });

  final int xp;
  final int level;
  final int xpToNextLevel;
  final int streakDays;
  final int leaderboardRank;
  final int coursesEnrolled;
  final int coursesCompleted;
  final int lessonsCompleted;
  final int testsPassed;
  final int totalWords;
  final int learnedWords;
  final int certificatesEarned;
  final List<UserCourseProgress> activeCourses;

  factory UserAnalytics.fromJson(Map<String, dynamic> json) {
    final List<dynamic> activeCourses = json['activeCourses'] is List<dynamic>
        ? json['activeCourses'] as List<dynamic>
        : const <dynamic>[];
    return UserAnalytics(
      xp: _asInt(json['xp']),
      level: _asInt(json['level']),
      xpToNextLevel: _asInt(json['xpToNextLevel']),
      streakDays: _asInt(json['streakDays']),
      leaderboardRank: _asInt(json['leaderboardRank']),
      coursesEnrolled: _asInt(json['coursesEnrolled']),
      coursesCompleted: _asInt(json['coursesCompleted']),
      lessonsCompleted: _asInt(json['lessonsCompleted']),
      testsPassed: _asInt(json['testsPassed']),
      totalWords: _asInt(json['totalWords']),
      learnedWords: _asInt(json['learnedWords']),
      certificatesEarned: _asInt(json['certificatesEarned']),
      activeCourses: activeCourses
          .map((dynamic item) => UserCourseProgress.fromJson(_asMap(item)))
          .where((UserCourseProgress course) => course.courseId.isNotEmpty)
          .toList(),
    );
  }
}

class UserStats {
  const UserStats({
    required this.xp,
    required this.level,
    required this.xpToNextLevel,
    required this.xpForCurrentLevel,
    required this.streakDays,
    required this.coursesCompleted,
    required this.lessonsCompleted,
    required this.testsPassed,
    required this.wordsLearned,
    required this.leaderboardRank,
  });

  final int xp;
  final int level;
  final int xpToNextLevel;
  final int xpForCurrentLevel;
  final int streakDays;
  final int coursesCompleted;
  final int lessonsCompleted;
  final int testsPassed;
  final int wordsLearned;
  final int leaderboardRank;

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      xp: _asInt(json['xp']),
      level: _asInt(json['level']),
      xpToNextLevel: _asInt(json['xpToNextLevel']),
      xpForCurrentLevel: _asInt(json['xpForCurrentLevel']),
      streakDays: _asInt(json['streakDays']),
      coursesCompleted: _asInt(json['coursesCompleted']),
      lessonsCompleted: _asInt(json['lessonsCompleted']),
      testsPassed: _asInt(json['testsPassed']),
      wordsLearned: _asInt(json['wordsLearned']),
      leaderboardRank: _asInt(json['leaderboardRank']),
    );
  }
}

class AchievementInfo {
  const AchievementInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.earned,
    this.xpReward = 0,
  });

  final String id;
  final String title;
  final String description;
  final bool earned;
  final int xpReward;

  factory AchievementInfo.fromJson(Map<String, dynamic> json) {
    return AchievementInfo(
      id: _asString(json['id']),
      title: _asString(json['title']),
      description: _asString(json['description']),
      earned: json['earned'] == true,
      xpReward: _asInt(json['xpReward']),
    );
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.firstName,
    required this.lastName,
    required this.xp,
    required this.level,
    required this.currentUser,
  });

  final int rank;
  final String firstName;
  final String lastName;
  final int xp;
  final int level;
  final bool currentUser;

  String get name {
    final String fullName = <String>[
      firstName,
      lastName,
    ].where((String part) => part.trim().isNotEmpty).join(' ').trim();
    return fullName.isEmpty ? 'User' : fullName;
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: _asInt(json['rank']),
      firstName: _asString(json['firstName']),
      lastName: _asString(json['lastName']),
      xp: _asInt(json['xp']),
      level: _asInt(json['level']),
      currentUser: json['currentUser'] == true,
    );
  }
}

class CertificateInfo {
  const CertificateInfo({
    required this.id,
    required this.verificationCode,
    required this.recipientName,
    required this.courseTitle,
    required this.level,
    required this.finalScore,
    required this.status,
    this.pdfUrl = '',
    this.verificationUrl = '',
    this.issuedAt = '',
  });

  final String id;
  final String verificationCode;
  final String recipientName;
  final String courseTitle;
  final String level;
  final int finalScore;
  final String issuedAt;
  final String status;
  final String pdfUrl;
  final String verificationUrl;

  factory CertificateInfo.fromJson(Map<String, dynamic> json) {
    return CertificateInfo(
      id: _asString(json['id']),
      verificationCode: _asString(json['verificationCode']),
      recipientName: _asString(json['recipientName']),
      courseTitle: _asString(json['courseTitle']),
      level: _asString(json['level']),
      finalScore: _asInt(json['finalScore']),
      issuedAt: _asString(json['issuedAt']),
      status: _asString(json['status']),
      pdfUrl: _asString(json['pdfUrl']),
      verificationUrl: _asString(json['verificationUrl']),
    );
  }
}

class CertificateVerifyInfo {
  const CertificateVerifyInfo({
    required this.valid,
    required this.recipientName,
    required this.courseTitle,
    required this.level,
    required this.finalScore,
    required this.status,
    required this.message,
  });

  final bool valid;
  final String recipientName;
  final String courseTitle;
  final String level;
  final int finalScore;
  final String status;
  final String message;

  factory CertificateVerifyInfo.fromJson(Map<String, dynamic> json) {
    return CertificateVerifyInfo(
      valid: json['valid'] == true,
      recipientName: _asString(json['recipientName']),
      courseTitle: _asString(json['courseTitle']),
      level: _asString(json['level']),
      finalScore: _asInt(json['finalScore']),
      status: _asString(json['status']),
      message: _asString(json['message']),
    );
  }
}

class OnboardingInfo {
  const OnboardingInfo({
    required this.languageLevel,
    required this.goalType,
    required this.onboardingCompleted,
    required this.recommendedCourses,
    this.message = '',
  });

  final String languageLevel;
  final String goalType;
  final bool onboardingCompleted;
  final List<CourseInfo> recommendedCourses;
  final String message;

  factory OnboardingInfo.fromJson(Map<String, dynamic> json) {
    final List<dynamic> recommendedCourses =
        json['recommendedCourses'] is List<dynamic>
        ? json['recommendedCourses'] as List<dynamic>
        : const <dynamic>[];
    return OnboardingInfo(
      languageLevel: _asString(json['languageLevel']),
      goalType: _asString(json['goalType']),
      onboardingCompleted: json['onboardingCompleted'] == true,
      recommendedCourses: recommendedCourses
          .map((dynamic item) => CourseInfo.fromJson(_asMap(item)))
          .where((CourseInfo course) => course.id.isNotEmpty)
          .toList(),
      message: _asString(json['message']),
    );
  }
}

class UserApiException implements Exception {
  const UserApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

Map<String, dynamic> _asMap(dynamic value) {
  return value is Map<String, dynamic> ? value : <String, dynamic>{};
}

String _asString(dynamic value) {
  return (value ?? '').toString().trim();
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse((value ?? '').toString()) ?? 0;
}

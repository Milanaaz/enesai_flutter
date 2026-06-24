import 'package:dipl/app/app_colors.dart';
import 'package:dipl/app/widgets/main_bottom_nav.dart';
import 'package:dipl/features/courses/presentation/data/course_api_service.dart';
import 'package:dipl/features/courses/presentation/models/course_models.dart';
import 'package:dipl/features/user/data/user_api_service.dart';
import 'package:dipl/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<_HomeData>? _homeDataFuture;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _loadHomeData();
  }

  Future<_HomeData> _loadHomeData() async {
    final String? rawName = await AuthService.instance.getRegisteredName();
    final String? rawLevel = await AuthService.instance.getSelectedLevel();
    UserProfile? profile;
    UserAnalytics? analytics;
    List<UserCourseProgress> myCourses = const <UserCourseProgress>[];
    List<CourseInfo> recommendedCourses = const <CourseInfo>[];
    try {
      profile = await UserApiService.instance.getMyProfile();
      if (profile.fullName.trim().isNotEmpty) {
        await AuthService.instance.saveRegisteredName(profile.fullName);
      }
      if (profile.languageLevel.trim().isNotEmpty) {
        await AuthService.instance.saveSelectedLevel(profile.languageLevel);
      }
      if (profile.goalType.trim().isNotEmpty) {
        await AuthService.instance.saveGoalType(profile.goalType);
      }
    } on UserApiException {
      profile = null;
    }
    try {
      analytics = await UserApiService.instance.getMyAnalytics();
      if (analytics.activeCourses.isNotEmpty) {
        myCourses = analytics.activeCourses;
      }
    } on UserApiException {
      analytics = null;
    }
    try {
      if (myCourses.isEmpty) {
        myCourses = await CourseApiService.instance.getMyCourses();
      }
    } on CourseApiException {
      myCourses = const <UserCourseProgress>[];
    }
    try {
      final OnboardingInfo recommendations = await UserApiService.instance
          .getRecommendations();
      recommendedCourses = recommendations.recommendedCourses;
    } on UserApiException {
      recommendedCourses = const <CourseInfo>[];
    }
    try {
      if (recommendedCourses.isEmpty) {
        recommendedCourses = await CourseApiService.instance.getCourses(
          size: 6,
        );
      }
    } on CourseApiException {
      recommendedCourses = const <CourseInfo>[];
    }
    return _HomeData(
      userName: (rawName ?? '').trim().isNotEmpty
          ? rawName!.trim()
          : 'Пользователь',
      level: (rawLevel ?? '').trim().isNotEmpty ? rawLevel!.trim() : 'A1',
      xp: analytics?.xp ?? 1245,
      streakDays: analytics?.streakDays ?? 12,
      myCourses: myCourses,
      recommendedCourses: recommendedCourses,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: FutureBuilder<_HomeData>(
          future: _homeDataFuture ??= _loadHomeData(),
          builder: (context, snapshot) {
            final _HomeData info =
                snapshot.data ??
                const _HomeData(
                  userName: 'Пользователь',
                  level: 'A1',
                  xp: 1245,
                  streakDays: 12,
                  myCourses: <UserCourseProgress>[],
                  recommendedCourses: <CourseInfo>[],
                );

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _HomeHeader(
                    userName: info.userName,
                    level: info.level,
                    xp: info.xp,
                    streakDays: info.streakDays,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _CurrentCourseCard(course: info.currentCourse),
                ),
                const SliverToBoxAdapter(child: _DailyGoalCard()),
                const SliverToBoxAdapter(child: _LibraryShortcutCard()),
                SliverToBoxAdapter(
                  child: _RecommendedSection(courses: info.recommendedCourses),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 0),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.userName,
    required this.level,
    required this.xp,
    required this.streakDays,
  });

  final String userName;
  final String level;
  final int xp;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Добрый день!',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => context.push('/profile'),
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(Icons.person_outline, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeaderMetric(
                  label: 'Уровень',
                  value: level,
                  icon: Icons.track_changes_outlined,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _HeaderMetric(
                  label: 'Баллы',
                  value: _formatNumber(xp),
                  icon: Icons.stars_outlined,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _HeaderMetric(
                  label: 'Дни',
                  value: streakDays.toString(),
                  icon: Icons.access_time_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeData {
  const _HomeData({
    required this.userName,
    required this.level,
    required this.xp,
    required this.streakDays,
    required this.myCourses,
    required this.recommendedCourses,
  });

  final String userName;
  final String level;
  final int xp;
  final int streakDays;
  final List<UserCourseProgress> myCourses;
  final List<CourseInfo> recommendedCourses;

  UserCourseProgress? get currentCourse {
    if (myCourses.isEmpty) return null;
    return myCourses.firstWhere(
      (UserCourseProgress course) => !course.completed,
      orElse: () => myCourses.first,
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentCourseCard extends StatelessWidget {
  const _CurrentCourseCard({required this.course});

  final UserCourseProgress? course;

  @override
  Widget build(BuildContext context) {
    final int percent = course?.progressPercent.clamp(0, 100) ?? 75;
    final int completedLessons = course?.completedLessons ?? 9;
    final int totalLessons = course?.totalLessons ?? 12;
    final int remainingLessons = (totalLessons - completedLessons).clamp(
      0,
      totalLessons,
    );
    final String title = course?.courseTitle ?? 'Основы кыргызского языка';
    final String lessonId = course?.lastLessonId ?? '';
    return _SectionCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Текущий курс',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF065F46),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 7,
              backgroundColor: Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF111827)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$completedLessons из $totalLessons уроков',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              Spacer(),
              Text(
                '$remainingLessons урока осталось',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: course == null
                  ? () => context.push('/courses')
                  : () {
                      final String path = lessonId.isEmpty
                          ? '/courses/${course!.courseId}'
                          : '/courses/${course!.courseId}/lesson?lessonId=$lessonId';
                      context.push(path);
                    },
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                course == null ? 'Выбрать курс' : 'Продолжить обучение',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ежедневная цель',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _SectionCard(
            margin: EdgeInsets.zero,
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCA5A5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.gps_fixed_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '20 минут в день',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Spacer(),
                          Text(
                            '15/20 мин',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                        child: LinearProgressIndicator(
                          value: 0.75,
                          minHeight: 6,
                          backgroundColor: Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF111827),
                          ),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Осталось 5 минут',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryShortcutCard extends StatelessWidget {
  const _LibraryShortcutCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        onTap: () => context.push('/library'),
        borderRadius: BorderRadius.circular(16),
        child: _SectionCard(
          margin: EdgeInsets.zero,
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Библиотека',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Открыть книги и продолжить чтение',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendedSection extends StatelessWidget {
  const _RecommendedSection({required this.courses});

  final List<CourseInfo> courses;

  @override
  Widget build(BuildContext context) {
    final List<CourseInfo> visibleCourses = courses.take(2).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Рекомендуемые курсы',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/courses'),
                child: const Text(
                  'Все',
                  style: TextStyle(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (visibleCourses.isEmpty) ...[
            const _CourseCard(
              title: 'Разговорная практика',
              subtitle: 'Средний • 8 уроков',
              colorA: Color(0xFFA78BFA),
              colorB: Color(0xFF7C3AED),
            ),
            const SizedBox(height: 8),
            const _CourseCard(
              title: 'Грамматика для начинающих',
              subtitle: 'Начальный • 10 уроков',
              colorA: Color(0xFFFBBF24),
              colorB: Color(0xFFD97706),
            ),
          ] else
            ...visibleCourses.map(
              (CourseInfo course) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CourseCard(
                  title: course.title,
                  subtitle:
                      '${course.level.isEmpty ? 'Курс' : course.level} • ${course.lessonCount} уроков',
                  colorA: _courseColorA(course.type),
                  colorB: _courseColorB(course.type),
                  onTap: () => context.push('/courses/${course.id}'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.title,
    required this.subtitle,
    required this.colorA,
    required this.colorB,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Color colorA;
  final Color colorB;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: _SectionCard(
        margin: EdgeInsets.zero,
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(colors: [colorA, colorB]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _courseColorA(CourseType type) {
  return switch (type) {
    CourseType.grammar => const Color(0xFFFBBF24),
    CourseType.speaking => const Color(0xFFA78BFA),
    CourseType.reading => const Color(0xFF93C5FD),
    CourseType.pronunciation => const Color(0xFF6EE7B7),
    CourseType.business => const Color(0xFFFCA5A5),
    CourseType.ort => const Color(0xFFC4B5FD),
    CourseType.general => const Color(0xFFA78BFA),
  };
}

Color _courseColorB(CourseType type) {
  return switch (type) {
    CourseType.grammar => const Color(0xFFD97706),
    CourseType.speaking => const Color(0xFF7C3AED),
    CourseType.reading => const Color(0xFF2563EB),
    CourseType.pronunciation => const Color(0xFF059669),
    CourseType.business => const Color(0xFFDC2626),
    CourseType.ort => const Color(0xFF6D28D9),
    CourseType.general => const Color(0xFF7C3AED),
  };
}

String _formatNumber(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, required this.margin});

  final Widget child;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }
}

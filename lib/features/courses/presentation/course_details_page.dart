import 'package:dipl/app/app_colors.dart';
import 'package:dipl/features/courses/presentation/data/course_api_service.dart';
import 'package:dipl/features/courses/presentation/data/mock_courses.dart';
import 'package:dipl/features/courses/presentation/models/course_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CourseDetailsPage extends StatefulWidget {
  const CourseDetailsPage({required this.courseId, super.key});

  final String courseId;

  @override
  State<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage> {
  late Future<CourseInfo?> _courseFuture;
  bool _startingCourse = false;

  @override
  void initState() {
    super.initState();
    _courseFuture = _loadCourse();
  }

  Future<CourseInfo?> _loadCourse() async {
    return CourseApiService.instance.getCourseDetail(widget.courseId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CourseInfo?>(
      future: _courseFuture,
      builder: (context, snapshot) {
        final CourseInfo? fallback = _findMockCourse(widget.courseId);
        final CourseInfo? course = snapshot.data ?? fallback;
        if (course == null &&
            snapshot.connectionState != ConnectionState.waiting) {
          return const Scaffold(body: Center(child: Text('Курс не найден')));
        }
        final CourseInfo safeCourse = course ?? fallback ?? mockCourses.first;
        final LessonInfo? firstLesson = _firstAvailableLesson(safeCourse);
        final CourseModule? activeModule = _activeModule(safeCourse);
        final String cta = safeCourse.status == CourseStatus.notStarted
            ? 'Начать'
            : 'Продолжить';

        return Scaffold(
          appBar: AppBar(title: const Text('Страница курса')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                if (snapshot.hasError)
                  _LoadErrorBanner(
                    message: snapshot.error.toString(),
                    onRetry: () => setState(() {
                      _courseFuture = _loadCourse();
                    }),
                  ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(minHeight: 2),
                if (snapshot.hasError ||
                    snapshot.connectionState == ConnectionState.waiting)
                  const SizedBox(height: 12),
                _CourseSummaryCard(course: safeCourse),
                const SizedBox(height: 20),
                const Text(
                  'Программа курса',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...List<Widget>.generate(safeCourse.modules.length, (
                  int moduleIndex,
                ) {
                  final CourseModule module = safeCourse.modules[moduleIndex];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ModuleCard(
                      module: module,
                      moduleIndex: moduleIndex,
                      course: safeCourse,
                      onStartLesson: (LessonInfo lesson) =>
                          _openLesson(safeCourse, lesson),
                      onStartTest: module.id.isEmpty
                          ? null
                          : () => context.push(
                              '/courses/${widget.courseId}/module-test?moduleId=${module.id}',
                            ),
                    ),
                  );
                }),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: FilledButton(
              onPressed: firstLesson == null || _startingCourse
                  ? null
                  : () => _openLesson(safeCourse, firstLesson),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                activeModule == null || activeModule.id.isEmpty
                    ? cta
                    : '$cta модуль',
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openLesson(CourseInfo course, LessonInfo lesson) async {
    setState(() => _startingCourse = true);
    try {
      if (course.status == CourseStatus.notStarted) {
        await CourseApiService.instance.enrollInCourse(widget.courseId);
      }
      if (!mounted) return;
      context.push('/courses/${widget.courseId}/lesson?lessonId=${lesson.id}');
    } on CourseApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _startingCourse = false);
    }
  }

  CourseInfo? _findMockCourse(String id) {
    for (final CourseInfo item in mockCourses) {
      if (item.id == id) return item;
    }
    return null;
  }

  LessonInfo? _firstAvailableLesson(CourseInfo course) {
    final CourseModule? module = _activeModule(course);
    if (module == null || module.lessons.isEmpty) return null;
    final int index = (module.progress * module.lessons.length).round().clamp(
      0,
      module.lessons.length - 1,
    );
    return module.lessons[index];
  }

  CourseModule? _activeModule(CourseInfo course) {
    if (course.modules.isEmpty) return null;
    return course.modules.firstWhere(
      (CourseModule module) => module.progress < 1,
      orElse: () => course.modules.last,
    );
  }
}

class _CourseSummaryCard extends StatelessWidget {
  const _CourseSummaryCard({required this.course});

  final CourseInfo course;

  @override
  Widget build(BuildContext context) {
    final double progress = _courseProgress(course);
    final int percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E6EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.title,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          if (course.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              course.description,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.layers_outlined,
                size: 20,
                color: Color(0xFF475467),
              ),
              const SizedBox(width: 5),
              Text(
                '${course.modules.length} мод.',
                style: const TextStyle(fontSize: 15, color: Color(0xFF344054)),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.menu_book_outlined,
                size: 20,
                color: Color(0xFF475467),
              ),
              const SizedBox(width: 5),
              Text(
                '${course.lessonCount} уроков',
                style: const TextStyle(fontSize: 15, color: Color(0xFF344054)),
              ),
              const Spacer(),
              const Icon(
                Icons.schedule_outlined,
                size: 20,
                color: Color(0xFF475467),
              ),
              const SizedBox(width: 5),
              Text(
                '${(course.totalMinutes / 60).toStringAsFixed(1)} ч',
                style: const TextStyle(fontSize: 15, color: Color(0xFF344054)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagPill(
                text: course.level.isEmpty ? 'Курс' : course.level,
                bg: const Color(0xFFECE7FF),
                fg: const Color(0xFF7F56D9),
              ),
              _TagPill(
                text: statusLabel(course.status),
                bg: const Color(0xFFD7F5E6),
                fg: const Color(0xFF027A48),
              ),
              const _TagPill(
                text: 'Сертификат',
                bg: Color(0xFFFEF0C7),
                fg: Color(0xFFB54708),
                icon: Icons.workspace_premium_outlined,
              ),
            ],
          ),
          if (course.goals.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Цели',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...course.goals.map(
              (String goal) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Icon(
                        Icons.circle,
                        size: 7,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(goal)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Прогресс курса',
                style: TextStyle(fontSize: 16, color: Color(0xFF344054)),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF344054),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFD1D5DB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF090920),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.text,
    required this.bg,
    required this.fg,
    this.icon,
  });

  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.module,
    required this.moduleIndex,
    required this.course,
    required this.onStartLesson,
    required this.onStartTest,
  });

  final CourseModule module;
  final int moduleIndex;
  final CourseInfo course;
  final ValueChanged<LessonInfo> onStartLesson;
  final VoidCallback? onStartTest;

  @override
  Widget build(BuildContext context) {
    final int totalLessons = module.lessons.length;
    final int completedLessons = (module.progress * totalLessons).round().clamp(
      0,
      totalLessons,
    );
    final int activeModuleIndex = _activeModuleIndex(course);
    final bool isLockedModule = moduleIndex > activeModuleIndex;
    final bool isActiveModule = moduleIndex == activeModuleIndex;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  module.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FC),
                  border: Border.all(color: const Color(0xFFD0D5DD)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$completedLessons/$totalLessons',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List<Widget>.generate(module.lessons.length, (int lessonIndex) {
            final LessonInfo lesson = module.lessons[lessonIndex];
            final _LessonState state = _resolveLessonState(
              isLockedModule: isLockedModule,
              isActiveModule: isActiveModule,
              completedLessons: completedLessons,
              lessonIndex: lessonIndex,
            );
            return _ModuleLessonRow(
              lesson: lesson,
              state: state,
              showAction: state == _LessonState.current,
              onTapAction: () => onStartLesson(lesson),
            );
          }),
          if (!isLockedModule && totalLessons > 0) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onStartTest,
                icon: const Icon(Icons.quiz_outlined),
                label: const Text('Тест модуля'),
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFE4E7EC), height: 1),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: module.progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFD1D5DB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF090920),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _LessonState _resolveLessonState({
    required bool isLockedModule,
    required bool isActiveModule,
    required int completedLessons,
    required int lessonIndex,
  }) {
    if (isLockedModule) return _LessonState.locked;
    if (lessonIndex < completedLessons) return _LessonState.completed;
    if (isActiveModule && lessonIndex == completedLessons) {
      return _LessonState.current;
    }
    return _LessonState.locked;
  }
}

class _ModuleLessonRow extends StatelessWidget {
  const _ModuleLessonRow({
    required this.lesson,
    required this.state,
    required this.showAction,
    required this.onTapAction,
  });

  final LessonInfo lesson;
  final _LessonState state;
  final bool showAction;
  final VoidCallback onTapAction;

  @override
  Widget build(BuildContext context) {
    final bool completed = state == _LessonState.completed;
    final bool current = state == _LessonState.current;
    final bool locked = state == _LessonState.locked;
    final Color textColor = locked
        ? const Color(0xFF98A2B3)
        : const Color(0xFF101828);
    final Color subColor = locked
        ? const Color(0xFF98A2B3)
        : const Color(0xFF667085);
    final Color iconWrap = switch (state) {
      _LessonState.completed => const Color(0xFFD7F5E6),
      _LessonState.current => const Color(0xFFECE7FF),
      _LessonState.locked => const Color(0xFFF2F4F7),
    };
    final Color iconColor = switch (state) {
      _LessonState.completed => const Color(0xFF12B76A),
      _LessonState.current => AppColors.brandPrimary,
      _LessonState.locked => const Color(0xFF98A2B3),
    };
    final IconData icon = switch (state) {
      _LessonState.completed => Icons.check_circle_outline,
      _LessonState.current => Icons.play_arrow_rounded,
      _LessonState.locked => Icons.lock_outline,
    };

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconWrap,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: current ? 24 : 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${lesson.durationMinutes} мин',
                  style: TextStyle(color: subColor, fontSize: 14),
                ),
              ],
            ),
          ),
          if (showAction)
            FilledButton(
              onPressed: onTapAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: const Text(
                'Начать',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          if (completed || locked) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _LoadErrorBanner extends StatelessWidget {
  const _LoadErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDA29B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB42318), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFB42318), fontSize: 12),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}

enum _LessonState { completed, current, locked }

double _courseProgress(CourseInfo course) {
  if (course.modules.isEmpty) return 0;
  final double sum = course.modules.fold<double>(
    0,
    (double total, CourseModule module) => total + module.progress,
  );
  return (sum / course.modules.length).clamp(0, 1).toDouble();
}

int _activeModuleIndex(CourseInfo course) {
  for (int i = 0; i < course.modules.length; i++) {
    if (course.modules[i].progress < 1) return i;
  }
  return course.modules.isEmpty ? 0 : course.modules.length - 1;
}

import 'package:dipl/app/app_colors.dart';
import 'package:dipl/features/courses/presentation/data/mock_courses.dart';
import 'package:dipl/features/courses/presentation/models/course_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CourseDetailsPage extends StatelessWidget {
  const CourseDetailsPage({required this.courseId, super.key});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    CourseInfo? course;
    for (final CourseInfo item in mockCourses) {
      if (item.id == courseId) {
        course = item;
        break;
      }
    }
    if (course == null) {
      return const Scaffold(body: Center(child: Text('Курс не найден')));
    }
    final String cta = course.status == CourseStatus.notStarted
        ? 'Начать'
        : 'Продолжить';
    return Scaffold(
      appBar: AppBar(title: const Text('Страница курса')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(16),
              child: Text(
                course.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Описание',
              child: Text(
                course.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
            _Section(
              title: 'Цели курса',
              child: Column(
                children: course.goals
                    .map(
                      (String item) =>
                          _ListRow(icon: Icons.flag_outlined, text: item),
                    )
                    .toList(),
              ),
            ),
            _Section(
              title: 'Для кого',
              child: Column(
                children: course.audience
                    .map(
                      (String item) =>
                          _ListRow(icon: Icons.person_outline, text: item),
                    )
                    .toList(),
              ),
            ),
            _Section(
              title: 'Структура курса',
              child: Column(
                children: course.modules.map((CourseModule module) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: module.progress,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.brandPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(module.progress * 100).round()}% выполнено · ${module.lessons.length} уроков',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...module.lessons.map(
                          (LessonInfo lesson) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '• ${lesson.title}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton(
          onPressed: () => context.push('/courses/$courseId/lesson'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(cta),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.brandPrimary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

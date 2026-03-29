import 'package:dipl/app/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LessonSummaryPage extends StatelessWidget {
  const LessonSummaryPage({
    required this.courseId,
    required this.score,
    super.key,
  });

  final String courseId;
  final int score;

  @override
  Widget build(BuildContext context) {
    final int safeScore = score.clamp(0, 100);
    return Scaffold(
      appBar: AppBar(title: const Text('Итоги урока')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F3FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '$safeScore%',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  const Text('Правильных ответов'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _StatRow(title: 'Ошибки: перевод', value: '2'),
            const _StatRow(title: 'Ошибки: грамматика', value: '1'),
            const _StatRow(title: 'Ошибки: аудирование', value: '1'),
            const SizedBox(height: 12),
            const Text(
              'Слова для повторения',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                Chip(label: Text('таанышуу')),
                Chip(label: Text('мекеме')),
                Chip(label: Text('баяндама')),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.workspace_premium_outlined,
                    color: AppColors.brandPrimary,
                  ),
                  SizedBox(width: 8),
                  Expanded(child: Text('Награда за урок: +50 XP')),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.push('/courses/$courseId/module-test'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                ),
                child: const Text('Следующий урок'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/courses/$courseId/lesson'),
                child: const Text('Повторить ошибки'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

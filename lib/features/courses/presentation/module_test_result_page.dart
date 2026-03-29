import 'package:dipl/app/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ModuleTestResultPage extends StatelessWidget {
  const ModuleTestResultPage({
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
      appBar: AppBar(title: const Text('Результат теста')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: safeScore >= 70
                    ? const Color(0xFFECFDF3)
                    : const Color(0xFFFEF3F2),
              ),
              child: Column(
                children: [
                  Text(
                    '$safeScore%',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: safeScore >= 70
                          ? const Color(0xFF027A48)
                          : const Color(0xFFB42318),
                    ),
                  ),
                  Text(safeScore >= 70 ? 'Модуль пройден' : 'Нужно повторение'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Аналитика',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const _AnalyticRow(label: 'Грамматика', value: '80%'),
            const _AnalyticRow(label: 'Слова', value: '66%'),
            const _AnalyticRow(label: 'Аудирование', value: '73%'),
            const SizedBox(height: 14),
            const Text(
              'Рекомендации',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const _Recommendation(text: 'Повтори урок 3'),
            const _Recommendation(text: 'Потренируй грамматику в модуле 2'),
            const _Recommendation(text: 'Повтори слова из темы "Учеба"'),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton(
          onPressed: safeScore >= 70
              ? () => context.push('/courses/$courseId/certificate')
              : () => context.push('/courses/$courseId/module-test'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandPrimary,
          ),
          child: Text(
            safeScore >= 70 ? 'Открыть сертификат' : 'Пройти тест снова',
          ),
        ),
      ),
    );
  }
}

class _AnalyticRow extends StatelessWidget {
  const _AnalyticRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Recommendation extends StatelessWidget {
  const _Recommendation({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 8, color: AppColors.brandPrimary),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

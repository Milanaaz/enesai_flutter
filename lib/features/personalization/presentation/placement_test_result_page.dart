import 'dart:async';

import 'package:dipl/app/app_colors.dart';
import 'package:dipl/features/personalization/data/placement_test_models.dart';
import 'package:dipl/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PlacementTestResultPage extends StatefulWidget {
  const PlacementTestResultPage({
    required this.goalCode,
    required this.result,
    super.key,
  });

  final String goalCode;
  final PlacementTestResult? result;

  @override
  State<PlacementTestResultPage> createState() =>
      _PlacementTestResultPageState();
}

class _PlacementTestResultPageState extends State<PlacementTestResultPage> {
  bool _isSaving = false;

  Future<void> _continue() async {
    final PlacementTestResult? result = widget.result;
    if (result == null || _isSaving) return;

    final String level = result.determinedLevel.trim().toUpperCase();
    if (level.isEmpty) {
      _showMessage('Сервер не вернул определенный уровень');
      return;
    }

    setState(() => _isSaving = true);
    final String goalType = _goalTypeFromCode(widget.goalCode);
    await AuthService.instance.saveSelectedLevel(level);
    await AuthService.instance.saveGoalType(goalType);

    unawaited(
      AuthService.instance
          .updateOnboardingProfile(languageLevel: level, goalType: goalType)
          .catchError((Object _) {}),
    );

    if (!mounted) return;
    context.go('/');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PlacementTestResult? result = widget.result;
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Результат теста')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Результат не найден. Пройдите стартовый тест заново.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final int score = result.scorePercent.clamp(0, 100);
    final String level = result.determinedLevel.trim().toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Результат теста')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                border: Border.all(color: const Color(0xFFE9D5FF)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    level.isNotEmpty ? level : '-',
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ваш стартовый уровень',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _ResultRow(label: 'Баллы', value: '$score%'),
            _ResultRow(
              label: 'Правильные ответы',
              value: '${result.correctAnswers}/${result.totalQuestions}',
            ),
            if (result.recommendedCourseTitle.trim().isNotEmpty)
              _ResultRow(
                label: 'Рекомендованный курс',
                value: result.recommendedCourseTitle.trim(),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton(
          onPressed: _isSaving ? null : _continue,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Продолжить',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _goalTypeFromCode(String code) {
  switch (code) {
    case 'ort':
      return 'ORT_PREP';
    case 'speaking':
      return 'CONVERSATIONAL';
    case 'business':
      return 'BUSINESS';
    case 'learn':
    default:
      return 'LEARN_KYRGYZ';
  }
}

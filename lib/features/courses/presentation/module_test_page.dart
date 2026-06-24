import 'package:dipl/app/app_colors.dart';
import 'package:dipl/features/courses/presentation/data/course_api_service.dart';
import 'package:dipl/features/courses/presentation/models/course_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ModuleTestPage extends StatefulWidget {
  const ModuleTestPage({required this.courseId, this.moduleId, super.key});

  final String courseId;
  final String? moduleId;

  @override
  State<ModuleTestPage> createState() => _ModuleTestPageState();
}

class _ModuleTestPageState extends State<ModuleTestPage> {
  final Map<String, String> _answers = <String, String>{};
  bool _timerEnabled = false;
  bool _submitting = false;
  late Future<TestInfo> _testFuture;

  @override
  void initState() {
    super.initState();
    _testFuture = _loadTest();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TestInfo>(
      future: _testFuture,
      builder: (context, snapshot) {
        final TestInfo? test = snapshot.data;
        final bool ready =
            test != null &&
            test.questions.isNotEmpty &&
            _answers.length == test.questions.length &&
            !_submitting;

        return Scaffold(
          appBar: AppBar(title: Text(test?.title ?? 'Тест по модулю')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: [
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(minHeight: 2),
                if (snapshot.hasError)
                  _ErrorBanner(
                    message: snapshot.error.toString(),
                    onRetry: () => setState(() {
                      _testFuture = _loadTest();
                    }),
                  ),
                if (test != null) ...[
                  SwitchListTile(
                    value: _timerEnabled,
                    onChanged: (bool value) =>
                        setState(() => _timerEnabled = value),
                    title: const Text('Включить таймер'),
                    subtitle: Text(
                      test.timeLimitMinutes > 0
                          ? '${test.timeLimitMinutes} мин на весь тест'
                          : 'Без ограничения времени',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (test.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      test.description,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 8),
                  ...test.questions.map(_questionCard),
                ],
                if (test == null && !snapshot.hasError)
                  const Text('Загрузка теста...'),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: FilledButton(
              onPressed: ready ? () => _submit(test) : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
              ),
              child: Text(_submitting ? 'Отправка...' : 'Завершить тест'),
            ),
          ),
        );
      },
    );
  }

  Future<TestInfo> _loadTest() {
    final String? moduleId = widget.moduleId;
    if ((moduleId ?? '').isNotEmpty) {
      return CourseApiService.instance.getModuleTest(moduleId!);
    }
    return CourseApiService.instance.getCourseTest(widget.courseId);
  }

  Widget _questionCard(TestQuestionInfo question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.questionText,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...question.options.map((AnswerOption option) {
            final bool isSelected = _answers[question.id] == option.id;
            return InkWell(
              onTap: () => setState(() => _answers[question.id] = option.id),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brandPrimary
                        : const Color(0xFFD0D5DD),
                  ),
                  color: isSelected
                      ? const Color(0xFFF5F3FF)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: isSelected
                          ? AppColors.brandPrimary
                          : const Color(0xFF667085),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(option.text)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _submit(TestInfo test) async {
    setState(() => _submitting = true);
    try {
      final int score = await CourseApiService.instance.submitTest(
        testId: test.id,
        selectedOptionIds: _answers,
      );
      if (!mounted) return;
      context.push(
        '/courses/${widget.courseId}/module-test/result?score=$score',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

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

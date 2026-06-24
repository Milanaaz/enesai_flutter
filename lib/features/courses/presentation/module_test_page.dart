import 'dart:async';

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
  final Map<String, String> _optionAnswers = <String, String>{};
  final Map<String, String> _textAnswers = <String, String>{};
  bool _timerEnabled = false;
  bool _submitting = false;
  Timer? _timer;
  int? _remainingSeconds;
  late Future<TestInfo> _testFuture;

  @override
  void initState() {
    super.initState();
    _testFuture = _loadTest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
            test.questions.every(_hasAnswer) &&
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
                    onChanged: (bool value) => _toggleTimer(value, test),
                    title: const Text('Включить таймер'),
                    subtitle: Text(_timerSubtitle(test)),
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
    if (question.options.isEmpty) {
      return _textQuestionCard(question);
    }

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
            final bool isSelected = _optionAnswers[question.id] == option.id;
            return InkWell(
              onTap: () =>
                  setState(() => _optionAnswers[question.id] = option.id),
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

  Widget _textQuestionCard(TestQuestionInfo question) {
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
          const SizedBox(height: 10),
          TextField(
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            onChanged: (String value) {
              setState(() {
                final String answer = value.trim();
                if (answer.isEmpty) {
                  _textAnswers.remove(question.id);
                } else {
                  _textAnswers[question.id] = answer;
                }
              });
            },
            decoration: InputDecoration(
              hintText: _textAnswerHint(question),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasAnswer(TestQuestionInfo question) {
    if (question.options.isNotEmpty) {
      return (_optionAnswers[question.id] ?? '').isNotEmpty;
    }
    return (_textAnswers[question.id] ?? '').trim().isNotEmpty;
  }

  String _textAnswerHint(TestQuestionInfo question) {
    switch (question.type.toUpperCase()) {
      case 'TRANSLATION':
        return 'Введите перевод';
      case 'FILL_BLANK':
        return 'Введите пропущенное слово';
      default:
        return 'Введите ответ';
    }
  }

  String _timerSubtitle(TestInfo test) {
    final int? remaining = _remainingSeconds;
    if (_timerEnabled && remaining != null) {
      return 'Осталось ${_formatDuration(remaining)}';
    }
    return test.timeLimitMinutes > 0
        ? '${test.timeLimitMinutes} мин на весь тест'
        : 'Без ограничения времени';
  }

  void _toggleTimer(bool value, TestInfo test) {
    if (!value) {
      _timer?.cancel();
      setState(() {
        _timerEnabled = false;
        _remainingSeconds = null;
      });
      return;
    }

    final int limitMinutes = test.timeLimitMinutes;
    if (limitMinutes <= 0) {
      setState(() => _timerEnabled = true);
      return;
    }

    _timer?.cancel();
    setState(() {
      _timerEnabled = true;
      _remainingSeconds = limitMinutes * 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _submitting) return;
      final int next = (_remainingSeconds ?? 0) - 1;
      if (next <= 0) {
        _timer?.cancel();
        setState(() => _remainingSeconds = 0);
        _submit(test, allowIncomplete: true);
        return;
      }
      setState(() => _remainingSeconds = next);
    });
  }

  String _formatDuration(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _submit(TestInfo test, {bool allowIncomplete = false}) async {
    if (!allowIncomplete && !test.questions.every(_hasAnswer)) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final int score = await CourseApiService.instance.submitTest(
        testId: test.id,
        selectedOptionIds: _optionAnswers,
        textAnswers: _textAnswers,
      );
      if (!mounted) return;
      context.push(
        '/courses/${widget.courseId}/module-test/result?score=$score',
      );
    } on CourseApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
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

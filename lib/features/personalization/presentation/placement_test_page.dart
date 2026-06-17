import 'package:dipl/app/app_colors.dart';
import 'package:dipl/features/personalization/data/placement_test_models.dart';
import 'package:dipl/features/personalization/data/placement_test_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PlacementTestPage extends StatefulWidget {
  const PlacementTestPage({
    required this.languageCode,
    required this.goalCode,
    super.key,
  });

  final String languageCode;
  final String goalCode;

  @override
  State<PlacementTestPage> createState() => _PlacementTestPageState();
}

class _PlacementTestPageState extends State<PlacementTestPage> {
  late Future<PlacementTest> _testFuture;
  final Map<String, String> _selectedOptions = <String, String>{};
  final Map<String, TextEditingController> _textControllers =
      <String, TextEditingController>{};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _testFuture = PlacementTestService.instance.getActiveTest();
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(PlacementTest test) async {
    if (_isSubmitting) return;
    final List<PlacementAnswer> answers = <PlacementAnswer>[];

    for (final PlacementQuestion question in test.questions) {
      if (question.options.isNotEmpty) {
        final String optionId = (_selectedOptions[question.id] ?? '').trim();
        if (optionId.isEmpty) {
          _showMessage('Ответьте на все вопросы');
          return;
        }
        answers.add(
          PlacementAnswer(questionId: question.id, selectedOptionId: optionId),
        );
      } else {
        final String textAnswer = (_textControllers[question.id]?.text ?? '')
            .trim();
        if (textAnswer.isEmpty) {
          _showMessage('Ответьте на все вопросы');
          return;
        }
        answers.add(
          PlacementAnswer(questionId: question.id, textAnswer: textAnswer),
        );
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final PlacementTestResult result = await PlacementTestService.instance
          .submitAnswers(testId: test.id, answers: answers);
      if (!mounted) return;
      context.push(
        '/onboarding/placement-test/result?lang=${widget.languageCode}&goal=${widget.goalCode}',
        extra: result,
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlacementTest>(
      future: _testFuture,
      builder: (BuildContext context, AsyncSnapshot<PlacementTest> snapshot) {
        final PlacementTest? test = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Стартовый тест'),
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              tooltip: 'Назад',
            ),
          ),
          body: SafeArea(child: _buildBody(snapshot)),
          bottomNavigationBar: test == null
              ? null
              : SafeArea(
                  minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : () => _submit(test),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Завершить тест',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<PlacementTest> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return _ErrorState(
        message: snapshot.error.toString(),
        onRetry: () {
          setState(() {
            _selectedOptions.clear();
            for (final TextEditingController controller
                in _textControllers.values) {
              controller.dispose();
            }
            _textControllers.clear();
            _testFuture = PlacementTestService.instance.getActiveTest();
          });
        },
      );
    }

    final PlacementTest? test = snapshot.data;
    if (test == null || test.questions.isEmpty) {
      return _ErrorState(
        message: 'Активный стартовый тест пока не найден',
        onRetry: () {
          setState(() {
            _testFuture = PlacementTestService.instance.getActiveTest();
          });
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        Text(
          test.title.isNotEmpty ? test.title : 'Стартовый тест',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        if (test.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            test.description,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: 18),
        ...List<Widget>.generate(test.questions.length, (int index) {
          return _QuestionCard(
            index: index,
            question: test.questions[index],
            selectedOptionId: _selectedOptions[test.questions[index].id],
            textController: _controllerFor(test.questions[index].id),
            onOptionSelected: (String optionId) {
              setState(() {
                _selectedOptions[test.questions[index].id] = optionId;
              });
            },
          );
        }),
      ],
    );
  }

  TextEditingController _controllerFor(String questionId) {
    return _textControllers.putIfAbsent(questionId, TextEditingController.new);
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.textController,
    required this.onOptionSelected,
    this.selectedOptionId,
  });

  final int index;
  final PlacementQuestion question;
  final TextEditingController textController;
  final ValueChanged<String> onOptionSelected;
  final String? selectedOptionId;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. ${question.questionText.isNotEmpty ? question.questionText : 'Вопрос'}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (question.options.isEmpty)
            TextField(
              controller: textController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Введите ответ',
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
              ),
            )
          else
            ...question.options.map((PlacementOption option) {
              final bool selected = selectedOptionId == option.id;
              return InkWell(
                onTap: () => onOptionSelected(option.id),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFF5F3FF) : null,
                    border: Border.all(
                      color: selected
                          ? AppColors.brandPrimary
                          : AppColors.inputBorder,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: selected
                            ? AppColors.brandPrimary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
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
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.textSecondary,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
              ),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

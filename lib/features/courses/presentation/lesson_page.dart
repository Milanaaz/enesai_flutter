import 'package:dipl/app/app_colors.dart';
import 'package:dipl/features/courses/presentation/data/course_api_service.dart';
import 'package:dipl/features/courses/presentation/data/mock_courses.dart';
import 'package:dipl/features/courses/presentation/models/course_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LessonPage extends StatefulWidget {
  const LessonPage({required this.courseId, this.lessonId, super.key});

  final String courseId;
  final String? lessonId;

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  int _step = 0;
  int _practiceScore = 0;
  bool _completingLesson = false;
  late Future<_LessonPayload> _lessonFuture;

  static const List<String> _steps = <String>[
    'Видео',
    'Конспект',
    'Слова',
    'Практика',
  ];

  @override
  void initState() {
    super.initState();
    _lessonFuture = _loadLesson();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LessonPayload>(
      future: _lessonFuture,
      builder: (context, snapshot) {
        final _LessonPayload payload = snapshot.data ?? _fallbackPayload();
        final LessonInfo lesson = payload.lesson;

        return Scaffold(
          appBar: AppBar(title: Text(lesson.title)),
          body: SafeArea(
            child: Column(
              children: [
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(minHeight: 2),
                if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _ErrorBanner(
                      message: snapshot.error.toString(),
                      onRetry: () => setState(() {
                        _lessonFuture = _loadLesson();
                      }),
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: List<Widget>.generate(_steps.length, (int index) {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _step = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: index == _step
                                  ? AppColors.brandPrimary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _steps[index],
                              style: TextStyle(
                                color: index == _step
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    children: [
                      if (_step == 0) _VideoStep(lesson: lesson),
                      if (_step == 1) _NotesStep(lesson: lesson),
                      if (_step == 2) _WordsStep(words: lesson.words),
                      if (_step == 3)
                        _PracticeStep(
                          exercises: payload.exercises,
                          onScoreUpdated: (int score) => _practiceScore = score,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step -= 1),
                      child: const Text('Назад'),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _completingLesson
                        ? null
                        : () {
                            if (_step < _steps.length - 1) {
                              setState(() => _step += 1);
                              return;
                            }
                            _completeLesson();
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                    ),
                    child: Text(
                      _step < _steps.length - 1 ? 'Далее' : 'Завершить урок',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<_LessonPayload> _loadLesson() async {
    final String? lessonId = widget.lessonId;
    if ((lessonId ?? '').isEmpty) return _fallbackPayload();

    final _LessonPayload fallback = _fallbackPayload();
    final CourseInfo course = await CourseApiService.instance.getCourseDetail(
      widget.courseId,
    );
    final LessonInfo lesson = _findLesson(course, lessonId!) ?? fallback.lesson;
    await CourseApiService.instance.startLesson(lessonId);
    final List<ExerciseInfo> exercises = await CourseApiService.instance
        .getLessonExercises(lessonId);

    return _LessonPayload(lesson: lesson, exercises: exercises);
  }

  LessonInfo? _findLesson(CourseInfo course, String lessonId) {
    for (final CourseModule module in course.modules) {
      for (final LessonInfo lesson in module.lessons) {
        if (lesson.id == lessonId) return lesson;
      }
    }
    return null;
  }

  Future<void> _completeLesson() async {
    final String lessonId = widget.lessonId ?? '';
    setState(() => _completingLesson = true);
    try {
      if (lessonId.isNotEmpty) {
        await CourseApiService.instance.completeLesson(
          lessonId: lessonId,
          exerciseScorePercent: _practiceScore,
        );
      }
      if (!mounted) return;
      context.push(
        '/courses/${widget.courseId}/lesson/summary?score=$_practiceScore',
      );
    } on CourseApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _completingLesson = false);
    }
  }

  _LessonPayload _fallbackPayload() {
    for (final CourseInfo course in mockCourses) {
      if (course.id == widget.courseId &&
          course.modules.isNotEmpty &&
          course.modules.first.lessons.isNotEmpty) {
        return _LessonPayload(
          lesson: course.modules.first.lessons.first,
          exercises: const <ExerciseInfo>[],
        );
      }
    }
    return const _LessonPayload(
      lesson: _fallbackLesson,
      exercises: <ExerciseInfo>[],
    );
  }
}

class _VideoStep extends StatelessWidget {
  const _VideoStep({required this.lesson});

  final LessonInfo lesson;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF1F2937),
            ),
            alignment: Alignment.center,
            child: lesson.videoUrl.isEmpty
                ? const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 64,
                  )
                : const Text(
                    'Видео доступно по ссылке из API',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ),
        if (lesson.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(lesson.description),
        ],
      ],
    );
  }
}

class _NotesStep extends StatelessWidget {
  const _NotesStep({required this.lesson});

  final LessonInfo lesson;

  @override
  Widget build(BuildContext context) {
    return Text(
      lesson.textContent.isNotEmpty
          ? lesson.textContent
          : 'Материал урока пока не заполнен.',
      style: const TextStyle(height: 1.45),
    );
  }
}

class _WordsStep extends StatelessWidget {
  const _WordsStep({required this.words});

  final List<LessonWord> words;

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return const Text(
        'В этом уроке пока нет слов.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }
    return Column(
      children: words
          .map(
            (LessonWord word) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(word.value),
                subtitle: Text(
                  [
                    word.translation,
                    if (word.transcription.isNotEmpty) word.transcription,
                    if (word.example.isNotEmpty) word.example,
                  ].join('\n'),
                ),
                leading: const Icon(Icons.translate),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PracticeStep extends StatefulWidget {
  const _PracticeStep({required this.exercises, required this.onScoreUpdated});

  final List<ExerciseInfo> exercises;
  final ValueChanged<int> onScoreUpdated;

  @override
  State<_PracticeStep> createState() => _PracticeStepState();
}

class _PracticeStepState extends State<_PracticeStep> {
  final Map<String, bool> _results = <String, bool>{};
  final Map<String, TextEditingController> _textControllers =
      <String, TextEditingController>{};

  @override
  void dispose() {
    for (final TextEditingController controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exercises.isEmpty) {
      widget.onScoreUpdated(100);
      return const Text(
        'Упражнений для урока пока нет.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    final int correct = _results.values.where((bool value) => value).length;
    final int score = (correct / widget.exercises.length * 100).round();
    widget.onScoreUpdated(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Практика',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...widget.exercises.map(_exerciseCard),
        const SizedBox(height: 8),
        Text(
          'Текущий результат: $score%',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _exerciseCard(ExerciseInfo exercise) {
    final bool? result = _results[exercise.id];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.questionText,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (exercise.hint.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              exercise.hint,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 8),
          if (exercise.options.isNotEmpty)
            ...exercise.options.map(
              (AnswerOption option) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: OutlinedButton(
                  onPressed: () => _submitOptionAnswer(exercise, option),
                  child: Text(option.text),
                ),
              ),
            )
          else ...[
            TextField(
              controller: _textControllers.putIfAbsent(
                exercise.id,
                TextEditingController.new,
              ),
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Введите ответ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => _submitTextAnswer(exercise),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
              ),
              child: const Text('Проверить'),
            ),
          ],
          if (result != null)
            Text(
              result ? 'Верно' : 'Неверно',
              style: TextStyle(
                color: result
                    ? const Color(0xFF027A48)
                    : const Color(0xFFB42318),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _submitOptionAnswer(
    ExerciseInfo exercise,
    AnswerOption option,
  ) async {
    final bool correct = await CourseApiService.instance.submitExerciseAnswer(
      exerciseId: exercise.id,
      selectedOptionId: option.id,
    );
    setState(() => _results[exercise.id] = correct);
  }

  Future<void> _submitTextAnswer(ExerciseInfo exercise) async {
    final String answer = _textControllers[exercise.id]?.text.trim() ?? '';
    if (answer.isEmpty) return;
    final bool correct = await CourseApiService.instance.submitExerciseAnswer(
      exerciseId: exercise.id,
      textAnswer: answer,
    );
    setState(() => _results[exercise.id] = correct);
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
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

class _LessonPayload {
  const _LessonPayload({required this.lesson, required this.exercises});

  final LessonInfo lesson;
  final List<ExerciseInfo> exercises;
}

const LessonInfo _fallbackLesson = LessonInfo(
  id: 'lesson',
  title: 'Урок',
  durationMinutes: 30,
  words: <LessonWord>[_fallbackWord],
);

const LessonWord _fallbackWord = LessonWord(
  value: 'таанышуу',
  translation: 'знакомство',
  transcription: '[таанышуу]',
  example: 'Биз бүгүн таанышуу темасын өтөбүз.',
);

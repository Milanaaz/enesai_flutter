import 'package:dipl/app/app_colors.dart';
import 'package:dipl/features/courses/presentation/data/mock_courses.dart';
import 'package:dipl/features/courses/presentation/models/course_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LessonPage extends StatefulWidget {
  const LessonPage({required this.courseId, super.key});

  final String courseId;

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  int _step = 0;
  bool _showSubtitles = true;
  bool _savedWord = false;
  bool _markedHard = false;
  int _practiceScore = 0;

  static const List<String> _steps = <String>[
    'Видео',
    'Конспект',
    'Диалоги',
    'Практика',
  ];

  @override
  Widget build(BuildContext context) {
    final CourseInfo? course = _findCourse(widget.courseId);
    final LessonInfo lesson =
        course?.modules.first.lessons.first ?? _fallbackLesson;

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: SafeArea(
        child: Column(
          children: [
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
                  if (_step == 0)
                    _VideoStep(
                      showSubtitles: _showSubtitles,
                      onChanged: (v) => setState(() => _showSubtitles = v),
                      onWordsTap: () => _openWordList(lesson.words),
                    ),
                  if (_step == 1)
                    _NotesStep(words: lesson.words, onTapWord: _openWordCard),
                  if (_step == 2) const _DialogStep(),
                  if (_step == 3)
                    _PracticeStep(
                      onScoreUpdated: (score) => _practiceScore = score,
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
                onPressed: () {
                  if (_step < 3) {
                    setState(() => _step += 1);
                    return;
                  }
                  context.push(
                    '/courses/${widget.courseId}/lesson/summary?score=$_practiceScore',
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                ),
                child: Text(_step < 3 ? 'Далее' : 'Завершить урок'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CourseInfo? _findCourse(String id) {
    for (final CourseInfo course in mockCourses) {
      if (course.id == id) {
        return course;
      }
    }
    return null;
  }

  Future<void> _openWordList(List<LessonWord> words) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Слова урока',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 8),
                ...words.map(
                  (LessonWord word) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(word.value),
                    subtitle: Text(word.translation),
                    onTap: () {
                      Navigator.of(context).pop();
                      _openWordCard(word);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openWordCard(LessonWord word) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    word.translation,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(word.transcription),
                  const SizedBox(height: 8),
                  Text(
                    'Пример: ${word.example}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.volume_up_outlined),
                        label: const Text('Озвучить'),
                      ),
                      FilledButton.tonal(
                        onPressed: () {
                          setState(() => _savedWord = !_savedWord);
                          setSheetState(() {});
                        },
                        child: Text(
                          _savedWord ? 'В словаре' : 'Добавить в словарь',
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () {
                          setState(() => _markedHard = !_markedHard);
                          setSheetState(() {});
                        },
                        child: Text(
                          _markedHard ? 'Помечено трудным' : 'Пометить трудным',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _VideoStep extends StatelessWidget {
  const _VideoStep({
    required this.showSubtitles,
    required this.onChanged,
    required this.onWordsTap,
  });

  final bool showSubtitles;
  final ValueChanged<bool> onChanged;
  final VoidCallback onWordsTap;

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
            child: const Icon(
              Icons.play_circle_fill,
              color: Colors.white,
              size: 64,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: showSubtitles,
          onChanged: onChanged,
          title: const Text('Субтитры: кыргызский + русский'),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 4),
        FilledButton.tonalIcon(
          onPressed: onWordsTap,
          icon: const Icon(Icons.menu_book_outlined),
          label: const Text('Слова урока'),
        ),
      ],
    );
  }
}

class _NotesStep extends StatelessWidget {
  const _NotesStep({required this.words, required this.onTapWord});

  final List<LessonWord> words;
  final ValueChanged<LessonWord> onTapWord;

  @override
  Widget build(BuildContext context) {
    final LessonWord first = words.isNotEmpty ? words.first : _fallbackWord;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'В этом уроке вы научитесь представляться, задавать уточняющие вопросы и вежливо завершать диалог.',
          style: TextStyle(height: 1.45),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _WordChip(word: first, onTap: onTapWord),
            if (words.length > 1) _WordChip(word: words[1], onTap: onTapWord),
          ],
        ),
      ],
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.word, required this.onTap});

  final LessonWord word;
  final ValueChanged<LessonWord> onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: () => onTap(word),
      label: Text(word.value),
      side: const BorderSide(color: AppColors.brandPrimary),
      labelStyle: const TextStyle(color: AppColors.brandPrimary),
      avatar: const Icon(
        Icons.translate,
        color: AppColors.brandPrimary,
        size: 18,
      ),
    );
  }
}

class _DialogStep extends StatelessWidget {
  const _DialogStep();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Диалог 1: В университете',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _PhraseRow(
          phrase: 'Саламатсызбы, менин атым Азамат.',
          translation: 'Здравствуйте, меня зовут Азамат.',
        ),
        _PhraseRow(
          phrase: 'Таанышканыма кубанычтамын.',
          translation: 'Рад знакомству.',
        ),
      ],
    );
  }
}

class _PhraseRow extends StatelessWidget {
  const _PhraseRow({required this.phrase, required this.translation});

  final String phrase;
  final String translation;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phrase,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  translation,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.volume_up_outlined),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.replay_outlined)),
        ],
      ),
    );
  }
}

class _PracticeStep extends StatefulWidget {
  const _PracticeStep({required this.onScoreUpdated});

  final ValueChanged<int> onScoreUpdated;

  @override
  State<_PracticeStep> createState() => _PracticeStepState();
}

class _PracticeStepState extends State<_PracticeStep> {
  final List<bool?> _answers = <bool?>[null, null, null];

  @override
  Widget build(BuildContext context) {
    final int score = _answers.where((bool? e) => e == true).length * 33;
    widget.onScoreUpdated(score);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Практика',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _QuestionCard(
          title: '1. Выберите правильный перевод',
          options: const ['Меня зовут...', 'Я работаю...', 'Я студент...'],
          onAnswered: (bool ok) => setState(() => _answers[0] = ok),
        ),
        _QuestionCard(
          title: '2. Вставьте пропуск',
          options: const ['барамын', 'келемин', 'окуп жатам'],
          onAnswered: (bool ok) => setState(() => _answers[1] = ok),
        ),
        _QuestionCard(
          title: '3. Устная практика',
          options: const ['Записать ответ'],
          onAnswered: (bool ok) => setState(() => _answers[2] = ok),
          voice: true,
        ),
        const SizedBox(height: 8),
        Text(
          'Текущий результат: $score%',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.title,
    required this.options,
    required this.onAnswered,
    this.voice = false,
  });

  final String title;
  final List<String> options;
  final ValueChanged<bool> onAnswered;
  final bool voice;

  @override
  Widget build(BuildContext context) {
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...options.map(
            (String option) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: voice
                  ? OutlinedButton.icon(
                      onPressed: () => onAnswered(true),
                      icon: const Icon(Icons.mic_none),
                      label: Text(option),
                    )
                  : OutlinedButton(
                      onPressed: () => onAnswered(option == options.first),
                      child: Text(option),
                    ),
            ),
          ),
        ],
      ),
    );
  }
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

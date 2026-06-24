enum CourseStatus { notStarted, inProgress, completed }

enum CourseType {
  general,
  ort,
  speaking,
  business,
  grammar,
  reading,
  pronunciation,
}

class LessonInfo {
  const LessonInfo({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.words,
    this.description = '',
    this.videoUrl = '',
    this.subtitlesUrl = '',
    this.textContent = '',
  });

  final String id;
  final String title;
  final int durationMinutes;
  final List<LessonWord> words;
  final String description;
  final String videoUrl;
  final String subtitlesUrl;
  final String textContent;

  factory LessonInfo.fromJson(Map<String, dynamic> json) {
    final List<dynamic> lessonWords = json['lessonWords'] is List<dynamic>
        ? json['lessonWords'] as List<dynamic>
        : const <dynamic>[];
    final int durationSec = _asInt(json['videoDurationSec']);
    return LessonInfo(
      id: _asString(json['id']),
      title: _asString(json['title'], fallback: 'Урок'),
      durationMinutes: durationSec > 0 ? (durationSec / 60).ceil() : 30,
      description: _asString(json['description']),
      videoUrl: _asString(json['videoUrl']),
      subtitlesUrl: _asString(json['subtitlesUrl']),
      textContent: _asString(json['textContent']),
      words: lessonWords
          .map((dynamic item) => LessonWord.fromLessonWordJson(_asMap(item)))
          .where((LessonWord word) => word.value.isNotEmpty)
          .toList(),
    );
  }
}

class LessonWord {
  const LessonWord({
    required this.value,
    required this.translation,
    required this.transcription,
    required this.example,
    this.id = '',
    this.audioUrl = '',
  });

  final String id;
  final String value;
  final String translation;
  final String transcription;
  final String example;
  final String audioUrl;

  factory LessonWord.fromLessonWordJson(Map<String, dynamic> json) {
    final Map<String, dynamic> word = _asMap(json['word']);
    return LessonWord.fromJson(word.isEmpty ? json : word);
  }

  factory LessonWord.fromJson(Map<String, dynamic> json) {
    return LessonWord(
      id: _asString(json['id']),
      value: _asString(json['word'], fallback: _asString(json['value'])),
      translation: _asString(json['translation']),
      transcription: _asString(json['transcription']),
      example: _asString(
        json['exampleKg'],
        fallback: _asString(
          json['example'],
          fallback: _asString(json['exampleRu']),
        ),
      ),
      audioUrl: _asString(json['audioUrl']),
    );
  }
}

class CourseModule {
  const CourseModule({
    required this.id,
    required this.title,
    required this.progress,
    required this.lessons,
  });

  final String id;
  final String title;
  final double progress;
  final List<LessonInfo> lessons;

  factory CourseModule.fromJson(Map<String, dynamic> json) {
    final List<dynamic> lessons = json['lessons'] is List<dynamic>
        ? json['lessons'] as List<dynamic>
        : const <dynamic>[];
    final int totalLessons = _asInt(
      json['totalLessons'],
      fallback: lessons.length,
    );
    final int completedLessons = _asInt(json['completedLessons']);
    return CourseModule(
      id: _asString(json['id']),
      title: _asString(json['title'], fallback: 'Модуль'),
      progress: totalLessons <= 0
          ? 0
          : (completedLessons / totalLessons).clamp(0, 1).toDouble(),
      lessons: lessons
          .map((dynamic item) => LessonInfo.fromJson(_asMap(item)))
          .where(
            (LessonInfo lesson) =>
                lesson.id.isNotEmpty || lesson.title.isNotEmpty,
          )
          .toList(),
    );
  }
}

class CourseInfo {
  const CourseInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.coverLabel,
    required this.level,
    required this.type,
    required this.lessonCount,
    required this.totalMinutes,
    required this.status,
    required this.goals,
    required this.audience,
    required this.modules,
  });

  final String id;
  final String title;
  final String description;
  final String coverLabel;
  final String level;
  final CourseType type;
  final int lessonCount;
  final int totalMinutes;
  final CourseStatus status;
  final List<String> goals;
  final List<String> audience;
  final List<CourseModule> modules;

  factory CourseInfo.fromJson(Map<String, dynamic> json) {
    final List<dynamic> modules = json['modules'] is List<dynamic>
        ? json['modules'] as List<dynamic>
        : const <dynamic>[];
    final int progress = _asInt(json['userProgressPercent']);
    return CourseInfo(
      id: _asString(json['id']),
      title: _asString(json['title'], fallback: 'Курс'),
      description: _asString(json['description']),
      coverLabel: _asString(json['level'], fallback: 'Курс'),
      level: _asString(json['level']),
      type: _courseTypeFromApi(_asString(json['type'])),
      lessonCount: _asInt(json['totalLessons']),
      totalMinutes: _estimateCourseMinutes(modules),
      status: _courseStatusFromApi(json),
      goals: _splitApiText(_asString(json['learningGoals'])),
      audience: _splitApiText(_asString(json['targetAudience'])),
      modules: modules
          .map((dynamic item) => CourseModule.fromJson(_asMap(item)))
          .where(
            (CourseModule module) =>
                module.id.isNotEmpty || module.title.isNotEmpty,
          )
          .toList(),
    )._withProgressFallback(progress);
  }

  CourseInfo _withProgressFallback(int progressPercent) {
    if (modules.isNotEmpty || progressPercent <= 0) return this;
    return CourseInfo(
      id: id,
      title: title,
      description: description,
      coverLabel: coverLabel,
      level: level,
      type: type,
      lessonCount: lessonCount,
      totalMinutes: totalMinutes,
      status: status,
      goals: goals,
      audience: audience,
      modules: <CourseModule>[
        CourseModule(
          id: '${id}_progress',
          title: 'Прогресс курса',
          progress: (progressPercent / 100).clamp(0, 1).toDouble(),
          lessons: const <LessonInfo>[],
        ),
      ],
    );
  }
}

class UserCourseProgress {
  const UserCourseProgress({
    required this.courseId,
    required this.courseTitle,
    required this.progressPercent,
    required this.completedLessons,
    required this.totalLessons,
    required this.completed,
    this.courseCoverUrl = '',
    this.lastLessonId = '',
    this.lastLessonTitle = '',
    this.lastLessonStatus = '',
  });

  final String courseId;
  final String courseTitle;
  final String courseCoverUrl;
  final int progressPercent;
  final int completedLessons;
  final int totalLessons;
  final bool completed;
  final String lastLessonId;
  final String lastLessonTitle;
  final String lastLessonStatus;

  factory UserCourseProgress.fromJson(Map<String, dynamic> json) {
    return UserCourseProgress(
      courseId: _asString(json['courseId']),
      courseTitle: _asString(json['courseTitle'], fallback: 'Курс'),
      courseCoverUrl: _asString(json['courseCoverUrl']),
      progressPercent: _asInt(json['progressPercent']),
      completedLessons: _asInt(json['completedLessons']),
      totalLessons: _asInt(json['totalLessons']),
      completed: json['completed'] == true,
      lastLessonId: _asString(json['lastLessonId']),
      lastLessonTitle: _asString(json['lastLessonTitle']),
      lastLessonStatus: _asString(json['lastLessonStatus']),
    );
  }

  CourseInfo toCourseInfo() {
    final int safeTotal = totalLessons <= 0 ? completedLessons : totalLessons;
    return CourseInfo(
      id: courseId,
      title: courseTitle,
      description: lastLessonTitle.isEmpty
          ? ''
          : 'Последний урок: $lastLessonTitle',
      coverLabel: courseTitle.isNotEmpty ? courseTitle.substring(0, 1) : 'К',
      level: '',
      type: CourseType.general,
      lessonCount: safeTotal,
      totalMinutes: safeTotal * 30,
      status: completed
          ? CourseStatus.completed
          : progressPercent > 0 || lastLessonId.isNotEmpty
          ? CourseStatus.inProgress
          : CourseStatus.notStarted,
      goals: const <String>[],
      audience: const <String>[],
      modules: <CourseModule>[
        CourseModule(
          id: '${courseId}_progress',
          title: 'Прогресс курса',
          progress: (progressPercent / 100).clamp(0, 1).toDouble(),
          lessons: const <LessonInfo>[],
        ),
      ],
    );
  }
}

class ExerciseInfo {
  const ExerciseInfo({
    required this.id,
    required this.type,
    required this.questionText,
    required this.options,
    this.hint = '',
    this.audioUrl = '',
    this.imageUrl = '',
  });

  final String id;
  final String type;
  final String questionText;
  final String hint;
  final String audioUrl;
  final String imageUrl;
  final List<AnswerOption> options;

  factory ExerciseInfo.fromJson(Map<String, dynamic> json) {
    final List<dynamic> options = json['options'] is List<dynamic>
        ? json['options'] as List<dynamic>
        : const <dynamic>[];
    return ExerciseInfo(
      id: _asString(json['id']),
      type: _asString(json['type']),
      questionText: _asString(json['questionText'], fallback: 'Вопрос'),
      hint: _asString(json['hint']),
      audioUrl: _asString(json['audioUrl']),
      imageUrl: _asString(json['imageUrl']),
      options: options
          .map((dynamic item) => AnswerOption.fromJson(_asMap(item)))
          .where((AnswerOption option) => option.text.isNotEmpty)
          .toList(),
    );
  }
}

class TestInfo {
  const TestInfo({
    required this.id,
    required this.title,
    required this.questions,
    this.description = '',
    this.passingScore = 70,
    this.timeLimitMinutes = 0,
  });

  final String id;
  final String title;
  final String description;
  final int passingScore;
  final int timeLimitMinutes;
  final List<TestQuestionInfo> questions;

  factory TestInfo.fromJson(Map<String, dynamic> json) {
    final List<dynamic> questions = json['questions'] is List<dynamic>
        ? json['questions'] as List<dynamic>
        : const <dynamic>[];
    return TestInfo(
      id: _asString(json['id']),
      title: _asString(json['title'], fallback: 'Тест'),
      description: _asString(json['description']),
      passingScore: _asInt(json['passingScore'], fallback: 70),
      timeLimitMinutes: _asInt(json['timeLimitMinutes']),
      questions: questions
          .map((dynamic item) => TestQuestionInfo.fromJson(_asMap(item)))
          .where((TestQuestionInfo question) => question.id.isNotEmpty)
          .toList(),
    );
  }
}

class TestAttemptInfo {
  const TestAttemptInfo({
    required this.attemptId,
    required this.testId,
    required this.testTitle,
    required this.scorePercent,
    required this.passingScore,
    required this.passed,
    required this.xpEarned,
    this.unlockMessage = '',
  });

  final String attemptId;
  final String testId;
  final String testTitle;
  final int scorePercent;
  final int passingScore;
  final bool passed;
  final int xpEarned;
  final String unlockMessage;

  factory TestAttemptInfo.fromJson(Map<String, dynamic> json) {
    return TestAttemptInfo(
      attemptId: _asString(json['attemptId']),
      testId: _asString(json['testId']),
      testTitle: _asString(json['testTitle'], fallback: 'Тест'),
      scorePercent: _asInt(json['scorePercent']),
      passingScore: _asInt(json['passingScore'], fallback: 70),
      passed: json['passed'] == true,
      xpEarned: _asInt(json['xpEarned']),
      unlockMessage: _asString(json['unlockMessage']),
    );
  }
}

class TestQuestionInfo {
  const TestQuestionInfo({
    required this.id,
    required this.type,
    required this.questionText,
    required this.options,
    this.audioUrl = '',
    this.imageUrl = '',
  });

  final String id;
  final String type;
  final String questionText;
  final String audioUrl;
  final String imageUrl;
  final List<AnswerOption> options;

  factory TestQuestionInfo.fromJson(Map<String, dynamic> json) {
    final List<dynamic> options = json['options'] is List<dynamic>
        ? json['options'] as List<dynamic>
        : const <dynamic>[];
    return TestQuestionInfo(
      id: _asString(json['id']),
      type: _asString(json['type']),
      questionText: _asString(json['questionText'], fallback: 'Вопрос'),
      audioUrl: _asString(json['audioUrl']),
      imageUrl: _asString(json['imageUrl']),
      options: options
          .map((dynamic item) => AnswerOption.fromJson(_asMap(item)))
          .where((AnswerOption option) => option.text.isNotEmpty)
          .toList(),
    );
  }
}

class AnswerOption {
  const AnswerOption({
    required this.id,
    required this.text,
    this.matchText = '',
  });

  final String id;
  final String text;
  final String matchText;

  factory AnswerOption.fromJson(Map<String, dynamic> json) {
    return AnswerOption(
      id: _asString(json['id']),
      text: _asString(json['text']),
      matchText: _asString(json['matchText']),
    );
  }
}

CourseType _courseTypeFromApi(String value) {
  return switch (value.toUpperCase()) {
    'ORT' => CourseType.ort,
    'CONVERSATIONAL' => CourseType.speaking,
    'BUSINESS' => CourseType.business,
    'GRAMMAR' => CourseType.grammar,
    'READING' => CourseType.reading,
    'PRONUNCIATION' => CourseType.pronunciation,
    _ => CourseType.general,
  };
}

CourseStatus _courseStatusFromApi(Map<String, dynamic> json) {
  if (json['userCompleted'] == true) return CourseStatus.completed;
  if (_asInt(json['userProgressPercent']) > 0 || json['userEnrolled'] == true) {
    return CourseStatus.inProgress;
  }
  return CourseStatus.notStarted;
}

int _estimateCourseMinutes(List<dynamic> modules) {
  int total = 0;
  for (final dynamic module in modules) {
    final List<dynamic> lessons = _asMap(module)['lessons'] is List<dynamic>
        ? _asMap(module)['lessons'] as List<dynamic>
        : const <dynamic>[];
    for (final dynamic lesson in lessons) {
      total += (_asInt(_asMap(lesson)['videoDurationSec']) / 60).ceil();
    }
  }
  return total;
}

List<String> _splitApiText(String value) {
  return value
      .split(RegExp(r'[\n;]+'))
      .map((String item) => item.trim())
      .where((String item) => item.isNotEmpty)
      .toList();
}

Map<String, dynamic> _asMap(dynamic value) {
  return value is Map<String, dynamic> ? value : <String, dynamic>{};
}

String _asString(dynamic value, {String fallback = ''}) {
  final String text = (value ?? '').toString().trim();
  return text.isEmpty ? fallback : text;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse((value ?? '').toString()) ?? fallback;
}

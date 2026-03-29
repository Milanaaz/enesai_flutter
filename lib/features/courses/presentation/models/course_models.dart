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
  });

  final String id;
  final String title;
  final int durationMinutes;
  final List<LessonWord> words;
}

class LessonWord {
  const LessonWord({
    required this.value,
    required this.translation,
    required this.transcription,
    required this.example,
  });

  final String value;
  final String translation;
  final String transcription;
  final String example;
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
}

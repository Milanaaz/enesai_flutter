enum WordStatus { learning, learned }

class DictionaryWord {
  const DictionaryWord({
    required this.id,
    required this.kyrgyz,
    required this.translation,
    required this.transcription,
    required this.example,
    required this.topic,
    required this.sourceLesson,
    required this.addedAt,
    required this.status,
    required this.isFavorite,
    required this.difficulty,
    this.knowStreak = 0,
  });

  final String id;
  final String kyrgyz;
  final String translation;
  final String transcription;
  final String example;
  final String topic;
  final String sourceLesson;
  final DateTime addedAt;
  final WordStatus status;
  final bool isFavorite;
  final int difficulty;
  final int knowStreak;

  DictionaryWord copyWith({
    WordStatus? status,
    bool? isFavorite,
    int? difficulty,
    int? knowStreak,
  }) {
    return DictionaryWord(
      id: id,
      kyrgyz: kyrgyz,
      translation: translation,
      transcription: transcription,
      example: example,
      topic: topic,
      sourceLesson: sourceLesson,
      addedAt: addedAt,
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
      difficulty: difficulty ?? this.difficulty,
      knowStreak: knowStreak ?? this.knowStreak,
    );
  }
}

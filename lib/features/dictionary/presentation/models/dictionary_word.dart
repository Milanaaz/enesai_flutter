enum WordStatus { learning, learned, favorite, difficult }

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
    this.nextReviewAt,
    this.audioUrl = '',
    this.level = '',
    this.userWordId,
    this.wordId,
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
  final DateTime? nextReviewAt;
  final String audioUrl;
  final String level;
  final String? userWordId;
  final String? wordId;

  factory DictionaryWord.fromUserJson(Map<String, dynamic> json) {
    final Map<String, dynamic> word = _asMap(json['word']);
    final String statusText = (json['status'] ?? '').toString();
    final WordStatus status = _statusFromApi(statusText);
    final int repetitionCount = _asInt(json['repetitionCount']);
    return DictionaryWord(
      id: (json['id'] ?? word['id'] ?? '').toString(),
      userWordId: (json['id'] ?? '').toString(),
      wordId: (word['id'] ?? '').toString(),
      kyrgyz: (word['word'] ?? '').toString(),
      translation: (word['translation'] ?? '').toString(),
      transcription: (word['transcription'] ?? '').toString(),
      example: (word['exampleKg'] ?? word['exampleRu'] ?? '').toString(),
      topic: (word['topic'] ?? '').toString(),
      sourceLesson: (word['level'] ?? '').toString(),
      addedAt: _asDate(json['addedAt']) ?? DateTime.now(),
      status: status == WordStatus.favorite ? WordStatus.learning : status,
      isFavorite: status == WordStatus.favorite,
      difficulty: status == WordStatus.difficult
          ? 5
          : (2 + repetitionCount).clamp(1, 5),
      knowStreak: repetitionCount,
      nextReviewAt: _asDate(json['nextReviewAt']),
      audioUrl: (word['audioUrl'] ?? '').toString(),
      level: (word['level'] ?? '').toString(),
    );
  }

  factory DictionaryWord.fromGlobalJson(Map<String, dynamic> json) {
    return DictionaryWord(
      id: (json['id'] ?? '').toString(),
      wordId: (json['id'] ?? '').toString(),
      kyrgyz: (json['word'] ?? '').toString(),
      translation: (json['translation'] ?? '').toString(),
      transcription: (json['transcription'] ?? '').toString(),
      example: (json['exampleKg'] ?? json['exampleRu'] ?? '').toString(),
      topic: (json['topic'] ?? '').toString(),
      sourceLesson: (json['level'] ?? '').toString(),
      addedAt: DateTime.now(),
      status: WordStatus.learning,
      isFavorite: false,
      difficulty: 2,
      audioUrl: (json['audioUrl'] ?? '').toString(),
      level: (json['level'] ?? '').toString(),
    );
  }

  DictionaryWord copyWith({
    WordStatus? status,
    bool? isFavorite,
    int? difficulty,
    int? knowStreak,
    DateTime? nextReviewAt,
    String? userWordId,
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
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      audioUrl: audioUrl,
      level: level,
      userWordId: userWordId ?? this.userWordId,
      wordId: wordId,
    );
  }
}

String wordStatusLabel(WordStatus status) {
  switch (status) {
    case WordStatus.learning:
      return 'Изучаю';
    case WordStatus.learned:
      return 'Выучил';
    case WordStatus.favorite:
      return 'Избранное';
    case WordStatus.difficult:
      return 'Сложное';
  }
}

String wordStatusToApi(WordStatus status) {
  switch (status) {
    case WordStatus.learning:
      return 'LEARNING';
    case WordStatus.learned:
      return 'LEARNED';
    case WordStatus.favorite:
      return 'FAVORITE';
    case WordStatus.difficult:
      return 'DIFFICULT';
  }
}

WordStatus _statusFromApi(String value) {
  switch (value.toUpperCase()) {
    case 'LEARNED':
      return WordStatus.learned;
    case 'FAVORITE':
      return WordStatus.favorite;
    case 'DIFFICULT':
      return WordStatus.difficult;
    case 'LEARNING':
    default:
      return WordStatus.learning;
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  return value is Map<String, dynamic> ? value : <String, dynamic>{};
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse((value ?? '').toString()) ?? 0;
}

DateTime? _asDate(dynamic value) {
  final String text = (value ?? '').toString();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

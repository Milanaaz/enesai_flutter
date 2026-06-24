class LibraryBook {
  const LibraryBook({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.coverUrl,
    required this.level,
    required this.genre,
    required this.readingTimeMinutes,
    required this.totalPages,
    required this.userCurrentPage,
    required this.userProgressPercent,
    required this.userStarted,
    required this.userFinished,
  });

  factory LibraryBook.fromJson(Map<String, dynamic> json) {
    return LibraryBook(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      author: (json['author'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      coverUrl: (json['coverUrl'] ?? '').toString(),
      level: (json['level'] ?? '').toString(),
      genre: (json['genre'] ?? '').toString(),
      readingTimeMinutes: _asInt(json['readingTimeMinutes']),
      totalPages: _asInt(json['totalPages']),
      userCurrentPage: _asInt(json['userCurrentPage'], fallback: 1),
      userProgressPercent: _asInt(json['userProgressPercent']),
      userStarted: json['userStarted'] == true,
      userFinished: json['userFinished'] == true,
    );
  }

  final String id;
  final String title;
  final String author;
  final String description;
  final String coverUrl;
  final String level;
  final String genre;
  final int readingTimeMinutes;
  final int totalPages;
  final int userCurrentPage;
  final int userProgressPercent;
  final bool userStarted;
  final bool userFinished;
}

class LibraryBookPage {
  const LibraryBookPage({
    required this.id,
    required this.pageNumber,
    required this.totalPages,
    required this.content,
    required this.contentRu,
    required this.audioUrl,
    required this.hasNext,
    required this.hasPrev,
    required this.progressPercent,
  });

  factory LibraryBookPage.fromJson(Map<String, dynamic> json) {
    return LibraryBookPage(
      id: (json['id'] ?? '').toString(),
      pageNumber: _asInt(json['pageNumber'], fallback: 1),
      totalPages: _asInt(json['totalPages']),
      content: (json['content'] ?? '').toString(),
      contentRu: (json['contentRu'] ?? '').toString(),
      audioUrl: (json['audioUrl'] ?? '').toString(),
      hasNext: json['hasNext'] == true,
      hasPrev: json['hasPrev'] == true,
      progressPercent: _asInt(json['progressPercent']),
    );
  }

  final String id;
  final int pageNumber;
  final int totalPages;
  final String content;
  final String contentRu;
  final String audioUrl;
  final bool hasNext;
  final bool hasPrev;
  final int progressPercent;
}

class WordTranslation {
  const WordTranslation({
    required this.wordId,
    required this.word,
    required this.translation,
    required this.transcription,
    required this.inUserDictionary,
    required this.userWordId,
  });

  factory WordTranslation.fromJson(Map<String, dynamic> json) {
    return WordTranslation(
      wordId: (json['wordId'] ?? json['id'] ?? '').toString(),
      word: (json['word'] ?? '').toString(),
      translation: (json['translation'] ?? '').toString(),
      transcription: (json['transcription'] ?? '').toString(),
      inUserDictionary: json['inUserDictionary'] == true,
      userWordId: (json['userWordId'] ?? '').toString(),
    );
  }

  final String wordId;
  final String word;
  final String translation;
  final String transcription;
  final bool inUserDictionary;
  final String userWordId;

  WordTranslation copyWith({
    String? wordId,
    String? word,
    String? translation,
    String? transcription,
    bool? inUserDictionary,
    String? userWordId,
  }) {
    return WordTranslation(
      wordId: wordId ?? this.wordId,
      word: word ?? this.word,
      translation: translation ?? this.translation,
      transcription: transcription ?? this.transcription,
      inUserDictionary: inUserDictionary ?? this.inUserDictionary,
      userWordId: userWordId ?? this.userWordId,
    );
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse((value ?? '').toString()) ?? fallback;
}

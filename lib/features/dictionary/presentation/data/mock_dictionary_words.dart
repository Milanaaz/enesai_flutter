import 'package:dipl/features/dictionary/presentation/models/dictionary_word.dart';

List<DictionaryWord> buildMockDictionaryWords() {
  final DateTime now = DateTime.now();
  return <DictionaryWord>[
    DictionaryWord(
      id: 'w1',
      kyrgyz: 'Салам',
      translation: 'Привет',
      transcription: '[салам]',
      example: 'Салам! Кандайсың?',
      topic: 'Приветствие',
      sourceLesson: 'Модуль 1',
      addedAt: now.subtract(const Duration(days: 2)),
      status: WordStatus.learning,
      isFavorite: true,
      difficulty: 2,
    ),
    DictionaryWord(
      id: 'w2',
      kyrgyz: 'Рахмат',
      translation: 'Спасибо',
      transcription: '[рахмат]',
      example: 'Рахмат, жардам болду.',
      topic: 'Вежливость',
      sourceLesson: 'Модуль 1',
      addedAt: now.subtract(const Duration(days: 5)),
      status: WordStatus.learned,
      isFavorite: false,
      difficulty: 1,
      knowStreak: 2,
    ),
  ];
}

import 'dart:math';

import 'package:dipl/app/app_colors.dart';
import 'package:dipl/features/dictionary/presentation/models/dictionary_word.dart';
import 'package:flutter/material.dart';

class WordReviewPage extends StatefulWidget {
  const WordReviewPage({required this.initialWords, super.key});

  final List<DictionaryWord> initialWords;

  @override
  State<WordReviewPage> createState() => _WordReviewPageState();
}

class _WordReviewPageState extends State<WordReviewPage> {
  static const int _dailyTarget = 20;

  late List<DictionaryWord> _words = List<DictionaryWord>.from(
    widget.initialWords,
  );
  final Map<String, int> _weights = <String, int>{};
  final Map<String, int> _shownCount = <String, int>{};
  int _reviewedToday = 0;
  bool _started = false;
  DictionaryWord? _current;

  @override
  void initState() {
    super.initState();
    for (final DictionaryWord word in _words) {
      _weights[word.id] = _initialWeight(word);
    }
    _current = _pickNextWord();
  }

  @override
  Widget build(BuildContext context) {
    final int learnedCount = _words
        .where((DictionaryWord w) => w.status == WordStatus.learned)
        .length;
    final int hardCount = _weights.values
        .where((int value) => value >= 4)
        .length;
    final double progress = _words.isEmpty ? 0 : learnedCount / _words.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Повторение слов')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Сегодня повторить: 20 слов',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _current == null
                            ? null
                            : () {
                                setState(() {
                                  _started = true;
                                });
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                        ),
                        child: const Text('Начать повторение'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _ReviewStats(
                reviewedToday: _reviewedToday,
                learned: learnedCount,
                hard: hardCount,
                progress: progress,
              ),
              const SizedBox(height: 14),
              if (!_started)
                const _ReviewHint()
              else
                Expanded(
                  child: _current == null
                      ? _ReviewFinished(
                          onBack: () => Navigator.of(context).pop(_words),
                        )
                      : _ReviewCard(
                          word: _current!,
                          reviewed: _reviewedToday,
                          target: _dailyTarget,
                          onKnow: () => _handleAnswer(_ReviewAnswer.know),
                          onHard: () => _handleAnswer(_ReviewAnswer.hard),
                          onDontKnow: () =>
                              _handleAnswer(_ReviewAnswer.dontKnow),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  int _initialWeight(DictionaryWord word) {
    if (word.status == WordStatus.learned) {
      return 1;
    }
    return max(2, word.difficulty);
  }

  void _handleAnswer(_ReviewAnswer answer) {
    final DictionaryWord current = _current!;
    final int currentWeight = _weights[current.id] ?? 2;
    final int currentShown = _shownCount[current.id] ?? 0;
    _shownCount[current.id] = currentShown + 1;

    int updatedWeight = currentWeight;
    DictionaryWord updatedWord = current;

    switch (answer) {
      case _ReviewAnswer.know:
        updatedWeight = max(1, currentWeight - 2);
        final int streak = current.knowStreak + 1;
        updatedWord = current.copyWith(
          knowStreak: streak,
          status: streak >= 2 ? WordStatus.learned : current.status,
          difficulty: max(1, current.difficulty - 1),
        );
        break;
      case _ReviewAnswer.hard:
        updatedWeight = min(6, currentWeight + 2);
        updatedWord = current.copyWith(
          knowStreak: 0,
          status: WordStatus.learning,
          difficulty: min(5, current.difficulty + 1),
        );
        break;
      case _ReviewAnswer.dontKnow:
        updatedWeight = min(6, currentWeight + 3);
        updatedWord = current.copyWith(
          knowStreak: 0,
          status: WordStatus.learning,
          difficulty: min(5, current.difficulty + 1),
        );
        break;
    }

    _weights[current.id] = updatedWeight;
    _words = _words.map((DictionaryWord word) {
      if (word.id == current.id) {
        return updatedWord;
      }
      return word;
    }).toList();
    _reviewedToday++;

    if (_reviewedToday >= _dailyTarget) {
      setState(() {
        _current = null;
      });
      return;
    }

    setState(() {
      _current = _pickNextWord();
    });
  }

  DictionaryWord? _pickNextWord() {
    if (_words.isEmpty) {
      return null;
    }

    final List<DictionaryWord> sorted = List<DictionaryWord>.from(_words);
    sorted.sort((a, b) {
      final int wa = _weights[a.id] ?? 1;
      final int wb = _weights[b.id] ?? 1;
      if (wa != wb) {
        return wb.compareTo(wa);
      }
      final int shownA = _shownCount[a.id] ?? 0;
      final int shownB = _shownCount[b.id] ?? 0;
      return shownA.compareTo(shownB);
    });
    return sorted.first;
  }
}

class _ReviewStats extends StatelessWidget {
  const _ReviewStats({
    required this.reviewedToday,
    required this.learned,
    required this.hard,
    required this.progress,
  });

  final int reviewedToday;
  final int learned;
  final int hard;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  title: 'Повторено сегодня',
                  value: '$reviewedToday',
                ),
              ),
              Expanded(
                child: _StatItem(title: 'Усвоено', value: '$learned'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatItem(title: 'Осталось трудными', value: '$hard'),
              ),
              Expanded(
                child: _StatItem(
                  title: 'Общий прогресс',
                  value: '${(progress * 100).round()}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ReviewHint extends StatelessWidget {
  const _ReviewHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'После старта слово показывается на карточке. Отмечайте: "Знаю", '
        '"Сложно", "Не знаю". Трудные слова будут появляться чаще.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.word,
    required this.reviewed,
    required this.target,
    required this.onKnow,
    required this.onHard,
    required this.onDontKnow,
  });

  final DictionaryWord word;
  final int reviewed;
  final int target;
  final VoidCallback onKnow;
  final VoidCallback onHard;
  final VoidCallback onDontKnow;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE4E7EC)),
          ),
          child: Column(
            children: [
              Text(
                word.kyrgyz,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                word.translation,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandPrimary,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                word.transcription,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: reviewed / target,
            minHeight: 7,
            backgroundColor: const Color(0xFFE4E7EC),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.brandPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: onKnow,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF12B76A),
                ),
                child: const Text('Знаю'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonal(
                onPressed: onHard,
                child: const Text('Сложно'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: onDontKnow,
                child: const Text('Не знаю'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReviewFinished extends StatelessWidget {
  const _ReviewFinished({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF12B76A), size: 56),
          const SizedBox(height: 10),
          const Text(
            'Повторение на сегодня завершено',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: onBack,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
            ),
            child: const Text('Вернуться в словарь'),
          ),
        ],
      ),
    );
  }
}

enum _ReviewAnswer { know, hard, dontKnow }

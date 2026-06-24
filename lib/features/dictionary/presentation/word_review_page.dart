import 'package:dipl/app/app_colors.dart';
import 'package:dipl/features/dictionary/presentation/data/dictionary_api_service.dart';
import 'package:dipl/features/dictionary/presentation/models/dictionary_word.dart';
import 'package:flutter/material.dart';

class WordReviewPage extends StatefulWidget {
  const WordReviewPage({super.key});

  @override
  State<WordReviewPage> createState() => _WordReviewPageState();
}

class _WordReviewPageState extends State<WordReviewPage> {
  final DictionaryApiService _service = DictionaryApiService.instance;
  List<DictionaryWord> _words = const <DictionaryWord>[];
  int _index = 0;
  int _reviewedToday = 0;
  bool _started = false;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  DictionaryWord? get _current =>
      _index < _words.length ? _words[_index] : null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final DictionaryWord? current = _current;

    return Scaffold(
      appBar: AppBar(title: const Text('Повторение слов')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : Column(
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
                          Text(
                            'Сегодня повторить: ${_words.length} слов',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: current == null
                                  ? null
                                  : () => setState(() => _started = true),
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
                      total: _words.length,
                      remaining: (_words.length - _reviewedToday).clamp(
                        0,
                        _words.length,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (!_started)
                      const _ReviewHint()
                    else
                      Expanded(
                        child: current == null
                            ? _ReviewFinished(
                                onBack: () => Navigator.of(context).pop(),
                              )
                            : _ReviewCard(
                                word: current,
                                reviewed: _reviewedToday,
                                total: _words.length,
                                submitting: _submitting,
                                onKnow: () => _handleAnswer(true),
                                onDontKnow: () => _handleAnswer(false),
                              ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<DictionaryWord> words = await _service.getReviewWords();
      if (!mounted) return;
      setState(() {
        _words = words;
        _index = 0;
        _reviewedToday = 0;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _handleAnswer(bool knew) async {
    final DictionaryWord? current = _current;
    if (current == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      await _service.submitReview(
        userWordId: current.userWordId ?? current.id,
        knew: knew,
      );
      if (!mounted) return;
      setState(() {
        _reviewedToday++;
        _index++;
        _submitting = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _ReviewStats extends StatelessWidget {
  const _ReviewStats({
    required this.reviewedToday,
    required this.total,
    required this.remaining,
  });

  final int reviewedToday;
  final int total;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final double progress = total == 0 ? 0 : reviewedToday / total;
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
                child: _StatItem(title: 'Осталось', value: '$remaining'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFE4E7EC),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.brandPrimary,
              ),
            ),
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
        'После ответа сервер пересчитает дату следующего повторения.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.word,
    required this.reviewed,
    required this.total,
    required this.submitting,
    required this.onKnow,
    required this.onDontKnow,
  });

  final DictionaryWord word;
  final int reviewed;
  final int total;
  final bool submitting;
  final VoidCallback onKnow;
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
              if (word.transcription.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  word.transcription,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('${reviewed + 1} / $total'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: submitting ? null : onKnow,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF12B76A),
                ),
                child: const Text('Знаю'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: submitting ? null : onDontKnow,
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB42318), size: 40),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}

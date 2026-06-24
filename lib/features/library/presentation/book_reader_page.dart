import 'package:dipl/app/app_colors.dart';
import 'package:dipl/features/dictionary/presentation/data/dictionary_api_service.dart';
import 'package:dipl/features/dictionary/presentation/models/dictionary_word.dart';
import 'package:dipl/features/library/data/library_api_service.dart';
import 'package:dipl/features/library/data/library_models.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class BookReaderPage extends StatefulWidget {
  const BookReaderPage({required this.bookId, super.key});

  final String bookId;

  @override
  State<BookReaderPage> createState() => _BookReaderPageState();
}

class _BookReaderPageState extends State<BookReaderPage> {
  final LibraryApiService _service = LibraryApiService.instance;
  final DictionaryApiService _dictionaryService = DictionaryApiService.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  LibraryBook? _book;
  LibraryBookPage? _page;
  bool _loading = true;
  String? _error;
  String? _preparedAudioUrl;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LibraryBookPage? page = _page;
    return Scaffold(
      appBar: AppBar(title: Text(_book?.title ?? 'Книга')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorState(message: _error!, onRetry: _loadInitial)
            : page == null
            ? const Center(child: Text('Страница не найдена'))
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text('Стр. ${page.pageNumber}/${page.totalPages}'),
                            const Spacer(),
                            Text('${page.progressPercent}%'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: (page.progressPercent / 100).clamp(0, 1),
                            minHeight: 7,
                            backgroundColor: const Color(0xFFE4E7EC),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.brandPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: _TappableText(
                        text: page.content,
                        onWordTap: _translateWord,
                      ),
                    ),
                  ),
                  if (page.audioUrl.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _AudioControls(
                        player: _audioPlayer,
                        onPlayPause: () => _toggleAudio(page.audioUrl),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: page.hasPrev
                                ? () => _loadPage(page.pageNumber - 1)
                                : null,
                            icon: const Icon(Icons.chevron_left),
                            label: const Text('Назад'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: page.hasNext
                                ? () => _loadPage(page.pageNumber + 1)
                                : () => _finishBook(page),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandPrimary,
                            ),
                            icon: Icon(
                              page.hasNext ? Icons.chevron_right : Icons.check,
                            ),
                            label: Text(page.hasNext ? 'Далее' : 'Завершить'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final LibraryBook book = await _service.getBook(widget.bookId);
      final int pageNumber = book.userCurrentPage < 1
          ? 1
          : book.userCurrentPage;
      final LibraryBookPage page = await _service.getPage(
        bookId: widget.bookId,
        pageNumber: pageNumber,
      );
      if (!mounted) return;
      setState(() {
        _book = book;
        _page = page;
        _loading = false;
      });
      await _preparePageAudio(page.audioUrl);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadPage(int pageNumber) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final LibraryBookPage page = await _service.getPage(
        bookId: widget.bookId,
        pageNumber: pageNumber,
      );
      await _service.updateProgress(
        bookId: widget.bookId,
        currentPage: page.pageNumber,
      );
      if (!mounted) return;
      setState(() {
        _page = page;
        _loading = false;
      });
      await _preparePageAudio(page.audioUrl);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _finishBook(LibraryBookPage page) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _service.updateProgress(
        bookId: widget.bookId,
        currentPage: page.pageNumber,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _translateWord(String rawWord) async {
    final String word = rawWord.replaceAll(
      RegExp(r'[^\p{L}\-]', unicode: true),
      '',
    );
    if (word.trim().isEmpty) return;
    try {
      final WordTranslation translation = await _resolveTranslation(word);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _TranslationSheet(
          translation: translation,
          onAdd: translation.inUserDictionary || translation.wordId.isEmpty
              ? null
              : () async {
                  await _dictionaryService.addWord(translation.wordId);
                  if (context.mounted) Navigator.of(context).pop();
                },
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<WordTranslation> _resolveTranslation(String word) async {
    final WordTranslation translation = await _service.translateWord(word);
    if (translation.wordId.isNotEmpty || translation.inUserDictionary) {
      return translation;
    }

    final List<DictionaryWord> matches = await _dictionaryService
        .searchGlobalWords(search: word);
    if (matches.isEmpty) return translation;

    final String normalizedWord = word.toLowerCase();
    final DictionaryWord match = matches.firstWhere(
      (DictionaryWord item) => item.kyrgyz.toLowerCase() == normalizedWord,
      orElse: () => matches.first,
    );
    return translation.copyWith(
      wordId: match.wordId ?? match.id,
      word: translation.word.isEmpty ? match.kyrgyz : translation.word,
      translation: translation.translation.isEmpty
          ? match.translation
          : translation.translation,
      transcription: translation.transcription.isEmpty
          ? match.transcription
          : translation.transcription,
    );
  }

  Future<void> _preparePageAudio(String rawUrl) async {
    final String audioUrl = rawUrl.trim();
    await _audioPlayer.stop();
    _preparedAudioUrl = null;
    if (audioUrl.isEmpty) return;

    try {
      await _audioPlayer.setUrl(audioUrl);
      _preparedAudioUrl = audioUrl;
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось загрузить аудио: $error')),
      );
    }
  }

  Future<void> _toggleAudio(String rawUrl) async {
    final String audioUrl = rawUrl.trim();
    if (audioUrl.isEmpty) return;

    try {
      if (_preparedAudioUrl != audioUrl) {
        await _preparePageAudio(audioUrl);
      }
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось воспроизвести аудио: $error')),
      );
    }
  }
}

class _AudioControls extends StatelessWidget {
  const _AudioControls({required this.player, required this.onPlayPause});

  final AudioPlayer player;
  final VoidCallback onPlayPause;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          StreamBuilder<PlayerState>(
            stream: player.playerStateStream,
            builder: (context, snapshot) {
              final PlayerState? state = snapshot.data;
              final bool loading =
                  state?.processingState == ProcessingState.loading ||
                  state?.processingState == ProcessingState.buffering;
              final bool playing = state?.playing == true;
              return IconButton.filled(
                onPressed: loading ? null : onPlayPause,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                ),
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(playing ? Icons.pause : Icons.play_arrow),
                tooltip: playing ? 'Пауза' : 'Слушать',
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (context, snapshot) {
                final Duration position = snapshot.data ?? Duration.zero;
                final Duration duration = player.duration ?? Duration.zero;
                final double progress = duration.inMilliseconds <= 0
                    ? 0
                    : (position.inMilliseconds / duration.inMilliseconds)
                          .clamp(0, 1)
                          .toDouble();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Аудио страницы',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFE4E7EC),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatAudioDuration(position)} / ${_formatAudioDuration(duration)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _formatAudioDuration(Duration duration) {
  final int minutes = duration.inMinutes;
  final int seconds = duration.inSeconds.remainder(60);
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

class _TappableText extends StatelessWidget {
  const _TappableText({required this.text, required this.onWordTap});

  final String text;
  final ValueChanged<String> onWordTap;

  @override
  Widget build(BuildContext context) {
    final List<String> words = text.split(RegExp(r'(\s+)'));
    return Wrap(
      spacing: 4,
      runSpacing: 8,
      children: words.map((String word) {
        if (word.trim().isEmpty) return Text(word);
        return InkWell(
          onTap: () => onWordTap(word),
          child: Text(word, style: const TextStyle(fontSize: 20, height: 1.35)),
        );
      }).toList(),
    );
  }
}

class _TranslationSheet extends StatelessWidget {
  const _TranslationSheet({required this.translation, required this.onAdd});

  final WordTranslation translation;
  final Future<void> Function()? onAdd;

  @override
  Widget build(BuildContext context) {
    final bool canAdd = onAdd != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translation.word,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            Text(
              translation.translation,
              style: const TextStyle(
                color: AppColors.brandPrimary,
                fontSize: 16,
              ),
            ),
            if (translation.transcription.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(translation.transcription),
            ],
            if (!canAdd && !translation.inUserDictionary) ...[
              const SizedBox(height: 10),
              const Text(
                'Слово не найдено в глобальном словаре, поэтому его нельзя добавить автоматически.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canAdd
                    ? () async {
                        try {
                          await onAdd!.call();
                        } on Object catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                ),
                icon: Icon(
                  translation.inUserDictionary ? Icons.check : Icons.add,
                ),
                label: Text(
                  translation.inUserDictionary
                      ? 'Уже в словаре'
                      : 'Добавить в словарь',
                ),
              ),
            ),
          ],
        ),
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

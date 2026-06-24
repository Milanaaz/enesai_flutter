import 'package:dipl/app/app_colors.dart';
import 'package:dipl/app/widgets/main_bottom_nav.dart';
import 'package:dipl/features/dictionary/presentation/data/dictionary_api_service.dart';
import 'package:dipl/features/dictionary/presentation/models/dictionary_word.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage>
    with TickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  )..addListener(() => setState(() {}));
  final TextEditingController _searchController = TextEditingController();
  final DictionaryApiService _service = DictionaryApiService.instance;

  List<DictionaryWord> _words = const <DictionaryWord>[];
  DictionaryStats? _stats;
  String _query = '';
  WordSort _sort = WordSort.addedDate;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<DictionaryWord> filtered = _sortedWords(
      _words.where(_matchesTab).where(_matchesSearch).toList(),
    );
    final DictionaryStats stats =
        _stats ??
        DictionaryStats(
          totalWords: _words.length,
          learningWords: _words
              .where((DictionaryWord w) => w.status == WordStatus.learning)
              .length,
          learnedWords: _words
              .where((DictionaryWord w) => w.status == WordStatus.learned)
              .length,
          favoriteWords: 0,
          difficultWords: _words
              .where((DictionaryWord w) => w.status == WordStatus.difficult)
              .length,
          dueForReviewToday: 0,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой словарь'),
        actions: [
          IconButton(
            tooltip: 'Глобальный словарь',
            onPressed: _openGlobalSearch,
            icon: const Icon(Icons.manage_search),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    _SearchField(controller: _searchController),
                    const SizedBox(height: 10),
                    _QuickCounters(stats: stats),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: stats.dueForReviewToday == 0
                                ? null
                                : _openReview,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              stats.dueForReviewToday == 0
                                  ? 'Нет слов для повторения'
                                  : 'Повторить ${stats.dueForReviewToday}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _SortMenu(
                          value: _sort,
                          onChanged: (WordSort value) =>
                              setState(() => _sort = value),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_error != null)
                _ErrorBanner(message: _error!, onRetry: _load)
              else if (_loading)
                const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.brandPrimary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x267C3AED),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF667085),
                    labelPadding: EdgeInsets.zero,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    tabs: [
                      Tab(text: 'Изучаю ${stats.learningWords}'),
                      Tab(text: 'Выучил ${stats.learnedWords}'),
                      Tab(text: 'Сложные ${stats.difficultWords}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyDictionary(onAddFromGlobal: _openGlobalSearch)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final DictionaryWord word = filtered[index];
                          return _WordCard(
                            word: word,
                            onDelete: () => _removeWord(word),
                            onTap: () => _openWordDetails(word),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 2),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<Object> results = await Future.wait<Object>([
        _service.getMyDictionary(),
        _service.getStats(),
      ]);
      if (!mounted) return;
      setState(() {
        _words = results[0] as List<DictionaryWord>;
        _stats = results[1] as DictionaryStats;
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

  bool _matchesTab(DictionaryWord word) {
    switch (_tabController.index) {
      case 0:
        return word.status == WordStatus.learning;
      case 1:
        return word.status == WordStatus.learned;
      case 2:
        return word.status == WordStatus.difficult;
      default:
        return true;
    }
  }

  bool _matchesSearch(DictionaryWord word) {
    if (_query.isEmpty) return true;
    return word.kyrgyz.toLowerCase().contains(_query) ||
        word.translation.toLowerCase().contains(_query) ||
        word.topic.toLowerCase().contains(_query);
  }

  List<DictionaryWord> _sortedWords(List<DictionaryWord> words) {
    final List<DictionaryWord> sorted = List<DictionaryWord>.from(words);
    switch (_sort) {
      case WordSort.addedDate:
        sorted.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case WordSort.difficulty:
        sorted.sort((a, b) => b.difficulty.compareTo(a.difficulty));
        break;
      case WordSort.alphabet:
        sorted.sort((a, b) => a.kyrgyz.compareTo(b.kyrgyz));
        break;
    }
    return sorted;
  }

  Future<void> _updateStatus(DictionaryWord word, WordStatus status) async {
    final List<String> ids = _dictionaryPathIds(word);
    if (ids.isEmpty) return;
    Object? lastError;
    try {
      for (final String id in ids) {
        try {
          final DictionaryWord updated = await _service.updateStatus(
            userWordId: id,
            status: status,
          );
          if (!mounted) return;
          setState(() {
            _words = _words
                .map(
                  (DictionaryWord item) =>
                      _sameDictionaryWord(item, word) ? updated : item,
                )
                .toList();
          });
          await _refreshStats();
          return;
        } on Object catch (error) {
          lastError = error;
        }
      }
      _showSnack(lastError?.toString() ?? 'Не удалось обновить слово');
    } on Object catch (error) {
      _showSnack(error.toString());
    }
  }

  Future<void> _removeWord(DictionaryWord word) async {
    final List<String> ids = _dictionaryPathIds(word);
    if (ids.isEmpty) return;
    Object? lastError;
    try {
      for (final String id in ids) {
        try {
          await _service.removeWord(id);
          if (!mounted) return;
          setState(() {
            _words = _words
                .where(
                  (DictionaryWord item) => !_sameDictionaryWord(item, word),
                )
                .toList();
          });
          await _refreshStats();
          return;
        } on Object catch (error) {
          lastError = error;
        }
      }
      _showSnack(lastError?.toString() ?? 'Не удалось удалить слово');
    } on Object catch (error) {
      _showSnack(error.toString());
    }
  }

  List<String> _dictionaryPathIds(DictionaryWord word) {
    final List<String> ids = <String>[
      (word.wordId ?? '').trim(),
      (word.userWordId ?? '').trim(),
      word.id.trim(),
    ].where((String id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) {
      _showSnack('Не найден ID слова в вашем словаре');
    }
    return ids;
  }

  bool _sameDictionaryWord(DictionaryWord left, DictionaryWord right) {
    return left.id == right.id ||
        ((left.userWordId ?? '').isNotEmpty &&
            left.userWordId == right.userWordId) ||
        ((left.wordId ?? '').isNotEmpty && left.wordId == right.wordId);
  }

  Future<void> _refreshStats() async {
    try {
      final DictionaryStats stats = await _service.getStats();
      if (mounted) setState(() => _stats = stats);
    } on Object {
      return;
    }
  }

  Future<void> _openReview() async {
    await context.push<void>('/dictionary/review');
    await _load();
  }

  Future<void> _openGlobalSearch() async {
    final bool? changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _GlobalWordSearchSheet(),
    );
    if (changed == true) await _load();
  }

  Future<void> _openWordDetails(DictionaryWord word) async {
    final DictionaryWord displayWord = await _loadWordDetails(word);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayWord.kyrgyz,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  displayWord.translation,
                  style: const TextStyle(
                    color: AppColors.brandPrimary,
                    fontSize: 16,
                  ),
                ),
                if (displayWord.transcription.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(displayWord.transcription),
                ],
                if (displayWord.example.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Пример: ${displayWord.example}'),
                ],
                const SizedBox(height: 8),
                Text(
                  'Тема: ${displayWord.topic.isEmpty ? 'Без темы' : displayWord.topic}',
                ),
                Text(
                  'Уровень: ${displayWord.level.isEmpty ? displayWord.sourceLesson : displayWord.level}',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _updateStatus(displayWord, WordStatus.learned);
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Выучил'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _updateStatus(displayWord, WordStatus.difficult);
                      },
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Сложное'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _removeWord(displayWord);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Удалить'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<DictionaryWord> _loadWordDetails(DictionaryWord word) async {
    final String wordId = word.wordId ?? '';
    if (wordId.isEmpty) return word;
    try {
      final DictionaryWord details = await _service.getWord(wordId);
      return word.copyWithDetails(details);
    } on Object {
      return word;
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Поиск слова...',
          hintStyle: const TextStyle(fontSize: 14),
          filled: true,
          fillColor: const Color(0xFFF2F4F7),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF98A2B3),
            size: 20,
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _QuickCounters extends StatelessWidget {
  const _QuickCounters({required this.stats});

  final DictionaryStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CounterCard(
            value: stats.learningWords,
            label: 'Изучаю',
            color: AppColors.brandPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CounterCard(
            value: stats.totalWords,
            label: 'Всего слов',
            color: const Color(0xFF101828),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CounterCard(
            value: stats.dueForReviewToday,
            label: 'Повторить',
            color: const Color(0xFF12B76A),
          ),
        ),
      ],
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E7EC)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF667085)),
          ),
        ],
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.value, required this.onChanged});

  final WordSort value;
  final ValueChanged<WordSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<WordSort>(
      tooltip: 'Сортировка',
      onSelected: onChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(value: WordSort.addedDate, child: Text('По дате')),
        PopupMenuItem(value: WordSort.difficulty, child: Text('По сложности')),
        PopupMenuItem(value: WordSort.alphabet, child: Text('По алфавиту')),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE4E7EC)),
        ),
        child: const Row(
          children: [
            Icon(Icons.swap_vert_rounded, size: 18, color: Color(0xFF667085)),
            SizedBox(width: 6),
            Text('Сорт.', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({
    required this.word,
    required this.onDelete,
    required this.onTap,
  });

  final DictionaryWord word;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4E7EC)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.kyrgyz,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    word.translation,
                    style: const TextStyle(
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StatusChip(word: word),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (String value) {
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'delete', child: Text('Удалить')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.word});

  final DictionaryWord word;

  @override
  Widget build(BuildContext context) {
    final WordStatus visibleStatus = word.status == WordStatus.favorite
        ? WordStatus.learning
        : word.status;
    final bool learned = visibleStatus == WordStatus.learned;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: learned ? const Color(0xFFD1FADF) : const Color(0xFFECE7FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        wordStatusLabel(visibleStatus),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: learned ? const Color(0xFF027A48) : AppColors.brandPrimary,
        ),
      ),
    );
  }
}

class _GlobalWordSearchSheet extends StatefulWidget {
  const _GlobalWordSearchSheet();

  @override
  State<_GlobalWordSearchSheet> createState() => _GlobalWordSearchSheetState();
}

class _GlobalWordSearchSheetState extends State<_GlobalWordSearchSheet> {
  final DictionaryApiService _service = DictionaryApiService.instance;
  final TextEditingController _controller = TextEditingController();
  Future<List<DictionaryWord>>? _future;
  final Set<String> _adding = <String>{};
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _future = _service.searchGlobalWords();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * .78,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            14,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Глобальный словарь',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(_changed),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'Найти слово на платформе',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: _search,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF2F4F7),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<DictionaryWord>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _ErrorBanner(
                        message: snapshot.error.toString(),
                        onRetry: _search,
                      );
                    }
                    final List<DictionaryWord> words =
                        snapshot.data ?? const <DictionaryWord>[];
                    if (words.isEmpty) {
                      return const Center(child: Text('Слова не найдены'));
                    }
                    return ListView.separated(
                      itemCount: words.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final DictionaryWord word = words[index];
                        final String id = word.wordId ?? word.id;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            word.kyrgyz,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(word.translation),
                          trailing: _adding.contains(id)
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : IconButton(
                                  tooltip: 'Добавить',
                                  onPressed: () => _add(word),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _search() {
    setState(() {
      _future = _service.searchGlobalWords(search: _controller.text);
    });
  }

  Future<void> _add(DictionaryWord word) async {
    final String id = word.wordId ?? word.id;
    setState(() => _adding.add(id));
    try {
      await _service.addWord(id);
      _changed = true;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${word.kyrgyz} добавлено')));
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _adding.remove(id));
    }
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDA29B)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFB42318), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFB42318), fontSize: 12),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}

class _EmptyDictionary extends StatelessWidget {
  const _EmptyDictionary({required this.onAddFromGlobal});

  final VoidCallback onAddFromGlobal;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Слова не найдены',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAddFromGlobal,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Добавить из глобального словаря'),
            ),
          ],
        ),
      ),
    );
  }
}

enum WordSort { addedDate, difficulty, alphabet }

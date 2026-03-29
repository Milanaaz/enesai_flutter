import 'package:dipl/app/app_colors.dart';
import 'package:dipl/app/widgets/main_bottom_nav.dart';
import 'package:dipl/features/dictionary/presentation/data/mock_dictionary_words.dart';
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
  List<DictionaryWord> _words = buildMockDictionaryWords();
  String _query = '';
  WordSort _sort = WordSort.addedDate;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int learningCount = _words
        .where((DictionaryWord w) => w.status == WordStatus.learning)
        .length;
    final int learnedCount = _words
        .where((DictionaryWord w) => w.status == WordStatus.learned)
        .length;
    final int favoriteCount = _words
        .where((DictionaryWord w) => w.isFavorite)
        .length;

    final List<DictionaryWord> filtered = _sortedWords(
      _words.where(_matchesTab).where(_matchesSearch).toList(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Мой словарь')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _searchController,
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
                  ),
                  const SizedBox(height: 10),
                  _QuickCounters(
                    learning: learningCount,
                    total: _words.length,
                    favorites: favoriteCount,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _openReview,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Повторить слова'),
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
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF667085),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: 'Изучаю $learningCount'),
                  Tab(text: 'Выучил $learnedCount'),
                  Tab(text: 'Избранные $favoriteCount'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const _EmptyDictionary()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final DictionaryWord word = filtered[index];
                        return _WordCard(
                          word: word,
                          onToggleFavorite: () => _toggleFavorite(word.id),
                          onTap: () => _openWordDetails(word),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 2),
    );
  }

  bool _matchesTab(DictionaryWord word) {
    switch (_tabController.index) {
      case 0:
        return word.status == WordStatus.learning;
      case 1:
        return word.status == WordStatus.learned;
      case 2:
        return word.isFavorite;
      default:
        return true;
    }
  }

  bool _matchesSearch(DictionaryWord word) {
    if (_query.isEmpty) {
      return true;
    }
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

  void _toggleFavorite(String id) {
    setState(() {
      _words = _words.map((DictionaryWord word) {
        if (word.id != id) {
          return word;
        }
        return word.copyWith(isFavorite: !word.isFavorite);
      }).toList();
    });
  }

  Future<void> _openReview() async {
    final List<DictionaryWord>? updated = await context
        .push<List<DictionaryWord>>('/dictionary/review', extra: _words);
    if (updated == null) {
      return;
    }
    setState(() {
      _words = updated;
    });
  }

  Future<void> _openWordDetails(DictionaryWord word) async {
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
                  word.kyrgyz,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  word.translation,
                  style: const TextStyle(
                    color: AppColors.brandPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(word.transcription),
                const SizedBox(height: 8),
                Text('Пример: ${word.example}'),
                const SizedBox(height: 8),
                Text('Тема: ${word.topic}'),
                Text('Источник: ${word.sourceLesson}'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () {},
                      icon: const Icon(Icons.volume_up_outlined),
                      label: const Text('Озвучить'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _toggleFavorite(word.id);
                      },
                      icon: Icon(
                        word.isFavorite
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                      ),
                      label: Text(
                        word.isFavorite ? 'В избранном' : 'В избранное',
                      ),
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
}

class _QuickCounters extends StatelessWidget {
  const _QuickCounters({
    required this.learning,
    required this.total,
    required this.favorites,
  });

  final int learning;
  final int total;
  final int favorites;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CounterCard(
            value: learning,
            label: 'Сохранено',
            color: AppColors.brandPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CounterCard(
            value: total,
            label: 'Всего слов',
            color: const Color(0xFF101828),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CounterCard(
            value: favorites,
            label: 'Категории',
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
        PopupMenuItem(
          value: WordSort.addedDate,
          child: Text('По дате добавления'),
        ),
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
        child: Row(
          children: const [
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
    required this.onToggleFavorite,
    required this.onTap,
  });

  final DictionaryWord word;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: word.status == WordStatus.learning
                          ? const Color(0xFFECE7FF)
                          : const Color(0xFFD1FADF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      wordStatusLabel(word.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: word.status == WordStatus.learning
                            ? AppColors.brandPrimary
                            : const Color(0xFF027A48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.volume_up_outlined,
                color: AppColors.brandPrimary,
                size: 20,
              ),
            ),
            IconButton(
              onPressed: onToggleFavorite,
              icon: Icon(
                word.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                color: word.isFavorite
                    ? AppColors.brandPrimary
                    : const Color(0xFF98A2B3),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDictionary extends StatelessWidget {
  const _EmptyDictionary();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Слова не найдены',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

enum WordSort { addedDate, difficulty, alphabet }

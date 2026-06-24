import 'package:dipl/app/app_colors.dart';
import 'package:dipl/features/library/data/library_api_service.dart';
import 'package:dipl/features/library/data/library_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with TickerProviderStateMixin {
  final LibraryApiService _service = LibraryApiService.instance;
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  )..addListener(() => setState(() {}));
  final TextEditingController _searchController = TextEditingController();
  Future<List<LibraryBook>>? _future;
  String _search = '';
  String? _level;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => _search = _searchController.text);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Библиотека'), centerTitle: false),
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: AppColors.brandPrimary,
              indicatorColor: AppColors.brandPrimary,
              unselectedLabelColor: AppColors.textPrimary,
              onTap: (_) => _load(),
              tabs: const [
                Tab(text: 'Каталог'),
                Tab(text: 'Мои книги'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _load(),
                      decoration: InputDecoration(
                        hintText: 'Поиск книг...',
                        filled: true,
                        fillColor: const Color(0xFFF2F3F8),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF98A0B3),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  PopupMenuButton<String?>(
                    tooltip: 'Уровень',
                    onSelected: (String? value) {
                      setState(() => _level = value);
                      _load();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String?>(value: null, child: Text('Все')),
                      PopupMenuItem<String?>(value: 'A1', child: Text('A1')),
                      PopupMenuItem<String?>(value: 'A2', child: Text('A2')),
                      PopupMenuItem<String?>(value: 'B1', child: Text('B1')),
                      PopupMenuItem<String?>(value: 'B2', child: Text('B2')),
                    ],
                    child: Container(
                      width: 50,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.filter_alt_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_level != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Chip(
                    label: Text(_level!),
                    onDeleted: () {
                      setState(() => _level = null);
                      _load();
                    },
                  ),
                ),
              ),
            Expanded(
              child: FutureBuilder<List<LibraryBook>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _ErrorState(
                      message: snapshot.error.toString(),
                      onRetry: _load,
                    );
                  }
                  final List<LibraryBook> books =
                      snapshot.data ?? const <LibraryBook>[];
                  if (books.isEmpty) return const _EmptyLibrary();
                  return RefreshIndicator(
                    onRefresh: () async => _load(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                      itemCount: books.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final LibraryBook book = books[index];
                        return _BookCard(
                          book: book,
                          onTap: () => context.push('/library/${book.id}'),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _load() {
    setState(() {
      _future = _tabController.index == 1
          ? _service.getMyBooks()
          : _service.getCatalog(search: _search, level: _level);
    });
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book, required this.onTap});

  final LibraryBook book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E9EF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BookCover(book: book),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      _MetaChip(label: book.level.isEmpty ? 'A1' : book.level),
                      if (book.genre.isNotEmpty) _MetaChip(label: book.genre),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (book.userProgressPercent / 100).clamp(0, 1),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE9E9EF),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.brandPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${book.userProgressPercent}% · ${book.totalPages} стр.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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
}

class _BookCover extends StatelessWidget {
  const _BookCover({required this.book});

  final LibraryBook book;

  @override
  Widget build(BuildContext context) {
    if (book.coverUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          book.coverUrl,
          width: 84,
          height: 112,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _FallbackCover(book: book),
        ),
      );
    }
    return _FallbackCover(book: book);
  }
}

class _FallbackCover extends StatelessWidget {
  const _FallbackCover({required this.book});

  final LibraryBook book;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 112,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFECE7FF),
      ),
      alignment: Alignment.center,
      child: Text(
        book.title.isEmpty ? 'Китеп' : book.title.characters.first,
        style: const TextStyle(
          color: AppColors.brandPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      side: BorderSide.none,
      backgroundColor: const Color(0xFFF2F4F7),
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

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Книги не найдены',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

import 'package:dipl/app/app_colors.dart';
import 'package:dipl/app/widgets/main_bottom_nav.dart';
import 'package:dipl/features/courses/presentation/data/course_api_service.dart';
import 'package:dipl/features/courses/presentation/data/mock_courses.dart';
import 'package:dipl/features/courses/presentation/models/course_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CourseCatalogPage extends StatefulWidget {
  const CourseCatalogPage({super.key});

  @override
  State<CourseCatalogPage> createState() => _CourseCatalogPageState();
}

class _CourseCatalogPageState extends State<CourseCatalogPage>
    with TickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  )..addListener(() => setState(() {}));
  final TextEditingController _searchController = TextEditingController();
  late Future<List<CourseInfo>> _coursesFuture;
  String _search = '';
  String? _selectedLevel;
  CourseType? _selectedType;
  DurationFilter _durationFilter = DurationFilter.any;

  @override
  void initState() {
    super.initState();
    _coursesFuture = _loadCourses();
    _searchController.addListener(() {
      setState(() {
        _search = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<List<CourseInfo>> _loadCourses() {
    return CourseApiService.instance.getCourses();
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
      appBar: AppBar(title: const Text('Курсы'), centerTitle: false),
      body: SafeArea(
        child: FutureBuilder<List<CourseInfo>>(
          future: _coursesFuture,
          builder: (context, snapshot) {
            final List<CourseInfo> source = snapshot.hasData
                ? snapshot.data!
                : mockCourses;
            final List<CourseInfo> filtered = source
                .where(_matchesTab)
                .where(_matchesSearch)
                .where(_matchesFilter)
                .toList();

            return Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.brandPrimary,
                  indicatorColor: AppColors.brandPrimary,
                  unselectedLabelColor: AppColors.textPrimary,
                  tabs: const [
                    Tab(text: 'Все'),
                    Tab(text: 'Мои курсы'),
                    Tab(text: 'Завершенные'),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Поиск курсов...',
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
                      InkWell(
                        onTap: _openFilterSheet,
                        borderRadius: BorderRadius.circular(14),
                        child: Ink(
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
                if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _LoadErrorBanner(
                      message: snapshot.error.toString(),
                      onRetry: () => setState(() {
                        _coursesFuture = _loadCourses();
                      }),
                    ),
                  ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(minHeight: 2),
                if (_hasSelectedFilters)
                  SizedBox(
                    height: 32,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      children: _selectedFilterChips(),
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? const _EmptyState()
                      : RefreshIndicator(
                          onRefresh: () async {
                            final Future<List<CourseInfo>> future =
                                _loadCourses();
                            setState(() => _coursesFuture = future);
                            await future;
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final CourseInfo course = filtered[index];
                              return _CourseCard(
                                course: course,
                                onTap: () =>
                                    context.push('/courses/${course.id}'),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 1),
    );
  }

  bool get _hasSelectedFilters =>
      _selectedLevel != null ||
      _selectedType != null ||
      _durationFilter != DurationFilter.any;

  bool _matchesTab(CourseInfo course) {
    if (_tabController.index == 1) {
      return course.status != CourseStatus.notStarted;
    }
    if (_tabController.index == 2) {
      return course.status == CourseStatus.completed;
    }
    return true;
  }

  bool _matchesSearch(CourseInfo course) {
    if (_search.isEmpty) return true;
    return course.title.toLowerCase().contains(_search) ||
        course.description.toLowerCase().contains(_search);
  }

  bool _matchesFilter(CourseInfo course) {
    final bool levelOk =
        _selectedLevel == null || course.level == _selectedLevel;
    final bool typeOk = _selectedType == null || course.type == _selectedType;
    final bool durationOk = switch (_durationFilter) {
      DurationFilter.any => true,
      DurationFilter.short => course.lessonCount <= 10,
      DurationFilter.medium =>
        course.lessonCount > 10 && course.lessonCount <= 18,
      DurationFilter.long => course.lessonCount > 18,
    };
    return levelOk && typeOk && durationOk;
  }

  List<Widget> _selectedFilterChips() {
    final List<Widget> chips = <Widget>[];
    if (_selectedLevel != null) {
      chips.add(
        _FilterBadge(
          label: _selectedLevel!,
          onDelete: () => setState(() => _selectedLevel = null),
        ),
      );
    }
    if (_selectedType != null) {
      chips.add(
        _FilterBadge(
          label: courseTypeLabels[_selectedType]!,
          onDelete: () => setState(() => _selectedType = null),
        ),
      );
    }
    if (_durationFilter != DurationFilter.any) {
      chips.add(
        _FilterBadge(
          label: _durationFilter.label,
          onDelete: () => setState(() => _durationFilter = DurationFilter.any),
        ),
      );
    }
    return chips;
  }

  Future<void> _openFilterSheet() async {
    final FilterValues? result = await showModalBottomSheet<FilterValues>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _FilterSheet(
          values: FilterValues(
            level: _selectedLevel,
            type: _selectedType,
            duration: _durationFilter,
          ),
        );
      },
    );
    if (result == null) return;
    setState(() {
      _selectedLevel = result.level;
      _selectedType = result.type;
      _durationFilter = result.duration;
    });
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.onTap});

  final CourseInfo course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final int done = (course.lessonCount * _courseProgress()).round();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E9EF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 110,
              height: 82,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFFDCE7FF), Color(0xFFC3D3F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                course.coverLabel,
                style: const TextStyle(
                  color: Color(0xFF475467),
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Уроков: ${course.lessonCount}  ·  ${course.totalMinutes} мин',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Статус: ${statusLabel(course.status)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: _courseProgress(),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE9E9EF),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.brandPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$done / ${course.lessonCount} уроков',
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

  double _courseProgress() {
    if (course.status == CourseStatus.completed) return 1;
    if (course.status == CourseStatus.notStarted) return 0;
    if (course.modules.isEmpty) return .45;
    final double sum = course.modules.fold<double>(
      0,
      (double total, CourseModule module) => total + module.progress,
    );
    return (sum / course.modules.length).clamp(0, 1).toDouble();
  }
}

class _LoadErrorBanner extends StatelessWidget {
  const _LoadErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _FilterBadge extends StatelessWidget {
  const _FilterBadge({required this.label, required this.onDelete});

  final String label;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        labelStyle: const TextStyle(color: Color(0xFF374151)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onDelete,
        backgroundColor: const Color(0xFFE9EDFF),
        side: BorderSide.none,
        visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.values});

  final FilterValues values;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _level = widget.values.level;
  late CourseType? _type = widget.values.type;
  late DurationFilter _duration = widget.values.duration;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Фильтры',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          const Text('Уровень', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: courseLevels.map((String level) {
              return ChoiceChip(
                label: Text(level),
                selected: _level == level,
                onSelected: (_) =>
                    setState(() => _level = _level == level ? null : level),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Text(
            'Тип курса',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CourseType.values.map((CourseType type) {
              return ChoiceChip(
                label: Text(courseTypeLabels[type]!),
                selected: _type == type,
                onSelected: (_) =>
                    setState(() => _type = _type == type ? null : type),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Text(
            'Длительность',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: DurationFilter.values.map((DurationFilter value) {
              return ChoiceChip(
                label: Text(value.label),
                selected: _duration == value,
                onSelected: (_) => setState(() => _duration = value),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _level = null;
                      _type = null;
                      _duration = DurationFilter.any;
                    });
                  },
                  child: const Text('Сброс'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      FilterValues(
                        level: _level,
                        type: _type,
                        duration: _duration,
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                  ),
                  child: const Text('Применить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'По выбранным фильтрам курсы не найдены',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

enum DurationFilter {
  any('Любая'),
  short('До 10 уроков'),
  medium('11-18 уроков'),
  long('19+ уроков');

  const DurationFilter(this.label);
  final String label;
}

class FilterValues {
  const FilterValues({
    required this.level,
    required this.type,
    required this.duration,
  });

  final String? level;
  final CourseType? type;
  final DurationFilter duration;
}

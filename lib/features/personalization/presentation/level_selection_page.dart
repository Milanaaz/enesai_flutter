import 'package:dipl/app/app_colors.dart';
import 'package:dipl/features/personalization/presentation/widgets/personalization_option_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LevelSelectionPage extends StatefulWidget {
  const LevelSelectionPage({
    required this.languageCode,
    required this.goalCode,
    super.key,
  });

  final String languageCode;
  final String goalCode;

  @override
  State<LevelSelectionPage> createState() => _LevelSelectionPageState();
}

class _LevelSelectionPageState extends State<LevelSelectionPage> {
  _LevelMode? _levelMode;
  String? _manualLevel;

  bool get _canContinue {
    if (_levelMode == _LevelMode.test) return true;
    if (_levelMode == _LevelMode.manual && _manualLevel != null) return true;
    return false;
  }

  void _continue() {
    if (!_canContinue) return;
    context.go('/');
  }

  void _goBack() {
    context.go(
      '/onboarding/goal?lang=${widget.languageCode}&goal=${widget.goalCode}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isManual = _levelMode == _LevelMode.manual;
    final String languageTitle = _languageTitle(widget.languageCode);
    final String goalTitle = _goalTitle(widget.goalCode);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                tooltip: 'Назад',
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Выберите стартовый уровень',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Язык: $languageTitle\nЦель: $goalTitle',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    PersonalizationOptionTile(
                      title: 'Пройти стартовый тест',
                      subtitle: 'Рекомендуемый вариант для точного маршрута',
                      isSelected: _levelMode == _LevelMode.test,
                      onTap: () {
                        setState(() {
                          _levelMode = _LevelMode.test;
                          _manualLevel = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    PersonalizationOptionTile(
                      title: 'Выбрать уровень вручную',
                      subtitle: 'A1, A2, B1, B2',
                      isSelected: _levelMode == _LevelMode.manual,
                      onTap: () =>
                          setState(() => _levelMode = _LevelMode.manual),
                    ),
                  ],
                ),
              ),
              if (isManual) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <String>['A1', 'A2', 'B1', 'B2'].map((level) {
                      final bool selected = _manualLevel == level;
                      return ChoiceChip(
                        label: Text(level),
                        selected: selected,
                        onSelected: (_) => setState(() => _manualLevel = level),
                        selectedColor: const Color(0xFFEDE4FF),
                        side: BorderSide(
                          color: selected
                              ? AppColors.brandPrimary
                              : AppColors.indicatorInactive,
                        ),
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.brandPrimary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Маршрут может быть менее точным.',
                      style: TextStyle(
                        color: Color(0xFF9A3412),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _canContinue ? _continue : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Далее',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _LevelMode { test, manual }

String _languageTitle(String code) {
  switch (code) {
    case 'ky':
      return 'Кыргызский';
    default:
      return 'Русский';
  }
}

String _goalTitle(String code) {
  switch (code) {
    case 'ort':
      return 'Подготовка к ОРТ';
    case 'speaking':
      return 'Разговорный';
    case 'business':
      return 'Деловой';
    default:
      return 'Выучить кыргызский';
  }
}

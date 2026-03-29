import 'package:dipl/app/app_colors.dart';
import 'package:dipl/features/personalization/presentation/widgets/personalization_option_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GoalSelectionPage extends StatefulWidget {
  const GoalSelectionPage({
    required this.languageCode,
    this.initialGoalCode,
    super.key,
  });

  final String languageCode;
  final String? initialGoalCode;

  @override
  State<GoalSelectionPage> createState() => _GoalSelectionPageState();
}

class _GoalSelectionPageState extends State<GoalSelectionPage> {
  String? _selectedGoalCode;

  @override
  void initState() {
    super.initState();
    _selectedGoalCode = widget.initialGoalCode;
  }

  void _continue() {
    final String? goal = _selectedGoalCode;
    if (goal == null) return;
    context.go('/onboarding/level?lang=${widget.languageCode}&goal=$goal');
  }

  void _goBack() {
    context.go('/onboarding/language?lang=${widget.languageCode}');
  }

  @override
  Widget build(BuildContext context) {
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Выберите вашу цель обучения',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    PersonalizationOptionTile(
                      title: 'Выучить кыргызский',
                      isSelected: _selectedGoalCode == 'learn',
                      onTap: () => setState(() => _selectedGoalCode = 'learn'),
                    ),
                    const SizedBox(height: 12),
                    PersonalizationOptionTile(
                      title: 'Подготовка к ОРТ',
                      isSelected: _selectedGoalCode == 'ort',
                      onTap: () => setState(() => _selectedGoalCode = 'ort'),
                    ),
                    const SizedBox(height: 12),
                    PersonalizationOptionTile(
                      title: 'Разговорный',
                      isSelected: _selectedGoalCode == 'speaking',
                      onTap: () =>
                          setState(() => _selectedGoalCode = 'speaking'),
                    ),
                    const SizedBox(height: 12),
                    PersonalizationOptionTile(
                      title: 'Деловой',
                      isSelected: _selectedGoalCode == 'business',
                      onTap: () =>
                          setState(() => _selectedGoalCode = 'business'),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _selectedGoalCode == null ? null : _continue,
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

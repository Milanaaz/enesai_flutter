import 'package:dipl/app/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ModuleTestPage extends StatefulWidget {
  const ModuleTestPage({required this.courseId, super.key});

  final String courseId;

  @override
  State<ModuleTestPage> createState() => _ModuleTestPageState();
}

class _ModuleTestPageState extends State<ModuleTestPage> {
  final List<int?> _answers = <int?>[null, null, null];
  bool _timerEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Тест по модулю')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          children: [
            SwitchListTile(
              value: _timerEnabled,
              onChanged: (bool value) => setState(() => _timerEnabled = value),
              title: const Text('Включить таймер'),
              subtitle: const Text('Опционально: 10 минут на весь тест'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            _TestQuestion(
              title: '1. Выберите правильный вариант',
              options: const <String>['Вариант A', 'Вариант B', 'Вариант C'],
              selected: _answers[0],
              onSelect: (int value) => setState(() => _answers[0] = value),
            ),
            _TestQuestion(
              title: '2. Сопоставьте перевод',
              options: const <String>['Слово 1', 'Слово 2', 'Слово 3'],
              selected: _answers[1],
              onSelect: (int value) => setState(() => _answers[1] = value),
            ),
            _TestQuestion(
              title: '3. Аудирование с вопросом',
              options: const <String>['Ответ 1', 'Ответ 2', 'Ответ 3'],
              selected: _answers[2],
              onSelect: (int value) => setState(() => _answers[2] = value),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton(
          onPressed: _answers.every((int? e) => e != null)
              ? () {
                  final int score = _computeScore();
                  context.push(
                    '/courses/${widget.courseId}/module-test/result?score=$score',
                  );
                }
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandPrimary,
          ),
          child: const Text('Завершить тест'),
        ),
      ),
    );
  }

  int _computeScore() {
    final List<int> key = <int>[0, 1, 2];
    int ok = 0;
    for (int i = 0; i < _answers.length; i++) {
      if (_answers[i] == key[i]) {
        ok++;
      }
    }
    return (ok / _answers.length * 100).round();
  }
}

class _TestQuestion extends StatelessWidget {
  const _TestQuestion({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final List<String> options;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...List<Widget>.generate(options.length, (int index) {
            final bool isSelected = selected == index;
            return InkWell(
              onTap: () => onSelect(index),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brandPrimary
                        : const Color(0xFFD0D5DD),
                  ),
                  color: isSelected
                      ? const Color(0xFFF5F3FF)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: isSelected
                          ? AppColors.brandPrimary
                          : const Color(0xFF667085),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(options[index])),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

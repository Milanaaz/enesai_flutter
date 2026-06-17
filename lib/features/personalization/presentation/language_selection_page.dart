import 'package:dipl/app/app_colors.dart';
import 'package:dipl/features/personalization/presentation/widgets/personalization_option_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({this.initialLanguageCode, super.key});

  final String? initialLanguageCode;

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  String? _selectedLanguageCode;

  @override
  void initState() {
    super.initState();
    _selectedLanguageCode = widget.initialLanguageCode == 'ru'
        ? widget.initialLanguageCode
        : null;
  }

  void _continue() {
    final String? language = _selectedLanguageCode;
    if (language == null) return;
    context.go('/onboarding/goal?lang=$language');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'На каком языке вам удобно изучать кыргызский язык?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              PersonalizationOptionTile(
                title: 'Русский',
                isSelected: _selectedLanguageCode == 'ru',
                onTap: () => setState(() => _selectedLanguageCode = 'ru'),
              ),
              const SizedBox(height: 12),
              PersonalizationOptionTile(
                title: 'Кыргызча',
                subtitle: 'В разработке',
                isSelected: false,
                onTap: () {},
              ),
              const SizedBox(height: 12),
              PersonalizationOptionTile(
                title: 'English',
                subtitle: 'В разработке',
                isSelected: false,
                onTap: () {},
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedLanguageCode == null ? null : _continue,
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
            ],
          ),
        ),
      ),
    );
  }
}

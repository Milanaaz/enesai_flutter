import 'package:dipl/app/app_colors.dart';
import 'package:dipl/features/welcome/presentation/models/welcome_slide.dart';
import 'package:flutter/material.dart';

class WelcomeSlideView extends StatelessWidget {
  const WelcomeSlideView({required this.slide, super.key});

  final WelcomeSlide slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            height: 1.2,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          slide.description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

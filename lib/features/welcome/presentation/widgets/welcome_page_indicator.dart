import 'package:dipl/app/app_colors.dart';
import 'package:flutter/material.dart';

class WelcomePageIndicator extends StatelessWidget {
  const WelcomePageIndicator({
    required this.total,
    required this.currentIndex,
    super.key,
  });

  final int total;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(total, (index) {
        final bool isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: isActive
                ? AppColors.brandPrimary
                : AppColors.indicatorInactive,
          ),
        );
      }),
    );
  }
}

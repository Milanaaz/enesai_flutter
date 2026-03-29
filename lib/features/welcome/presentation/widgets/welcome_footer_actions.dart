import 'package:dipl/app/app_colors.dart';
import 'package:flutter/material.dart';

class WelcomeFooterActions extends StatelessWidget {
  const WelcomeFooterActions({
    required this.onPrimaryPressed,
    required this.onLoginPressed,
    super.key,
  });

  final VoidCallback onPrimaryPressed;
  final VoidCallback onLoginPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onPrimaryPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Поехали!',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Уже есть аккаунт? ',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            GestureDetector(
              onTap: onLoginPressed,
              child: const Text(
                'ВОЙТИ',
                style: TextStyle(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

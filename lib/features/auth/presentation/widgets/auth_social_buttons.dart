import 'package:dipl/app/app_colors.dart';
import 'package:flutter/material.dart';

class AuthSocialButtons extends StatelessWidget {
  const AuthSocialButtons({
    required this.onGooglePressed,
    required this.onFacebookPressed,
    super.key,
  });

  final VoidCallback onGooglePressed;
  final VoidCallback onFacebookPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onGooglePressed,
            icon: const Text(
              'G',
              style: TextStyle(
                color: Color(0xFFDB4437),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            label: const Text('Google'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.divider),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onFacebookPressed,
            icon: const Text(
              'f',
              style: TextStyle(
                color: Color(0xFF1877F2),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            label: const Text('Facebook'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.divider),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

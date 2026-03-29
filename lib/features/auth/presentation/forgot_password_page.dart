import 'package:dipl/app/app_colors.dart';
import 'package:dipl/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:dipl/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Инструкция для сброса пароля отправлена на вашу почту.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      title: 'Восстановление пароля',
      subtitle: 'Введите email, и мы отправим инструкции для сброса пароля',
      children: [
        Form(
          key: _formKey,
          child: AuthTextField(
            label: 'Email',
            hint: 'example@mail.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline,
            validator: (value) {
              final String email = value?.trim() ?? '';
              if (email.isEmpty) return 'Введите email';
              if (!email.contains('@') || !email.contains('.')) {
                return 'Введите корректный email';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Отправить инструкцию',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.go('/login'),
            child: const Text(
              'Вернуться ко входу',
              style: TextStyle(
                color: AppColors.brandPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

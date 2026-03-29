import 'package:dipl/app/app_colors.dart';
import 'package:dipl/features/auth/presentation/widgets/auth_divider.dart';
import 'package:dipl/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:dipl/features/auth/presentation/widgets/auth_social_buttons.dart';
import 'package:dipl/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      title: 'Добро пожаловать!',
      subtitle: 'Войдите в свой аккаунт',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              AuthTextField(
                label: 'Email',
                hint: 'example@mail.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline,
                validator: _validateEmail,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                label: 'Пароль',
                hint: '••••••••',
                controller: _passwordController,
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                validator: _validatePassword,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/forgot-password'),
                  child: const Text(
                    'Забыли пароль?',
                    style: TextStyle(
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
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
                    'Войти',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Нет аккаунта? ',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            GestureDetector(
              onTap: () => context.go('/register'),
              child: const Text(
                'Зарегистрироваться',
                style: TextStyle(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const AuthDivider(text: 'или войти через'),
        const SizedBox(height: 14),
        AuthSocialButtons(onGooglePressed: () {}, onFacebookPressed: () {}),
      ],
    );
  }
}

String? _validateEmail(String? value) {
  final String email = value?.trim() ?? '';
  if (email.isEmpty) return 'Введите email';
  if (!email.contains('@') || !email.contains('.')) {
    return 'Введите корректный email';
  }
  return null;
}

String? _validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Введите пароль';
  if (value.length < 6) return 'Минимум 6 символов';
  return null;
}

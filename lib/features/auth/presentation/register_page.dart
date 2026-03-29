import 'package:dipl/app/app_colors.dart';
import 'package:dipl/features/auth/presentation/widgets/auth_divider.dart';
import 'package:dipl/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:dipl/features/auth/presentation/widgets/auth_social_buttons.dart';
import 'package:dipl/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    final bool isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Подтвердите согласие с условиями использования и политикой конфиденциальности.',
          ),
        ),
      );
      return;
    }
    context.go('/');
  }

  void _goToLogin() => context.go('/login');

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      title: 'Создать аккаунт',
      subtitle: 'Зарегистрируйтесь для начала обучения',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              AuthTextField(
                label: 'Имя',
                hint: 'Иван Иванов',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите имя';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
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
              const SizedBox(height: 14),
              AuthTextField(
                label: 'Подтвердите пароль',
                hint: '••••••••',
                controller: _confirmPasswordController,
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Подтвердите пароль';
                  }
                  if (value != _passwordController.text) {
                    return 'Пароли не совпадают';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    onChanged: (bool? value) {
                      setState(() => _acceptedTerms = value ?? false);
                    },
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 13),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(text: 'Я согласен с '),
                            TextSpan(
                              text: 'условиями использования',
                              style: TextStyle(
                                color: AppColors.brandPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: ' и '),
                            TextSpan(
                              text: 'политикой конфиденциальности',
                              style: TextStyle(
                                color: AppColors.brandPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                    'Зарегистрироваться',
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
              'Уже есть аккаунт? ',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            GestureDetector(
              onTap: _goToLogin,
              child: const Text(
                'Войти',
                style: TextStyle(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const AuthDivider(text: 'или зарегистрироваться через'),
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

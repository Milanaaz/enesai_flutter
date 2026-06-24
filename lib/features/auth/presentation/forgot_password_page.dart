import 'package:dipl/app/app_colors.dart';
import 'package:dipl/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:dipl/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:dipl/services/auth_service.dart';
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
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSubmitting = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await AuthService.instance.forgotPassword(_emailController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Инструкция для сброса пароля отправлена на вашу почту.',
          ),
        ),
      );
      setState(() => _codeSent = true);
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await AuthService.instance.verifyResetCode(
        email: _emailController.text,
        code: _codeController.text,
      );
      await AuthService.instance.resetPassword(
        email: _emailController.text,
        code: _codeController.text,
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароль обновлен. Войдите заново.')),
      );
      context.go('/login');
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
            hint: 'example@gmail.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.email],
            hintLocales: const <Locale>[Locale('en')],
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
        if (_codeSent) ...[
          const SizedBox(height: 14),
          AuthTextField(
            label: 'Код',
            hint: '6 цифр',
            controller: _codeController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.password_outlined,
            validator: (value) {
              final String code = value?.trim() ?? '';
              if (!_codeSent) return null;
              if (code.length != 6) return 'Введите код из 6 символов';
              return null;
            },
          ),
          const SizedBox(height: 14),
          AuthTextField(
            label: 'Новый пароль',
            hint: 'Минимум 8 символов',
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.lock_outline,
            validator: (value) {
              if (!_codeSent) return null;
              if ((value ?? '').length < 8) {
                return 'Минимум 8 символов';
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isSubmitting
                ? null
                : _codeSent
                ? _resetPassword
                : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _codeSent ? 'Сбросить пароль' : 'Отправить инструкцию',
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

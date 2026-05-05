import 'package:dipl/app/app_colors.dart';
import 'package:dipl/app/widgets/main_bottom_nav.dart';
import 'package:dipl/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Future<String?> _userNameFuture;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  String _interfaceLanguage = '\u0420\u0443\u0441\u0441\u043a\u0438\u0439';
  String _learningLanguage = '\u041a\u044b\u0440\u0433\u044b\u0437\u0441\u043a\u0438\u0439';
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _userNameFuture = AuthService.instance.getRegisteredName();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: FutureBuilder<String?>(
          future: _userNameFuture,
          builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
            final String userName = (snapshot.data ?? '').trim().isNotEmpty
                ? snapshot.data!.trim()
                : 'Milana';
            final String email = '${userName.toLowerCase()}@example.com';

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                _ProfileHeader(
                  userName: userName,
                  email: email,
                  level: 'A2',
                  points: '1 245',
                  learningDays: '12',
                ),
                const SizedBox(height: 12),
                const _BlockTitle('Мои курсы'),
                const SizedBox(height: 8),
                _InfoCard(
                  child: _CourseTile(
                    title: 'Основы кыргызского языка',
                    subtitle: 'Прогресс: 75% • 9 из 12 уроков',
                    progress: 0.75,
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 12),
                const _BlockTitle('Сертификаты'),
                const SizedBox(height: 8),
                _InfoCard(
                  child: _SimpleInfoTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Сертификаты',
                    subtitle: '2 получено • 1 в процессе',
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 12),
                const _BlockTitle('Прогресс обучения'),
                const SizedBox(height: 8),
                _InfoCard(
                  child: Column(
                    children: const [
                      _ProgressRow(label: 'Завершено уроков', value: '34'),
                      SizedBox(height: 10),
                      _ProgressRow(label: 'Выучено слов', value: '412'),
                      SizedBox(height: 10),
                      _ProgressRow(label: 'Текущая серия', value: '12 дней'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const _BlockTitle('Настройки'),
                const SizedBox(height: 8),
                _InfoCard(
                  child: Column(
                    children: [
                      _SettingsValueTile(
                        icon: Icons.language_outlined,
                        title: 'Язык интерфейса',
                        value: _interfaceLanguage,
                        onTap: _changeInterfaceLanguage,
                      ),
                      const Divider(height: 20, color: AppColors.divider),
                      _SettingsValueTile(
                        icon: Icons.school_outlined,
                        title: 'Язык обучения',
                        value: _learningLanguage,
                        onTap: _changeLearningLanguage,
                      ),
                      const Divider(height: 20, color: AppColors.divider),
                      _SettingsSwitchTile(
                        icon: Icons.notifications_outlined,
                        title: 'Уведомления и напоминания',
                        value: _notificationsEnabled,
                        onChanged: (bool value) {
                          setState(() => _notificationsEnabled = value);
                        },
                      ),
                      const Divider(height: 20, color: AppColors.divider),
                      _SettingsValueTile(
                        icon: Icons.access_time_outlined,
                        title: 'Время напоминаний',
                        value: _reminderTime.format(context),
                        onTap: _pickReminderTime,
                      ),
                      const Divider(height: 20, color: AppColors.divider),
                      _SettingsSwitchTile(
                        icon: Icons.volume_up_outlined,
                        title: 'Звук',
                        value: _soundEnabled,
                        onChanged: (bool value) {
                          setState(() => _soundEnabled = value);
                        },
                      ),
                      const Divider(height: 20, color: AppColors.divider),
                      _SettingsValueTile(
                        icon: Icons.lock_outline,
                        title: 'Сменить пароль',
                        value: 'Изменить',
                        onTap: _openChangePasswordDialog,
                      ),
                      const Divider(height: 20, color: AppColors.divider),
                      _SettingsValueTile(
                        icon: Icons.logout,
                        title: 'Выйти из аккаунта',
                        value: 'Выйти',
                        isDestructive: true,
                        onTap: _logout,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 0),
    );
  }

  Future<void> _changeInterfaceLanguage() async {
    final String? selected = await _pickFromOptions(
      title: 'Язык интерфейса',
      options: const [
        '\u0420\u0443\u0441\u0441\u043a\u0438\u0439',
        '\u041a\u044b\u0440\u0433\u044b\u0437\u0447\u0430',
        'English',
      ],
      currentValue: _interfaceLanguage,
    );
    if (selected == null) {
      return;
    }
    setState(() => _interfaceLanguage = selected);
  }

  Future<void> _changeLearningLanguage() async {
    final String? selected = await _pickFromOptions(
      title: 'Язык обучения',
      options: const [
        '\u041a\u044b\u0440\u0433\u044b\u0437\u0441\u043a\u0438\u0439',
        '\u0420\u0443\u0441\u0441\u043a\u0438\u0439',
        'English',
      ],
      currentValue: _learningLanguage,
    );
    if (selected == null) {
      return;
    }
    setState(() => _learningLanguage = selected);
  }

  Future<void> _pickReminderTime() async {
    final TimeOfDay? selected = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (selected == null) {
      return;
    }
    setState(() => _reminderTime = selected);
  }

  Future<String?> _pickFromOptions({
    required String title,
    required List<String> options,
    required String currentValue,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...options.map((String value) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(value),
                    trailing: value == currentValue
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.brandPrimary,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(value),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInfo(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _openChangePasswordDialog() async {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    bool isSubmitting = false;
    bool obscureCurrentPassword = true;
    bool obscurePassword = true;
    bool obscureConfirm = true;

    final bool? passwordChanged = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Сменить пароль'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrentPassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Текущий пароль',
                        hintText: 'Введите текущий пароль',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(
                              () => obscureCurrentPassword =
                                  !obscureCurrentPassword,
                            );
                          },
                          icon: Icon(
                            obscureCurrentPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      validator: (String? value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Введите текущий пароль';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      textInputAction: TextInputAction.next,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Новый пароль',
                        hintText: 'Минимум 6 символов',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(
                              () => obscurePassword = !obscurePassword,
                            );
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      validator: (String? value) {
                        if ((value ?? '').isEmpty) {
                          return 'Введите новый пароль';
                        }
                        if ((value ?? '').length < 6) {
                          return 'Минимум 6 символов';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmController,
                      textInputAction: TextInputAction.done,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Подтвердите пароль',
                        hintText: 'Повторите пароль',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(
                              () => obscureConfirm = !obscureConfirm,
                            );
                          },
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      validator: (String? value) {
                        if ((value ?? '').isEmpty) {
                          return 'Подтвердите пароль';
                        }
                        if (value != passwordController.text) {
                          return 'Пароли не совпадают';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          setDialogState(() => isSubmitting = true);
                          try {
                            await AuthService.instance.changePassword(
                              currentPassword: currentPasswordController.text,
                              newPassword: passwordController.text,
                            );
                            Navigator.of(dialogContext).pop(true);
                          } on AuthException catch (error) {
                            if (!mounted) return;
                            _showInfo(error.message);
                            setDialogState(() => isSubmitting = false);
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    currentPasswordController.dispose();
    passwordController.dispose();
    confirmController.dispose();

    if (passwordChanged == true) {
      await AuthService.instance.logout();
      if (!mounted) return;
      context.go('/login');
    }
  }

  Future<void> _logout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выйти из аккаунта?'),
          content: const Text('Вы сможете войти снова в любое время.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Выйти'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await AuthService.instance.logout();
    if (!mounted) return;
    context.go('/login');
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.userName,
    required this.email,
    required this.level,
    required this.points,
    required this.learningDays,
  });

  final String userName;
  final String email;
  final String level;
  final String points;
  final String learningDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Профиль',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(Icons.person_outline, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeaderMetric(
                  label: 'Уровень',
                  value: level,
                  icon: Icons.track_changes_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeaderMetric(
                  label: 'Баллы',
                  value: points,
                  icon: Icons.stars_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeaderMetric(
                  label: 'Дни',
                  value: learningDays,
                  icon: Icons.access_time_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockTitle extends StatelessWidget {
  const _BlockTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.brandPrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF98A2B3)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: const Color(0xFFE9E9EF),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.brandPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleInfoTile extends StatelessWidget {
  const _SimpleInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.brandPrimary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF98A2B3)),
      onTap: onTap,
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SettingsValueTile extends StatelessWidget {
  const _SettingsValueTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final Color color = isDestructive
        ? const Color(0xFFB42318)
        : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive
                  ? const Color(0xFFB42318)
                  : AppColors.brandPrimary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w500, color: color),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: isDestructive
                    ? const Color(0xFFB42318)
                    : AppColors.textSecondary,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDestructive
                  ? const Color(0xFFB42318)
                  : const Color(0xFF98A2B3),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.brandPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.brandPrimary.withValues(alpha: 0.4),
          activeThumbColor: AppColors.brandPrimary,
        ),
      ],
    );
  }
}



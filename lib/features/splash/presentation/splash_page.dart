import 'dart:async';

import 'package:dipl/app/app_colors.dart';
import 'package:dipl/app/app_durations.dart';
import 'package:dipl/features/splash/presentation/widgets/splash_logo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(AppDurations.splash, () {
      if (!mounted) return;
      context.go('/welcome');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: Center(child: SplashLogo()),
    );
  }
}

import 'package:dipl/app/app_durations.dart';
import 'package:dipl/features/welcome/presentation/models/welcome_slide.dart';
import 'package:dipl/features/welcome/presentation/widgets/welcome_footer_actions.dart';
import 'package:dipl/features/welcome/presentation/widgets/welcome_page_indicator.dart';
import 'package:dipl/features/welcome/presentation/widgets/welcome_slide_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  static const List<WelcomeSlide> _slides = <WelcomeSlide>[
    WelcomeSlide(
      title: 'Изучайте кыргызский шаг за шагом',
      description:
          'Изучайте лексику, грамматику и фразы из реальных ситуаций - '
          'от начального до продвинутого уровня.',
    ),
    WelcomeSlide(
      title: 'Практика с ИИ-помощником',
      description:
          'Общайтесь, пишите и тренируйте язык с персональным наставником, '
          'который помогает исправлять ошибки и развиваться каждый день.',
    ),
    WelcomeSlide(
      title: 'Играйте, учитесь и развивайтесь',
      description:
          'Учитесь через игры, задания и награды, отслеживая свой прогресс '
          'каждый день.',
    ),
  ];

  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onPrimaryPressed() async {
    final int lastIndex = _slides.length - 1;
    if (_currentIndex < lastIndex) {
      await _pageController.nextPage(
        duration: AppDurations.pageAnimation,
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (!mounted) return;
    context.go('/register');
  }

  void _onLoginPressed() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (int index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (BuildContext context, int index) {
                    return WelcomeSlideView(slide: _slides[index]);
                  },
                ),
              ),
              WelcomePageIndicator(
                total: _slides.length,
                currentIndex: _currentIndex,
              ),
              const SizedBox(height: 24),
              WelcomeFooterActions(
                onPrimaryPressed: _onPrimaryPressed,
                onLoginPressed: _onLoginPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

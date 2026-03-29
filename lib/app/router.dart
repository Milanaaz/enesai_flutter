import 'package:dipl/features/auth/presentation/forgot_password_page.dart';
import 'package:dipl/features/auth/presentation/login_page.dart';
import 'package:dipl/features/auth/presentation/register_page.dart';
import 'package:dipl/features/home/presentation/home_page.dart';
import 'package:dipl/features/personalization/presentation/goal_selection_page.dart';
import 'package:dipl/features/personalization/presentation/language_selection_page.dart';
import 'package:dipl/features/personalization/presentation/level_selection_page.dart';
import 'package:dipl/features/splash/presentation/splash_page.dart';
import 'package:dipl/features/welcome/presentation/welcome_page.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: <RouteBase>[
    GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomePage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/onboarding/language',
      builder: (context, state) {
        final String? initialLanguageCode =
            state.uri.queryParameters['lang']?.trim().isNotEmpty == true
            ? state.uri.queryParameters['lang']
            : null;
        return LanguageSelectionPage(initialLanguageCode: initialLanguageCode);
      },
    ),
    GoRoute(
      path: '/onboarding/goal',
      builder: (context, state) {
        final String languageCode =
            state.uri.queryParameters['lang']?.trim().isNotEmpty == true
            ? state.uri.queryParameters['lang']!
            : 'ru';
        final String? initialGoalCode =
            state.uri.queryParameters['goal']?.trim().isNotEmpty == true
            ? state.uri.queryParameters['goal']
            : null;
        return GoalSelectionPage(
          languageCode: languageCode,
          initialGoalCode: initialGoalCode,
        );
      },
    ),
    GoRoute(
      path: '/onboarding/level',
      builder: (context, state) {
        final String languageCode =
            state.uri.queryParameters['lang']?.trim().isNotEmpty == true
            ? state.uri.queryParameters['lang']!
            : 'ru';
        final String goalCode =
            state.uri.queryParameters['goal']?.trim().isNotEmpty == true
            ? state.uri.queryParameters['goal']!
            : 'learn';
        return LevelSelectionPage(
          languageCode: languageCode,
          goalCode: goalCode,
        );
      },
    ),
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
  ],
);

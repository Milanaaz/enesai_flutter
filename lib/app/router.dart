import 'package:dipl/features/auth/presentation/forgot_password_page.dart';
import 'package:dipl/features/auth/presentation/login_page.dart';
import 'package:dipl/features/auth/presentation/register_page.dart';
import 'package:dipl/features/home/presentation/home_page.dart';
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
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
  ],
);

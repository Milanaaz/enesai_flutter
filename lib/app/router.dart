import 'package:dipl/features/home/presentation/home_page.dart';
import 'package:dipl/features/splash/presentation/splash_page.dart';
import 'package:dipl/features/welcome/presentation/welcome_page.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: <RouteBase>[
    GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomePage()),
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
  ],
);

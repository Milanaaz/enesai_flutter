import 'package:dipl/features/auth/presentation/forgot_password_page.dart';
import 'package:dipl/features/auth/presentation/login_page.dart';
import 'package:dipl/features/auth/presentation/register_page.dart';
import 'package:dipl/features/chat/presentation/chat_page.dart';
import 'package:dipl/features/courses/presentation/certificate_page.dart';
import 'package:dipl/features/courses/presentation/course_catalog_page.dart';
import 'package:dipl/features/courses/presentation/course_details_page.dart';
import 'package:dipl/features/courses/presentation/lesson_page.dart';
import 'package:dipl/features/courses/presentation/lesson_summary_page.dart';
import 'package:dipl/features/courses/presentation/module_test_page.dart';
import 'package:dipl/features/courses/presentation/module_test_result_page.dart';
import 'package:dipl/features/dictionary/presentation/dictionary_page.dart';
import 'package:dipl/features/dictionary/presentation/word_review_page.dart';
import 'package:dipl/features/home/presentation/home_page.dart';
import 'package:dipl/features/library/presentation/book_reader_page.dart';
import 'package:dipl/features/library/presentation/library_page.dart';
import 'package:dipl/features/personalization/data/placement_test_models.dart';
import 'package:dipl/features/personalization/presentation/goal_selection_page.dart';
import 'package:dipl/features/personalization/presentation/language_selection_page.dart';
import 'package:dipl/features/personalization/presentation/level_selection_page.dart';
import 'package:dipl/features/personalization/presentation/placement_test_page.dart';
import 'package:dipl/features/personalization/presentation/placement_test_result_page.dart';
import 'package:dipl/features/profile/presentation/profile_page.dart';
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
    GoRoute(
      path: '/onboarding/placement-test',
      builder: (context, state) {
        final String languageCode =
            state.uri.queryParameters['lang']?.trim().isNotEmpty == true
            ? state.uri.queryParameters['lang']!
            : 'ru';
        final String goalCode =
            state.uri.queryParameters['goal']?.trim().isNotEmpty == true
            ? state.uri.queryParameters['goal']!
            : 'learn';
        return PlacementTestPage(
          languageCode: languageCode,
          goalCode: goalCode,
        );
      },
    ),
    GoRoute(
      path: '/onboarding/placement-test/result',
      builder: (context, state) {
        final String goalCode =
            state.uri.queryParameters['goal']?.trim().isNotEmpty == true
            ? state.uri.queryParameters['goal']!
            : 'learn';
        return PlacementTestResultPage(
          goalCode: goalCode,
          result: state.extra is PlacementTestResult
              ? state.extra! as PlacementTestResult
              : null,
        );
      },
    ),
    GoRoute(
      path: '/library',
      pageBuilder: (context, state) =>
          const NoTransitionPage<void>(child: LibraryPage()),
    ),
    GoRoute(
      path: '/library/:bookId',
      builder: (context, state) {
        final String bookId = state.pathParameters['bookId'] ?? '';
        return BookReaderPage(bookId: bookId);
      },
    ),
    GoRoute(
      path: '/courses',
      pageBuilder: (context, state) =>
          const NoTransitionPage<void>(child: CourseCatalogPage()),
    ),
    GoRoute(
      path: '/chat',
      pageBuilder: (context, state) =>
          const NoTransitionPage<void>(child: ChatPage()),
    ),
    GoRoute(
      path: '/courses/:courseId',
      builder: (context, state) {
        final String courseId = state.pathParameters['courseId'] ?? '';
        return CourseDetailsPage(courseId: courseId);
      },
    ),
    GoRoute(
      path: '/courses/:courseId/lesson',
      builder: (context, state) {
        final String courseId = state.pathParameters['courseId'] ?? '';
        final String? lessonId =
            state.uri.queryParameters['lessonId']?.trim().isNotEmpty == true
            ? state.uri.queryParameters['lessonId']
            : null;
        return LessonPage(courseId: courseId, lessonId: lessonId);
      },
    ),
    GoRoute(
      path: '/courses/:courseId/lesson/summary',
      builder: (context, state) {
        final String courseId = state.pathParameters['courseId'] ?? '';
        final int score =
            int.tryParse(state.uri.queryParameters['score'] ?? '') ?? 0;
        return LessonSummaryPage(courseId: courseId, score: score);
      },
    ),
    GoRoute(
      path: '/courses/:courseId/module-test',
      builder: (context, state) {
        final String courseId = state.pathParameters['courseId'] ?? '';
        final String? moduleId =
            state.uri.queryParameters['moduleId']?.trim().isNotEmpty == true
            ? state.uri.queryParameters['moduleId']
            : null;
        return ModuleTestPage(courseId: courseId, moduleId: moduleId);
      },
    ),
    GoRoute(
      path: '/courses/:courseId/module-test/result',
      builder: (context, state) {
        final String courseId = state.pathParameters['courseId'] ?? '';
        final int score =
            int.tryParse(state.uri.queryParameters['score'] ?? '') ?? 0;
        return ModuleTestResultPage(courseId: courseId, score: score);
      },
    ),
    GoRoute(
      path: '/courses/:courseId/certificate',
      builder: (context, state) {
        final String courseId = state.pathParameters['courseId'] ?? '';
        return CertificatePage(courseId: courseId);
      },
    ),
    GoRoute(
      path: '/dictionary',
      pageBuilder: (context, state) =>
          const NoTransitionPage<void>(child: DictionaryPage()),
    ),
    GoRoute(
      path: '/dictionary/review',
      builder: (context, state) => const WordReviewPage(),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) =>
          const NoTransitionPage<void>(child: ProfilePage()),
    ),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          const NoTransitionPage<void>(child: HomePage()),
    ),
  ],
);

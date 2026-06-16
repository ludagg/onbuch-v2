import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/onboarding/splash_screen.dart';
import '../screens/onboarding/value_screens.dart';
import '../screens/onboarding/auth_phone_screen.dart';
import '../screens/onboarding/profile_setup_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/main_shell.dart';
import '../screens/home/home_screen.dart';
import '../screens/school/school_life_screen.dart';
import '../screens/results/results_search_screen.dart';
import '../screens/results/result_success_screen.dart';
import '../screens/results/result_fail_screen.dart';
import '../screens/annales/annales_library_screen.dart';
import '../screens/annales/annales_folder_screen.dart';
import '../screens/annales/annale_detail_screen.dart';
import '../screens/annales/pdf_reader_screen.dart';
import '../screens/annales/video_corrige_screen.dart';
import '../screens/tutor/tutor_hub_screen.dart';
import '../screens/tutor/tutor_camera_screen.dart';
import '../screens/tutor/tutor_correction_screen.dart';
import '../screens/tutor/tutor_similar_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../services/auth_service.dart';

final _authService = AuthService();

final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) async {
    final path = state.uri.path;
    final isPublic = path == '/splash' ||
        path.startsWith('/onboarding') ||
        path.startsWith('/auth') ||
        path == '/welcome';
    if (isPublic) return null;
    final loggedIn = await _authService.isLoggedIn();
    if (!loggedIn) return '/auth/phone';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding/1', builder: (_, __) => const Value1Screen()),
    GoRoute(path: '/onboarding/2', builder: (_, __) => const Value2Screen()),
    GoRoute(path: '/onboarding/3', builder: (_, __) => const Value3Screen()),
    GoRoute(path: '/auth/phone', builder: (_, __) => const AuthPhoneScreen()),
    GoRoute(path: '/auth/profile', builder: (_, __) => const ProfileSetupScreen()),
    GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
    ShellRoute(
      builder: (_, state, child) => MainShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/campus', builder: (_, __) => const SchoolLifeScreen()),
        GoRoute(
          path: '/results',
          builder: (_, __) => const ResultsSearchScreen(),
          routes: [
            GoRoute(path: 'success', builder: (_, __) => const ResultSuccessScreen()),
            GoRoute(path: 'fail', builder: (_, __) => const ResultFailScreen()),
          ],
        ),
        GoRoute(
          path: '/annales',
          builder: (_, __) => const AnnalesLibraryScreen(),
          routes: [
            GoRoute(path: 'folder/:name', builder: (_, s) => AnnalesFolderScreen(folderName: s.pathParameters['name'] ?? '')),
            GoRoute(path: 'detail', builder: (_, __) => const AnnaleDetailScreen()),
            GoRoute(path: 'pdf', builder: (_, __) => const PdfReaderScreen()),
            GoRoute(path: 'video', builder: (_, __) => const VideoCorrigeScreen()),
          ],
        ),
        GoRoute(
          path: '/tutor',
          builder: (_, __) => const TutorHubScreen(),
          routes: [
            GoRoute(path: 'camera', builder: (_, __) => const TutorCameraScreen()),
            GoRoute(path: 'correction', builder: (_, __) => const TutorCorrectionScreen()),
            GoRoute(path: 'similar', builder: (_, __) => const TutorSimilarScreen()),
          ],
        ),
        GoRoute(path: '/cours', builder: (_, __) => const CoursPlaceholderScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
  ],
);

class CoursPlaceholderScreen extends StatelessWidget {
  const CoursPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Cours — Bientôt disponible')),
    );
  }
}
